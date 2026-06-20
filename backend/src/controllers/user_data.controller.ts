// @ts-nocheck
import { Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

const prisma = new PrismaClient();

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

    const { displayName, phone, grade, interest } = req.body;

    const user = await prisma.user.update({
      where: { id: userId },
      data: { displayName, phone, grade, interest },
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

    if (!userId || !lessonId) {
      res.status(400).json({ error: 'Missing userId or lessonId' });
      return;
    }

    const progress = await prisma.progress.upsert({
      where: {
        userId_lessonId: { userId, lessonId }
      },
      update: {
        currentPosition,
        totalDuration,
        isCompleted
      },
      create: {
        userId,
        lessonId,
        currentPosition,
        totalDuration,
        isCompleted
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
    const { lessonId } = req.params;
    const userId = req.user?.uid;

    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

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
    const { courseId } = req.params;
    const userId = req.user?.uid;

    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    // Find all lessons for this course
    const course = await prisma.course.findUnique({
      where: { id: courseId },
      include: { modules: { include: { lessons: true } } }
    });

    if (!course) return res.status(404).json({ error: 'Course not found' });

    const lessonIds = course.modules.flatMap(m => m.lessons.map(l => l.id));
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

export const getUserStats = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.uid;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const enrolledCourses = await prisma.enrollment.count({ where: { userId } });
    const completedCourses = await prisma.enrollment.count({ where: { userId, status: 'completed' } });
    const totalLessonsWatched = await prisma.progress.count({ where: { userId, isCompleted: true } });
    const totalQuizzesTaken = await prisma.quizResult.count({ where: { userId } });

    res.status(200).json({
      enrolledCourses,
      completedCourses,
      totalLessonsWatched,
      totalQuizzesTaken,
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
    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' }
    });
    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const markNotificationRead = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const notification = await prisma.notification.update({
      where: { id },
      data: { isRead: true }
    });
    res.status(200).json(notification);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// QUIZZES
export const saveQuizResult = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { moduleId, score, totalQuestions, passed } = req.body;
    const userId = req.user?.uid;

    const result = await prisma.quizResult.create({
      data: { userId, moduleId, score, totalQuestions, passed }
    });
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// CERTIFICATES
export const getUserCertificates = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.uid;
    const certificates = await prisma.certificate.findMany({
      where: { userId },
      include: { course: true },
      orderBy: { issueDate: 'desc' }
    });
    res.status(200).json(certificates);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
