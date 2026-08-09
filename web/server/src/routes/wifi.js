import { Router } from 'express';
import { z } from 'zod';

import { analyzeNetwork } from '../engines/wifiEngine.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { asyncRoute } from '../middleware/errors.js';
import { KnownNetwork, ScanResult } from '../models/history.js';
import { recordAlert, recordScan, updateScore } from '../services/historyService.js';

const router = Router();

const networkSchema = z.object({
  ssid: z.string().min(1, 'Enter the network name').max(64),
  bssid: z
    .string()
    .regex(/^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$/, 'Enter a valid MAC address')
    .optional()
    .or(z.literal('')),
  rssi: z.number().int().min(-100).max(0).default(-60),
  security: z.string().max(64).default(''),
  frequency: z.number().int().min(0).max(7200).default(2437),
  dnsResponseMs: z.number().int().min(0).max(10_000).optional(),
});

/**
 * Analyse a network the user describes.
 *
 * A browser cannot read the SSID, BSSID, signal or cipher of the Wi-Fi it is
 * on — no web API exposes any of it. So this takes the details from the user
 * (off the café's sign, or off their phone's network screen) and runs the same
 * rules and Isolation Forest the app runs on the values it measures directly.
 */
router.post(
  '/analyze',
  optionalAuth,
  asyncRoute(async (req, res) => {
    const network = networkSchema.parse(req.body);
    const bssid = (network.bssid ?? '').toLowerCase();

    // Evil Twin check: a rogue access point can copy a network's name but not
    // the real hardware's MAC. Only meaningful for a signed-in user, since it
    // needs a record of what this network looked like last time.
    let bssidChanged = false;
    if (req.user && bssid) {
      const known = await KnownNetwork.findOne({
        user: req.user._id,
        ssid: network.ssid,
      });
      if (known && known.bssid && known.bssid !== bssid) bssidChanged = true;
    }

    const result = analyzeNetwork({ ...network, bssid, bssidChanged });

    if (req.user && bssid) {
      // Recorded after the comparison, so the first sighting establishes the
      // baseline and a later change is what raises the flag.
      await KnownNetwork.findOneAndUpdate(
        { user: req.user._id, ssid: network.ssid },
        { $set: { bssid, lastSeenAt: new Date() } },
        { upsert: true },
      );
    }

    await recordScan(req.user, {
      type: 'wifi',
      input: network.ssid,
      verdict: result.riskLevel,
      confidence: result.trustScore,
      riskScore: 100 - result.trustScore,
      shapReasons: result.checks.filter((c) => !c.passed).map((c) => c.detail),
      details: result,
    });

    if (result.riskLevel === 'critical' || result.riskLevel === 'high') {
      await recordAlert(req.user, {
        type: result.riskLevel === 'critical' ? 'critical' : 'warning',
        title:
          result.riskLevel === 'critical'
            ? 'Dangerous Wi-Fi Network'
            : 'Unsafe Wi-Fi Network',
        description: `"${network.ssid}" — ${result.checks
          .filter((c) => !c.passed)
          .map((c) => c.name)
          .join(', ')} failed`,
        module: 'wifi',
      });
    }

    await updateScore(req.user, { wifiScore: result.trustScore });

    res.json({ result, signedIn: Boolean(req.user) });
  }),
);

router.get(
  '/history',
  requireAuth,
  asyncRoute(async (req, res) => {
    const scans = await ScanResult.find({ user: req.user._id, type: 'wifi' })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
    res.json({ scans });
  }),
);

router.get(
  '/known-networks',
  requireAuth,
  asyncRoute(async (req, res) => {
    const networks = await KnownNetwork.find({ user: req.user._id })
      .sort({ lastSeenAt: -1 })
      .lean();
    res.json({ networks });
  }),
);

router.delete(
  '/known-networks/:id',
  requireAuth,
  asyncRoute(async (req, res) => {
    const deleted = await KnownNetwork.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id,
    });
    if (!deleted) return res.status(404).json({ error: 'Network not found' });
    return res.json({ ok: true });
  }),
);

export default router;
