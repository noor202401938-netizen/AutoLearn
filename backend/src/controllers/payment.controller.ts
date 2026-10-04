import { Request, Response } from 'express';
import Stripe from 'stripe';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import prisma from '../prisma';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || 'sk_test_placeholder', {
  // @ts-ignore
  apiVersion: '2024-04-10',
});

// POST /api/payments/checkout { courseId }
// Starts a Stripe Checkout session for a course. The price always comes from
// the database, never from the client. The webhook enrols the student.
export const createCheckoutSession = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const userId = req.user!.uid;
  const courseId = String(req.body?.courseId ?? '');
  try {
    if (!process.env.STRIPE_SECRET_KEY) {
      res.status(503).json({ error: 'Payments are not configured on this server' });
      return;
    }
    const course = /^[a-f0-9]{24}$/.test(courseId) ? await prisma.course.findUnique({ where: { id: courseId } }) : null;
    if (!course || !course.isPublished) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }
    if (course.price <= 0) {
      res.status(400).json({ error: 'This course is free — enrol directly' });
      return;
    }
    if (await prisma.enrollment.findUnique({ where: { userId_courseId: { userId, courseId } } })) {
      res.status(409).json({ error: "You're already enrolled in this course" });
      return;
    }

    const appUrl = (process.env.APP_URL || 'http://localhost:8080').replace(/\/$/, '');
    const amount = Math.round(course.price * 100);
    const metadata = { userId, courseId };
    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      line_items: [{
        quantity: 1,
        price_data: { currency: course.currency.toLowerCase(), unit_amount: amount, product_data: { name: course.title } },
      }],
      metadata,
      payment_intent_data: { metadata },
      success_url: `${appUrl}/?paid=${courseId}`,
      cancel_url: `${appUrl}/`,
    });

    await prisma.payment.create({
      data: { userId, courseId, amount: course.price, currency: course.currency.toUpperCase(), status: 'pending', stripePiId: session.id },
    });
    res.status(200).json({ url: session.url });
  } catch (error: any) {
    console.error('Stripe checkout error:', error);
    res.status(502).json({ error: 'Could not start the payment. Please try again.' });
  }
};

/** Enrols the student once (safe to call on webhook retries). */
async function enrolAfterPayment(userId: string, courseId: string) {
  const existing = await prisma.enrollment.findUnique({ where: { userId_courseId: { userId, courseId } } });
  if (existing) return;
  await prisma.enrollment.create({ data: { userId, courseId, status: 'active' } });
  await prisma.course.update({ where: { id: courseId }, data: { enrollmentCount: { increment: 1 } } });
  await prisma.notification.create({
    data: { userId, title: 'Enrolment confirmed', message: 'Your payment went through — the course is in your notebook.', type: 'payment' },
  });
}

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

    if (payment.status !== 'succeeded') {
      res.status(400).json({ error: `Only successful payments can be refunded (this one is ${payment.status})` });
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
    // A refunded course is no longer theirs.
    if (payment.courseId) {
      const { count } = await prisma.enrollment.deleteMany({ where: { userId: payment.userId, courseId: payment.courseId } });
      if (count) await prisma.course.update({ where: { id: payment.courseId }, data: { enrollmentCount: { decrement: count } } });
    }

    res.status(200).json({ message: 'Refund processed successfully', payment: updatedPayment });
  } catch (error) {
    console.error('Refund payment error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// The fields of a Checkout Session the webhook reads.
type CheckoutSession = {
  id: string;
  payment_status?: string;
  payment_intent?: string | { id: string } | null;
  metadata?: Record<string, string> | null;
};

// POST /api/payments/webhook — needs the raw body (mounted before express.json).
export const handleStripeWebhook = async (req: Request, res: Response): Promise<void> => {
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  const sig = req.headers['stripe-signature'];
  if (!webhookSecret) {
    // Never trust unsigned events: anyone could forge a "payment succeeded".
    res.status(503).json({ error: 'Stripe webhook is not configured' });
    return;
  }

  let event: ReturnType<typeof stripe.webhooks.constructEvent>;
  try {
    event = stripe.webhooks.constructEvent(req.body, String(sig ?? ''), webhookSecret);
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as unknown as CheckoutSession;
        if (session.payment_status !== 'paid') break;
        const { userId, courseId } = session.metadata ?? {};
        // Swap the session id for the PaymentIntent id so refunds work.
        await prisma.payment.updateMany({
          where: { stripePiId: session.id },
          data: { status: 'succeeded', stripePiId: typeof session.payment_intent === 'string' ? session.payment_intent : session.payment_intent?.id ?? session.id },
        });
        if (userId && courseId) await enrolAfterPayment(userId, courseId);
        break;
      }
      case 'checkout.session.expired': {
        const session = event.data.object as unknown as CheckoutSession;
        await prisma.payment.updateMany({ where: { stripePiId: session.id, status: 'pending' }, data: { status: 'failed' } });
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

// GET /api/finance/stats (admin) — revenue summary from recorded payments
export const getFinanceStats = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden: Admin access required' });
      return;
    }
    const payments = await prisma.payment.findMany({ select: { amount: true, status: true, createdAt: true } });
    const sum = (status: string) =>
      payments.filter((p) => p.status === status).reduce((s, p) => s + p.amount, 0);

    // Succeeded revenue for each of the last 6 calendar months, oldest first.
    const now = new Date();
    const monthly = Array.from({ length: 6 }, (_, i) => {
      const start = new Date(now.getFullYear(), now.getMonth() - 5 + i, 1);
      const end = new Date(start.getFullYear(), start.getMonth() + 1, 1);
      const revenue = payments
        .filter((p) => p.status === 'succeeded' && p.createdAt >= start && p.createdAt < end)
        .reduce((s, p) => s + p.amount, 0);
      // Local year-month: toISOString() would shift to UTC and mislabel the month.
      return { month: `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, '0')}`, revenue };
    });

    res.status(200).json({
      totalRevenue: sum('succeeded'),
      refunded: sum('refunded'),
      pending: sum('pending'),
      transactions: payments.length,
      successfulTransactions: payments.filter((p) => p.status === 'succeeded').length,
      monthly,
    });
  } catch (error) {
    console.error('Finance stats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
