import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jwt-simple';
import { PrismaClient } from '@prisma/client';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_for_dev_only';
const JWT_EXPIRY_DAYS = 7;

function createToken(uid: string, role: string): string {
  const exp = Math.floor(Date.now() / 1000) + JWT_EXPIRY_DAYS * 24 * 60 * 60;
  return jwt.encode({ uid, role, exp }, JWT_SECRET);
}

export const signup = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, displayName } = req.body;

    if (!email || !password) {
      res.status(400).json({ error: 'Email and password are required' });
      return;
    }

    if (password.length < 6) {
      res.status(400).json({ error: 'Password must be at least 6 characters' });
      return;
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      res.status(400).json({ error: 'User already exists with this email' });
      return;
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        displayName,
        role: 'student',
      },
    });

    const token = createToken(user.id, user.role);

    res.status(201).json({
      token,
      user: {
        uid: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({ error: 'Email and password are required' });
      return;
    }

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    if (!user.isActive) {
      res.status(403).json({ error: 'Account is disabled. Contact support.' });
      return;
    }

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    const token = createToken(user.id, user.role);

    res.status(200).json({
      token,
      user: {
        uid: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/auth/me — Get current user profile (requires auth)
export const getMe = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const uid = req.user?.uid;
    if (!uid) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: uid },
      select: {
        id: true,
        email: true,
        displayName: true,
        role: true,
        phone: true,
        grade: true,
        interest: true,
        isActive: true,
        createdAt: true,
        _count: { select: { enrollments: true, certificates: true } },
      },
    });

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.status(200).json({
      uid: user.id,
      email: user.email,
      displayName: user.displayName,
      role: user.role,
      phone: user.phone,
      grade: user.grade,
      interest: user.interest,
      isActive: user.isActive,
      createdAt: user.createdAt,
      enrollmentCount: user._count.enrollments,
      certificateCount: user._count.certificates,
    });
  } catch (error) {
    console.error('Get me error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/user/enrollments — Get user's enrolled courses
export const getUserEnrollments = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const uid = req.user?.uid;
    if (!uid) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const enrollments = await prisma.enrollment.findMany({
      where: { userId: uid },
      include: {
        course: {
          include: { modules: { include: { lessons: true } } },
        },
        user: {
          include: { progress: true },
        }
      },
      orderBy: { enrolledAt: 'desc' },
    });

    res.status(200).json(
      enrollments.map((e) => {
        // Calculate progress
        let completedLessons = 0;
        let totalLessons = 0;
        e.course.modules.forEach(m => {
          totalLessons += m.lessons.length;
          m.lessons.forEach(l => {
            if (e.user.progress.some(p => p.lessonId === l.id && p.isCompleted)) {
              completedLessons++;
            }
          });
        });
        const progressPercent = totalLessons === 0 ? 0 : completedLessons / totalLessons;
        
        return {
          enrollmentId: e.id,
          courseId: e.courseId,
          status: e.status,
          enrolledAt: e.enrolledAt,
          progressPercent: progressPercent,
          course: {
            courseId: e.course.id,
            title: e.course.title,
            description: e.course.description,
            instructor: e.course.instructor,
            thumbnailURL: e.course.thumbnailURL,
            level: e.course.level,
            duration: e.course.duration,
          },
        };
      })
    );
  } catch (error) {
    console.error('Get enrollments error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/auth/users (Admin only) — List all users
export const listUsers = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }

    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        displayName: true,
        role: true,
        isActive: true,
        createdAt: true,
        _count: { select: { enrollments: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json(
      users.map((u) => ({
        uid: u.id,
        email: u.email,
        displayName: u.displayName,
        role: u.role,
        isActive: u.isActive,
        createdAt: u.createdAt,
        enrollmentCount: u._count.enrollments,
      }))
    );
  } catch (error) {
    console.error('List users error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// PATCH /api/auth/users/:uid/toggle-status (Admin only)
export const toggleUserStatus = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }

    const uid = String(req.params.uid);
    const user = await prisma.user.findUnique({ where: { id: uid } });
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    const updated = await prisma.user.update({
      where: { id: uid },
      data: { isActive: !user.isActive },
    });

    res.status(200).json({ uid: updated.id, isActive: updated.isActive });
  } catch (error) {
    console.error('Toggle user status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
