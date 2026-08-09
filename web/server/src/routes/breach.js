import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';

import { checkAccount, checkPasswordByPrefix } from '../engines/breachEngine.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { asyncRoute } from '../middleware/errors.js';
import { ScanResult } from '../models/history.js';
import { recordAlert, recordScan, updateScore } from '../services/historyService.js';

const router = Router();

/**
 * Both endpoints reach out to haveibeenpwned.com. HIBP rate-limits by
 * originating IP, and every user of a deployment shares this server's — so
 * without a limit here one enthusiastic client gets the whole instance
 * throttled for everyone else.
 */
const breachLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Slow down — breach checks are limited to 10 a minute.' },
});

/**
 * k-anonymity password check.
 *
 * The body carries a hash prefix and suffix, never a password: the browser
 * computes SHA-1 with WebCrypto and splits it before the request is made (see
 * `client/src/lib/kAnonymity.js`). So the plaintext never reaches this
 * process, and cannot appear in a request log, an APM trace or a heap dump.
 *
 * The schema is what enforces that. `prefix` must be exactly 5 hex characters
 * and `suffix` exactly 35 — a client that tried to send a password instead
 * would be rejected rather than quietly relayed to a third party.
 */
router.post(
  '/password',
  breachLimiter,
  optionalAuth,
  asyncRoute(async (req, res) => {
    const { prefix, suffix } = z
      .object({
        prefix: z.string().regex(/^[0-9a-fA-F]{5}$/, 'prefix must be 5 hex chars'),
        suffix: z
          .string()
          .regex(/^[0-9a-fA-F]{35}$/, 'suffix must be 35 hex chars'),
      })
      .parse(req.body);

    const count = await checkPasswordByPrefix(prefix, suffix);

    await recordScan(req.user, {
      type: 'breach',
      // The prefix is all that is stored, matching what the mobile app writes
      // to Hive. It identifies 1-in-many hashes, not the credential.
      input: prefix.toUpperCase(),
      verdict: count > 0 ? 'breached' : 'safe',
      confidence: 99,
      shapReasons: [
        count > 0
          ? `Password found ${count} time${count > 1 ? 's' : ''} in data breaches`
          : 'Password not found in known breaches',
      ],
      details: { count, kind: 'password' },
    });

    res.json({
      isBreached: count > 0,
      count,
      checkedAt: new Date().toISOString(),
      signedIn: Boolean(req.user),
    });
  }),
);

/**
 * Account check.
 *
 * Unlike the password path this needs the address itself — HIBP's account
 * endpoint has no k-anonymity equivalent, and the offline fallback has to hash
 * the full address to pick its deterministic subset. The address is used for
 * the lookup and then dropped: only the masked form and the hash prefix are
 * returned, and only the prefix is written to history.
 */
router.post(
  '/account',
  breachLimiter,
  optionalAuth,
  asyncRoute(async (req, res) => {
    const { email } = z
      .object({ email: z.string().email('Enter a valid email address').max(320) })
      .parse(req.body);

    const result = await checkAccount(email);

    await recordScan(req.user, {
      type: 'breach',
      input: result.hashPrefix,
      verdict: result.isBreached ? 'breached' : 'safe',
      confidence: 99,
      shapReasons: [
        result.isBreached
          ? `Found in ${result.breachCount} data breach${result.breachCount > 1 ? 'es' : ''}`
          : 'No breaches found',
      ],
      details: {
        kind: 'account',
        source: result.source,
        maskedEmail: result.maskedEmail,
        breaches: result.breaches.map((b) => b.name),
      },
    });

    if (result.isBreached) {
      await recordAlert(req.user, {
        type: 'critical',
        title: 'Data Breach Found',
        description: `${result.maskedEmail} found in ${result.breachCount} breach${
          result.breachCount > 1 ? 'es' : ''
        }`,
        module: 'breach',
      });
    }

    // Exposed credentials cap the unified score at 45 — see
    // `unifiedScore`'s `breachActive` handling.
    await updateScore(req.user, {
      breachScore: result.isBreached ? Math.max(0, 100 - result.breachCount * 15) : 100,
    });

    res.json({ ...result, signedIn: Boolean(req.user) });
  }),
);

router.get(
  '/history',
  requireAuth,
  asyncRoute(async (req, res) => {
    const scans = await ScanResult.find({ user: req.user._id, type: 'breach' })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
    res.json({ scans });
  }),
);

export default router;
