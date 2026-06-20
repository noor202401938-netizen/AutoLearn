import { Router } from 'express';
import { createPaymentIntent, getAllPayments, refundPayment } from '../controllers/payment.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.post('/create-intent', createPaymentIntent);
router.get('/', getAllPayments);
router.post('/:id/refund', refundPayment);

export default router;
