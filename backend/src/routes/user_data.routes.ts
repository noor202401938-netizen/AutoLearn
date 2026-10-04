import { Router } from 'express';
import { 
  updateVideoProgress, getVideoProgress, getCourseCompletion, getUserStats,
  getNotifications, markNotificationRead, createNotification, broadcastNotification, getBroadcastHistory,
  saveQuizResult,
  getUserProfile, updateUserProfile,
  getUnreadCount, markAllNotificationsRead,
} from '../controllers/user_data.controller';
import { authenticateToken, adminOnly } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

// Profile
router.get('/profile', getUserProfile);
router.put('/profile', updateUserProfile);

// Progress
router.post('/progress', updateVideoProgress);
router.get('/progress/:lessonId', getVideoProgress);
router.get('/courses/:courseId/completion', getCourseCompletion);

// User Stats
router.get('/stats', getUserStats);

// Notifications
router.get('/notifications', getNotifications);
router.get('/notifications/unread-count', getUnreadCount);
router.put('/notifications/read-all', markAllNotificationsRead);
router.put('/notifications/:id/read', markNotificationRead);
router.post('/notifications', adminOnly, createNotification);
router.post('/notifications/broadcast', adminOnly, broadcastNotification);
router.get('/notifications/broadcast-history', adminOnly, getBroadcastHistory);

// Quiz
router.post('/quiz', saveQuizResult);

export default router;
