// Password reset/change and admin user management.
import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import crypto from 'crypto';
import prisma from '../prisma';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { sendMail } from '../mailer';
import { passwordProblem } from '../validation';

const RESET_TTL_MINUTES = 30;
const sha256 = (s: string) => crypto.createHash('sha256').update(s).digest('hex');
const isObjectId = (s: unknown): s is string => typeof s === 'string' && /^[a-f0-9]{24}$/.test(s);

// POST /api/auth/password-reset { email }
// Always answers the same way so the endpoint can't be used to discover accounts.
export const requestPasswordReset = async (req: Request, res: Response): Promise<void> => {
  const email = String(req.body?.email ?? '').trim();
  const ok = { message: 'If an account exists for that email, a reset link is on its way.' };
  if (!email) {
    res.status(400).json({ error: 'Email is required' });
    return;
  }
  try {
    const user = await prisma.user.findFirst({ where: { email: { equals: email, mode: 'insensitive' } } });
    if (user && user.isActive) {
      const token = crypto.randomBytes(32).toString('hex');
      await prisma.passwordReset.create({
        data: { userId: user.id, tokenHash: sha256(token), expiresAt: new Date(Date.now() + RESET_TTL_MINUTES * 60_000) },
      });
      const appUrl = (process.env.APP_URL || 'http://localhost:8080').replace(/\/$/, '');
      await sendMail(
        user.email,
        'Reset your AutoLearn password',
        'Someone asked to reset the password for this AutoLearn account.\n\n' +
          `Open this link within ${RESET_TTL_MINUTES} minutes to choose a new one:\n${appUrl}/reset-password?token=${token}\n\n` +
          "If it wasn't you, ignore this email and your password won't change.",
      );
    }
    res.status(200).json(ok);
  } catch (error) {
    console.error('Password reset request error:', error);
    res.status(200).json(ok);
  }
};

// POST /api/auth/password-reset/confirm { token, newPassword }
export const confirmPasswordReset = async (req: Request, res: Response): Promise<void> => {
  const token = String(req.body?.token ?? '');
  const newPassword = req.body?.newPassword;
  const passwordIssue = passwordProblem(newPassword);
  if (!token || passwordIssue) {
    res.status(400).json({ error: passwordIssue ?? 'A reset token is required' });
    return;
  }
  try {
    const reset = await prisma.passwordReset.findUnique({ where: { tokenHash: sha256(token) } });
    if (!reset || reset.usedAt || reset.expiresAt < new Date()) {
      res.status(400).json({ error: 'This reset link is invalid or has expired. Request a new one.' });
      return;
    }
    await prisma.user.update({ where: { id: reset.userId }, data: { password: await bcrypt.hash(newPassword as string, 12) } });
    // Burn this token and any other outstanding ones for the user.
    await prisma.passwordReset.updateMany({ where: { userId: reset.userId, usedAt: null }, data: { usedAt: new Date() } });
    res.status(200).json({ message: 'Password updated. You can sign in now.' });
  } catch (error) {
    console.error('Password reset confirm error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/auth/change-password { currentPassword, newPassword }
export const changePassword = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const currentPassword = String(req.body?.currentPassword ?? '');
  const newPassword = req.body?.newPassword;
  const passwordIssue = passwordProblem(newPassword);
  if (!currentPassword || passwordIssue) {
    res.status(400).json({ error: passwordIssue ?? 'Your current password is required' });
    return;
  }
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user!.uid } });
    if (!user || !(await bcrypt.compare(currentPassword, user.password))) {
      res.status(401).json({ error: 'Current password is incorrect' });
      return;
    }
    await prisma.user.update({ where: { id: user.id }, data: { password: await bcrypt.hash(newPassword as string, 12) } });
    res.status(200).json({ message: 'Password changed' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ── Admin user management (/api/users) ──────────────────────────────────────

const publicUser = {
  id: true, email: true, displayName: true, role: true, phone: true, grade: true,
  interest: true, isActive: true, createdAt: true,
} as const;

// GET /api/users/:uid — yourself, or anyone if admin
export const getUserById = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const id = String(req.params.uid);
  if (req.user?.uid !== id && req.user?.role !== 'admin') {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }
  try {
    const user = isObjectId(id) ? await prisma.user.findUnique({ where: { id }, select: publicUser }) : null;
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    res.status(200).json({ ...user, uid: user.id });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// PUT /api/users/:uid/role { role } (admin)
export const setUserRole = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const id = String(req.params.uid);
  const role = String(req.body?.role ?? '');
  if (!['student', 'teacher', 'admin'].includes(role) || !isObjectId(id)) {
    res.status(400).json({ error: 'role must be "student", "teacher" or "admin"' });
    return;
  }
  if (id === req.user?.uid && role !== 'admin') {
    res.status(400).json({ error: "You can't remove your own admin access" });
    return;
  }
  try {
    const user = await prisma.user.update({ where: { id }, data: { role }, select: publicUser });
    res.status(200).json({ ...user, uid: user.id });
  } catch (error) {
    console.error('Set role error:', error);
    res.status(404).json({ error: 'User not found' });
  }
};

// DELETE /api/users/:uid (admin)
export const deleteUser = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const id = String(req.params.uid);
  if (id === req.user?.uid) {
    res.status(400).json({ error: "You can't delete your own account from the admin panel" });
    return;
  }
  try {
    await prisma.user.delete({ where: { id } });
    res.status(204).end();
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(404).json({ error: 'User not found' });
  }
};
