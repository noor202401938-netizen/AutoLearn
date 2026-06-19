import { Router } from 'express';
import { 
  updateVideoProgress, getVideoProgress,
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

// Notifications
router.get('/notifications', getNotifications);
router.put('/notifications/:id/read', markNotificationRead);

// Quiz
router.post('/quiz', saveQuizResult);

// Certificates
router.get('/certificates', getUserCertificates);

export default router;
