// Bookmarks, learning paths and the discussion forum.
import { Response } from 'express';
import prisma from '../prisma';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { courseCompletion } from './learning.controller';

const isObjectId = (s: unknown): s is string => typeof s === 'string' && /^[a-f0-9]{24}$/.test(s);
const uid = (req: AuthenticatedRequest) => req.user!.uid;
const isAdmin = (req: AuthenticatedRequest) => req.user?.role === 'admin';

function fail(res: Response, where: string, error: unknown) {
  console.error(`${where} error:`, error);
  res.status(500).json({ error: 'Internal server error' });
}

// ── Bookmarks ────────────────────────────────────────────────────────────────

// GET /api/user/bookmarks
export const listBookmarks = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const bookmarks = await prisma.bookmark.findMany({ where: { userId: uid(req) }, orderBy: { createdAt: 'desc' } });
    const courses = await prisma.course.findMany({
      where: { id: { in: [...new Set(bookmarks.map((b) => b.courseId))] } },
      select: { id: true, title: true, category: true },
    });
    const byId = new Map(courses.map((c) => [c.id, c]));
    // Drop bookmarks whose course was deleted.
    res.status(200).json(
      bookmarks
        .filter((b) => byId.has(b.courseId))
        .map((b) => ({ ...b, courseTitle: byId.get(b.courseId)!.title, category: byId.get(b.courseId)!.category })),
    );
  } catch (e) {
    fail(res, 'List bookmarks', e);
  }
};

// POST /api/user/bookmarks { courseId, lessonId?, title, note?, positionSeconds? }
export const addBookmark = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const { courseId, lessonId = null, title, note = null } = req.body ?? {};
  const positionSeconds = req.body?.positionSeconds == null ? null : Math.max(0, Math.floor(Number(req.body.positionSeconds)) || 0);
  if (!isObjectId(courseId) || !title) {
    res.status(400).json({ error: 'courseId and title are required' });
    return;
  }
  try {
    if (!(await prisma.course.findUnique({ where: { id: courseId }, select: { id: true } }))) {
      res.status(404).json({ error: 'Course not found' });
      return;
    }
    const where = { userId: uid(req), courseId, lessonId: lessonId ? String(lessonId) : null, positionSeconds };
    const existing = await prisma.bookmark.findFirst({ where });
    if (existing) {
      res.status(200).json(existing);
      return;
    }
    const b = await prisma.bookmark.create({
      data: { ...where, title: String(title).slice(0, 200), note: note ? String(note).slice(0, 1000) : null },
    });
    res.status(201).json(b);
  } catch (e) {
    fail(res, 'Add bookmark', e);
  }
};

// DELETE /api/user/bookmarks/:id
export const deleteBookmark = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = String(req.params.id);
    const { count } = isObjectId(id) ? await prisma.bookmark.deleteMany({ where: { id, userId: uid(req) } }) : { count: 0 };
    res.status(count ? 204 : 404).end();
  } catch (e) {
    fail(res, 'Delete bookmark', e);
  }
};

// ── Learning paths ───────────────────────────────────────────────────────────

// GET /api/learning-paths — published paths with the user's progress through each
export const listLearningPaths = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const paths = await prisma.learningPath.findMany({
      where: isAdmin(req) ? {} : { isPublished: true },
      orderBy: { createdAt: 'asc' },
    });
    const courseIds = [...new Set(paths.flatMap((p) => p.courseIds))];
    const courses = await prisma.course.findMany({
      where: { id: { in: courseIds }, ...(isAdmin(req) ? {} : { isPublished: true }) },
      select: { id: true, title: true, level: true, duration: true, thumbnailURL: true },
    });
    const enrolled = new Set(
      (await prisma.enrollment.findMany({ where: { userId: uid(req), courseId: { in: courseIds } }, select: { courseId: true } }))
        .map((e) => e.courseId),
    );
    const completion = new Map<string, number>();
    for (const id of enrolled) completion.set(id, await courseCompletion(uid(req), id));

    const byId = new Map(courses.map((c) => [c.id, c]));
    res.status(200).json(
      paths.map((p) => {
        const steps = p.courseIds.filter((id) => byId.has(id)).map((id) => ({
          ...byId.get(id)!,
          courseId: id,
          enrolled: enrolled.has(id),
          completion: completion.get(id) ?? 0,
        }));
        const progress = steps.length === 0 ? 0 : steps.reduce((s, c) => s + c.completion, 0) / steps.length;
        return { ...p, courses: steps, progress };
      }),
    );
  } catch (e) {
    fail(res, 'List learning paths', e);
  }
};

// POST /api/learning-paths (admin)  PUT /api/learning-paths/:id (admin)
export const saveLearningPath = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const { title, description, level = 'beginner', skills = [], courseIds = [], isPublished = true } = req.body ?? {};
  if (!title || !description || !Array.isArray(courseIds) || !courseIds.every(isObjectId)) {
    res.status(400).json({ error: 'title, description and a list of valid courseIds are required' });
    return;
  }
  try {
    const data = {
      title: String(title), description: String(description), level: String(level),
      skills: Array.isArray(skills) ? skills.map(String) : [], courseIds, isPublished: !!isPublished,
    };
    const id = req.params.id ? String(req.params.id) : null;
    const path = id ? await prisma.learningPath.update({ where: { id }, data }) : await prisma.learningPath.create({ data });
    res.status(id ? 200 : 201).json(path);
  } catch (e) {
    fail(res, 'Save learning path', e);
  }
};

// DELETE /api/learning-paths/:id (admin)
export const deleteLearningPath = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    await prisma.learningPath.delete({ where: { id: String(req.params.id) } });
    res.status(204).end();
  } catch (e) {
    fail(res, 'Delete learning path', e);
  }
};

// ── Forum ────────────────────────────────────────────────────────────────────

const author = { select: { id: true, displayName: true, email: true, role: true } };
const authorView = (a: { id: string; displayName: string | null; email: string; role: string }) => ({
  id: a.id,
  name: a.displayName || a.email.split('@')[0],
  role: a.role,
});

function threadView(t: any, me: string) {
  const { upvoterIds, author: a, ...rest } = t;
  return { ...rest, author: authorView(a), upvotes: upvoterIds.length, upvotedByMe: upvoterIds.includes(me) };
}

// GET /api/forum/threads?category=&q=&sort=new|top|unanswered
export const listThreads = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { category, q, sort } = req.query as Record<string, string | undefined>;
    const threads = await prisma.forumThread.findMany({
      where: {
        ...(category && category !== 'all' && { category }),
        ...(q && { OR: [{ title: { contains: q, mode: 'insensitive' } }, { body: { contains: q, mode: 'insensitive' } }] }),
        ...(sort === 'unanswered' && { replyCount: 0 }),
      },
      include: { author },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    const views = threads.map((t) => threadView(t, uid(req)));
    if (sort === 'top') views.sort((a, b) => b.upvotes - a.upvotes);
    res.status(200).json(views);
  } catch (e) {
    fail(res, 'List threads', e);
  }
};

// POST /api/forum/threads { title, body, category?, tags?, courseId? }
export const createThread = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const title = String(req.body?.title ?? '').trim();
  const body = String(req.body?.body ?? '').trim();
  if (title.length < 5 || body.length < 10) {
    res.status(400).json({ error: 'Give your question a title (5+ characters) and some detail (10+ characters)' });
    return;
  }
  try {
    const t = await prisma.forumThread.create({
      data: {
        authorId: uid(req),
        title: title.slice(0, 200),
        body: body.slice(0, 10000),
        category: String(req.body?.category ?? 'general').slice(0, 40),
        tags: Array.isArray(req.body?.tags) ? req.body.tags.slice(0, 5).map((x: unknown) => String(x).slice(0, 30)) : [],
        courseId: isObjectId(req.body?.courseId) ? req.body.courseId : null,
      },
      include: { author },
    });
    res.status(201).json(threadView(t, uid(req)));
  } catch (e) {
    fail(res, 'Create thread', e);
  }
};

// GET /api/forum/threads/:id — thread with replies (accepted answer first)
export const getThread = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = String(req.params.id);
    const t = isObjectId(id)
      ? await prisma.forumThread.findUnique({
          where: { id },
          include: { author, replies: { include: { author }, orderBy: { createdAt: 'asc' } } },
        })
      : null;
    if (!t) {
      res.status(404).json({ error: 'Thread not found' });
      return;
    }
    const { replies, ...thread } = t;
    const me = uid(req);
    const replyViews = replies
      .map(({ upvoterIds, author: a, ...r }) => ({
        ...r,
        author: authorView(a),
        upvotes: upvoterIds.length,
        upvotedByMe: upvoterIds.includes(me),
        accepted: r.id === t.acceptedReplyId,
      }))
      .sort((a, b) => Number(b.accepted) - Number(a.accepted));
    res.status(200).json({ ...threadView(thread, me), replies: replyViews });
  } catch (e) {
    fail(res, 'Get thread', e);
  }
};

// POST /api/forum/threads/:id/replies { body }
export const createReply = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const id = String(req.params.id);
  const body = String(req.body?.body ?? '').trim();
  if (!isObjectId(id) || body.length < 2) {
    res.status(400).json({ error: 'Write a reply first' });
    return;
  }
  try {
    if (!(await prisma.forumThread.findUnique({ where: { id }, select: { id: true } }))) {
      res.status(404).json({ error: 'Thread not found' });
      return;
    }
    const r = await prisma.forumReply.create({ data: { threadId: id, authorId: uid(req), body: body.slice(0, 10000) }, include: { author } });
    await prisma.forumThread.update({ where: { id }, data: { replyCount: { increment: 1 } } });
    const { upvoterIds, author: a, ...rest } = r;
    res.status(201).json({ ...rest, author: authorView(a), upvotes: upvoterIds.length, upvotedByMe: false, accepted: false });
  } catch (e) {
    fail(res, 'Create reply', e);
  }
};

/** Toggles the user's upvote in an upvoterIds array; returns the new array. */
export function toggleVote(voters: string[], me: string): string[] {
  return voters.includes(me) ? voters.filter((v) => v !== me) : [...voters, me];
}

// POST /api/forum/threads/:id/upvote   (toggle)
export const upvoteThread = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = String(req.params.id);
    const t = isObjectId(id) ? await prisma.forumThread.findUnique({ where: { id }, select: { upvoterIds: true } }) : null;
    if (!t) {
      res.status(404).json({ error: 'Thread not found' });
      return;
    }
    const upvoterIds = toggleVote(t.upvoterIds, uid(req));
    await prisma.forumThread.update({ where: { id }, data: { upvoterIds } });
    res.status(200).json({ upvotes: upvoterIds.length, upvotedByMe: upvoterIds.includes(uid(req)) });
  } catch (e) {
    fail(res, 'Upvote thread', e);
  }
};

// POST /api/forum/replies/:id/upvote   (toggle)
export const upvoteReply = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = String(req.params.id);
    const r = isObjectId(id) ? await prisma.forumReply.findUnique({ where: { id }, select: { upvoterIds: true } }) : null;
    if (!r) {
      res.status(404).json({ error: 'Reply not found' });
      return;
    }
    const upvoterIds = toggleVote(r.upvoterIds, uid(req));
    await prisma.forumReply.update({ where: { id }, data: { upvoterIds } });
    res.status(200).json({ upvotes: upvoterIds.length, upvotedByMe: upvoterIds.includes(uid(req)) });
  } catch (e) {
    fail(res, 'Upvote reply', e);
  }
};

// POST /api/forum/threads/:id/accept { replyId } — thread author or admin marks the answer
export const acceptReply = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = String(req.params.id);
    const replyId = String(req.body?.replyId ?? '');
    const t = isObjectId(id) ? await prisma.forumThread.findUnique({ where: { id } }) : null;
    if (!t) {
      res.status(404).json({ error: 'Thread not found' });
      return;
    }
    if (t.authorId !== uid(req) && !isAdmin(req)) {
      res.status(403).json({ error: 'Only the person who asked can accept an answer' });
      return;
    }
    const reply = isObjectId(replyId) ? await prisma.forumReply.findUnique({ where: { id: replyId } }) : null;
    if (!reply || reply.threadId !== id) {
      res.status(400).json({ error: 'That reply is not part of this thread' });
      return;
    }
    // Accepting the already-accepted reply un-accepts it.
    const acceptedReplyId = t.acceptedReplyId === replyId ? null : replyId;
    await prisma.forumThread.update({ where: { id }, data: { acceptedReplyId } });
    res.status(200).json({ acceptedReplyId });
  } catch (e) {
    fail(res, 'Accept reply', e);
  }
};

// DELETE /api/forum/threads/:id — author or admin
export const deleteThread = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const id = String(req.params.id);
    const t = isObjectId(id) ? await prisma.forumThread.findUnique({ where: { id }, select: { authorId: true } }) : null;
    if (!t) {
      res.status(404).json({ error: 'Thread not found' });
      return;
    }
    if (t.authorId !== uid(req) && !isAdmin(req)) {
      res.status(403).json({ error: 'You can only delete your own threads' });
      return;
    }
    await prisma.forumThread.delete({ where: { id } });
    res.status(204).end();
  } catch (e) {
    fail(res, 'Delete thread', e);
  }
};
