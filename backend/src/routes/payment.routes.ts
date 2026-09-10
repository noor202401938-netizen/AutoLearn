import { Router } from 'express';
import { createPaymentIntent, getAllPayments, refundPayment, handleStripeWebhook } from '../controllers/payment.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

// Unauthenticated webhook for Stripe events
router.post('/webhook', handleStripeWebhook);

// Authenticated routes
router.use(authenticateToken);
router.post('/create-intent', createPaymentIntent);
router.get('/', getAllPayments);
router.post('/:id/refund', refundPayment);

export default router;
