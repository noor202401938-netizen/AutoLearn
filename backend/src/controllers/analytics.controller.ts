import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getAdminAnalytics = async (req: Request, res: Response) => {
  try {
    const totalCourses = await prisma.course.count();
    const publishedCourses = await prisma.course.count({ where: { isPublished: true } });
    const totalUsers = await prisma.user.count();

    const enrollments = await prisma.enrollment.findMany();
    const totalEnrollments = enrollments.length;

    // Sum of successful payments
    const payments = await prisma.payment.findMany({ where: { status: 'succeeded' } });
    const totalRevenue = payments.reduce((sum, p) => sum + p.amount, 0);

    // Get courses for chart
    const courses = await prisma.course.findMany({
      select: {
        title: true,
        enrollmentCount: true,
      },
      take: 10,
      orderBy: { enrollmentCount: 'desc' },
    });

    res.status(200).json({
      totalCourses,
      publishedCourses,
      totalUsers,
      totalEnrollments,
      totalRevenue,
      courses,
    });
  } catch (error: any) {
    console.error('Error fetching analytics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
