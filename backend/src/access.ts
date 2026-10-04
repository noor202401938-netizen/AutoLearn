// Who may change what: admins manage everything, teachers only courses they created.
import prisma from './prisma';

/** Pure rule, kept separate so it can be tested without a database. */
export function mayManage(user: { uid: string; role: string } | undefined, course: { createdBy: string } | null): boolean {
  if (!user || !course) return false;
  return user.role === 'admin' || (user.role === 'teacher' && course.createdBy === user.uid);
}

const isObjectId = (s: unknown): s is string => typeof s === 'string' && /^[a-f0-9]{24}$/.test(s);

export async function canManageCourse(user: { uid: string; role: string } | undefined, courseId: unknown): Promise<boolean> {
  if (!isObjectId(courseId)) return false;
  const course = await prisma.course.findUnique({ where: { id: courseId }, select: { createdBy: true } });
  return mayManage(user, course);
}

/** Ids of the courses this user may manage (every course for an admin). */
export async function managedCourseIds(user: { uid: string; role: string }): Promise<string[]> {
  const courses = await prisma.course.findMany({ where: user.role === 'admin' ? {} : { createdBy: user.uid }, select: { id: true } });
  return courses.map((c) => c.id);
}
