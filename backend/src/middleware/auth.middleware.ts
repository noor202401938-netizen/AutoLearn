import { Request, Response, NextFunction } from 'express';
import jwt from 'jwt-simple';

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_for_dev_only';

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    role: string;
  };
}

export const authenticateToken = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized: No token provided' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.decode(token, JWT_SECRET) as any;

    // Check token expiry
    if (decoded.exp && Date.now() / 1000 > decoded.exp) {
      res.status(401).json({ error: 'Unauthorized: Token has expired' });
      return;
    }

    req.user = { uid: decoded.uid, role: decoded.role };
    next();
  } catch (error) {
    res.status(403).json({ error: 'Forbidden: Invalid or malformed token' });
  }
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
