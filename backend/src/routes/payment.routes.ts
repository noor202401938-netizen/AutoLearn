import { Router } from 'express';
import { createPaymentIntent } from '../controllers/payment.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/create-intent', createPaymentIntent);

export default router;
