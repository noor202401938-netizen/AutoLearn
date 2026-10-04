import { Response } from 'express';
import prisma from '../prisma';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { canLearnIn } from '../access';
import { isObjectId, optionalText } from '../validation';

// PROFILE
export const getUserProfile = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
        role: true,
        phone: true,
        grade: true,
        interest: true,
        isActive: true,
      }
    });

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.status(200).json(user);
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updateUserProfile = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const limits = { displayName: 80, phone: 30, grade: 40, interest: 80 } as const;
    const data: Partial<Record<keyof typeof limits, string>> = {};
    for (const [field, max] of Object.entries(limits) as [keyof typeof limits, number][]) {
      const value = optionalText(req.body?.[field], max);
      if (value === 'too-long') {
        res.status(400).json({ error: `${field} must be at most ${max} characters` });
        return;
      }
      if (value !== undefined) data[field] = value;
    }

    const user = await prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        email: true,
        displayName: true,
        role: true,
        phone: true,
        grade: true,
        interest: true,
        isActive: true,
      }
    });

    res.status(200).json(user);
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// PROGRESS
export const updateVideoProgress = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { lessonId, currentPosition, totalDuration, isCompleted } = req.body;
    const userId = req.user?.uid;

    if (!userId || !isObjectId(lessonId)) {
      res.status(400).json({ error: 'A valid lessonId is required' });
      return;
    }
    const lesson = await prisma.lesson.findUnique({ where: { id: lessonId }, select: { module: { select: { courseId: true } } } });
    if (!lesson) {
      res.status(404).json({ error: 'Lesson not found' });
      return;
    }
    // Progress (and so completion and certificates) only counts for people enrolled in the course.
    if (!(await canLearnIn(req.user, lesson.module.courseId))) {
      res.status(403).json({ error: 'Enrol in this course to track your progress' });
      return;
    }
    const seconds = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) && v >= 0 ? Math.floor(v) : 0);
    const position = seconds(currentPosition);
    const duration = seconds(totalDuration);

    const progress = await prisma.progress.upsert({
      where: {
        userId_lessonId: { userId, lessonId }
      },
      update: {
        currentPosition: position,
        totalDuration: duration,
        // Completion is sticky: rewatching a lesson never un-completes it.
        ...(isCompleted === true && { isCompleted: true }),
      },
      create: {
        userId,
        lessonId,
        currentPosition: position,
        totalDuration: duration,
        isCompleted: isCompleted === true,
      }
    });

    res.status(200).json(progress);
  } catch (error) {
    console.error('Error updating progress:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getVideoProgress = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const lessonId = req.params.lessonId as string;
    const userId = req.user?.uid;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const progress = await prisma.progress.findUnique({
      where: { userId_lessonId: { userId, lessonId } }
    });

    res.status(200).json(progress || { currentPosition: 0, isCompleted: false });
  } catch (error) {
    console.error('Error fetching progress:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getCourseCompletion = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const courseId = req.params.courseId as string;
    const userId = req.user?.uid;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    // Find all lessons for this course
    const course = await prisma.course.findUnique({
      where: { id: courseId },
      include: { modules: { include: { lessons: true } } }
    });

    if (!course) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }

    const lessonIds = (course.modules || []).flatMap((m: any) => (m.lessons || []).map((l: any) => l.id as string));
    if (lessonIds.length === 0) {
      res.status(200).json({ completionPercentage: 0 });
      return;
    }

    const completedProgress = await prisma.progress.count({
      where: {
        userId,
        lessonId: { in: lessonIds },
        isCompleted: true
      }
    });

    const completionPercentage = (completedProgress / lessonIds.length) * 100;
    res.status(200).json({ completionPercentage });
  } catch (error) {
    console.error('Error fetching course completion:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

/** Consecutive days (ending today or yesterday) with any study activity. */
export function streakDays(activity: Date[], now = new Date()): number {
  const day = (d: Date) => Math.floor((d.getTime() - d.getTimezoneOffset() * 60_000) / 86_400_000);
  const days = new Set(activity.map(day));
  let d = day(now);
  if (!days.has(d)) d -= 1; // today not started yet doesn't break the streak
  let streak = 0;
  while (days.has(d)) {
    streak++;
    d--;
  }
  return streak;
}

export const getUserStats = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const [enrolledCourses, completedCourses, totalLessonsWatched, totalQuizzesTaken, certificates, progress] = await Promise.all([
      prisma.enrollment.count({ where: { userId } }),
      prisma.enrollment.count({ where: { userId, status: 'completed' } }),
      prisma.progress.count({ where: { userId, isCompleted: true } }),
      prisma.quizSubmission.count({ where: { userId } }),
      prisma.certificate.count({ where: { userId } }),
      prisma.progress.findMany({ where: { userId }, select: { currentPosition: true, updatedAt: true } }),
    ]);

    res.status(200).json({
      enrolledCourses,
      completedCourses,
      totalLessonsWatched,
      totalQuizzesTaken,
      certificates,
      // Watch position is the best measure of video time we record.
      hoursLearned: Math.round((progress.reduce((s, p) => s + p.currentPosition, 0) / 3600) * 10) / 10,
      streakDays: streakDays(progress.map((p) => p.updatedAt)),
    });
  } catch (error) {
    console.error('Error fetching user stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// NOTIFICATIONS
export const getNotifications = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.uid;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { page, limit } = req.query;
    const pageNum = page ? parseInt(String(page), 10) : undefined;
    const limitNum = limit ? parseInt(String(limit), 10) : undefined;
    const skip = pageNum && limitNum ? (pageNum - 1) * limitNum : undefined;
    const take = limitNum;

    const [notifications, total] = await Promise.all([
      prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        ...(skip !== undefined && { skip }),
        ...(take !== undefined && { take }),
      }),
      prisma.notification.count({ where: { userId } }),
    ]);

    if (limitNum !== undefined) {
      res.setHeader('X-Total-Count', total.toString());
      res.setHeader('X-Page', (pageNum || 1).toString());
      res.setHeader('X-Per-Page', limitNum.toString());
    }

    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const markNotificationRead = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    // Scoped to the caller so nobody can touch someone else's notifications.
    const { count } = await prisma.notification.updateMany({
      where: { id, userId: req.user!.uid },
      data: { isRead: true }
    });
    res.status(count ? 200 : 404).json({ id, isRead: count > 0 });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getUnreadCount = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const count = await prisma.notification.count({ where: { userId: req.user!.uid, isRead: false } });
    res.status(200).json({ count });
  } catch (error) {
    console.error('Unread count error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const markAllNotificationsRead = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    await prisma.notification.updateMany({ where: { userId: req.user!.uid, isRead: false }, data: { isRead: true } });
    res.status(204).end();
  } catch (error) {
    console.error('Mark all read error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const createNotification = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { userId, title, message, type } = req.body;
    const targetUserId = userId || req.user?.uid;
    if (!targetUserId) {
      res.status(400).json({ error: 'Missing userId' });
      return;
    }

    const notification = await prisma.notification.create({
      data: {
        userId: targetUserId,
        title,
        message,
        type: type || 'system',
      }
    });
    res.status(200).json(notification);
  } catch (error) {
    console.error('Broadcast notification error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getBroadcastHistory = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }

    const broadcasts = await prisma.adminBroadcast.findMany({
      orderBy: { sentAt: 'desc' },
      take: 50,
    });

    res.status(200).json(broadcasts);
  } catch (error) {
    console.error('Get broadcast history error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const broadcastNotification = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const title = String(req.body?.title ?? '').trim();
    const message = String(req.body?.message ?? '').trim();
    const type = String(req.body?.type ?? 'system');
    if (!title || !message) {
      res.status(400).json({ error: 'An announcement needs a title and a message' });
      return;
    }

    const students = await prisma.user.findMany({
      where: { role: 'student' }
    });

    const notificationsData = students.map(student => ({
      userId: student.id,
      title,
      message,
      type: type || 'system',
    }));

    if (notificationsData.length > 0) {
      await prisma.notification.createMany({
        data: notificationsData
      });
    }

    await prisma.adminBroadcast.create({
      data: {
        title,
        message,
        type,
      },
    });

    res.status(200).json({ message: `Broadcast sent to ${students.length} students` });
  } catch (error) {
    console.error('Error broadcasting notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};


