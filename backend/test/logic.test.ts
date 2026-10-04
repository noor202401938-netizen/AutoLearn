// Pure-logic checks that don't need a database.
import test from 'node:test';
import assert from 'node:assert/strict';
import { gradeQuiz, withoutAnswers } from '../src/controllers/learning.controller';
import { toggleVote } from '../src/controllers/community.controller';
import { streakDays } from '../src/controllers/user_data.controller';

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
