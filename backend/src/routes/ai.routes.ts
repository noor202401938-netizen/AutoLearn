import { Router } from 'express';
import { generateSummary, chat, getHistory } from '../controllers/ai.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Protect all AI routes with authentication
router.use(authenticateToken);

router.post('/summary', generateSummary);
router.post('/chat', chat);
router.get('/history/:sessionId', getHistory);

export default router;
