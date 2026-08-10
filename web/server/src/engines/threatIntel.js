/**
 * Port of `lib/data/services/threat_intel/threat_intel_source.dart`.
 *
 * The shared vocabulary of the fusion engine: a four-level threat taxonomy, a
 * per-source verdict, and the arbitration trust weights that decide whose
 * opinion can overrule whose.
 */

/** Canonical threat bands, mapped onto the unified 0-100 score. */
export const ThreatLevel = {
  safe: 'safe', // 0-30
  suspicious: 'suspicious', // 31-60
  dangerous: 'dangerous', // 61-80
  critical: 'critical', // 81-100
};

export function levelFromScore(score) {
  if (score >= 81) return ThreatLevel.critical;
  if (score >= 61) return ThreatLevel.dangerous;
  if (score >= 31) return ThreatLevel.suspicious;
  return ThreatLevel.safe;
}

/** Inclusive lower bound of a band — what an override floors the score to. */
export function floorScore(level) {
  switch (level) {
    case ThreatLevel.critical:
      return 81;
    case ThreatLevel.dangerous:
      return 61;
    case ThreatLevel.suspicious:
      return 31;
    default:
      return 0;
  }
}

export function levelLabel(level) {
  return { safe: 'Safe', suspicious: 'Suspicious', dangerous: 'Dangerous', critical: 'Critical' }[
    level
  ];
}

export const isMalicious = (level) =>
  level === ThreatLevel.dangerous || level === ThreatLevel.critical;

/**
 * Arbitration trust weights. Higher is more authoritative.
 *
 * A source at or above [trustedOverrideThreshold] can floor a "safe" local
 * verdict into the dangerous band — the rule that stops an on-device model's
 * false negative from silently allowing a URL a major feed already knows is
 * malicious.
 */
export const TrustWeights = {
  googleSafeBrowsing: 10,
  virusTotal: 9,
  openPhish: 8,
  phishTank: 8,
  cyberGuardAi: 7,
  domainReputation: 6,
  sslAnalyzer: 5,
  screenshotAnalyzer: 5,
  trustedOverrideThreshold: 8,
};

/**
 * One source's opinion about a URL.
 *
 * `available: false` is not the same as "safe". A source that is disabled,
 * offline or errored is *excluded* from fusion rather than counted as a clean
 * verdict — otherwise every outage would quietly improve the score.
 */
export function sourceVerdict({
  sourceName,
  trustWeight,
  maliciousScore,
  confidence,
  reasons = [],
  available = true,
  fromCache = false,
}) {
  const score = Math.min(100, Math.max(0, Math.round(maliciousScore)));
  return {
    sourceName,
    trustWeight,
    maliciousScore: score,
    confidence: Math.min(1, Math.max(0, confidence)),
    level: levelFromScore(score),
    reasons,
    available,
    fromCache,
  };
}

export function unavailableVerdict(sourceName, trustWeight, reason = 'Source unavailable') {
  return sourceVerdict({
    sourceName,
    trustWeight,
    maliciousScore: 0,
    confidence: 0,
    reasons: [reason],
    available: false,
  });
}
