import jwt from 'jsonwebtoken';

import { config } from '../config/env.js';
import { User } from '../models/User.js';

/**
 * Session handling.
 *
 * The token lives in an httpOnly cookie rather than in localStorage. A scanner
 * whose whole job is judging hostile input is exactly the app that must assume
 * an XSS will eventually land somewhere in its UI, and a token in localStorage
 * is readable by any script that runs on the page. httpOnly takes that off the
 * table; SameSite=Lax closes the CSRF path for the state-changing routes.
 */

const COOKIE_NAME = 'cg_session';

export function issueSession(res, user) {
  const token = jwt.sign({ sub: user._id.toString() }, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn,
  });

  res.cookie(COOKIE_NAME, token, {
    httpOnly: true,
    sameSite: 'lax',
    // Set only over HTTPS in production; a Secure cookie is never sent over
    // the plain-HTTP dev server, which would make local login silently fail.
    secure: config.isProduction,
    maxAge: 7 * 24 * 60 * 60 * 1000,
    path: '/',
  });

  return token;
}

export function clearSession(res) {
  res.clearCookie(COOKIE_NAME, { path: '/' });
}

/** Rejects the request unless it carries a valid session. */
export async function requireAuth(req, res, next) {
  const token = req.cookies?.[COOKIE_NAME];
  if (!token) {
    return res.status(401).json({ error: 'Sign in to continue' });
  }

  try {
    const payload = jwt.verify(token, config.jwtSecret);
    const user = await User.findById(payload.sub);
    if (!user) {
      // The token verified but the account is gone. Clearing the cookie stops
      // the client retrying with a credential that can never work again.
      clearSession(res);
      return res.status(401).json({ error: 'Session no longer valid' });
    }
    req.user = user;
    return next();
  } catch {
    clearSession(res);
    return res.status(401).json({ error: 'Session expired — sign in again' });
  }
}

/**
 * Attaches `req.user` when a session is present but never rejects.
 *
 * Used by the scanning routes: every engine in this app runs on the input
 * alone, so a signed-out visitor can still scan a URL and get the same verdict
 * — they just get no history, because there is no account to attach it to.
 */
export async function optionalAuth(req, _res, next) {
  const token = req.cookies?.[COOKIE_NAME];
  if (!token) return next();
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    req.user = await User.findById(payload.sub);
  } catch {
    req.user = undefined;
  }
  return next();
}
