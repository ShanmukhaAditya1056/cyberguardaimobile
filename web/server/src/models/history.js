import mongoose from 'mongoose';

/**
 * Scan history, alerts and the score trend.
 *
 * These mirror the Hive boxes in `lib/data/models/`, with two changes the
 * server context forces:
 *
 *  * every document is scoped by `user`, and
 *  * retention is enforced by a TTL index rather than the app's once-per-launch
 *    sweep. `AppConstants.retentionDays` is 90 on the phone and the same 90
 *    here, so a user who scans on both sees the same window.
 */

const RETENTION_SECONDS = 90 * 24 * 60 * 60;

/**
 * Verdicts that count as a threat, mirroring `ScanResultModel._threatVerdicts`
 * in `lib/data/models/scan_result_model.dart` exactly.
 *
 * 'suspicious' is deliberately absent on both sides — `ThreatLevel.isMalicious`
 * treats only dangerous/critical as malicious, and the dashboard's "Threats"
 * tile must count the same scans on the phone and in the browser or the two
 * report different numbers for the same account.
 */
export const THREAT_VERDICTS = [
  'phishing',
  'threats_found',
  'breached',
  'dangerous',
  'critical',
  'malicious',
  'unsafe',
];

const userRef = {
  type: mongoose.Schema.Types.ObjectId,
  ref: 'User',
  required: true,
  index: true,
};

/** One scan of any kind — the web equivalent of `ScanResultModel`. */
const scanResultSchema = new mongoose.Schema(
  {
    user: userRef,
    type: {
      type: String,
      required: true,
      enum: ['phishing', 'malware', 'breach', 'wifi'],
    },
    /**
     * What was scanned. For breach checks this is the 5-character SHA-1
     * prefix, never the address — the same substitution the mobile app makes
     * before writing to Hive, and the reason a database dump cannot be turned
     * into a list of which accounts a user was worried about.
     */
    input: { type: String, required: true, maxlength: 2048 },
    verdict: { type: String, required: true },
    confidence: { type: Number, min: 0, max: 100, default: 0 },
    riskScore: { type: Number, min: 0, max: 100 },
    shapReasons: { type: [String], default: [] },
    // Engine output kept whole so the detail view can re-render a past scan
    // without re-running it.
    details: { type: mongoose.Schema.Types.Mixed },
    createdAt: { type: Date, default: Date.now, expires: RETENTION_SECONDS },
  },
  { timestamps: { createdAt: false, updatedAt: true } },
);

// The history list is always "this user, this module, newest first".
scanResultSchema.index({ user: 1, type: 1, createdAt: -1 });

const alertSchema = new mongoose.Schema(
  {
    user: userRef,
    type: { type: String, required: true, enum: ['critical', 'warning', 'info'] },
    title: { type: String, required: true, maxlength: 200 },
    description: { type: String, default: '', maxlength: 1000 },
    module: {
      type: String,
      required: true,
      enum: ['phishing', 'malware', 'breach', 'wifi'],
    },
    isRead: { type: Boolean, default: false },
    actionData: { type: String, default: '' },
    createdAt: { type: Date, default: Date.now, expires: RETENTION_SECONDS },
  },
  { timestamps: { createdAt: false, updatedAt: true } },
);

alertSchema.index({ user: 1, createdAt: -1 });
// Backs the unread badge without scanning the whole collection.
alertSchema.index({ user: 1, isRead: 1 });

/** One day's unified score — drives the 7-day trend chart. */
const scoreEntrySchema = new mongoose.Schema(
  {
    user: userRef,
    date: { type: Date, required: true },
    score: { type: Number, required: true, min: 0, max: 100 },
    phishingScore: { type: Number, default: 100 },
    malwareScore: { type: Number, default: 100 },
    breachScore: { type: Number, default: 100 },
    wifiScore: { type: Number, default: 100 },
  },
  { timestamps: true },
);

// One entry per user per day: a re-scan updates the day rather than appending,
// which is what keeps the trend chart one point per day.
scoreEntrySchema.index({ user: 1, date: 1 }, { unique: true });

/**
 * BSSIDs previously seen for a given SSID.
 *
 * This is the Evil Twin check: an attacker standing up a rogue access point
 * with a familiar network name cannot also reproduce the real hardware's MAC.
 * The app compares against its local Hive record; the web version compares
 * against this.
 */
const knownNetworkSchema = new mongoose.Schema(
  {
    user: userRef,
    ssid: { type: String, required: true, maxlength: 64 },
    bssid: { type: String, required: true, lowercase: true, maxlength: 32 },
    lastSeenAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

knownNetworkSchema.index({ user: 1, ssid: 1 }, { unique: true });

/**
 * A fusion run where the sources materially disagreed, or where a trusted feed
 * overruled the local model.
 *
 * Kept separately from `ScanResult` because it answers a different question:
 * not "was this URL dangerous" but "did our detectors contradict each other,
 * and who won". That record is what makes an automated override auditable
 * after the fact instead of something the user has to take on faith.
 */
const arbitrationSchema = new mongoose.Schema(
  {
    user: userRef,
    url: { type: String, required: true, maxlength: 2048 },
    domain: { type: String, default: '', maxlength: 255 },
    unifiedScore: { type: Number, min: 0, max: 100, required: true },
    level: {
      type: String,
      required: true,
      enum: ['safe', 'suspicious', 'dangerous', 'critical'],
    },
    action: { type: String, required: true, enum: ['allow', 'warn', 'block'] },
    confidence: { type: Number, min: 0, max: 1, required: true },
    overrideApplied: { type: Boolean, default: false },
    overrideReason: { type: String, default: '' },
    hasConflict: { type: Boolean, default: false },
    verdicts: { type: mongoose.Schema.Types.Mixed, default: [] },
    explanation: { type: [String], default: [] },
    createdAt: { type: Date, default: Date.now, expires: RETENTION_SECONDS },
  },
  { timestamps: { createdAt: false, updatedAt: true } },
);

arbitrationSchema.index({ user: 1, createdAt: -1 });
// The log screen defaults to "show me only the disputed ones".
arbitrationSchema.index({ user: 1, hasConflict: 1, overrideApplied: 1 });

export const ScanResult = mongoose.model('ScanResult', scanResultSchema);
export const ArbitrationEntry = mongoose.model('ArbitrationEntry', arbitrationSchema);
export const Alert = mongoose.model('Alert', alertSchema);
export const ScoreEntry = mongoose.model('ScoreEntry', scoreEntrySchema);
export const KnownNetwork = mongoose.model('KnownNetwork', knownNetworkSchema);
