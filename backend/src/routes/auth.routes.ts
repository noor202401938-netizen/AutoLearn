import { Router } from 'express';
import {
  signup,
  login,
  getMe,
  getUserEnrollments,
  listUsers,
  toggleUserStatus,
} from '../controllers/auth.controller';
import { requestPasswordReset, confirmPasswordReset, changePassword } from '../controllers/account.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Public routes
router.post('/signup', signup);
router.post('/login', login);
router.post('/password-reset', requestPasswordReset);
router.post('/password-reset/confirm', confirmPasswordReset);

// Protected routes
router.get('/me', authenticateToken, getMe);
router.post('/change-password', authenticateToken, changePassword);
router.get('/users', authenticateToken, listUsers);               // Admin only
router.patch('/users/:uid/toggle-status', authenticateToken, toggleUserStatus); // Admin only

export default router;
