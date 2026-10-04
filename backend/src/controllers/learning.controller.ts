// Quizzes, assignments, certificates and per-course progress.
import { Response } from 'express';
import prisma from '../prisma';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { canLearnIn, canManageCourse, canReadCourseContent, isEnrolled } from '../access';
import { complete, aiErrorStatus } from '../ai';

const isObjectId = (s: unknown): s is string => typeof s === 'string' && /^[a-f0-9]{24}$/.test(s);
const uid = (req: AuthenticatedRequest) => req.user!.uid;

function fail(res: Response, where: string, error: unknown) {
  console.error(`${where} error:`, error);
  res.status(500).json({ error: 'Internal server error' });
}

/** Marks a real lesson complete for the user (no-op for synthetic lesson ids). */
async function completeLesson(userId: string, lessonId: string) {
  if (!isObjectId(lessonId)) return;
  const lesson = await prisma.lesson.findUnique({ where: { id: lessonId }, select: { id: true } });
  if (!lesson) return;
  await prisma.progress.upsert({
    where: { userId_lessonId: { userId, lessonId } },
    create: { userId, lessonId, isCompleted: true },
    update: { isCompleted: true },
  });
}

/** Fraction (0..1) of a course's lessons the user has completed. */
export async function courseCompletion(userId: string, courseId: string): Promise<number> {
  const lessons = await prisma.lesson.findMany({ where: { module: { courseId } }, select: { id: true } });
  if (lessons.length === 0) return 0;
  const done = await prisma.progress.count({
    where: { userId, isCompleted: true, lessonId: { in: lessons.map((l) => l.id) } },
  });
  return done / lessons.length;
}

/** Id of the last lesson in the course's syllabus order, or null if empty. */
export async function finalLessonId(courseId: string): Promise<string | null> {
  const modules = await prisma.module.findMany({
    where: { courseId },
    orderBy: { order: 'desc' },
    include: { lessons: { orderBy: { order: 'desc' }, take: 1, select: { id: true } } },
  });
  return modules.find((m) => m.lessons.length > 0)?.lessons[0].id ?? null;
}

// ── Quizzes ──────────────────────────────────────────────────────────────────

/** A quiz as a student may see it before submitting: no answers or explanations. */
export function withoutAnswers<T extends { questions: unknown }>(quiz: T): T {
  const questions = (quiz.questions as any[]).map(({ correctOptionIndex, correctAnswer, explanation, ...q }) => q);
  return { ...quiz, questions };
}

// GET /api/quizzes/lesson/:lessonId
export const getQuizByLesson = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const quiz = await prisma.quiz.findUnique({ where: { lessonId: String(req.params.lessonId) } });
    if (!quiz) {
      res.status(404).json({ error: 'No quiz for this lesson yet' });
      return;
    }
    if (!(await canReadCourseContent(req.user, quiz.courseId))) {
      res.status(403).json({ error: 'Enrol in this course to take its quizzes' });
      return;
    }
    // The answer key goes only to whoever manages the course.
    res.status(200).json((await canManageCourse(req.user, quiz.courseId)) ? quiz : withoutAnswers(quiz));
  } catch (e) {
    fail(res, 'Get quiz', e);
  }
};

// POST /api/quizzes (staff, own courses) — create or replace a lesson's quiz
export const upsertQuiz = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const { courseId, moduleId = '', lessonId, title, description = '', questions, timeLimit = 0, passingScore = 70 } = req.body ?? {};
  if (!courseId || !lessonId || !title || !Array.isArray(questions) || questions.length === 0) {
    res.status(400).json({ error: 'courseId, lessonId, title and at least one question are required' });
    return;
  }
  try {
    if (!(await canManageCourse(req.user, courseId))) {
      res.status(403).json({ error: 'Forbidden: you can only edit quizzes in your own courses' });
      return;
    }
    const data = {
      courseId: String(courseId), moduleId: String(moduleId), title: String(title), description: String(description),
      questions, timeLimit: Number(timeLimit) || 0, passingScore: Number(passingScore) || 70, createdBy: uid(req),
    };
    const quiz = await prisma.quiz.upsert({
      where: { lessonId: String(lessonId) },
      create: { ...data, lessonId: String(lessonId) },
      update: data,
    });
    res.status(200).json(quiz);
  } catch (e) {
    fail(res, 'Upsert quiz', e);
  }
};

/** Grades answers {questionId: optionIndex | text} against the stored quiz. */
export function gradeQuiz(questions: any[], answers: Record<string, unknown>) {
  let earned = 0;
  let total = 0;
  for (const q of questions) {
    const points = Number(q.points) || 1;
    total += points;
    const a = answers[q.questionId];
    const kind = String(q.type ?? '').replace(/_/g, '').toLowerCase(); // 'short_answer' or 'shortAnswer'
    const right =
      kind === 'shortanswer' || kind === 'truefalse'
        ? q.correctAnswer != null && String(a ?? '').trim().toLowerCase() === String(q.correctAnswer).trim().toLowerCase()
        : Number(a) === Number(q.correctOptionIndex);
    if (right) earned += points;
  }
  return { earned, total, score: total === 0 ? 0 : Math.round((earned / total) * 100) };
}

// POST /api/user/quizzes/:quizId/submit { answers, timeSpent? }
export const submitQuiz = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const quizId = String(req.params.quizId);
  const answers = req.body?.answers;
  if (!isObjectId(quizId) || typeof answers !== 'object' || answers === null) {
    res.status(400).json({ error: 'A valid quiz id and answers object are required' });
    return;
  }
  try {
    const quiz = await prisma.quiz.findUnique({ where: { id: quizId } });
    if (!quiz) {
      res.status(404).json({ error: 'Quiz not found' });
      return;
    }
    if (!(await canLearnIn(req.user, quiz.courseId))) {
      res.status(403).json({ error: 'Enrol in this course before taking its quizzes' });
      return;
    }
    // Score on the server — never trust a client-computed grade.
    const { earned, total, score } = gradeQuiz(quiz.questions as any[], answers);
    const passed = score >= quiz.passingScore;
    const data = { answers, score, earnedPoints: earned, totalPoints: total, passed, timeSpent: Number(req.body?.timeSpent) || null, submittedAt: new Date() };
    const submission = await prisma.quizSubmission.upsert({
      where: { userId_quizId: { userId: uid(req), quizId } },
      create: { ...data, userId: uid(req), quizId },
      update: data,
    });
    if (passed) await completeLesson(uid(req), quiz.lessonId);
    // Once submitted, the student gets the answer key and explanations to review.
    res.status(200).json({ ...submission, courseId: quiz.courseId, moduleId: quiz.moduleId, lessonId: quiz.lessonId, review: quiz.questions });
  } catch (e) {
    fail(res, 'Submit quiz', e);
  }
};

// GET /api/user/quizzes/:quizId/submission
export const getQuizSubmission = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const quizId = String(req.params.quizId);
    const sub = isObjectId(quizId)
      ? await prisma.quizSubmission.findUnique({ where: { userId_quizId: { userId: uid(req), quizId } }, include: { quiz: true } })
      : null;
    if (!sub) {
      res.status(404).json({ error: 'Not submitted yet' });
      return;
    }
    const { quiz, ...rest } = sub;
    res.status(200).json({ ...rest, courseId: quiz.courseId, moduleId: quiz.moduleId, lessonId: quiz.lessonId, review: quiz.questions });
  } catch (e) {
    fail(res, 'Get quiz submission', e);
  }
};

// ── Assignments ──────────────────────────────────────────────────────────────

// GET /api/assignments/lesson/:lessonId
export const getAssignmentByLesson = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const a = await prisma.assignment.findUnique({ where: { lessonId: String(req.params.lessonId) } });
    if (!a) {
      res.status(404).json({ error: 'No assignment for this lesson yet' });
      return;
    }
    if (!(await canReadCourseContent(req.user, a.courseId))) {
      res.status(403).json({ error: 'Enrol in this course to see its assignments' });
      return;
    }
    res.status(200).json(a);
  } catch (e) {
    fail(res, 'Get assignment', e);
  }
};

// POST /api/assignments (staff, own courses) — create or replace a lesson's assignment
export const upsertAssignment = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const { courseId, moduleId = '', lessonId, title, description = '', instructions = '', dueDate, maxPoints = 100 } = req.body ?? {};
  const due = new Date(dueDate);
  if (!courseId || !lessonId || !title || isNaN(due.getTime())) {
    res.status(400).json({ error: 'courseId, lessonId, title and a valid dueDate are required' });
    return;
  }
  try {
    if (!(await canManageCourse(req.user, courseId))) {
      res.status(403).json({ error: 'Forbidden: you can only edit assignments in your own courses' });
      return;
    }
    const data = {
      courseId: String(courseId), moduleId: String(moduleId), title: String(title), description: String(description),
      instructions: String(instructions), dueDate: due, maxPoints: Number(maxPoints) || 100, createdBy: uid(req),
    };
    const a = await prisma.assignment.upsert({
      where: { lessonId: String(lessonId) },
      create: { ...data, lessonId: String(lessonId) },
      update: data,
    });
    res.status(200).json(a);
  } catch (e) {
    fail(res, 'Upsert assignment', e);
  }
};

// GET /api/user/assignments — every assignment in the user's enrolled courses,
// with their submission (if any). Powers the Assignments hub.
export const listMyAssignments = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const enrollments = await prisma.enrollment.findMany({
      where: { userId: uid(req) },
      include: { course: { select: { id: true, title: true, modules: { select: { id: true, title: true, lessons: { select: { id: true, title: true } } } } } } },
    });
    const courses = new Map(enrollments.map((e) => [e.courseId, e.course]));
    const assignments = await prisma.assignment.findMany({
      where: { courseId: { in: [...courses.keys()] } },
      include: { submissions: { where: { userId: uid(req) } } },
      orderBy: { dueDate: 'asc' },
    });
    res.status(200).json(
      assignments.map(({ submissions, ...a }) => {
        const course = courses.get(a.courseId);
        const mod = course?.modules.find((m) => m.id === a.moduleId);
        const lesson = mod?.lessons.find((l) => l.id === a.lessonId);
        return {
          ...a,
          courseTitle: course?.title ?? '',
          moduleTitle: mod?.title ?? '',
          lessonTitle: lesson?.title ?? a.title,
          submission: submissions[0] ?? null,
        };
      }),
    );
  } catch (e) {
    fail(res, 'List assignments', e);
  }
};

// POST /api/user/assignments/:assignmentId/submit { content, fileUrl? }
// Stores the work and asks the AI for rubric feedback + a score. If the AI
// isn't available, the submission is still saved, ungraded.
export const submitAssignment = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const assignmentId = String(req.params.assignmentId);
  const content = String(req.body?.content ?? '').trim().slice(0, 20000);
  const fileUrl = req.body?.fileUrl ? String(req.body.fileUrl).slice(0, 500) : null;
  if (!isObjectId(assignmentId) || (!content && !fileUrl)) {
    res.status(400).json({ error: 'Write an answer or attach a file before submitting' });
    return;
  }
  try {
    const a = await prisma.assignment.findUnique({ where: { id: assignmentId } });
    if (!a) {
      res.status(404).json({ error: 'Assignment not found' });
      return;
    }
    if (!(await canLearnIn(req.user, a.courseId))) {
      res.status(403).json({ error: 'Enrol in this course before handing in its assignments' });
      return;
    }
    // A mark given by a teacher is not silently replaced by a resubmission.
    const earlier = await prisma.assignmentSubmission.findUnique({ where: { userId_assignmentId: { userId: uid(req), assignmentId } } });
    if (earlier?.gradedBy && earlier.gradedBy !== 'ai') {
      res.status(409).json({ error: 'Your teacher has already marked this assignment. Ask them if you need to hand in again.' });
      return;
    }

    let feedback: string | null = null;
    let score: number | null = null;
    let aiError: string | null = null;
    if (content) {
      try {
        const raw = await complete(
          [
            { role: 'system', content: 'You are a fair, specific teaching assistant grading student work. Reply as JSON.' },
            {
              role: 'user',
              content:
                `Assignment: ${a.title}\nInstructions: ${a.instructions || a.description}\nMaximum points: ${a.maxPoints}\n\n` +
                `Student answer:\n${content}\n\n` +
                'Return {"score": <integer 0..max>, "feedback": "what is correct, what is missing or wrong, and one concrete next step"}',
            },
          ],
          { json: true, maxTokens: 700 },
        );
        const parsed = JSON.parse(raw);
        score = Math.min(Math.max(Math.round(Number(parsed.score) || 0), 0), a.maxPoints);
        feedback = String(parsed.feedback ?? '');
      } catch (e) {
        aiError = aiErrorStatus(e).error;
      }
    }

    const graded = score !== null;
    const data = { content, fileUrl, feedback, score, isGraded: graded, gradedBy: graded ? 'ai' : null, submittedAt: new Date(), gradedAt: graded ? new Date() : null };
    const sub = await prisma.assignmentSubmission.upsert({
      where: { userId_assignmentId: { userId: uid(req), assignmentId } },
      create: { ...data, userId: uid(req), assignmentId },
      update: data,
    });
    await completeLesson(uid(req), a.lessonId);
    res.status(200).json({ ...sub, courseId: a.courseId, moduleId: a.moduleId, lessonId: a.lessonId, ...(aiError && { gradingNote: aiError }) });
  } catch (e) {
    fail(res, 'Submit assignment', e);
  }
};

// GET /api/user/assignments/:assignmentId/submission
export const getAssignmentSubmission = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const assignmentId = String(req.params.assignmentId);
    const sub = isObjectId(assignmentId)
      ? await prisma.assignmentSubmission.findUnique({
          where: { userId_assignmentId: { userId: uid(req), assignmentId } },
          include: { assignment: true },
        })
      : null;
    if (!sub) {
      res.status(404).json({ error: 'Not submitted yet' });
      return;
    }
    const { assignment, ...rest } = sub;
    res.status(200).json({ ...rest, courseId: assignment.courseId, moduleId: assignment.moduleId, lessonId: assignment.lessonId });
  } catch (e) {
    fail(res, 'Get assignment submission', e);
  }
};

// ── Certificates ─────────────────────────────────────────────────────────────

function mapCertificate(c: any) {
  return {
    id: c.id,
    certificateId: c.id,
    userId: c.userId,
    userName: c.user?.displayName || c.user?.email || '',
    courseId: c.courseId,
    courseName: c.course?.title ?? '',
    lessonId: '',
    lessonName: c.title,
    completionDate: c.issueDate,
    issueDate: c.issueDate,
    dayOfWeek: new Date(c.issueDate).toLocaleDateString('en-US', { weekday: 'long' }),
    certificateUrl: c.certificateUrl,
  };
}

// GET /api/user/certificates
export const getUserCertificates = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const certs = await prisma.certificate.findMany({
      where: { userId: uid(req) },
      include: { course: true, user: { select: { displayName: true, email: true } } },
      orderBy: { issueDate: 'desc' },
    });
    res.status(200).json(certs.map(mapCertificate));
  } catch (e) {
    fail(res, 'Get certificates', e);
  }
};

// GET /api/user/certificates/check?courseId=
export const checkCertificate = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const courseId = String(req.query.courseId ?? '');
    const exists = isObjectId(courseId) && (await prisma.certificate.count({ where: { userId: uid(req), courseId } })) > 0;
    res.status(200).json({ exists });
  } catch (e) {
    fail(res, 'Check certificate', e);
  }
};

// POST /api/user/certificates { courseId, lessonId? }
// Issued only if the student earned it: passed the course's final quiz
// (lessonId) or completed every lesson. One certificate per course.
export const issueCertificate = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const courseId = String(req.body?.courseId ?? '');
  const lessonId = req.body?.lessonId ? String(req.body.lessonId) : null;
  if (!isObjectId(courseId)) {
    res.status(400).json({ error: 'A valid courseId is required' });
    return;
  }
  try {
    const course = await prisma.course.findUnique({ where: { id: courseId } });
    if (!course) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }
    const include = { course: true, user: { select: { displayName: true, email: true } } };
    const existing = await prisma.certificate.findFirst({ where: { userId: uid(req), courseId }, include });
    if (existing) {
      res.status(200).json(mapCertificate(existing));
      return;
    }
    // Only students who are enrolled (and so, for paid courses, have paid) can earn one.
    if (!(await isEnrolled(uid(req), courseId))) {
      res.status(403).json({ error: 'Enrol in this course to earn its certificate' });
      return;
    }

    let earned = (await courseCompletion(uid(req), courseId)) >= 1;
    // A passed quiz only counts if it is the course's final test: the very
    // last lesson of the syllabus. Mid-course quizzes never grant certificates.
    if (!earned && lessonId && lessonId === (await finalLessonId(courseId))) {
      const quiz = await prisma.quiz.findUnique({ where: { lessonId } });
      earned = !!quiz && quiz.courseId === courseId &&
        !!(await prisma.quizSubmission.findFirst({ where: { userId: uid(req), quizId: quiz.id, passed: true } }));
    }
    if (!earned) {
      res.status(403).json({ error: 'Finish every lesson or pass the final test to earn this certificate' });
      return;
    }

    const cert = await prisma.certificate.create({
      data: { userId: uid(req), courseId, title: `Certificate of completion — ${course.title}` },
      include,
    });
    await prisma.enrollment.updateMany({ where: { userId: uid(req), courseId }, data: { status: 'completed' } });
    res.status(201).json(mapCertificate(cert));
  } catch (e) {
    fail(res, 'Issue certificate', e);
  }
};

// ── Progress ─────────────────────────────────────────────────────────────────

// GET /api/user/courses/:courseId/progress — per-lesson progress rows
export const getCourseProgress = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const courseId = String(req.params.courseId);
    if (!isObjectId(courseId)) {
      res.status(200).json([]);
      return;
    }
    const lessons = await prisma.lesson.findMany({
      where: { module: { courseId } },
      select: { id: true, moduleId: true, videoUrl: true },
    });
    const byId = new Map(lessons.map((l) => [l.id, l]));
    const rows = await prisma.progress.findMany({ where: { userId: uid(req), lessonId: { in: [...byId.keys()] } } });
    res.status(200).json(
      rows.map((p) => ({
        progressId: p.id,
        lessonId: p.lessonId,
        moduleId: byId.get(p.lessonId)?.moduleId,
        videoURL: byId.get(p.lessonId)?.videoUrl ?? '',
        currentPosition: p.currentPosition,
        totalDuration: p.totalDuration,
        isCompleted: p.isCompleted,
        lastWatchedAt: p.updatedAt,
        createdAt: p.updatedAt,
      })),
    );
  } catch (e) {
    fail(res, 'Get course progress', e);
  }
};
