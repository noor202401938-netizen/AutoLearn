import { Router } from 'express';
import { getAdminAnalytics } from '../controllers/analytics.controller';
import { authenticateToken, adminOnly } from '../middleware/auth.middleware';

const router = Router();

router.get('/', authenticateToken, adminOnly, getAdminAnalytics);

export default router;
