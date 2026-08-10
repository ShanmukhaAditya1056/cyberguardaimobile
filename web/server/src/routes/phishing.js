import { Router } from 'express';
import { z } from 'zod';

import { analyzeText, analyzeUrl } from '../engines/phishingEngine.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { asyncRoute } from '../middleware/errors.js';
import { ScanResult } from '../models/history.js';
import { recordAlert, recordScan, updateScore } from '../services/historyService.js';

const router = Router();

const scanBody = z.object({
  url: z.string().min(4, 'Enter a URL').max(2048, 'That URL is too long'),
});

const textBody = z.object({
  text: z.string().min(1, 'Paste some text').max(20_000),
});

/**
 * Score the phishing module from the verdict.
 *
 * A single bad link does not mean the user is compromised, but it does mean
 * they are being targeted, so the module score tracks the worst recent result
 * rather than an average — an average lets one clean scan wash out a
 * confirmed phishing hit.
 */
const moduleScoreFor = (result) =>
  result.isPhishing ? Math.max(0, 100 - result.confidence) : 100;

router.post(
  '/scan',
  optionalAuth,
  asyncRoute(async (req, res) => {
    const { url } = scanBody.parse(req.body);
    const result = analyzeUrl(url);

    await recordScan(req.user, {
      type: 'phishing',
      input: result.url.slice(0, 2048),
      verdict: result.isPhishing ? 'phishing' : 'safe',
      confidence: result.confidence,
      shapReasons: result.shapReasons.map((s) => s.feature),
      details: result,
    });

    if (result.isPhishing) {
      await recordAlert(req.user, {
        type: 'critical',
        title: 'Phishing URL Detected',
        description: `Dangerous link: ${truncate(result.url, 60)}`,
        module: 'phishing',
        actionData: result.url,
      });
    }

    await updateScore(req.user, { phishingScore: moduleScoreFor(result) });

    res.json({ result, signedIn: Boolean(req.user) });
  }),
);

/**
 * Scan every link inside a block of text.
 *
 * This is the browser's stand-in for the app's live SMS guard: a web page can
 * never be handed incoming messages, but a user can paste one in, and the URL
 * extraction and scoring that follow are the same code the guard runs.
 */
router.post(
  '/scan-text',
  optionalAuth,
  asyncRoute(async (req, res) => {
    const { text } = textBody.parse(req.body);
    const analysis = analyzeText(text);

    if (analysis.worst) {
      await recordScan(req.user, {
        type: 'phishing',
        input: analysis.worst.url.slice(0, 2048),
        verdict: 'phishing',
        confidence: analysis.worst.confidence,
        shapReasons: analysis.worst.shapReasons.map((s) => s.feature),
        details: analysis.worst,
      });
      await recordAlert(req.user, {
        type: 'critical',
        title: 'Phishing link found in pasted message',
        description: `${analysis.urlsFound} link(s) checked. Worst: ${truncate(
          analysis.worst.url,
          60,
        )}`,
        module: 'phishing',
        actionData: analysis.worst.url,
      });
      await updateScore(req.user, {
        phishingScore: moduleScoreFor(analysis.worst),
      });
    }

    res.json({ ...analysis, signedIn: Boolean(req.user) });
  }),
);

router.get(
  '/history',
  requireAuth,
  asyncRoute(async (req, res) => {
    const scans = await ScanResult.find({ user: req.user._id, type: 'phishing' })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
    res.json({ scans });
  }),
);

router.delete(
  '/history/:id',
  requireAuth,
  asyncRoute(async (req, res) => {
    // Scoped to the caller: without the `user` filter any signed-in account
    // could delete another's history by guessing an id.
    const deleted = await ScanResult.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id,
      type: 'phishing',
    });
    if (!deleted) return res.status(404).json({ error: 'Scan not found' });
    return res.json({ ok: true });
  }),
);

function truncate(text, max) {
  return text.length <= max ? text : `${text.slice(0, max)}...`;
}

export default router;
