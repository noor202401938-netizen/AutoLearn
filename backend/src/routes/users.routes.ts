import { Router } from 'express';
import { getUserById, setUserRole, deleteUser } from '../controllers/account.controller';
import { getFinanceStats } from '../controllers/payment.controller';
import { authenticateToken, adminOnly } from '../middleware/auth.middleware';

const router = Router();

router.get('/users/:uid', authenticateToken, getUserById); // self or admin, checked in controller
router.put('/users/:uid/role', authenticateToken, adminOnly, setUserRole);
router.delete('/users/:uid', authenticateToken, adminOnly, deleteUser);
router.get('/finance/stats', authenticateToken, adminOnly, getFinanceStats);

export default router;
