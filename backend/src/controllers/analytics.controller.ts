import { Request, Response } from 'express';
import prisma from '../prisma';

const DAY = 86_400_000;

// GET /api/admin/analytics (admin) — every number here is counted from the database.
export const getAdminAnalytics = async (_req: Request, res: Response) => {
  try {
    const now = Date.now();
    const weekAgo = new Date(now - 7 * DAY);
    const eightWeeksAgo = new Date(now - 56 * DAY);

    const [
      totalCourses, publishedCourses, students, admins,
      totalEnrollments, completedEnrollments, payments,
      recentActivity, recentSignups, quizScores, toMark, openQuestions, courses,
    ] = await Promise.all([
      prisma.course.count(),
      prisma.course.count({ where: { isPublished: true } }),
      prisma.user.count({ where: { role: 'student' } }),
      prisma.user.count({ where: { role: 'admin' } }),
      prisma.enrollment.count(),
      prisma.enrollment.count({ where: { status: 'completed' } }),
      prisma.payment.findMany({ where: { status: 'succeeded' }, select: { amount: true } }),
      prisma.progress.findMany({ where: { updatedAt: { gte: weekAgo } }, select: { userId: true } }),
      prisma.user.findMany({ where: { createdAt: { gte: eightWeeksAgo }, role: 'student' }, select: { createdAt: true } }),
      prisma.quizSubmission.aggregate({ _avg: { score: true }, _count: { score: true } }),
      prisma.assignmentSubmission.count({ where: { isGraded: false } }),
      prisma.forumThread.count({ where: { replyCount: 0 } }),
      prisma.course.findMany({
        select: { id: true, title: true, enrollmentCount: true, rating: true, ratingCount: true, isPublished: true },
        orderBy: { enrollmentCount: 'desc' },
        take: 10,
      }),
    ]);

    // Students who signed up in each of the last 8 weeks, oldest first.
    const signupsByWeek = Array.from({ length: 8 }, (_, i) => {
      const end = now - (7 - i) * 7 * DAY;
      const start = end - 7 * DAY;
      return {
        weekStart: new Date(start).toISOString().slice(0, 10),
        count: recentSignups.filter((u) => u.createdAt.getTime() >= start && u.createdAt.getTime() < end).length,
      };
    });

    res.status(200).json({
      totalCourses,
      publishedCourses,
      students,
      admins,
      totalUsers: students + admins,
      totalEnrollments,
      completedEnrollments,
      completionRate: totalEnrollments === 0 ? 0 : completedEnrollments / totalEnrollments,
      totalRevenue: payments.reduce((s, p) => s + p.amount, 0),
      activeLearners7d: new Set(recentActivity.map((p) => p.userId)).size,
      averageQuizScore: quizScores._avg.score,
      quizzesTaken: quizScores._count.score,
      assignmentsToMark: toMark,
      unansweredQuestions: openQuestions,
      signupsByWeek,
      courses,
    });
  } catch (error: any) {
    console.error('Error fetching analytics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
