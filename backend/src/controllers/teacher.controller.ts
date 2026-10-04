// Teacher workspace (/api/teacher): everything is scoped to courses the caller manages.
import { Response } from 'express';
import prisma from '../prisma';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { canManageCourse, managedCourseIds } from '../access';

const DAY = 86_400_000;
const isObjectId = (s: unknown): s is string => typeof s === 'string' && /^[a-f0-9]{24}$/.test(s);

function fail(res: Response, where: string, error: unknown) {
  console.error(`${where} error:`, error);
  res.status(500).json({ error: 'Internal server error' });
}

const nameOf = (u: { displayName: string | null; email: string }) => u.displayName || u.email;

/** Clamp a mark to 0..max as a whole number; null if it isn't a number. */
export function clampScore(value: unknown, max: number): number | null {
  const n = Number(value);
  if (value === '' || value === null || value === undefined || !Number.isFinite(n)) return null;
  return Math.min(Math.max(Math.round(n), 0), max);
}

// GET /api/teacher/overview
export const getOverview = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const ids = await managedCourseIds(req.user!);
    const courses = await prisma.course.findMany({
      where: { id: { in: ids } },
      select: { id: true, title: true, isPublished: true, enrollmentCount: true, rating: true, ratingCount: true },
      orderBy: { createdAt: 'desc' },
    });
    const assignments = await prisma.assignment.findMany({ where: { courseId: { in: ids } }, select: { id: true } });
    const lessons = await prisma.lesson.findMany({ where: { module: { courseId: { in: ids } } }, select: { id: true } });
    const [enrollments, completed, toMark, openQuestions, quizzes, active] = await Promise.all([
      prisma.enrollment.count({ where: { courseId: { in: ids } } }),
      prisma.enrollment.count({ where: { courseId: { in: ids }, status: 'completed' } }),
      prisma.assignmentSubmission.count({ where: { isGraded: false, assignmentId: { in: assignments.map((a) => a.id) } } }),
      prisma.forumThread.count({ where: { replyCount: 0, courseId: { in: ids } } }),
      prisma.quizSubmission.aggregate({
        where: { quiz: { courseId: { in: ids } } },
        _avg: { score: true },
        _count: { score: true },
      }),
      prisma.progress.findMany({
        where: { updatedAt: { gte: new Date(Date.now() - 7 * DAY) }, lessonId: { in: lessons.map((l) => l.id) } },
        select: { userId: true },
      }),
    ]);
    res.status(200).json({
      courses,
      totalCourses: courses.length,
      publishedCourses: courses.filter((c) => c.isPublished).length,
      totalEnrollments: enrollments,
      completionRate: enrollments === 0 ? 0 : completed / enrollments,
      activeLearners7d: new Set(active.map((p) => p.userId)).size,
      averageQuizScore: quizzes._avg.score,
      quizzesTaken: quizzes._count.score,
      assignmentsToMark: toMark,
      unansweredQuestions: openQuestions,
    });
  } catch (e) {
    fail(res, 'Teacher overview', e);
  }
};

// GET /api/teacher/courses/:id/students — roster with progress
export const getCourseStudents = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const courseId = String(req.params.id);
  try {
    if (!(await canManageCourse(req.user, courseId))) {
      res.status(403).json({ error: 'Forbidden: this is not your course' });
      return;
    }
    const lessons = await prisma.lesson.findMany({ where: { module: { courseId } }, select: { id: true } });
    const lessonIds = lessons.map((l) => l.id);
    const enrollments = await prisma.enrollment.findMany({
      where: { courseId },
      include: { user: { select: { id: true, email: true, displayName: true } } },
      orderBy: { enrolledAt: 'desc' },
    });
    const userIds = enrollments.map((e) => e.userId);
    const [progress, quizzes] = await Promise.all([
      prisma.progress.findMany({
        where: { userId: { in: userIds }, lessonId: { in: lessonIds } },
        select: { userId: true, isCompleted: true, updatedAt: true },
      }),
      prisma.quizSubmission.findMany({
        where: { userId: { in: userIds }, quiz: { courseId } },
        select: { userId: true, score: true },
      }),
    ]);
    res.status(200).json(
      enrollments.map((e) => {
        const mine = progress.filter((p) => p.userId === e.userId);
        const scores = quizzes.filter((q) => q.userId === e.userId).map((q) => q.score);
        const last = mine.reduce<Date | null>((m, p) => (!m || p.updatedAt > m ? p.updatedAt : m), null);
        return {
          userId: e.userId,
          name: nameOf(e.user),
          email: e.user.email,
          status: e.status,
          enrolledAt: e.enrolledAt,
          lastActiveAt: last,
          lessonsDone: mine.filter((p) => p.isCompleted).length,
          lessonCount: lessonIds.length,
          averageQuizScore: scores.length ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : null,
        };
      }),
    );
  } catch (e) {
    fail(res, 'Teacher roster', e);
  }
};

// GET /api/teacher/submissions?status=pending|graded|all
export const listSubmissions = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const status = String(req.query.status ?? 'pending');
    const ids = await managedCourseIds(req.user!);
    const rows = await prisma.assignmentSubmission.findMany({
      where: {
        assignment: { courseId: { in: ids } },
        ...(status === 'pending' && { isGraded: false }),
        ...(status === 'graded' && { isGraded: true }),
      },
      include: {
        user: { select: { email: true, displayName: true } },
        assignment: { select: { title: true, maxPoints: true, courseId: true } },
      },
      orderBy: { submittedAt: 'desc' },
      take: 100,
    });
    const courses = await prisma.course.findMany({ where: { id: { in: ids } }, select: { id: true, title: true } });
    const titles = new Map(courses.map((c) => [c.id, c.title]));
    res.status(200).json(
      rows.map(({ user, assignment, ...s }) => ({
        ...s,
        studentName: nameOf(user),
        studentEmail: user.email,
        assignmentTitle: assignment.title,
        maxPoints: assignment.maxPoints,
        courseTitle: titles.get(assignment.courseId) ?? '',
      })),
    );
  } catch (e) {
    fail(res, 'Teacher submissions', e);
  }
};

// PUT /api/teacher/submissions/:id/grade { score, feedback } — mark or override the AI's mark
export const gradeSubmission = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const id = String(req.params.id);
  try {
    const sub = isObjectId(id)
      ? await prisma.assignmentSubmission.findUnique({ where: { id }, include: { assignment: true } })
      : null;
    if (!sub) {
      res.status(404).json({ error: 'Submission not found' });
      return;
    }
    if (!(await canManageCourse(req.user, sub.assignment.courseId))) {
      res.status(403).json({ error: 'Forbidden: this is not your course' });
      return;
    }
    const score = clampScore(req.body?.score, sub.assignment.maxPoints);
    if (score === null) {
      res.status(400).json({ error: `Give a mark between 0 and ${sub.assignment.maxPoints}` });
      return;
    }
    const feedback = String(req.body?.feedback ?? '').trim().slice(0, 5000);
    const updated = await prisma.assignmentSubmission.update({
      where: { id },
      data: { score, feedback, isGraded: true, gradedAt: new Date() },
    });
    await prisma.notification.create({
      data: {
        userId: sub.userId,
        title: 'Your assignment was marked',
        message: `${sub.assignment.title}: ${score}/${sub.assignment.maxPoints}`,
        type: 'course',
      },
    });
    res.status(200).json(updated);
  } catch (e) {
    fail(res, 'Grade submission', e);
  }
};

// POST /api/teacher/courses/:id/announce { title, message } — notify the course's students
export const announceToCourse = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const courseId = String(req.params.id);
  const title = String(req.body?.title ?? '').trim().slice(0, 120);
  const message = String(req.body?.message ?? '').trim().slice(0, 2000);
  if (!title || !message) {
    res.status(400).json({ error: 'An announcement needs a title and a message' });
    return;
  }
  try {
    if (!(await canManageCourse(req.user, courseId))) {
      res.status(403).json({ error: 'Forbidden: this is not your course' });
      return;
    }
    const enrolled = await prisma.enrollment.findMany({ where: { courseId }, select: { userId: true } });
    if (enrolled.length > 0) {
      await prisma.notification.createMany({ data: enrolled.map((e) => ({ userId: e.userId, title, message, type: 'course' })) });
    }
    res.status(200).json({ message: `Sent to ${enrolled.length} ${enrolled.length === 1 ? 'student' : 'students'}`, count: enrolled.length });
  } catch (e) {
    fail(res, 'Course announcement', e);
  }
};
