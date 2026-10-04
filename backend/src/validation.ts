// Input checks shared by the controllers. Everything here is pure so it can be tested
// without a database, and none of it trusts the type of a value from the request body.
import { NextFunction, Request, Response } from 'express';

export const isObjectId = (s: unknown): s is string => typeof s === 'string' && /^[a-f0-9]{24}$/.test(s);

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_EMAIL_LENGTH = 254;

/** A trimmed, lower-cased email, or null if the value isn't a plausible address. */
export function cleanEmail(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const email = value.trim().toLowerCase();
  return email.length <= MAX_EMAIL_LENGTH && EMAIL_PATTERN.test(email) ? email : null;
}

export const MIN_PASSWORD_LENGTH = 8;
export const MAX_PASSWORD_LENGTH = 128; // bcrypt ignores anything past 72 bytes; this just bounds the work

/** Why a new password is unacceptable, or null if it is fine. Matches the rule the sign-up form shows. */
export function passwordProblem(value: unknown): string | null {
  if (typeof value !== 'string') return 'A password is required';
  if (value.length < MIN_PASSWORD_LENGTH || !/[A-Za-z]/.test(value) || !/\d/.test(value)) {
    return `Password must be at least ${MIN_PASSWORD_LENGTH} characters with letters and numbers`;
  }
  if (value.length > MAX_PASSWORD_LENGTH) return `Password must be at most ${MAX_PASSWORD_LENGTH} characters`;
  return null;
}

/**
 * Reads an optional text field. `undefined` means "not provided" (or not text, which is ignored);
 * a string is the trimmed value; `'too-long'` means it exceeded [max].
 */
export function optionalText(value: unknown, max: number): string | undefined | 'too-long' {
  if (typeof value !== 'string') return undefined;
  const text = value.trim();
  return text.length > max ? 'too-long' : text;
}

export const MAX_PAGE_SIZE = 100;

/** Pagination from query strings; anything that isn't a positive whole number is ignored. */
export function parsePaging(page: unknown, limit: unknown): { page?: number; limit?: number } {
  const toPositive = (v: unknown) => {
    const n = typeof v === 'string' && /^\d+$/.test(v) ? parseInt(v, 10) : NaN;
    return n >= 1 ? n : undefined;
  };
  const size = toPositive(limit);
  return { page: toPositive(page), limit: size === undefined ? undefined : Math.min(size, MAX_PAGE_SIZE) };
}

/** router.param handler: a malformed id is a plain "not found", not a server error. */
export function objectIdParam(notFoundMessage: string) {
  return (_req: Request, res: Response, next: NextFunction, value: string) => {
    if (!isObjectId(value)) {
      res.status(404).json({ error: notFoundMessage });
      return;
    }
    next();
  };
}

/** Number of lessons in a syllabus payload from the course editor. */
export function lessonCountOf(syllabus: unknown): number {
  if (!Array.isArray(syllabus)) return 0;
  return syllabus.reduce((n, m) => n + (Array.isArray(m?.lessons) ? m.lessons.length : 0), 0);
}
