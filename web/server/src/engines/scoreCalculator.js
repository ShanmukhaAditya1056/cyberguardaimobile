/** Port of `lib/core/utils/score_calculator.dart`. */

const clamp = (v, min, max) => Math.min(max, Math.max(min, v));

/**
 * The unified security score.
 *
 * Malware carries the most weight because a malicious app on the device
 * compromises every other module's guarantees. The `breachActive` cap is not a
 * weighting but a hard ceiling: while credentials are known to be exposed, no
 * combination of clean scans should let the overall score read as "protected".
 */
export function unifiedScore({
  phishingScore,
  malwareScore,
  breachScore,
  wifiScore,
  breachActive,
}) {
  const weighted =
    phishingScore * 0.3 +
    malwareScore * 0.35 +
    breachScore * 0.25 +
    wifiScore * 0.1;

  const score = clamp(Math.round(weighted), 0, 100);
  return breachActive ? clamp(score, 0, 45) : score;
}

export function label(score) {
  if (score >= 70) return 'PROTECTED';
  if (score >= 40) return 'AT RISK';
  return 'CRITICAL';
}

export function labelVerbose(score) {
  if (score >= 90) return 'Excellent Protection';
  if (score >= 70) return 'Well Protected';
  if (score >= 50) return 'Some Issues Found';
  if (score >= 40) return 'At Risk';
  if (score >= 20) return 'Serious Threats';
  return 'Critical Danger';
}

export function fromThreatCount({ totalApps, threatCount }) {
  if (totalApps === 0) return 85;
  const ratio = threatCount / totalApps;
  if (ratio === 0) return 100;
  if (ratio < 0.01) return 90;
  if (ratio < 0.05) return 75;
  if (ratio < 0.1) return 55;
  if (ratio < 0.2) return 35;
  return 15;
}
