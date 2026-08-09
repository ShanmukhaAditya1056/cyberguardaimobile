/**
 * Port of `lib/data/services/predictive_risk_service.dart` — Feature 5.
 *
 * Note the inversion: the *security score* elsewhere in this app runs
 * higher = safer, but the **personal risk score** here runs higher = more
 * likely to be attacked. They answer different questions — "how well defended
 * are you" versus "how much is aimed at you".
 *
 * Pure and dependency-free. The route gathers signals from the account's own
 * history and feeds them in.
 */

const clamp = (v, min, max) => Math.min(max, Math.max(min, v));

/**
 * Per-signal caps.
 *
 * Each is capped so no single behaviour can saturate the score on its own —
 * ten phishing links in a week is worse than one, but it is not the whole
 * picture, and letting it reach 100 would hide every other factor.
 */
const CAPS = {
  phishing: 22,
  sms: 14,
  wifi: 14,
  malware: 24,
  interceptor: 10,
  breach: 20,
  trend: 10,
};

export const RiskBand = { low: 'low', medium: 'medium', high: 'high' };

export function bandFromScore(score) {
  if (score >= 67) return RiskBand.high;
  if (score >= 34) return RiskBand.medium;
  return RiskBand.low;
}

/**
 * Assess personal risk from recent behavioural signals.
 *
 * Factor `type` and forecast `category` are returned as stable identifiers
 * rather than prose, matching the Dart service — the app localises them into
 * four languages, and baking English in here would make that impossible.
 */
export function assessRisk({
  phishingHits = 0,
  suspiciousSms = 0,
  unknownWifi = 0,
  malwareDetections = 0,
  interceptorBlocks = 0,
  breachActive = false,
  securityScoreDelta = 0,
} = {}) {
  const factors = [];
  let score = 0;

  const add = (points, type, value) => {
    if (points <= 0) return;
    score += points;
    factors.push({ type, value, contribution: points });
  };

  add(clamp(phishingHits * 8, 0, CAPS.phishing), 'phishing', phishingHits);
  add(clamp(suspiciousSms * 5, 0, CAPS.sms), 'sms', suspiciousSms);
  add(clamp(unknownWifi * 5, 0, CAPS.wifi), 'wifi', unknownWifi);
  add(clamp(malwareDetections * 12, 0, CAPS.malware), 'malware', malwareDetections);
  add(clamp(interceptorBlocks * 5, 0, CAPS.interceptor), 'interceptor', interceptorBlocks);
  if (breachActive) add(CAPS.breach, 'breach', 0);
  if (securityScoreDelta < 0) {
    add(clamp(-securityScoreDelta, 0, CAPS.trend), 'trend', -securityScoreDelta);
  }

  score = clamp(score, 0, 100);
  factors.sort((a, b) => b.contribution - a.contribution);

  return {
    riskScore: score,
    band: bandFromScore(score),
    factors,
    forecast: forecast({
      phishingHits,
      suspiciousSms,
      unknownWifi,
      malwareDetections,
      interceptorBlocks,
      breachActive,
    }),
    recommendations: recommendations({
      phishingHits,
      suspiciousSms,
      unknownWifi,
      malwareDetections,
      interceptorBlocks,
      breachActive,
    }),
    generatedAt: new Date().toISOString(),
  };
}

/**
 * Forward-looking likelihood per attack category.
 *
 * Weighted differently from the risk score itself: a breach dominates the
 * credential-theft forecast (45 points on its own) because exposed credentials
 * are the precondition for that whole attack class, while contributing a
 * capped 20 to overall risk.
 */
function forecast(s) {
  const band = (weight) => bandFromScore(clamp(weight, 0, 100));
  return [
    {
      category: 'phishing',
      likelihood: band(s.phishingHits * 22 + s.suspiciousSms * 14 + s.interceptorBlocks * 12),
    },
    {
      category: 'credentialTheft',
      likelihood: band((s.breachActive ? 45 : 0) + s.phishingHits * 12 + s.unknownWifi * 10),
    },
    {
      category: 'malware',
      likelihood: band(s.malwareDetections * 30 + (s.unknownWifi > 0 ? 10 : 0)),
    },
  ];
}

function recommendations(s) {
  const recs = [];
  if (s.breachActive) recs.push('breach');
  if (s.phishingHits > 0 || s.suspiciousSms > 0) recs.push('phishing');
  if (s.unknownWifi > 0) recs.push('wifi');
  if (s.malwareDetections > 0) recs.push('malware');
  if (s.interceptorBlocks > 0) recs.push('interceptor');
  if (recs.length === 0) recs.push('healthy');
  return recs;
}
