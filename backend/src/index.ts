import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

import dotenv from 'dotenv';
import authRoutes from './routes/auth.routes';
import aiRoutes from './routes/ai.routes';
import courseRoutes from './routes/course.routes';
import userDataRoutes from './routes/user_data.routes';
import { authenticateToken } from './middleware/auth.middleware';
import { getUserEnrollments } from './controllers/auth.controller';
import paymentRoutes from './routes/payment.routes';
import { handleStripeWebhook } from './controllers/payment.controller';
import analyticsRoutes from './routes/analytics.routes';
import uploadRoutes from './routes/upload.routes';
import chatRoutes from './routes/chat.routes';
import learningRoutes from './routes/learning.routes';
import communityRoutes from './routes/community.routes';
import usersRoutes from './routes/users.routes';
import path from 'path';

import { createClient } from 'redis';
import { RedisStore } from 'rate-limit-redis';
import prisma from './prisma';

dotenv.config();

const app = express();
app.set('trust proxy', 1); // Trust the first proxy (Railway/Nginx)
const PORT = process.env.PORT || 3001;

// ─── Redis Setup for Distributed Rate Limiting ────────────────────────────────
let redisClient: ReturnType<typeof createClient> | null = null;
let redisConnected = false;

if (process.env.REDIS_URL && process.env.NODE_ENV !== 'test') {
  try {
    redisClient = createClient({ url: process.env.REDIS_URL });
    redisClient.on('error', () => {
      redisConnected = false;
    });
    redisClient.connect().then(() => {
      redisConnected = true;
      console.log('✅ Connected to Redis for distributed rate-limiting');
    }).catch((err) => {
      redisConnected = false;
      console.warn('⚠️ Redis not available, using in-memory rate limiting fallback:', err.message);
    });
  } catch (err: any) {
    console.warn('⚠️ Redis init error:', err.message);
  }
}

// ─── Security Middleware ───────────────────────────────────────────────────────
app.use(helmet());

// Global rate limiter — 200 requests per 15 minutes per IP
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  passOnStoreError: true,
  message: { error: 'Too many requests, please try again later.' },
  store: (redisClient && process.env.NODE_ENV !== 'test') ? new RedisStore({
    sendCommand: (...args: string[]) => redisClient!.sendCommand(args),
    prefix: 'rl:global:',
  }) : undefined,
});

// Stricter rate limiter for auth endpoints — 20 attempts per 15 minutes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  passOnStoreError: true,
  message: { error: 'Too many authentication attempts. Please try again later.' },
  store: (redisClient && process.env.NODE_ENV !== 'test') ? new RedisStore({
    sendCommand: (...args: string[]) => redisClient!.sendCommand(args),
    prefix: 'rl:auth:',
  }) : undefined,
});

app.use(globalLimiter);

// ─── Body Parsing ─────────────────────────────────────────────────────────────
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
// Stripe signs the raw body, so this route must see it before JSON parsing.
app.post('/api/payments/webhook', express.raw({ type: 'application/json' }), handleStripeWebhook);
app.use(express.json({ limit: '10mb' }));

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/user', userDataRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/admin/analytics', analyticsRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api', learningRoutes);
app.use('/api', communityRoutes);
app.use('/api', usersRoutes);

// Serve uploads statically
app.use('/uploads', express.static(path.join(__dirname, '../../uploads')));

// GET /api/user/enrollments — get current user's enrolled courses
app.get('/api/user/enrollments', authenticateToken, getUserEnrollments);

// ─── Health Check ─────────────────────────────────────────────────────────────
app.get('/health', async (_req, res) => {
  let dbStatus = 'disconnected';
  try {
    const pingPromise = prisma.user.findFirst({ select: { id: true } });
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('timeout (database offline or unreachable)')), 1500)
    );
    await Promise.race([pingPromise, timeoutPromise]);
    dbStatus = 'connected';
  } catch (e: any) {
    dbStatus = `error: ${e.message}`;
  }

  const isHealthy = dbStatus === 'connected';
  res.status(isHealthy ? 200 : 503).json({
    status: isHealthy ? 'ok' : 'degraded',
    database: dbStatus,
    redis: redisConnected ? 'connected' : (process.env.REDIS_URL ? 'connecting_or_fallback' : 'disabled'),
    timestamp: new Date().toISOString(),
  });
});

// ─── 404 Handler ──────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// ─── Global Error Handler ─────────────────────────────────────────────────────
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Unhandled error:', err);
  const status = err.status || (err.code === 'LIMIT_FILE_SIZE' ? 413 : 500);
  res.status(status).json({
    // 4xx messages are meant for the user (e.g. "file type not allowed").
    error: process.env.NODE_ENV === 'production' && status >= 500
      ? 'Internal server error'
      : err.message || 'Internal server error',
  });
});

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`🚀 AutoLearn API running on port ${PORT}`);
  });
}

export { redisClient };
export default app;
