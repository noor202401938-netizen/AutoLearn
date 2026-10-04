import { Router } from 'express';
import { 
  updateVideoProgress, getVideoProgress, getCourseCompletion, getUserStats,
  getNotifications, markNotificationRead, createNotification, broadcastNotification, getBroadcastHistory,
  getUserProfile, updateUserProfile,
  getUnreadCount, markAllNotificationsRead,
} from '../controllers/user_data.controller';
import { authenticateToken, adminOnly } from '../middleware/auth.middleware';
import { objectIdParam } from '../validation';

const router = Router();

router.use(authenticateToken);

// Malformed ids are "not found", never a server error.
router.param('lessonId', objectIdParam('Lesson not found'));
router.param('courseId', objectIdParam('Course not found'));
router.param('id', objectIdParam('Notification not found'));

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

// Quiz scores are only ever computed and stored by the server (POST /api/user/quizzes/:id/submit);
// the old client-reported POST /quiz endpoint was removed because it accepted any score.

export default router;
