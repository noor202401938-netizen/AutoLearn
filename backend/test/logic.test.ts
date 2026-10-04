// Pure-logic checks that don't need a database.
import test from 'node:test';
import assert from 'node:assert/strict';
import { gradeQuiz, withoutAnswers } from '../src/controllers/learning.controller';
import { toggleVote } from '../src/controllers/community.controller';
import { streakDays } from '../src/controllers/user_data.controller';
import { mayManage, mayOwn, mayReadContent, mayView } from '../src/access';
import { cleanEmail, lessonCountOf, optionalText, parsePaging, passwordProblem } from '../src/validation';
import { courseFieldProblem } from '../src/controllers/course.controller';
import { resolveJwtSecret } from '../src/config';
import { checkAccount } from '../src/middleware/auth.middleware';
import { clampScore, summarizeEarnings } from '../src/controllers/teacher.controller';

test('gradeQuiz scores on the server from stored answers', () => {
  const questions = [
    { questionId: 'q1', type: 'multiple_choice', correctOptionIndex: 2, points: 1 },
    { questionId: 'q2', type: 'multiple_choice', correctOptionIndex: 0, points: 3 },
    { questionId: 'q3', type: 'true_false', correctAnswer: 'True', points: 1 },
  ];
  assert.deepEqual(gradeQuiz(questions, { q1: 2, q2: 1, q3: 'true' }), { earned: 2, total: 5, score: 40 });
  assert.deepEqual(gradeQuiz(questions, { q1: '2', q2: 0, q3: ' TRUE ' }), { earned: 5, total: 5, score: 100 });
  assert.deepEqual(gradeQuiz(questions, {}), { earned: 0, total: 5, score: 0 });
  assert.deepEqual(gradeQuiz([], {}), { earned: 0, total: 0, score: 0 });
});

test('toggleVote adds then removes a single vote', () => {
  assert.deepEqual(toggleVote(['a'], 'b'), ['a', 'b']);
  assert.deepEqual(toggleVote(['a', 'b'], 'b'), ['a']);
});

test('streakDays counts consecutive days ending today or yesterday', () => {
  const now = new Date(2026, 9, 10, 12);
  const daysAgo = (n: number) => new Date(2026, 9, 10 - n, 9);
  assert.equal(streakDays([], now), 0);
  assert.equal(streakDays([daysAgo(0), daysAgo(1), daysAgo(2)], now), 3);
  assert.equal(streakDays([daysAgo(1), daysAgo(2)], now), 2); // haven't studied yet today
  assert.equal(streakDays([daysAgo(0), daysAgo(2)], now), 1); // gap breaks it
  assert.equal(streakDays([daysAgo(3)], now), 0);
});

test('withoutAnswers hides the answer key from students', () => {
  const quiz = { id: 'x', questions: [{ questionId: 'q1', questionText: 'Q', options: [], correctOptionIndex: 2, correctAnswer: null, explanation: 'because' }] };
  const safe = withoutAnswers(quiz).questions as any[];
  assert.deepEqual(Object.keys(safe[0]).sort(), ['options', 'questionId', 'questionText']);
  assert.equal((quiz.questions[0] as any).correctOptionIndex, 2, 'original is not mutated');
});

test('mayManage lets admins touch any course but teachers only their own', () => {
  const course = { createdBy: 't1' };
  assert.equal(mayManage({ uid: 'a', role: 'admin' }, course), true);
  assert.equal(mayManage({ uid: 't1', role: 'teacher' }, course), true);
  assert.equal(mayManage({ uid: 't2', role: 'teacher' }, course), false);
  assert.equal(mayManage({ uid: 't1', role: 'student' }, course), false);
  assert.equal(mayManage({ uid: 't1', role: 'teacher' }, null), false);
  assert.equal(mayManage(undefined, course), false);
});

test('clampScore keeps marks whole and inside 0..max', () => {
  assert.equal(clampScore('72.6', 100), 73);
  assert.equal(clampScore(150, 100), 100);
  assert.equal(clampScore(-5, 100), 0);
  assert.equal(clampScore('', 100), null);
  assert.equal(clampScore('abc', 100), null);
  assert.equal(clampScore(null, 100), null);
});

test('co-teachers may manage a course but only its creator owns it', () => {
  const course = { createdBy: 't1', coTeacherIds: ['t2'] };
  assert.equal(mayManage({ uid: 't2', role: 'teacher' }, course), true);
  assert.equal(mayOwn({ uid: 't2', role: 'teacher' }, course), false);
  assert.equal(mayOwn({ uid: 't1', role: 'teacher' }, course), true);
  assert.equal(mayOwn({ uid: 'a', role: 'admin' }, course), true);
  assert.equal(mayManage({ uid: 't3', role: 'teacher' }, course), false);
  assert.equal(mayManage({ uid: 't2', role: 'student' }, course), false);
});

test('summarizeEarnings totals sales per currency and per course', () => {
  const r = summarizeEarnings([
    { courseId: 'a', amount: 10, currency: 'USD' },
    { courseId: 'a', amount: 15, currency: 'USD' },
    { courseId: 'b', amount: 5, currency: 'EUR' },
  ]);
  assert.deepEqual(r.totals, [{ currency: 'USD', amount: 25, sales: 2 }, { currency: 'EUR', amount: 5, sales: 1 }]);
  assert.deepEqual(r.perCourse.find((c) => c.courseId === 'a'), { courseId: 'a', currency: 'USD', amount: 25, sales: 2 });
  assert.deepEqual(summarizeEarnings([]), { totals: [], perCourse: [] });
});

test('a draft course is visible only to the people who manage it', () => {
  const draft = { isPublished: false, createdBy: 't1', coTeacherIds: ['t2'] };
  const live = { ...draft, isPublished: true };
  assert.equal(mayView(undefined, draft), false);
  assert.equal(mayView({ uid: 's1', role: 'student' }, draft), false);
  assert.equal(mayView({ uid: 't3', role: 'teacher' }, draft), false);
  assert.equal(mayView({ uid: 't1', role: 'teacher' }, draft), true);
  assert.equal(mayView({ uid: 't2', role: 'teacher' }, draft), true);
  assert.equal(mayView({ uid: 'a', role: 'admin' }, draft), true);
  assert.equal(mayView(undefined, live), true);
  assert.equal(mayView(undefined, null), false);
});

test('production refuses to start without a strong JWT secret', () => {
  const strong = 'x'.repeat(32);
  assert.throws(() => resolveJwtSecret({ NODE_ENV: 'production' }), /JWT_SECRET is required/);
  assert.throws(() => resolveJwtSecret({ NODE_ENV: 'production', JWT_SECRET: 'short' }), /at least 32/);
  assert.equal(resolveJwtSecret({ NODE_ENV: 'production', JWT_SECRET: strong }), strong);
  // The secrets shipped in .env.example and docker-compose are public, so they must not work in production.
  for (const placeholder of ['change_this_to_a_secure_random_64_char_secret_in_production', 'autolearn_jwt_secret_change_in_production_please']) {
    assert.throws(() => resolveJwtSecret({ NODE_ENV: 'production', JWT_SECRET: placeholder }), /placeholder/);
  }
  assert.equal(resolveJwtSecret({ NODE_ENV: 'development', JWT_SECRET: 'dev' }), 'dev');
  assert.equal(resolveJwtSecret({ NODE_ENV: 'test' }), 'fallback_secret_for_dev_only');
});

test('checkAccount turns away deleted and disabled users and trusts the stored role', () => {
  assert.deepEqual(checkAccount(null), { ok: false, status: 401, error: 'Unauthorized: this account no longer exists' });
  assert.deepEqual(checkAccount({ role: 'teacher', isActive: false }), { ok: false, status: 403, error: 'Forbidden: this account has been disabled' });
  assert.deepEqual(checkAccount({ role: 'student', isActive: true }), { ok: true, role: 'student' });
});

test('paid course content is for people who enrolled or who run the course', () => {
  const paid = { price: 20, createdBy: 't1', coTeacherIds: ['t2'] };
  const free = { ...paid, price: 0 };
  assert.equal(mayReadContent(undefined, paid, false), false);
  assert.equal(mayReadContent({ uid: 's1', role: 'student' }, paid, false), false);
  assert.equal(mayReadContent({ uid: 's1', role: 'student' }, paid, true), true);
  assert.equal(mayReadContent({ uid: 't1', role: 'teacher' }, paid, false), true);
  assert.equal(mayReadContent({ uid: 't2', role: 'teacher' }, paid, false), true);
  assert.equal(mayReadContent({ uid: 't3', role: 'teacher' }, paid, false), false);
  assert.equal(mayReadContent({ uid: 'a', role: 'admin' }, paid, false), true);
  assert.equal(mayReadContent(undefined, free, false), true);
  assert.equal(mayReadContent(undefined, null, false), false);
});

test('emails are normalised and anything that is not text is refused', () => {
  assert.equal(cleanEmail('  Maya@Example.COM '), 'maya@example.com');
  for (const bad of ['not-an-email', '', 'a@b', 'a b@c.de', null, undefined, 42, ['a@b.co'], { $ne: '' }, 'x'.repeat(250) + '@b.co']) {
    assert.equal(cleanEmail(bad), null, `should reject ${JSON.stringify(bad)}`);
  }
});

test('password rule matches the sign-up form: 8+ characters with a letter and a number', () => {
  assert.equal(passwordProblem('Study2026ok'), null);
  assert.equal(passwordProblem('admin123'), null);
  for (const bad of ['short1', '12345678', 'abcdefgh', '', null, undefined, 12345678, ['abc12345'], 'a1'.repeat(70)]) {
    assert.notEqual(passwordProblem(bad), null, `should reject ${JSON.stringify(bad)}`);
  }
});

test('optional text is trimmed, bounded, and ignored when it is not text', () => {
  assert.equal(optionalText('  hi ', 10), 'hi');
  assert.equal(optionalText('x'.repeat(11), 10), 'too-long');
  assert.equal(optionalText(undefined, 10), undefined);
  assert.equal(optionalText(5, 10), undefined);
  assert.equal(optionalText({ a: 1 }, 10), undefined);
});

test('paging accepts only positive whole numbers and caps the page size', () => {
  assert.deepEqual(parsePaging('2', '10'), { page: 2, limit: 10 });
  assert.deepEqual(parsePaging('abc', 'zz'), { page: undefined, limit: undefined });
  assert.deepEqual(parsePaging('-1', '-5'), { page: undefined, limit: undefined });
  assert.deepEqual(parsePaging('0', '0'), { page: undefined, limit: undefined });
  assert.deepEqual(parsePaging(undefined, '5000'), { page: undefined, limit: 100 });
  assert.deepEqual(parsePaging(['1'], { x: 1 }), { page: undefined, limit: undefined });
});

test('a syllabus with no lessons cannot be published', () => {
  assert.equal(lessonCountOf(undefined), 0);
  assert.equal(lessonCountOf([]), 0);
  assert.equal(lessonCountOf([{ title: 'Empty chapter', lessons: [] }]), 0);
  assert.equal(lessonCountOf([{ lessons: [{}, {}] }, { lessons: [{}] }, null]), 3);
});

test('course fields are validated before they reach the database', () => {
  assert.equal(courseFieldProblem({ title: 'Ok', description: 'Ok', price: 0 }), null);
  assert.equal(courseFieldProblem({}), null);
  assert.match(courseFieldProblem({ price: -1 }) ?? '', /Price/);
  assert.match(courseFieldProblem({ price: '20' }) ?? '', /Price/);
  assert.match(courseFieldProblem({ price: Infinity }) ?? '', /Price/);
  assert.match(courseFieldProblem({ title: { x: 1 } }) ?? '', /Title/);
  assert.match(courseFieldProblem({ title: 'x'.repeat(201) }) ?? '', /Title/);
  assert.match(courseFieldProblem({ description: 5 }) ?? '', /Description/);
});
