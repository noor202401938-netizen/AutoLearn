import { Router } from 'express';
import { 
  updateVideoProgress, getVideoProgress, getCourseCompletion, getUserStats,
  getNotifications, markNotificationRead,
  saveQuizResult,
  getUserCertificates
} from '../controllers/user_data.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Progress
router.post('/progress', updateVideoProgress);
router.get('/progress/:lessonId', getVideoProgress);
router.get('/courses/:courseId/completion', getCourseCompletion);

// User Stats
router.get('/stats', getUserStats);

// Notifications
router.get('/notifications', getNotifications);
router.put('/notifications/:id/read', markNotificationRead);

// Quiz
router.post('/quiz', saveQuizResult);

// Certificates
router.get('/certificates', getUserCertificates);

export default router;
