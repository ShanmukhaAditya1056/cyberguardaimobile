import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';

import { asyncRoute } from '../middleware/errors.js';
import { clearSession, issueSession, requireAuth } from '../middleware/auth.js';
import { User } from '../models/User.js';
import { verifyIdToken } from '../services/firebaseAdmin.js';

const router = Router();

/**
 * Sign-in attempts are throttled per IP. Without this, bcrypt's deliberate
 * slowness works against the server rather than the attacker: a few hundred
 * concurrent guesses saturate the event loop and take the API down while the
 * guessing continues anyway.
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Too many attempts. Try again in a few minutes.' },
});

const credentials = z.object({
  email: z.string().email('Enter a valid email address'),
  password: z
    .string()
    .min(10, 'Use at least 10 characters')
    .max(200, 'Password is too long'),
  displayName: z.string().max(80).optional(),
});

router.post(
  '/register',
  authLimiter,
  asyncRoute(async (req, res) => {
    const { email, password, displayName } = credentials.parse(req.body);

    const user = new User({ email, displayName: displayName ?? '' });
    await user.setPassword(password);
    // A duplicate email surfaces as Mongo error 11000, which the error handler
    // turns into a 409. Checking first would leave a race between the check
    // and the insert; the unique index is what actually enforces it.
    await user.save();

    issueSession(res, user);
    res.status(201).json({ user: user.toPublic() });
  }),
);

router.post(
  '/login',
  authLimiter,
  asyncRoute(async (req, res) => {
    const { email, password } = credentials
      .pick({ email: true, password: true })
      .parse(req.body);

    const user = await User.findOne({ email }).select('+passwordHash');

    // One message for both "no such account" and "wrong password". Telling
    // them apart would let anyone enumerate which addresses are registered.
    const invalid = () =>
      res.status(401).json({ error: 'Email or password is incorrect' });

    if (!user) return invalid();
    if (!(await user.verifyPassword(password))) return invalid();

    user.lastLoginAt = new Date();
    await user.save();

    issueSession(res, user);
    return res.json({ user: user.toPublic() });
  }),
);

/**
 * Exchanges a Firebase ID token for this API's session cookie.
 *
 * This is the join between the two builds. The phone and the browser both
 * authenticate against the same Firebase project, so an account created in
 * either one signs in to the other with no migration and no second password.
 * The Mongo document exists only to own scan history; Firebase owns the
 * credential.
 *
 * The token is presented exactly once, here. Everything afterwards uses the
 * httpOnly cookie, so no credential is ever readable by a script on the page —
 * the property that made cookies the choice for local accounts too.
 */
router.post(
  '/session',
  authLimiter,
  asyncRoute(async (req, res) => {
    const { idToken } = z
      .object({ idToken: z.string().min(1, 'Missing idToken') })
      .parse(req.body);

    // Throws 501 when Firebase is unconfigured, 401 when the token is bad.
    const claims = await verifyIdToken(idToken);

    // Firebase allows an account with no email — phone and anonymous sign-in.
    // Neither is offered here, and history keyed by a blank address would
    // collide across users, so it is refused rather than half-supported.
    const email = claims.email?.toLowerCase().trim();
    if (!email) {
      return res.status(400).json({
        error: 'That sign-in method has no email address, which this app needs.',
      });
    }

    let user = await User.findOne({ firebaseUid: claims.uid });

    if (!user) {
      // Same person, previously registered locally with this address: adopt
      // the existing account rather than stranding its history behind a second
      // one. The address is proof enough only because Firebase verified it.
      user = await User.findOne({ email });
      if (user) {
        user.firebaseUid = claims.uid;
      } else {
        user = new User({ email, firebaseUid: claims.uid });
      }
    }

    // Keep the address in step: changing it in Firebase must not leave this
    // record pointing at the old one.
    user.email = email;
    if (!user.displayName && claims.name) {
      user.displayName = String(claims.name).slice(0, 80);
    }
    user.lastLoginAt = new Date();
    await user.save();

    issueSession(res, user);
    return res.json({ user: user.toPublic() });
  }),
);

router.post('/logout', (_req, res) => {
  clearSession(res);
  res.json({ ok: true });
});

/** Who am I — how the client rehydrates a session on page load. */
router.get(
  '/me',
  requireAuth,
  asyncRoute(async (req, res) => {
    res.json({ user: req.user.toPublic() });
  }),
);

router.patch(
  '/settings',
  requireAuth,
  asyncRoute(async (req, res) => {
    const settings = z
      .object({
        realTimeAlerts: z.boolean().optional(),
        saveScanHistory: z.boolean().optional(),
        locale: z.enum(['en', 'hi', 'ta', 'te']).optional(),
      })
      .parse(req.body);

    Object.assign(req.user.settings, settings);
    await req.user.save();
    res.json({ user: req.user.toPublic() });
  }),
);

export default router;
