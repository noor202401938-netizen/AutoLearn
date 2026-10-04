import { Router } from 'express';
import { createCheckoutSession, getAllPayments, refundPayment } from '../controllers/payment.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// The Stripe webhook is mounted in index.ts, before JSON parsing, because
// signature checks need the raw request body.

// Authenticated routes
router.use(authenticateToken);
router.post('/checkout', createCheckoutSession);
router.get('/', getAllPayments);
router.post('/:id/refund', refundPayment);

export default router;
