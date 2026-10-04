// Environment-derived settings that must be right before the server takes traffic.
// Loads .env first: route modules are imported before index.ts calls dotenv, so
// reading process.env here without this would miss values defined in .env.
import 'dotenv/config';

const DEV_SECRET = 'fallback_secret_for_dev_only';
const MIN_PRODUCTION_SECRET_LENGTH = 32;
const PLACEHOLDER_MARKERS = ['change_this', 'change_in_production', 'fallback_secret'];

/**
 * The secret used to sign and verify session tokens. Outside production a
 * built-in dev secret is allowed so a fresh checkout runs; in production a
 * missing or short secret is a startup error, never a silent fallback that
 * would let anyone forge an admin token.
 */
export function resolveJwtSecret(env: Record<string, string | undefined>): string {
  const secret = env.JWT_SECRET;
  const production = env.NODE_ENV === 'production';
  if (!secret) {
    if (production) throw new Error('JWT_SECRET is required in production');
    return DEV_SECRET;
  }
  if (production && secret.length < MIN_PRODUCTION_SECRET_LENGTH) {
    throw new Error(`JWT_SECRET must be at least ${MIN_PRODUCTION_SECRET_LENGTH} characters in production`);
  }
  // The example file and docker-compose ship placeholder secrets; they are public.
  if (production && PLACEHOLDER_MARKERS.some((m) => secret.toLowerCase().includes(m))) {
    throw new Error('JWT_SECRET is still a placeholder from the example config; generate a random one');
  }
  return secret;
}

export const JWT_SECRET = resolveJwtSecret(process.env);
