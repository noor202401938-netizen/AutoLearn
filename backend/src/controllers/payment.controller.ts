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
