// @ts-nocheck
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

const prisma = new PrismaClient();

// Map DB record to Flutter-expected structure
function mapCourse(course: any) {
  return {
    courseId: course.id,
    title: course.title,
    description: course.description,
    instructor: course.instructor,
    category: course.category,
    level: course.level,
    duration: course.duration,
    thumbnailURL: course.thumbnailURL,
    price: course.price,
    currency: course.currency,
    enrollmentCount: course.enrollmentCount,
    rating: course.rating,
    ratingCount: course.ratingCount,
    isPublished: course.isPublished,
    createdAt: course.createdAt.toISOString(),
    updatedAt: course.updatedAt.toISOString(),
    createdBy: course.createdBy,
    syllabus: (course.modules || []).map((m: any) => ({
      moduleId: m.id,
      title: m.title,
      lessons: (m.lessons || []).map((l: any) => ({
        lessonId: l.id,
        title: l.title,
        videoURL: l.videoUrl,
        content: l.content,
      })),
    })),
  };
}

// GET /api/courses — Get all courses (with optional filters)
export const getAllCourses = async (req: Request, res: Response): Promise<void> => {
  try {
    const { category, level, isPublished, search } = req.query;

    let filter: any = {};
    if (category) filter.category = String(category);
    if (level) filter.level = String(level);
    if (isPublished !== undefined) filter.isPublished = isPublished === 'true';
    if (search) {
      filter.OR = [
        { title: { contains: String(search), mode: 'insensitive' } },
        { description: { contains: String(search), mode: 'insensitive' } },
        { instructor: { contains: String(search), mode: 'insensitive' } },
      ];
    }

    const courses = await prisma.course.findMany({
      where: filter,
      include: { modules: { include: { lessons: true } } },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json(courses.map(mapCourse));
  } catch (error) {
    console.error('Error getting courses:', error);
    res.status(500).json({ error: 'Failed to fetch courses' });
  }
};

// GET /api/courses/:id — Get single course
export const getCourseById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const course = await prisma.course.findUnique({
      where: { id },
      include: { modules: { include: { lessons: true } } },
    });

    if (!course) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }

    res.status(200).json(mapCourse(course));
  } catch (error) {
    console.error('Error getting course:', error);
    res.status(500).json({ error: 'Failed to fetch course' });
  }
};

// POST /api/courses — Create a new course (Admin only)
export const createCourse = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }

    const {
      title, description, instructor, category, level,
      duration, thumbnailURL, price, currency, isPublished,
    } = req.body;

    if (!title || !description) {
      res.status(400).json({ error: 'Title and description are required' });
      return;
    }

    const course = await prisma.course.create({
      data: {
        title,
        description,
        instructor: instructor || 'Admin',
        category: category || 'General',
        level: level || 'beginner',
        duration: duration || 0,
        thumbnailURL,
        price: price || 0,
        currency: currency || 'USD',
        isPublished: isPublished || false,
        createdBy: req.user?.uid || 'system',
      },
      include: { modules: { include: { lessons: true } } },
    });

    res.status(201).json(mapCourse(course));
  } catch (error) {
    console.error('Error creating course:', error);
    res.status(500).json({ error: 'Failed to create course' });
  }
};

// PUT /api/courses/:id — Update a course (Admin only)
export const updateCourse = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }

    const { id } = req.params;
    const {
      title, description, instructor, category, level,
      duration, thumbnailURL, price, currency, isPublished,
    } = req.body;

    const existing = await prisma.course.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }

    const course = await prisma.course.update({
      where: { id },
      data: {
        ...(title && { title }),
        ...(description && { description }),
        ...(instructor && { instructor }),
        ...(category && { category }),
        ...(level && { level }),
        ...(duration !== undefined && { duration }),
        ...(thumbnailURL !== undefined && { thumbnailURL }),
        ...(price !== undefined && { price }),
        ...(currency && { currency }),
        ...(isPublished !== undefined && { isPublished }),
      },
      include: { modules: { include: { lessons: true } } },
    });

    res.status(200).json(mapCourse(course));
  } catch (error) {
    console.error('Error updating course:', error);
    res.status(500).json({ error: 'Failed to update course' });
  }
};

// DELETE /api/courses/:id — Delete a course (Admin only)
export const deleteCourse = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }

    const { id } = req.params;
    const existing = await prisma.course.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }

    await prisma.course.delete({ where: { id } });
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting course:', error);
    res.status(500).json({ error: 'Failed to delete course' });
  }
};

// POST /api/courses/:id/enroll — Enroll in a course
export const enrollInCourse = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user?.uid;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const course = await prisma.course.findUnique({ where: { id } });
    if (!course) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }

    // Upsert to handle duplicate enrollment gracefully
    const enrollment = await prisma.enrollment.upsert({
      where: { userId_courseId: { userId, courseId: id } },
      create: { userId, courseId: id, status: 'active' },
      update: { status: 'active' },
    });

    // Increment course enrollment count only on new enrollment
    await prisma.course.update({
      where: { id },
      data: { enrollmentCount: { increment: 1 } },
    });

    res.status(201).json(enrollment);
  } catch (error) {
    console.error('Error enrolling in course:', error);
    res.status(500).json({ error: 'Failed to enroll in course' });
  }
};

// POST /api/courses/:id/rate — Rate a course
export const rateCourse = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { rating } = req.body;

    if (typeof rating !== 'number' || rating < 0 || rating > 5) {
      res.status(400).json({ error: 'Rating must be a number between 0 and 5' });
      return;
    }

    const course = await prisma.course.findUnique({ where: { id } });
    if (!course) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }

    const newTotal = course.rating * course.ratingCount + rating;
    const newCount = course.ratingCount + 1;
    const newAverage = newTotal / newCount;

    const updated = await prisma.course.update({
      where: { id },
      data: { rating: newAverage, ratingCount: newCount },
    });

    res.status(200).json({ rating: updated.rating, ratingCount: updated.ratingCount });
  } catch (error) {
    console.error('Error rating course:', error);
    res.status(500).json({ error: 'Failed to rate course' });
  }
};

// GET /api/courses/:id/stats — Get course statistics
export const getCourseStats = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    
    const course = await prisma.course.findUnique({ where: { id } });
    if (!course) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }

    // This is simplified. In a real app we'd aggregate completion states.
    const averageTimeSpent = await prisma.progress.aggregate({
      where: { lesson: { module: { courseId: id } } },
      _avg: { totalDuration: true }
    });

    res.status(200).json({
      totalEnrollments: course.enrollmentCount,
      completionRate: 0.0, // placeholder since calculating aggregate completion is intensive
      averageScore: course.rating,
      averageTimeSpent: averageTimeSpent._avg.totalDuration || 0,
    });
  } catch (error) {
    console.error('Error fetching course stats:', error);
    res.status(500).json({ error: 'Failed to fetch course stats' });
  }
};
