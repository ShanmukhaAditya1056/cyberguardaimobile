import { Router } from 'express';
import { z } from 'zod';

import { analyzeWithFusion } from '../engines/fusionEngine.js';
import { assessRisk } from '../engines/predictiveRisk.js';
import { classifyText } from '../engines/scamClassifier.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { asyncRoute } from '../middleware/errors.js';
import { Alert, ArbitrationEntry, ScanResult, ScoreEntry } from '../models/history.js';
import { recordAlert, recordScan } from '../services/historyService.js';

const router = Router();

// ── Threat Fusion ──────────────────────────────────────────────────────────

router.post(
  '/scan',
  optionalAuth,
  asyncRoute(async (req, res) => {
    const { url, cloudIntel } = z
      .object({
        url: z.string().min(4, 'Enter a URL').max(2048),
        // External feeds are off unless explicitly asked for, matching the
        // app's cloud-intel opt-in. Nothing here performs real network egress
        // yet, but the flag is the switch a real client would hang off.
        cloudIntel: z.boolean().default(false),
      })
      .parse(req.body);

    const result = analyzeWithFusion(url, { cloudIntel });

    await recordScan(req.user, {
      type: 'phishing',
      input: result.url.slice(0, 2048),
      verdict: result.level,
      confidence: Math.round(result.confidence * 100),
      riskScore: result.unifiedScore,
      shapReasons: result.explanation,
      details: { kind: 'fusion', action: result.action },
    });

    // Only disputed runs are logged. Recording every unanimous "safe" would
    // bury the handful of cases where the detectors actually disagreed, which
    // is the only thing this log is for.
    if (req.user && (result.hasConflict || result.overrideApplied)) {
      await ArbitrationEntry.create({
        user: req.user._id,
        url: result.url.slice(0, 2048),
        domain: result.domain ?? '',
        unifiedScore: result.unifiedScore,
        level: result.level,
        action: result.action,
        confidence: result.confidence,
        overrideApplied: result.overrideApplied,
        overrideReason: result.overrideReason ?? '',
        hasConflict: result.hasConflict,
        verdicts: result.verdicts,
        explanation: result.explanation,
      });
    }

    if (result.action === 'block') {
      await recordAlert(req.user, {
        type: 'critical',
        title: 'Link blocked by threat fusion',
        description: result.overrideReason ?? result.explanation[0] ?? result.url,
        module: 'phishing',
        actionData: result.url,
      });
    }

    res.json({ result, signedIn: Boolean(req.user) });
  }),
);

// ── Arbitration log ────────────────────────────────────────────────────────

router.get(
  '/arbitration',
  requireAuth,
  asyncRoute(async (req, res) => {
    const { conflictsOnly } = z
      .object({ conflictsOnly: z.enum(['true', 'false']).optional() })
      .parse(req.query);

    const filter = { user: req.user._id };
    if (conflictsOnly === 'true') filter.hasConflict = true;

    const entries = await ArbitrationEntry.find(filter)
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();

    res.json({
      entries,
      summary: {
        total: entries.length,
        conflicts: entries.filter((e) => e.hasConflict).length,
        overrides: entries.filter((e) => e.overrideApplied).length,
      },
    });
  }),
);

router.delete(
  '/arbitration/:id',
  requireAuth,
  asyncRoute(async (req, res) => {
    const deleted = await ArbitrationEntry.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id,
    });
    if (!deleted) return res.status(404).json({ error: 'Entry not found' });
    return res.json({ ok: true });
  }),
);

// ── Predictive risk ────────────────────────────────────────────────────────

/**
 * Personal risk, derived from the account's own recent history.
 *
 * The mobile app reads these signals from its local Hive boxes; here they come
 * from the same collections the scanners write to, over a 7-day window.
 */
router.get(
  '/risk',
  requireAuth,
  asyncRoute(async (req, res) => {
    const userId = req.user._id;
    const since = new Date();
    since.setDate(since.getDate() - 7);

    const [phishingHits, malwareDetections, unknownWifi, breachHits, blocks, scores] =
      await Promise.all([
        ScanResult.countDocuments({
          user: userId,
          type: 'phishing',
          verdict: { $in: ['phishing', 'dangerous', 'critical'] },
          createdAt: { $gte: since },
        }),
        ScanResult.countDocuments({
          user: userId,
          type: 'malware',
          verdict: { $in: ['threat', 'threats_found'] },
          createdAt: { $gte: since },
        }),
        ScanResult.countDocuments({
          user: userId,
          type: 'wifi',
          verdict: { $in: ['high', 'critical'] },
          createdAt: { $gte: since },
        }),
        ScanResult.countDocuments({
          user: userId,
          type: 'breach',
          verdict: 'breached',
          createdAt: { $gte: since },
        }),
        ArbitrationEntry.countDocuments({
          user: userId,
          action: 'block',
          createdAt: { $gte: since },
        }),
        ScoreEntry.find({ user: userId, date: { $gte: since } })
          .sort({ date: 1 })
          .lean(),
      ]);

    // Negative delta means the security score is worsening, which is itself a
    // risk signal — a declining posture predicts trouble better than a low but
    // stable one.
    const securityScoreDelta =
      scores.length >= 2 ? scores[scores.length - 1].score - scores[0].score : 0;

    const assessment = assessRisk({
      phishingHits,
      // The web build has no SMS inbox, so this signal is structurally always
      // zero here rather than merely absent. Left explicit so the shape of the
      // assessment matches the app's.
      suspiciousSms: 0,
      unknownWifi,
      malwareDetections,
      interceptorBlocks: blocks,
      breachActive: breachHits > 0,
      securityScoreDelta,
    });

    res.json({
      assessment,
      window: { days: 7, since: since.toISOString() },
      signals: {
        phishingHits,
        suspiciousSms: 0,
        unknownWifi,
        malwareDetections,
        interceptorBlocks: blocks,
        breachActive: breachHits > 0,
        securityScoreDelta,
      },
    });
  }),
);

// ── Screenshot / message text classifier ───────────────────────────────────

/**
 * The browser half of the Screenshot Scanner.
 *
 * ML Kit is mobile-only and uploading a screenshot — the input most likely to
 * contain a bank balance or an OTP — to a cloud OCR service would contradict
 * the whole module. So the user pastes the text and the identical classifier
 * scores it.
 */
router.post(
  '/screenshot',
  optionalAuth,
  asyncRoute(async (req, res) => {
    const { text } = z
      .object({ text: z.string().min(1, 'Paste the text').max(20_000) })
      .parse(req.body);

    const result = classifyText(text);

    if (result.isScam) {
      await recordAlert(req.user, {
        type: 'warning',
        title: 'Scam message detected',
        description: `${result.scamProbability}% scam probability (${result.category})`,
        module: 'phishing',
      });
    }

    res.json({ result, signedIn: Boolean(req.user) });
  }),
);

export default router;
