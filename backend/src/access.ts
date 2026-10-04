// Who may change what: admins manage everything; a teacher manages courses they
// created or were added to as a co-teacher, and only the creator may delete a
// course, change its team or see its earnings.
import prisma from './prisma';

type Actor = { uid: string; role: string } | undefined;
type CourseAccess = { createdBy: string; coTeacherIds?: string[] };

/** Pure rules, kept separate so they can be tested without a database. */
export function mayManage(user: Actor, course: CourseAccess | null): boolean {
  if (!user || !course) return false;
  if (user.role === 'admin') return true;
  return user.role === 'teacher' && (course.createdBy === user.uid || (course.coTeacherIds ?? []).includes(user.uid));
}

/** Published courses are public; a draft is visible only to people who manage it. */
export function mayView(user: Actor, course: (CourseAccess & { isPublished: boolean }) | null): boolean {
  return !!course && (course.isPublished || mayManage(user, course));
}

export function mayOwn(user: Actor, course: CourseAccess | null): boolean {
  if (!user || !course) return false;
  return user.role === 'admin' || (user.role === 'teacher' && course.createdBy === user.uid);
}

const isObjectId = (s: unknown): s is string => typeof s === 'string' && /^[a-f0-9]{24}$/.test(s);

async function loadAccess(courseId: unknown): Promise<CourseAccess | null> {
  if (!isObjectId(courseId)) return null;
  return prisma.course.findUnique({ where: { id: courseId }, select: { createdBy: true, coTeacherIds: true } });
}

export async function canManageCourse(user: Actor, courseId: unknown): Promise<boolean> {
  return mayManage(user, await loadAccess(courseId));
}

export async function canOwnCourse(user: Actor, courseId: unknown): Promise<boolean> {
  return mayOwn(user, await loadAccess(courseId));
}

/** Ids of the courses this user may manage (every course for an admin). */
export async function managedCourseIds(user: { uid: string; role: string }): Promise<string[]> {
  const where = user.role === 'admin' ? {} : { OR: [{ createdBy: user.uid }, { coTeacherIds: { has: user.uid } }] };
  return (await prisma.course.findMany({ where, select: { id: true } })).map((c) => c.id);
}

/**
 * Lesson text, video links, quizzes and assignments of a paid course are for people who
 * paid (so are enrolled) or who run the course. Free courses are open to read.
 */
export function mayReadContent(user: Actor, course: (CourseAccess & { price: number }) | null, enrolled: boolean): boolean {
  if (!course) return false;
  return course.price <= 0 || enrolled || mayManage(user, course);
}

export async function isEnrolled(userId: string | undefined, courseId: unknown): Promise<boolean> {
  if (!userId || !isObjectId(courseId)) return false;
  return (await prisma.enrollment.count({ where: { userId, courseId } })) > 0;
}

/** Progress, quiz and assignment writes need an enrolment (course staff may try their own course). */
export async function canLearnIn(user: Actor, courseId: unknown): Promise<boolean> {
  if (!user || !isObjectId(courseId)) return false;
  return (await isEnrolled(user.uid, courseId)) || (await canManageCourse(user, courseId));
}

/** Whether this user may read the paid content of a course, looked up by id. */
export async function canReadCourseContent(user: Actor, courseId: unknown): Promise<boolean> {
  if (!isObjectId(courseId)) return true; // synthetic ids (e.g. final tests) belong to no real course
  const course = await prisma.course.findUnique({ where: { id: courseId }, select: { createdBy: true, coTeacherIds: true, price: true } });
  if (!course) return true;
  return mayReadContent(user, course, course.price > 0 && (await isEnrolled(user?.uid, courseId)));
}

/** Ids of the courses this user created (every course for an admin). */
export async function ownedCourseIds(user: { uid: string; role: string }): Promise<string[]> {
  const where = user.role === 'admin' ? {} : { createdBy: user.uid };
  return (await prisma.course.findMany({ where, select: { id: true } })).map((c) => c.id);
}
