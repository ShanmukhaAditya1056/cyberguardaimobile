import { Alert, ScanResult, ScoreEntry } from '../models/history.js';
import { unifiedScore } from '../engines/scoreCalculator.js';

/**
 * Writing a scan to history, and everything that follows from it.
 *
 * Two rules hold everywhere this is used:
 *
 *  * A signed-out visitor still gets a full verdict — every engine works on
 *    the input alone. There is simply nowhere to file the result, so these
 *    helpers no-op rather than the route refusing to answer.
 *  * A user who has turned off `saveScanHistory` gets the same treatment.
 *    Honouring that setting has to happen here, at the one place that writes,
 *    rather than being remembered at six call sites.
 */

function canRecord(user) {
  return Boolean(user) && user.settings.saveScanHistory !== false;
}

export async function recordScan(user, scan) {
  if (!canRecord(user)) return null;
  return ScanResult.create({ user: user._id, ...scan });
}

export async function recordAlert(user, alert) {
  if (!canRecord(user)) return null;
  // Alerts respect `realTimeAlerts` the way the app does: the toggle silences
  // notifications, it does not hide findings. There are no push notifications
  // here, so an alert is only ever a row the user can look at — and hiding a
  // security finding from the person it concerns is not a setting worth
  // honouring.
  return Alert.create({ user: user._id, ...alert });
}

/**
 * Rolls today's module scores into the unified score and stores one entry per
 * day, replacing the day's existing entry rather than appending.
 *
 * `moduleScores` may be partial — a phishing scan updates only the phishing
 * leg — so the day's stored values are the baseline and anything absent keeps
 * its previous number.
 */
export async function updateScore(user, moduleScores) {
  if (!user) return null;

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const existing = await ScoreEntry.findOne({ user: user._id, date: startOfDay });
  const previous = await ScoreEntry.findOne({ user: user._id })
    .sort({ date: -1 })
    .lean();

  const base = existing ?? previous ?? {
    phishingScore: 100,
    malwareScore: 100,
    breachScore: 100,
    wifiScore: 100,
  };

  const merged = {
    phishingScore: moduleScores.phishingScore ?? base.phishingScore,
    malwareScore: moduleScores.malwareScore ?? base.malwareScore,
    breachScore: moduleScores.breachScore ?? base.breachScore,
    wifiScore: moduleScores.wifiScore ?? base.wifiScore,
  };

  const score = unifiedScore({
    ...merged,
    breachActive: merged.breachScore < 50,
  });

  return ScoreEntry.findOneAndUpdate(
    { user: user._id, date: startOfDay },
    { $set: { ...merged, score } },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
}

/** The last `days` score entries, oldest first — the dashboard trend chart. */
export async function scoreHistory(user, days = 7) {
  if (!user) return [];
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days);
  cutoff.setHours(0, 0, 0, 0);

  return ScoreEntry.find({ user: user._id, date: { $gte: cutoff } })
    .sort({ date: 1 })
    .lean();
}
