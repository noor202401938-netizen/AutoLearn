import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import prisma from '../prisma';
import { complete, aiErrorStatus, TUTOR_PROMPT } from '../ai';
import { withoutAnswers } from './learning.controller';

type Turn = { role: 'user' | 'assistant'; content: string };

// Caps what a client can push into a prompt.
const clean = (messages: any[]): Turn[] =>
  messages.slice(-10).map((m) => ({
    role: m?.role === 'assistant' ? 'assistant' : 'user',
    content: String(m?.content ?? '').slice(0, 2000),
  }));

// POST /api/ai/summary — summary + key points for a lesson video
export const generateSummary = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const { videoTitle } = req.body;
  if (!videoTitle) {
    res.status(400).json({ error: 'videoTitle is required' });
    return;
  }
  try {
    const content = await complete(
      [
        { role: 'system', content: 'You write concise study notes for economics lessons. Reply as JSON.' },
        {
          role: 'user',
          content: `Lesson title: ${String(videoTitle).slice(0, 300)}\n` +
            'Return {"summary": "2-3 short paragraphs", "keyPoints": ["3-5 points"]}.',
        },
      ],
      { json: true, maxTokens: 500 },
    );
    res.status(200).json(JSON.parse(content));
  } catch (e) {
    const { status, error } = aiErrorStatus(e);
    res.status(status).json({ error });
  }
};

// POST /api/ai/chat — stateless chat used by the in-player copilot
export const chat = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const { messages } = req.body;
  if (!Array.isArray(messages) || messages.length === 0) {
    res.status(400).json({ error: 'Valid messages array is required' });
    return;
  }
  try {
    const content = await complete([{ role: 'system', content: TUTOR_PROMPT }, ...clean(messages)]);
    res.status(200).json({ role: 'assistant', content });
  } catch (e) {
    const { status, error } = aiErrorStatus(e);
    res.status(status).json({ error });
  }
};

// ── Tutor sessions (persistent conversations) ────────────────────────────────

// POST /api/chat/session
export const createSession = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const session = await prisma.chatSession.create({
      data: { userId: req.user!.uid, title: String(req.body?.title ?? 'New conversation').slice(0, 120) },
    });
    res.status(201).json({ sessionId: session.id, ...session });
  } catch (error) {
    console.error('Create chat session error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/chat/sessions
export const listSessions = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const sessions = await prisma.chatSession.findMany({
      where: { userId: req.user!.uid },
      orderBy: { updatedAt: 'desc' },
      take: 50,
    });
    res.status(200).json(sessions);
  } catch (error) {
    console.error('List chat sessions error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

async function ownSession(req: AuthenticatedRequest, res: Response) {
  const id = String(req.params.sessionId);
  const session = /^[a-f0-9]{24}$/.test(id) ? await prisma.chatSession.findUnique({ where: { id } }) : null;
  if (!session || session.userId !== req.user!.uid) {
    res.status(404).json({ error: 'Conversation not found' });
    return null;
  }
  return session;
}

// GET /api/chat/:sessionId/history
export const getHistory = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const session = await ownSession(req, res);
    if (!session) return;
    const messages = await prisma.chatMessage.findMany({
      where: { sessionId: session.id },
      orderBy: { timestamp: 'asc' },
    });
    res.status(200).json(messages);
  } catch (error) {
    console.error('Get history error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/chat/:sessionId/message  { content, courseTitle?, lessonTitle? }
// Saves the student's message, asks the tutor with the conversation so far,
// saves and returns the reply.
export const sendMessage = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const content = String(req.body?.content ?? '').trim().slice(0, 2000);
  if (!content) {
    res.status(400).json({ error: 'Message content is required' });
    return;
  }
  try {
    const session = await ownSession(req, res);
    if (!session) return;

    const history = await prisma.chatMessage.findMany({
      where: { sessionId: session.id },
      orderBy: { timestamp: 'desc' },
      take: 10,
    });
    const context = [req.body?.courseTitle, req.body?.lessonTitle].filter(Boolean).join(' — ');
    const system = context ? `${TUTOR_PROMPT}\nThe student is currently studying: ${String(context).slice(0, 300)}.` : TUTOR_PROMPT;

    // Ask first, so a failed AI call doesn't leave an unanswered message behind.
    const reply = await complete([
      { role: 'system', content: system },
      ...clean(history.reverse()),
      { role: 'user', content },
    ]);

    await prisma.chatMessage.create({ data: { sessionId: session.id, role: 'user', content } });
    const saved = await prisma.chatMessage.create({ data: { sessionId: session.id, role: 'assistant', content: reply } });
    await prisma.chatSession.update({
      where: { id: session.id },
      // First question becomes the conversation title.
      data: history.length === 0 ? { title: content.slice(0, 80) } : { title: session.title },
    });
    res.status(201).json(saved);
  } catch (e) {
    const { status, error } = aiErrorStatus(e);
    res.status(status).json({ error });
  }
};

// DELETE /api/chat/:sessionId
export const deleteSession = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const session = await ownSession(req, res);
    if (!session) return;
    await prisma.chatSession.delete({ where: { id: session.id } });
    res.status(204).end();
  } catch (error) {
    console.error('Delete chat session error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/ai/quiz { courseId, moduleId, lessonId, lessonTitle, lessonContent?, numberOfQuestions? }
// Returns the lesson's quiz, generating and saving one the first time.
export const generateQuiz = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const { courseId, moduleId = '', lessonId, lessonTitle, lessonContent = '' } = req.body ?? {};
  const n = Math.min(Math.max(Number(req.body?.numberOfQuestions) || 5, 3), 10);
  if (!courseId || !lessonId || !lessonTitle) {
    res.status(400).json({ error: 'courseId, lessonId and lessonTitle are required' });
    return;
  }
  try {
    const existing = await prisma.quiz.findUnique({ where: { lessonId: String(lessonId) } });
    const forCaller = <T extends { questions: unknown }>(q: T) => (req.user?.role === 'admin' ? q : withoutAnswers(q));
    if (existing) {
      res.status(200).json(forCaller(existing));
      return;
    }
    const raw = await complete(
      [
        { role: 'system', content: 'You write rigorous multiple-choice economics quizzes. Reply as JSON.' },
        {
          role: 'user',
          content:
            `Write ${n} multiple-choice questions for the lesson "${String(lessonTitle).slice(0, 200)}".\n` +
            (lessonContent ? `Lesson notes:\n${String(lessonContent).slice(0, 4000)}\n` : '') +
            'Each question has exactly 4 options and one correct answer. Test understanding, not recall of wording.\n' +
            'Return {"questions":[{"questionText":"","options":["","","",""],"correctOptionIndex":0,"explanation":""}]}',
        },
      ],
      { json: true, maxTokens: 1800 },
    );
    const parsed = JSON.parse(raw);
    const questions = (Array.isArray(parsed.questions) ? parsed.questions : [])
      .filter((q: any) => q?.questionText && Array.isArray(q.options) && q.options.length >= 2)
      .map((q: any, i: number) => ({
        questionId: `q${i + 1}`,
        questionText: String(q.questionText),
        type: 'multiple_choice',
        options: q.options.map((t: any, j: number) => ({ optionId: `q${i + 1}o${j + 1}`, text: String(t) })),
        correctOptionIndex: Math.min(Math.max(Number(q.correctOptionIndex) || 0, 0), q.options.length - 1),
        explanation: q.explanation ? String(q.explanation) : null,
        points: 1,
      }));
    if (questions.length === 0) {
      res.status(502).json({ error: 'The AI returned no usable questions. Please try again.' });
      return;
    }
    const quiz = await prisma.quiz.create({
      data: {
        courseId: String(courseId),
        moduleId: String(moduleId),
        lessonId: String(lessonId),
        title: `Quiz: ${String(lessonTitle).slice(0, 150)}`,
        description: `Check your understanding of ${String(lessonTitle).slice(0, 150)}`,
        questions,
        timeLimit: questions.length * 2,
        passingScore: 70,
        createdBy: 'ai',
      },
    });
    res.status(201).json(forCaller(quiz));
  } catch (e) {
    if (e instanceof SyntaxError) {
      res.status(502).json({ error: 'The AI returned malformed questions. Please try again.' });
      return;
    }
    const { status, error } = aiErrorStatus(e);
    res.status(status).json({ error });
  }
};
