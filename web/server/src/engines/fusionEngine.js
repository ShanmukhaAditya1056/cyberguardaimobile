import { analyzeUrl } from './phishingEngine.js';
import { getDomain, normalize } from './urlExtractor.js';
import {
  ThreatLevel,
  TrustWeights,
  floorScore,
  isMalicious,
  levelFromScore,
  levelLabel,
  sourceVerdict,
  unavailableVerdict,
} from './threatIntel.js';

/**
 * Port of `ThreatFusionService` and `RiskEngine`.
 *
 * Reconciles several detection sources into one explainable verdict:
 *
 *   1. trust × confidence weighted mean of each source's malicious score
 *   2. arbitration override — a sufficiently trusted source that flags the URL
 *      floors the score into the dangerous band even when the local model
 *      called it safe
 *   3. conflict detection, for the arbitration log
 *   4. agreement-weighted confidence, so the UI can hedge when sources differ
 *
 * `fuse` is pure, which is what makes the arbitration behaviour testable
 * without standing up any source at all.
 */

/** A trusted source must be at least this sure before it can override. */
export const OVERRIDE_MIN_CONFIDENCE = 0.6;

/** And report at least this malicious score. */
export const OVERRIDE_MIN_SCORE = 70;

const clamp = (v, min, max) => Math.min(max, Math.max(min, v));

export function fuse(all) {
  const verdicts = all.filter((v) => v.available);

  if (verdicts.length === 0) {
    return {
      unifiedScore: 0,
      level: ThreatLevel.safe,
      confidence: 0,
      verdicts: [],
      explanation: ['No detection source was available.'],
      overrideApplied: false,
      overrideReason: null,
      hasConflict: false,
    };
  }

  // ── 1. Trust × confidence weighted mean ──────────────────────────────────
  let weightedSum = 0;
  let weightTotal = 0;
  for (const v of verdicts) {
    const w = v.trustWeight * v.confidence;
    weightedSum += w * v.maliciousScore;
    weightTotal += w;
  }
  let score = weightTotal === 0 ? 0 : Math.round(weightedSum / weightTotal);

  // ── 2. Arbitration override ──────────────────────────────────────────────
  let overrideApplied = false;
  let overrideReason = null;
  const trustedFlags = verdicts.filter(
    (v) =>
      v.trustWeight >= TrustWeights.trustedOverrideThreshold &&
      v.maliciousScore >= OVERRIDE_MIN_SCORE &&
      v.confidence >= OVERRIDE_MIN_CONFIDENCE,
  );

  if (trustedFlags.length > 0) {
    const top = trustedFlags.reduce((a, b) => (a.trustWeight >= b.trustWeight ? a : b));
    const flooredBand =
      top.level === ThreatLevel.critical ? ThreatLevel.critical : ThreatLevel.dangerous;
    const floor = floorScore(flooredBand);
    if (score < floor) {
      score = floor;
      overrideApplied = true;
      overrideReason =
        `Trusted threat intelligence override — ${top.sourceName} ` +
        `(trust ${top.trustWeight}) flagged this as ${levelLabel(top.level)}.`;
    }
  }

  score = clamp(score, 0, 100);
  const level = levelFromScore(score);

  // ── 3. Conflict detection ────────────────────────────────────────────────
  const flagged = verdicts.filter((v) => isMalicious(v.level));
  const cleared = verdicts.filter((v) => !isMalicious(v.level));
  const hasConflict = flagged.length > 0 && cleared.length > 0;

  // ── 4. Agreement-weighted confidence ─────────────────────────────────────
  const agreeing = verdicts.filter((v) => isMalicious(v.level) === isMalicious(level));
  const agreementRatio = agreeing.length / verdicts.length;
  const meanConfidence =
    verdicts.reduce((sum, v) => sum + v.confidence, 0) / verdicts.length;
  let confidence = agreementRatio * 0.6 + meanConfidence * 0.4;
  if (overrideApplied) {
    // A trusted override is high-confidence by construction.
    confidence = clamp(confidence, 0.75, 1.0);
  }

  // ── 5. Explainable report ────────────────────────────────────────────────
  const ranked = [...verdicts].sort((a, b) => b.trustWeight - a.trustWeight);
  const explanation = [];
  if (overrideApplied && overrideReason) explanation.push(overrideReason);
  for (const v of ranked) {
    const headline = v.reasons.length > 0 ? v.reasons[0] : levelLabel(v.level);
    explanation.push(`${v.sourceName}: ${levelLabel(v.level)} — ${headline}`);
  }

  return {
    unifiedScore: score,
    level,
    confidence: clamp(confidence, 0, 1),
    verdicts: ranked,
    explanation,
    overrideApplied,
    overrideReason,
    hasConflict,
    flaggingSources: flagged.sort((a, b) => b.trustWeight - a.trustWeight),
  };
}

/** What the interceptor would do with this link. */
export const LinkAction = { allow: 'allow', warn: 'warn', block: 'block' };

/**
 * Port of `RiskEngine.decide`.
 *
 * The safety rail: a trusted override is never silently allowed. Even when the
 * floored score lands in a band that would otherwise pass, an override means at
 * least a warning.
 */
export function decideAction(fusion) {
  if (fusion.overrideApplied) {
    return fusion.level === ThreatLevel.critical ? LinkAction.block : LinkAction.warn;
  }
  switch (fusion.level) {
    case ThreatLevel.safe:
      return LinkAction.allow;
    case ThreatLevel.suspicious:
    case ThreatLevel.dangerous:
      return LinkAction.warn;
    default:
      return LinkAction.block;
  }
}

// ── Sources ────────────────────────────────────────────────────────────────

/**
 * CyberGuard's own engine, expressed as a source so it sits in fusion
 * alongside external feeds. Always available: it performs no I/O.
 */
export function localEngineVerdict(url) {
  const r = analyzeUrl(url);
  // `confidence` is confidence in the *verdict*; fusion wants a malicious
  // score where high means dangerous.
  const maliciousScore = r.isPhishing ? r.confidence : 100 - r.confidence;
  const reasons =
    r.triggeredRules.length > 0
      ? r.triggeredRules
      : [r.isPhishing ? 'Heuristic phishing indicators' : 'No risk indicators found'];

  return sourceVerdict({
    sourceName: 'CyberGuard AI',
    trustWeight: TrustWeights.cyberGuardAi,
    maliciousScore,
    confidence: r.confidence / 100,
    reasons,
  });
}

/**
 * A deterministic reputation feed standing in for a real external API.
 *
 * Mirrors `MockReputationSource`: same contract a real client would implement,
 * no randomness so demos and tests reproduce, and — critically — it performs no
 * network egress. Swapping in a real Safe Browsing client later means replacing
 * this function and nothing else.
 *
 * Off unless the caller opts in, matching the app's cloud-intel toggle.
 */
const KNOWN_BAD_DOMAINS = new Set([
  'paytm-kyc-verify.xyz',
  'sbi-secure-login.top',
  'free-jio-recharge.tk',
  'hdfc-netbanking-update.click',
  // Deliberately innocuous-looking: no brand name, no throwaway TLD, no
  // phishing keyword, few hyphens — so the local engine scores it clean. Every
  // other entry above trips the local rules too, which means they all produce
  // unanimous verdicts and none can exercise arbitration. This one is the case
  // the whole feature exists for: a domain a feed has already seen in the wild
  // but the on-device model has no reason to suspect.
  'account-services-portal.com',
]);

export function reputationVerdict(url, { name, trustWeight, enabled }) {
  if (!enabled) {
    return unavailableVerdict(name, trustWeight, `${name} is disabled (cloud intel off)`);
  }

  const domain = getDomain(normalize(url)) ?? '';

  if (KNOWN_BAD_DOMAINS.has(domain)) {
    return sourceVerdict({
      sourceName: name,
      trustWeight,
      maliciousScore: 95,
      confidence: 0.95,
      reasons: [`Domain present on ${name} blocklist feed`],
      fromCache: true,
    });
  }

  // Nothing known about it. Reported as a low-confidence clean verdict rather
  // than as an endorsement — an absent blocklist entry is weak evidence.
  return sourceVerdict({
    sourceName: name,
    trustWeight,
    maliciousScore: 5,
    confidence: 0.4,
    reasons: [`Not listed on ${name} feed`],
  });
}

/** Collect every source's verdict and fuse them. */
export function analyzeWithFusion(url, { cloudIntel = false } = {}) {
  const verdicts = [
    localEngineVerdict(url),
    reputationVerdict(url, {
      name: 'OpenPhish',
      trustWeight: TrustWeights.openPhish,
      enabled: cloudIntel,
    }),
    reputationVerdict(url, {
      name: 'PhishTank',
      trustWeight: TrustWeights.phishTank,
      enabled: cloudIntel,
    }),
  ];

  const fusion = fuse(verdicts);
  return {
    url: normalize(url),
    domain: getDomain(normalize(url)),
    ...fusion,
    action: decideAction(fusion),
    cloudIntel,
  };
}
