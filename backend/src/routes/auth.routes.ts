import { Router } from 'express';
import {
  signup,
  login,
  getMe,
  getUserEnrollments,
  listUsers,
  toggleUserStatus,
} from '../controllers/auth.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Public routes
router.post('/signup', signup);
router.post('/login', login);

// Protected routes
router.get('/me', authenticateToken, getMe);
router.get('/users', authenticateToken, listUsers);               // Admin only
router.patch('/users/:uid/toggle-status', authenticateToken, toggleUserStatus); // Admin only

export default router;
