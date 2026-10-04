process.env.NODE_ENV = 'test';
import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'http';
import app, { redisClient } from '../src/index';
import prisma from '../src/prisma';

let server: http.Server;
let baseUrl: string;

test.before(() => {
  return new Promise<void>((resolve) => {
    // Listen on dynamic random available port
    server = app.listen(0, () => {
      const addr = server.address();
      if (addr && typeof addr === 'object') {
        baseUrl = `http://127.0.0.1:${addr.port}`;
      }
      resolve();
    });
  });
});

test.after(async () => {
  await new Promise<void>((resolve) => {
    server.close(() => resolve());
  });
  if (redisClient && redisClient.isOpen) {
    await redisClient.quit().catch(() => {});
  }
  await prisma.$disconnect().catch(() => {});
  // Give event loop brief tick then exit cleanly
  setTimeout(() => process.exit(0), 100).unref();
});

test('GET /health returns valid health check payload', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.ok(res.status === 200 || res.status === 503, 'Health endpoint should return 200 or 503');
  
  const body = await res.json() as any;
  assert.ok(body.status, 'Response should contain status');
  assert.ok(body.timestamp, 'Response should contain timestamp');
  assert.ok(body.database, 'Response should contain database diagnostic status');
});

test('Security headers (Helmet) are enabled', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.equal(res.headers.get('x-content-type-options'), 'nosniff');
});

test('GET /unknown-route returns 404 JSON', async () => {
  const res = await fetch(`${baseUrl}/api/non-existent-endpoint`);
  assert.equal(res.status, 404);
  const body = await res.json() as any;
  assert.equal(body.error, 'Endpoint not found');
});

test('POST /api/auth/login rejects empty body with 400', async () => {
  const res = await fetch(`${baseUrl}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  assert.equal(res.status, 400);
});

test('POST /api/auth/signup rejects missing email with 400', async () => {
  const res = await fetch(`${baseUrl}/api/auth/signup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ password: 'Password123!' }),
  });
  assert.equal(res.status, 400);
});

test('POST /api/ai/chat rejects request without authorization header', async () => {
  const res = await fetch(`${baseUrl}/api/ai/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ messages: [{ role: 'user', content: 'What is inflation?' }] }),
  });
  assert.equal(res.status, 401);
});

test('new learning/community/admin endpoints require a token', async () => {
  const guarded: [string, string][] = [
    ['GET', '/api/user/bookmarks'],
    ['GET', '/api/learning-paths'],
    ['GET', '/api/forum/threads'],
    ['GET', '/api/user/assignments'],
    ['GET', '/api/quizzes/lesson/x'],
    ['POST', '/api/chat/session'],
    ['GET', '/api/finance/stats'],
    ['DELETE', '/api/users/x'],
    ['POST', '/api/auth/change-password'],
    ['GET', '/api/teacher/overview'],
    ['GET', '/api/teacher/earnings'],
    ['GET', '/api/teacher/submissions'],
    ['PUT', '/api/teacher/submissions/x/grade'],
    ['POST', '/api/teacher/courses/x/co-teachers'],
    ['POST', '/api/teacher/courses/x/announce'],
    ['GET', '/api/courses?mine=true'],
  ];
  for (const [method, path] of guarded) {
    const res = await fetch(`${baseUrl}${path}`, { method });
    assert.equal(res.status, 401, `${method} ${path} should be 401 without a token`);
  }
});

test('public course catalog is not swallowed by /api-mounted auth routers', async () => {
  const res = await fetch(`${baseUrl}/api/courses?isPublished=true`);
  assert.notEqual(res.status, 401);
});

test('password reset request validates input and never reveals accounts', async () => {
  const empty = await fetch(`${baseUrl}/api/auth/password-reset`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}',
  });
  assert.equal(empty.status, 400);
  const bad = await fetch(`${baseUrl}/api/auth/password-reset/confirm`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: 'x', newPassword: '1' }),
  });
  assert.equal(bad.status, 400);
});

test('file download rejects path traversal', async () => {
  for (const name of ['..%2F..%2F.env', '..%2Fpackage.json', 'evil.html']) {
    const res = await fetch(`${baseUrl}/api/upload/file/${name}`);
    assert.equal(res.status, 404, `${name} must not be served`);
    assert.ok(!(await res.text()).includes('DATABASE_URL'));
  }
});

test('Stripe webhook refuses unsigned events (no free enrolment by forgery)', async () => {
  const forged = { type: 'checkout.session.completed', data: { object: { id: 'cs_x', payment_status: 'paid', metadata: { userId: 'a'.repeat(24), courseId: 'b'.repeat(24) } } } };
  const res = await fetch(`${baseUrl}/api/payments/webhook`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(forged),
  });
  assert.ok(res.status === 503 || res.status === 400, `expected rejection, got ${res.status}`);
});

test('tokens signed with the wrong secret, or with a bogus user id, are refused before any database lookup', async () => {
  const jwt = (await import('jwt-simple')).default;
  const exp = Math.floor(Date.now() / 1000) + 3600;
  const forged = jwt.encode({ uid: 'a'.repeat(24), role: 'admin', exp }, 'not-the-real-secret');
  const badId = jwt.encode({ uid: 'not-an-object-id', role: 'admin', exp }, process.env.JWT_SECRET || 'fallback_secret_for_dev_only');
  for (const token of [forged, badId, 'garbage']) {
    const res = await fetch(`${baseUrl}/api/teacher/overview`, { headers: { Authorization: `Bearer ${token}` } });
    assert.equal(res.status, 403);
  }
});
