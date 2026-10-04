import { Request, Response, NextFunction } from 'express';
import jwt from 'jwt-simple';
import prisma from '../prisma';
import { JWT_SECRET } from '../config';

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    role: string;
  };
}

const isObjectId = (s: unknown): s is string => typeof s === 'string' && /^[a-f0-9]{24}$/.test(s);

export type Account = { role: string; isActive: boolean } | null;
export type AccountCheck = { ok: true; role: string } | { ok: false; status: number; error: string };

/** Decides whether a token's owner may still use the API, using the account as it is now. */
export function checkAccount(account: Account): AccountCheck {
  if (!account) return { ok: false, status: 401, error: 'Unauthorized: this account no longer exists' };
  if (!account.isActive) return { ok: false, status: 403, error: 'Forbidden: this account has been disabled' };
  return { ok: true, role: account.role };
}

type Resolved = { ok: true; uid: string; role: string } | { ok: false; status: number; error: string };

/**
 * Verifies the bearer token, then re-reads the account so a disabled, deleted or
 * demoted user loses access immediately. The role comes from the database, never
 * from the token, which only proves who the caller is.
 */
async function resolveCaller(authHeader: string | undefined): Promise<Resolved> {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return { ok: false, status: 401, error: 'Unauthorized: No token provided' };
  }
  let uid: unknown;
  try {
    const decoded = jwt.decode(authHeader.split(' ')[1], JWT_SECRET) as any;
    if (decoded.exp && Date.now() / 1000 > decoded.exp) {
      return { ok: false, status: 401, error: 'Unauthorized: Token has expired' };
    }
    uid = decoded.uid;
  } catch {
    return { ok: false, status: 403, error: 'Forbidden: Invalid or malformed token' };
  }
  if (!isObjectId(uid)) return { ok: false, status: 403, error: 'Forbidden: Invalid or malformed token' };

  try {
    const account = await prisma.user.findUnique({ where: { id: uid }, select: { role: true, isActive: true } });
    const check = checkAccount(account);
    return check.ok ? { ok: true, uid, role: check.role } : check;
  } catch (error) {
    console.error('Account lookup error:', error);
    return { ok: false, status: 503, error: 'Service temporarily unavailable' };
  }
}

export const authenticateToken = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const caller = await resolveCaller(req.headers.authorization);
  if (!caller.ok) {
    res.status(caller.status).json({ error: caller.error });
    return;
  }
  req.user = { uid: caller.uid, role: caller.role };
  next();
};

/**
 * For public routes whose answer depends on who is asking (e.g. drafts are visible
 * to their teachers). A missing or bad token means "anonymous", never an error.
 */
export const optionalAuth = async (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  if (req.headers.authorization) {
    const caller = await resolveCaller(req.headers.authorization);
    if (caller.ok) req.user = { uid: caller.uid, role: caller.role };
  }
  next();
};

// Middleware to restrict routes to admin users only
export const adminOnly = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  if (!req.user || req.user.role !== 'admin') {
    res.status(403).json({ error: 'Forbidden: Admin access required' });
    return;
  }
  next();
};

export const isStaff = (role?: string): boolean => role === 'admin' || role === 'teacher';

// Admins and teachers. Teachers are further limited to their own courses by canManageCourse.
export const staffOnly = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  if (!isStaff(req.user?.role)) {
    res.status(403).json({ error: 'Forbidden: Staff access required' });
    return;
  }
  next();
};
