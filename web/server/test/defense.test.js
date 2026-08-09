import assert from 'node:assert/strict';
import { before, describe, it } from 'node:test';

import { loadModels } from '../src/engines/modelStore.js';
import {
  LinkAction,
  analyzeWithFusion,
  decideAction,
  fuse,
  localEngineVerdict,
} from '../src/engines/fusionEngine.js';
import { assessRisk, bandFromScore } from '../src/engines/predictiveRisk.js';
import { classifyText } from '../src/engines/scamClassifier.js';
import {
  ThreatLevel,
  TrustWeights,
  levelFromScore,
  sourceVerdict,
  unavailableVerdict,
} from '../src/engines/threatIntel.js';

before(async () => {
  await loadModels();
});

describe('threat taxonomy', () => {
  it('maps scores onto the documented bands', () => {
    assert.equal(levelFromScore(0), ThreatLevel.safe);
    assert.equal(levelFromScore(30), ThreatLevel.safe);
    assert.equal(levelFromScore(31), ThreatLevel.suspicious);
    assert.equal(levelFromScore(60), ThreatLevel.suspicious);
    assert.equal(levelFromScore(61), ThreatLevel.dangerous);
    assert.equal(levelFromScore(80), ThreatLevel.dangerous);
    assert.equal(levelFromScore(81), ThreatLevel.critical);
    assert.equal(levelFromScore(100), ThreatLevel.critical);
  });
});

describe('fusion arbitration', () => {
  const trusted = (score, confidence = 0.9) =>
    sourceVerdict({
      sourceName: 'OpenPhish',
      trustWeight: TrustWeights.openPhish,
      maliciousScore: score,
      confidence,
      reasons: ['On blocklist feed'],
    });

  const localSafe = sourceVerdict({
    sourceName: 'CyberGuard AI',
    trustWeight: TrustWeights.cyberGuardAi,
    maliciousScore: 5,
    confidence: 0.9,
    reasons: ['No risk indicators found'],
  });

  it('an unavailable source is excluded, never counted as safe', () => {
    // The failure mode this guards: an outage silently improving the score.
    const withOutage = fuse([
      localSafe,
      unavailableVerdict('OpenPhish', TrustWeights.openPhish, 'timed out'),
    ]);
    const alone = fuse([localSafe]);
    assert.equal(withOutage.unifiedScore, alone.unifiedScore);
    assert.equal(withOutage.verdicts.length, 1);
  });

  it('returns a safe, zero-confidence result when nothing is available', () => {
    const result = fuse([unavailableVerdict('X', 10)]);
    assert.equal(result.unifiedScore, 0);
    assert.equal(result.confidence, 0);
    assert.match(result.explanation[0], /No detection source/);
  });

  it('a trusted flag floors a clean local verdict into the danger band', () => {
    const result = fuse([localSafe, trusted(95)]);
    assert.equal(result.overrideApplied, true);
    assert.ok(result.unifiedScore >= 61, `score was ${result.unifiedScore}`);
    assert.match(result.overrideReason, /OpenPhish/);
  });

  it('an override never resolves to silently allowing the link', () => {
    // The safety rail in RiskEngine.decide: an overridden verdict is at
    // minimum a warning, whatever band the floored score lands in.
    const result = fuse([localSafe, trusted(95)]);
    assert.notEqual(decideAction(result), LinkAction.allow);
  });

  it('a low-confidence trusted source cannot override', () => {
    // Below OVERRIDE_MIN_CONFIDENCE. A feed that is unsure must not be able to
    // condemn a URL on its own.
    const result = fuse([localSafe, trusted(95, 0.3)]);
    assert.equal(result.overrideApplied, false);
  });

  it('a low-scoring trusted source cannot override', () => {
    const result = fuse([localSafe, trusted(40)]);
    assert.equal(result.overrideApplied, false);
  });

  it('an untrusted source cannot override however sure it is', () => {
    const weak = sourceVerdict({
      sourceName: 'SSL Analyzer',
      trustWeight: TrustWeights.sslAnalyzer,
      maliciousScore: 100,
      confidence: 1,
      reasons: ['Self-signed certificate'],
    });
    const result = fuse([localSafe, weak]);
    assert.equal(result.overrideApplied, false);
  });

  it('flags disagreement between sources', () => {
    const result = fuse([localSafe, trusted(95)]);
    assert.equal(result.hasConflict, true);
  });

  it('does not flag conflict when sources agree', () => {
    assert.equal(fuse([localSafe, trusted(5, 0.8)]).hasConflict, false);
  });

  it('confidence rises with agreement', () => {
    const agree = fuse([localSafe, trusted(5, 0.9)]);
    const disagree = fuse([localSafe, trusted(75, 0.65)]);
    assert.ok(agree.confidence > disagree.confidence);
  });

  it('an override is high-confidence by construction', () => {
    const result = fuse([localSafe, trusted(95)]);
    assert.ok(result.confidence >= 0.75);
  });

  it('explanation leads with the override reason', () => {
    const result = fuse([localSafe, trusted(95)]);
    assert.match(result.explanation[0], /Trusted threat intelligence override/);
  });

  it('ranks source verdicts by trust weight', () => {
    const result = fuse([localSafe, trusted(95)]);
    const weights = result.verdicts.map((v) => v.trustWeight);
    assert.deepEqual(weights, [...weights].sort((a, b) => b - a));
  });
});

describe('fusion end to end', () => {
  it('keeps external feeds out unless cloud intel is on', () => {
    const off = analyzeWithFusion('https://example.org', { cloudIntel: false });
    assert.equal(off.verdicts.length, 1, 'only the local engine should vote');
    assert.equal(off.verdicts[0].sourceName, 'CyberGuard AI');

    const on = analyzeWithFusion('https://example.org', { cloudIntel: true });
    assert.ok(on.verdicts.length > 1);
  });

  it('a feed overrules the local engine on an innocuous-looking domain', () => {
    // The case arbitration exists for. Every other blocklist entry trips the
    // local rules too, so they produce unanimous verdicts and never exercise
    // the override — this one looks clean to the rules engine.
    const clean = analyzeWithFusion('https://account-services-portal.com/login', {
      cloudIntel: false,
    });
    assert.equal(clean.action, LinkAction.allow, 'local engine sees nothing wrong');

    const withFeeds = analyzeWithFusion('https://account-services-portal.com/login', {
      cloudIntel: true,
    });
    assert.equal(withFeeds.overrideApplied, true);
    assert.equal(withFeeds.hasConflict, true);
    assert.notEqual(withFeeds.action, LinkAction.allow);
  });

  it('blocks a domain on the reputation blocklist', () => {
    const result = analyzeWithFusion('https://sbi-secure-login.top/verify', {
      cloudIntel: true,
    });
    assert.ok(['warn', 'block'].includes(result.action));
    assert.ok(result.unifiedScore >= 61);
  });

  it('allows an ordinary site', () => {
    const result = analyzeWithFusion('https://google.com');
    assert.equal(result.action, LinkAction.allow);
  });

  it('the local engine reports high malice for a phishing URL', () => {
    const verdict = localEngineVerdict('http://secure-hdfc-verify.tk/kyc-update');
    assert.ok(verdict.maliciousScore >= 50);
    assert.ok(verdict.reasons.length > 0);
  });

  it('the local engine always supplies a reason', () => {
    for (const url of ['https://google.com', 'http://a.tk/x']) {
      assert.ok(localEngineVerdict(url).reasons.length > 0, url);
    }
  });
});

describe('predictive risk', () => {
  it('is zero with no signals and recommends nothing to do', () => {
    const r = assessRisk();
    assert.equal(r.riskScore, 0);
    assert.equal(r.band, 'low');
    assert.deepEqual(r.recommendations, ['healthy']);
  });

  it('caps each signal so one behaviour cannot saturate the score', () => {
    // 100 phishing hits must not swamp everything else — the cap is 22.
    const many = assessRisk({ phishingHits: 100 });
    assert.equal(many.factors.find((f) => f.type === 'phishing').contribution, 22);
  });

  it('never exceeds 100 even with every signal maxed', () => {
    const r = assessRisk({
      phishingHits: 99,
      suspiciousSms: 99,
      unknownWifi: 99,
      malwareDetections: 99,
      interceptorBlocks: 99,
      breachActive: true,
      securityScoreDelta: -100,
    });
    assert.ok(r.riskScore <= 100);
    assert.equal(r.band, 'high');
  });

  it('orders factors by contribution', () => {
    const r = assessRisk({ phishingHits: 2, malwareDetections: 2, unknownWifi: 1 });
    const contributions = r.factors.map((f) => f.contribution);
    assert.deepEqual(contributions, [...contributions].sort((a, b) => b - a));
  });

  it('an improving security score is not counted as risk', () => {
    // Only a negative delta contributes; a rising score must not add points.
    assert.equal(assessRisk({ securityScoreDelta: 40 }).riskScore, 0);
    assert.ok(assessRisk({ securityScoreDelta: -40 }).riskScore > 0);
  });

  it('a breach dominates the credential-theft forecast', () => {
    const withBreach = assessRisk({ breachActive: true });
    const forecast = withBreach.forecast.find((f) => f.category === 'credentialTheft');
    assert.equal(forecast.likelihood, 'medium');
    assert.ok(withBreach.recommendations.includes('breach'));
  });

  it('bands split at the documented thresholds', () => {
    assert.equal(bandFromScore(33), 'low');
    assert.equal(bandFromScore(34), 'medium');
    assert.equal(bandFromScore(66), 'medium');
    assert.equal(bandFromScore(67), 'high');
  });
});

describe('scam text classifier', () => {
  it('flags a lottery scam', () => {
    const r = classifyText(
      'Congratulations! You have won a reward of Rs 25,00,000. Share OTP immediately to claim your prize.',
    );
    assert.equal(r.isScam, true);
    assert.ok(r.scamProbability >= 40);
  });

  it('picks the highest-weighted category as the headline', () => {
    // Lottery (45) outranks support (18) when both match.
    const r = classifyText('You have won a prize. Call now, customer care is waiting.');
    assert.equal(r.category, 'fakeLottery');
  });

  it('does not flag an ordinary message', () => {
    const r = classifyText('Hey, are we still meeting at 6pm near the station?');
    assert.equal(r.isScam, false);
    assert.equal(r.scamProbability, 0);
    assert.equal(r.reasons[0].type, 'noIndicators');
  });

  it('a brand name alone is not a scam signal', () => {
    // A screenshot merely mentioning HDFC is most likely a real bank page.
    const r = classifyText('Payment received from HDFC Bank. Thank you.');
    assert.equal(r.isScam, false);
    assert.ok(!r.reasons.some((x) => x.type === 'brand'));
  });

  it('a brand amplifies an existing scam signal', () => {
    const plain = classifyText('Your account is suspended, enter your card number and cvv.');
    const branded = classifyText('SBI: your account is suspended, enter your card number and cvv.');
    assert.ok(branded.scamProbability > plain.scamProbability);
    assert.equal(branded.detectedBrand, 'sbi');
  });

  it('reports empty input as having no text', () => {
    assert.equal(classifyText('').reasons[0].type, 'noText');
    assert.equal(classifyText('  ').reasons[0].type, 'noText');
  });

  it('truncates the preview it echoes back', () => {
    const r = classifyText('x'.repeat(500));
    assert.ok(r.textPreview.length <= 281);
  });
});
