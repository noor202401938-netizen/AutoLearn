import { Request, Response } from 'express';
import prisma from '../prisma';
import { AuthenticatedRequest, isStaff } from '../middleware/auth.middleware';
import { canManageCourse } from '../access';

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
    syllabus: [...(course.modules || [])]
      .sort((a: any, b: any) => a.order - b.order)
      .map((m: any) => ({
        moduleId: m.id,
        title: m.title,
        lessons: [...(m.lessons || [])]
          .sort((a: any, b: any) => a.order - b.order)
          .map((l: any) => ({
            lessonId: l.id,
            title: l.title,
            type: l.type,
            duration: l.duration,
            videoURL: l.videoUrl,
            content: l.content,
          })),
      })),
  };
}

const LESSON_TYPES = ['video', 'reading', 'quiz', 'assignment', 'project'];

/**
 * Makes the course's modules/lessons match `syllabus` exactly (order included).
 * Items whose id already belongs to this course are updated in place, so
 * student progress on them survives; new items are created; anything missing
 * from `syllabus` is deleted.
 */
export async function syncSyllabus(courseId: string, syllabus: any[]): Promise<void> {
  const existing = await prisma.module.findMany({ where: { courseId }, include: { lessons: true } });
  const moduleIds = new Set(existing.map((m) => m.id));
  const lessonIds = new Set(existing.flatMap((m) => m.lessons.map((l) => l.id)));
  const keepModules = new Set<string>();
  const keepLessons = new Set<string>();

  for (const [mi, m] of syllabus.entries()) {
    const title = String(m?.title ?? '').trim() || `Module ${mi + 1}`;
    const moduleId = moduleIds.has(m?.moduleId)
      ? (await prisma.module.update({ where: { id: m.moduleId }, data: { title, order: mi } })).id
      : (await prisma.module.create({ data: { courseId, title, order: mi } })).id;
    keepModules.add(moduleId);

    for (const [li, l] of (Array.isArray(m?.lessons) ? m.lessons : []).entries()) {
      const data = {
        moduleId,
        order: li,
        title: String(l?.title ?? '').trim() || `Lesson ${li + 1}`,
        type: LESSON_TYPES.includes(l?.type) ? l.type : 'video',
        duration: Math.max(0, Math.floor(Number(l?.duration) || 0)),
        videoUrl: l?.videoURL ? String(l.videoURL) : null,
        content: l?.content ? String(l.content) : null,
      };
      const lessonId = lessonIds.has(l?.lessonId)
        ? (await prisma.lesson.update({ where: { id: l.lessonId }, data })).id
        : (await prisma.lesson.create({ data })).id;
      keepLessons.add(lessonId);
    }
  }

  await prisma.lesson.deleteMany({ where: { id: { in: [...lessonIds].filter((id) => !keepLessons.has(id)) } } });
  await prisma.module.deleteMany({ where: { id: { in: [...moduleIds].filter((id) => !keepModules.has(id)) } } });
}

// GET /api/courses — Get all courses (with optional filters & pagination)
export const getAllCourses = async (req: Request, res: Response): Promise<void> => {
  try {
    const { category, level, isPublished, search, page, limit, mine } = req.query;

    let filter: any = {};
    // A teacher's studio: only their own courses, drafts included.
    if (mine === 'true') {
      const me = (req as AuthenticatedRequest).user;
      if (!me) {
        res.status(401).json({ error: 'Unauthorized: sign in to list your courses' });
        return;
      }
      filter.createdBy = me.uid;
    }
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

    const pageNum = page ? parseInt(String(page), 10) : undefined;
    const limitNum = limit ? parseInt(String(limit), 10) : undefined;
    const skip = pageNum && limitNum ? (pageNum - 1) * limitNum : undefined;
    const take = limitNum;

    const [courses, total] = await Promise.all([
      prisma.course.findMany({
        where: filter,
        include: { modules: { include: { lessons: true } } },
        orderBy: { createdAt: 'desc' },
        ...(skip !== undefined && { skip }),
        ...(take !== undefined && { take }),
      }),
      prisma.course.count({ where: filter }),
    ]);

    if (limitNum !== undefined) {
      res.setHeader('X-Total-Count', total.toString());
      res.setHeader('X-Page', (pageNum || 1).toString());
      res.setHeader('X-Per-Page', limitNum.toString());
    }

    res.status(200).json(courses.map(mapCourse));
  } catch (error) {
    console.error('Error getting courses:', error);
    res.status(500).json({ error: 'Failed to fetch courses' });
  }
};

// GET /api/courses/:id — Get single course
export const getCourseById = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
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
    if (!isStaff(req.user?.role)) {
      res.status(403).json({ error: 'Forbidden: Staff access required' });
      return;
    }

    const {
      title, description, instructor, category, level,
      duration, thumbnailURL, price, currency, isPublished, syllabus,
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
    });
    if (Array.isArray(syllabus)) await syncSyllabus(course.id, syllabus);

    const full = await prisma.course.findUnique({ where: { id: course.id }, include: { modules: { include: { lessons: true } } } });
    res.status(201).json(mapCourse(full));
  } catch (error) {
    console.error('Error creating course:', error);
    res.status(500).json({ error: 'Failed to create course' });
  }
};

// PUT /api/courses/:id — Update a course (Admin only)
export const updateCourse = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    if (!(await canManageCourse(req.user, id))) {
      res.status(403).json({ error: 'Forbidden: you can only edit your own courses' });
      return;
    }
    const {
      title, description, instructor, category, level,
      duration, thumbnailURL, price, currency, isPublished, syllabus,
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
    });
    if (Array.isArray(syllabus)) await syncSyllabus(course.id, syllabus);

    const full = await prisma.course.findUnique({ where: { id: course.id }, include: { modules: { include: { lessons: true } } } });
    res.status(200).json(mapCourse(full));
  } catch (error) {
    console.error('Error updating course:', error);
    res.status(500).json({ error: 'Failed to update course' });
  }
};

// DELETE /api/courses/:id — Delete a course (Admin only)
export const deleteCourse = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    if (!(await canManageCourse(req.user, id))) {
      res.status(403).json({ error: 'Forbidden: you can only delete your own courses' });
      return;
    }
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
    const id = req.params.id as string;
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

    const existing = await prisma.enrollment.findUnique({ where: { userId_courseId: { userId, courseId: id } } });
    if (existing) {
      // Already enrolled — don't double count, and don't reset a completed course.
      res.status(200).json(existing);
      return;
    }

    // Paid courses are enrolled by the Stripe webhook once payment succeeds.
    if (course.price > 0) {
      const paid = await prisma.payment.findFirst({ where: { userId, courseId: id, status: 'succeeded' } });
      if (!paid) {
        res.status(402).json({ error: 'This course requires payment before enrolling' });
        return;
      }
    }

    const enrollment = await prisma.enrollment.create({ data: { userId, courseId: id, status: 'active' } });
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
    const id = req.params.id as string;
    const { rating } = req.body;

    if (typeof rating !== 'number' || rating < 0 || rating > 5) {
      res.status(400).json({ error: 'Rating must be a number between 0 and 5' });
      return;
    }

    // One rating per enrolled student; re-rating replaces their earlier one.
    const userId = req.user!.uid;
    const { count } = await prisma.enrollment.updateMany({ where: { userId, courseId: id }, data: { rating } });
    if (count === 0) {
      res.status(403).json({ error: 'Enrol in the course before rating it' });
      return;
    }
    const agg = await prisma.enrollment.aggregate({
      where: { courseId: id, rating: { not: null } },
      _avg: { rating: true },
      _count: { rating: true },
    });
    const updated = await prisma.course.update({
      where: { id },
      data: { rating: agg._avg.rating ?? 0, ratingCount: agg._count.rating },
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
    const id = req.params.id as string;
    
    const course = await prisma.course.findUnique({ where: { id } });
    if (!course) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }

    const averageTimeSpent = await prisma.progress.aggregate({
      _avg: { totalDuration: true }
    });

    res.status(200).json({
      totalEnrollments: course.enrollmentCount,
      completionRate: 0.0,
      averageScore: course.rating,
      averageTimeSpent: averageTimeSpent._avg?.totalDuration || 0,
    });
  } catch (error) {
    console.error('Error fetching course stats:', error);
    res.status(500).json({ error: 'Failed to fetch course stats' });
  }
};
