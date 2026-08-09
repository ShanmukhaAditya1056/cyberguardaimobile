import { fileURLToPath } from 'node:url';
import path from 'node:path';
import dotenv from 'dotenv';

const here = path.dirname(fileURLToPath(import.meta.url));

/** `web/server` */
export const SERVER_ROOT = path.resolve(here, '..', '..');

/** Repository root — the Flutter project, four levels up from `src/config`. */
export const REPO_ROOT = path.resolve(SERVER_ROOT, '..', '..');

/**
 * The JSON model exports the Flutter app bundles as assets. The web build
 * reads the very same files rather than keeping a copy: a second copy would
 * drift the first time someone retrains a model and only updates one of them,
 * and then the phone and the browser would disagree about whether a URL is
 * phishing.
 */
export const MODELS_DIR = path.join(REPO_ROOT, 'assets', 'models');

dotenv.config({ path: path.join(SERVER_ROOT, '.env') });

const isProduction = process.env.NODE_ENV === 'production';

/**
 * Reads a required secret.
 *
 * In production a missing value is fatal: falling back to a built-in default
 * would mean every deployment that forgot to set JWT_SECRET signs tokens with
 * a value published in this repository, and anyone could mint a session for
 * any account. In development the fallback keeps `npm run dev` working with no
 * setup, and says loudly that it is not for real use.
 */
function requiredSecret(name, devFallback) {
  const value = process.env[name];
  if (value && value.length > 0) return value;
  if (isProduction) {
    throw new Error(
      `${name} must be set in production. Refusing to start with a default.`,
    );
  }
  console.warn(
    `[config] ${name} is unset — using an insecure development default. ` +
      'Set it in web/server/.env before deploying.',
  );
  return devFallback;
}

export const config = {
  isProduction,
  port: Number(process.env.PORT ?? 4000),
  mongoUri: process.env.MONGO_URI ?? 'mongodb://127.0.0.1:27017/cyberguard',
  jwtSecret: requiredSecret('JWT_SECRET', 'dev-only-insecure-secret'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',

  /**
   * Browsers send cookies cross-origin only with an explicit allow-list, so the
   * dev client origin is included by default. `credentials: true` on the CORS
   * middleware makes a wildcard illegal anyway.
   */
  corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:5173')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean),

  /**
   * Optional. Without it the Breach Monitor still works: the password check
   * uses the free k-anonymity range API, and the account check falls back to
   * the offline dataset — exactly as the mobile app does.
   */
  hibpApiKey: process.env.HIBP_API_KEY ?? '',
  hibpUserAgent: process.env.HIBP_USER_AGENT ?? 'CyberGuard-AI-Web',
};
