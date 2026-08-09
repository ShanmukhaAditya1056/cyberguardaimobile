import { Router } from 'express';
import { z } from 'zod';

import { label, labelVerbose, unifiedScore } from '../engines/scoreCalculator.js';
import { requireAuth } from '../middleware/auth.js';
import { asyncRoute } from '../middleware/errors.js';
import { Alert, ScanResult, ScoreEntry } from '../models/history.js';
import { scoreHistory } from '../services/historyService.js';

const router = Router();

router.get(
  '/',
  requireAuth,
  asyncRoute(async (req, res) => {
    const userId = req.user._id;

    // Five independent reads — issued together so the dashboard costs one
    // round trip's latency rather than five.
    const [latest, trend, recentScans, unreadAlerts, moduleCounts] =
      await Promise.all([
        ScoreEntry.findOne({ user: userId }).sort({ date: -1 }).lean(),
        scoreHistory(req.user, 7),
        ScanResult.find({ user: userId }).sort({ createdAt: -1 }).limit(10).lean(),
        Alert.countDocuments({ user: userId, isRead: false }),
        ScanResult.aggregate([
          { $match: { user: userId } },
          { $group: { _id: '$type', count: { $sum: 1 } } },
        ]),
      ]);

    const modules = latest ?? {
      phishingScore: 100,
      malwareScore: 100,
      breachScore: 100,
      wifiScore: 100,
    };

    const score =
      latest?.score ??
      unifiedScore({
        phishingScore: modules.phishingScore,
        malwareScore: modules.malwareScore,
        breachScore: modules.breachScore,
        wifiScore: modules.wifiScore,
        breachActive: false,
      });

    res.json({
      score,
      label: label(score),
      labelVerbose: labelVerbose(score),
      modules: {
        phishing: modules.phishingScore,
        malware: modules.malwareScore,
        breach: modules.breachScore,
        wifi: modules.wifiScore,
      },
      trend: trend.map((t) => ({ date: t.date, score: t.score })),
      recentScans,
      unreadAlerts,
      scanCounts: Object.fromEntries(moduleCounts.map((m) => [m._id, m.count])),
      lastScanAt: recentScans[0]?.createdAt ?? null,
    });
  }),
);

router.get(
  '/alerts',
  requireAuth,
  asyncRoute(async (req, res) => {
    const { module, unreadOnly } = z
      .object({
        module: z.enum(['phishing', 'malware', 'breach', 'wifi']).optional(),
        unreadOnly: z.enum(['true', 'false']).optional(),
      })
      .parse(req.query);

    const filter = { user: req.user._id };
    if (module) filter.module = module;
    if (unreadOnly === 'true') filter.isRead = false;

    const alerts = await Alert.find(filter)
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();
    res.json({ alerts });
  }),
);

router.patch(
  '/alerts/:id/read',
  requireAuth,
  asyncRoute(async (req, res) => {
    const alert = await Alert.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { $set: { isRead: true } },
      { new: true },
    );
    if (!alert) return res.status(404).json({ error: 'Alert not found' });
    return res.json({ alert });
  }),
);

router.post(
  '/alerts/read-all',
  requireAuth,
  asyncRoute(async (req, res) => {
    const result = await Alert.updateMany(
      { user: req.user._id, isRead: false },
      { $set: { isRead: true } },
    );
    res.json({ updated: result.modifiedCount });
  }),
);

router.delete(
  '/alerts/:id',
  requireAuth,
  asyncRoute(async (req, res) => {
    const deleted = await Alert.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id,
    });
    if (!deleted) return res.status(404).json({ error: 'Alert not found' });
    return res.json({ ok: true });
  }),
);

/**
 * Erase everything this account has recorded.
 *
 * A security tool that keeps a permanent record of every suspicious link its
 * user has ever received owes them a way to delete it, in one action, without
 * having to close the account.
 */
router.delete(
  '/history',
  requireAuth,
  asyncRoute(async (req, res) => {
    const userId = req.user._id;
    const [scans, alerts, scores] = await Promise.all([
      ScanResult.deleteMany({ user: userId }),
      Alert.deleteMany({ user: userId }),
      ScoreEntry.deleteMany({ user: userId }),
    ]);
    res.json({
      deleted: {
        scans: scans.deletedCount,
        alerts: alerts.deletedCount,
        scoreEntries: scores.deletedCount,
      },
    });
  }),
);

export default router;
