import { Router } from 'express';
import { createSession, listSessions, getHistory, sendMessage, deleteSession } from '../controllers/ai.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();
router.use(authenticateToken);

router.post('/session', createSession);
router.get('/sessions', listSessions);
router.get('/:sessionId/history', getHistory);
router.post('/:sessionId/message', sendMessage);
router.delete('/:sessionId', deleteSession);

export default router;
