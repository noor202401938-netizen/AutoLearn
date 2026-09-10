import { Request, Response } from 'express';
import Stripe from 'stripe';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import prisma from '../prisma';

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
        courseId: courseId || null,
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
        course: {
          select: { title: true },
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

    const id = String(req.params.id);
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

// POST /api/payments/webhook
export const handleStripeWebhook = async (req: Request, res: Response): Promise<void> => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event: any;

  try {
    if (webhookSecret && sig) {
      event = stripe.webhooks.constructEvent(req.body, sig as string, webhookSecret);
    } else {
      event = req.body;
    }
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  try {
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object;
        const userId = paymentIntent.metadata?.userId;
        const courseId = paymentIntent.metadata?.courseId;

        await prisma.payment.updateMany({
          where: { stripePiId: paymentIntent.id },
          data: { status: 'succeeded' },
        });

        if (userId && courseId) {
          await prisma.enrollment.upsert({
            where: { userId_courseId: { userId, courseId } },
            create: { userId, courseId, status: 'active' },
            update: { status: 'active' },
          });

          await prisma.course.update({
            where: { id: courseId },
            data: { enrollmentCount: { increment: 1 } },
          });

          await prisma.notification.create({
            data: {
              userId,
              title: 'Enrollment Confirmed',
              message: 'Your payment was successful and you are now enrolled in the course.',
              type: 'payment',
            },
          });
        }
        break;
      }
      case 'payment_intent.payment_failed': {
        const paymentIntent = event.data.object;
        await prisma.payment.updateMany({
          where: { stripePiId: paymentIntent.id },
          data: { status: 'failed' },
        });
        break;
      }
      default:
        break;
    }

    res.status(200).json({ received: true });
  } catch (error) {
    console.error('Error handling webhook event:', error);
    res.status(500).json({ error: 'Webhook handler failed' });
  }
};
