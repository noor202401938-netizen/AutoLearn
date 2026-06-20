import { Response } from 'express';
import Stripe from 'stripe';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || 'sk_test_placeholder', {
  // @ts-ignore
  apiVersion: '2024-04-10',
});

export const createPaymentIntent = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { amount, currency = 'USD', courseId } = req.body;
    const userId = req.user?.uid;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    if (!amount) {
      res.status(400).json({ error: 'Amount is required' });
      return;
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency.toLowerCase(),
      metadata: {
        userId,
        courseId: courseId || '',
      },
    });

    await prisma.payment.create({
      data: {
        userId,
        amount: amount / 100.0, // amount is in cents, Prisma expects float
        currency: currency.toUpperCase(),
        status: 'pending',
        stripePiId: paymentIntent.id,
      },
    });

    res.status(200).json({
      id: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      status: paymentIntent.status,
    });
  } catch (error: any) {
    console.error('Stripe PaymentIntent Error:', error);
    res.status(500).json({ error: error.message || 'Failed to create payment intent' });
  }
};

// GET /api/payments (Admin only)
export const getAllPayments = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }

    const payments = await prisma.payment.findMany({
      include: {
        user: {
          select: { displayName: true, email: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json(payments);
  } catch (error) {
    console.error('Get all payments error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/payments/:id/refund (Admin only)
export const refundPayment = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }

    const { id } = req.params;
    const payment = await prisma.payment.findUnique({ where: { id } });

    if (!payment) {
      res.status(404).json({ error: 'Payment not found' });
      return;
    }

    if (payment.status === 'refunded') {
      res.status(400).json({ error: 'Payment is already refunded' });
      return;
    }

    // Call Stripe API to process refund
    let stripeRefundId = null;
    try {
      const refund = await stripe.refunds.create({
        payment_intent: payment.stripePiId,
      });
      stripeRefundId = refund.id;
    } catch (stripeError: any) {
      console.error('Stripe refund error:', stripeError);
      res.status(400).json({ error: 'Stripe Refund Failed: ' + stripeError.message });
      return;
    }

    // Update database status
    const updatedPayment = await prisma.payment.update({
      where: { id },
      data: { status: 'refunded' },
    });

    res.status(200).json({ message: 'Refund processed successfully', payment: updatedPayment });
  } catch (error) {
    console.error('Refund payment error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
