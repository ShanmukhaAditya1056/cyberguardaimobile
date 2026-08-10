import { models } from './modelStore.js';
import { explainUrl } from './shapExplainer.js';
import { randomForestProba, sigmoid } from './trees.js';
import {
  safeDomains,
  suspiciousTlds,
  indianPhishingKeywords,
  suspiciousUrlPatterns,
} from './threatPatterns.js';
import * as urls from './urlExtractor.js';

/**
 * Port of `PhishingRepository.analyzeUrl` plus `PhishingMlService`.
 *
 * Twelve rules produce a score and an explanation; the trained model (logistic
 * regression or a random forest, whichever `phishing_weights.json` carries)
 * then blends in at 40 %. The rules stay the source of the SHAP reasoning so
 * there is always something to show the user, even when the model is absent.
 *
 * Rule order, weights and thresholds are identical to the Dart original. See
 * the note on `hasEncodedTricks` below for the one place where matching the
 * app means carrying over a quirk.
 */

const BRANDS = [
  'paytm', 'phonepe', 'sbi', 'hdfc', 'icici', 'axis',
  'amazon', 'flipkart', 'google', 'apple', 'microsoft',
  'jio', 'airtel', 'aadhaar', 'npci', 'upi',
];

const PHISHING_THRESHOLD = 35;

const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

function isWhitelisted(domain) {
  return safeDomains.some((d) => domain === d || domain.endsWith(`.${d}`));
}

export function analyzeUrl(rawUrl) {
  const url = urls.normalize(rawUrl);
  const domain = urls.getDomain(url) ?? '';
  const tld = domain ? urls.getTld(domain) ?? '' : '';

  const triggeredKeywords = [];
  const triggeredRules = [];
  let score = 0;

  // 1. Whitelist — the strongest safe signal, and an early return so no later
  //    rule can drag a known-good bank domain into a phishing verdict.
  if (isWhitelisted(domain)) {
    return withMlBoost(
      {
        url,
        isPhishing: false,
        confidence: 96,
        shapReasons: explainUrl({
          isSuspiciousTld: false,
          hasKeyword: false,
          keywords: [],
          isIpAddress: false,
          isWhitelisted: true,
          hasEncoding: false,
          isLong: false,
          subdomainCount: 0,
          isMismatch: false,
        }),
        triggeredKeywords: [],
        triggeredRules: ['Trusted domain whitelist'],
      },
      url,
      // A whitelist hit is a decision, not a score to be revised. Running the
      // model over it is what would let a low-confidence classifier overturn
      // "this is sbi.co.in".
      { skipMl: true },
    );
  }

  // 2. IP address in place of a domain.
  const isIpUrl = urls.isIpAddress(url);
  if (isIpUrl) {
    score += 35;
    triggeredRules.push('IP address instead of domain');
  }

  // 3. Suspicious TLD.
  const isSuspiciousTld = suspiciousTlds.some(
    (t) => domain.endsWith(t) || tld === t,
  );
  if (isSuspiciousTld) {
    score += 25;
    triggeredRules.push(`Suspicious TLD: ${tld}`);
  }

  // 4. Phishing keywords. Only the first match scores, matching the Dart
  //    `break` — a URL stuffed with ten of them is not ten times worse.
  const urlLower = url.toLowerCase();
  for (const keyword of indianPhishingKeywords) {
    if (urlLower.includes(keyword)) {
      triggeredKeywords.push(keyword);
      score += 15;
      break;
    }
  }
  if (triggeredKeywords.length > 0) {
    triggeredRules.push(
      `Phishing keywords: ${triggeredKeywords.slice(0, 3).join(', ')}`,
    );
  }

  // 5. Encoding obfuscation — percent-encoded ':' or '/', an '@', or a second
  //    scheme past the first. Matched case-insensitively on both sides; see
  //    `hasEncodedTricks` for why the original fixed-case form never fired.
  const hasEncoding = urls.hasEncodedTricks(url);
  if (hasEncoding) {
    score += 15;
    triggeredRules.push('URL encoding obfuscation');
  }

  // 6. Excessive length.
  const isLong = urls.isExcessivelyLong(url);
  if (isLong) {
    score += 8;
    triggeredRules.push('Excessively long URL');
  }

  // 7. Subdomain depth.
  const subCount = urls.subdomainCount(domain);
  if (subCount > 2) {
    score += 12;
    triggeredRules.push(`Excessive subdomains (${subCount})`);
  }

  // 8. Brand impersonation — a trusted brand's name appearing anywhere in a
  //    URL that is not on the whitelist.
  let isMismatch = false;
  for (const brand of BRANDS) {
    if (urlLower.includes(brand) && !isWhitelisted(domain)) {
      isMismatch = true;
      score += 20;
      triggeredRules.push(`Impersonates ${brand} brand`);
      break;
    }
  }

  // 9. Structural patterns (hash in path, login.php on a throwaway TLD, ...).
  for (const pattern of suspiciousUrlPatterns) {
    if (new RegExp(pattern, 'i').test(url)) {
      score += 10;
      triggeredRules.push('Suspicious URL pattern');
      break;
    }
  }

  // 10. `@` in the URL. Browsers discard everything before it, so
  //     `https://sbi.co.in@evil.tk` loads evil.tk — a classic and very strong
  //     signal.
  if (url.includes('@')) {
    score += 30;
    triggeredRules.push('"@" symbol used to hide the real domain');
  }

  // 11. Hyphen-stuffed domains (secure-login-hdfc-india-verify.tk).
  const hyphenCount = (domain.match(/-/g) ?? []).length;
  if (hyphenCount >= 3) {
    score += hyphenCount * 6;
    triggeredRules.push(`Excessive hyphens in domain (${hyphenCount})`);
  }

  // 12. Overall length.
  if (url.length > 100) {
    score += 10;
    triggeredRules.push(`Unusually long URL (${url.length} chars)`);
  }

  score = clamp(score, 0, 100);
  const isPhishing = score >= PHISHING_THRESHOLD;

  const confidence = isPhishing
    ? clamp(Math.round(50 + score * 0.5), 50, 99)
    : clamp(Math.round(100 - score), 60, 99);

  const rulesResult = {
    url,
    isPhishing,
    confidence,
    shapReasons: explainUrl({
      isSuspiciousTld,
      hasKeyword: triggeredKeywords.length > 0,
      keywords: triggeredKeywords,
      isIpAddress: isIpUrl,
      isWhitelisted: false,
      hasEncoding,
      isLong,
      subdomainCount: subCount,
      isMismatch,
    }),
    triggeredKeywords,
    triggeredRules,
  };

  return withMlBoost(rulesResult, url);
}

/** 60 % rules / 40 % model, matching `PhishingRepository._withMlBoost`. */
function withMlBoost(rules, url, { skipMl = false } = {}) {
  const verdict = { ...rules, verdict: rules.isPhishing ? 'Phishing' : 'Safe' };
  if (skipMl) return { ...verdict, mlAvailable: false };

  const prob = predictProbability(url);
  if (prob === null) return { ...verdict, mlAvailable: false };

  const rulesProb = rules.isPhishing
    ? rules.confidence / 100
    : 1 - rules.confidence / 100;
  const blended = 0.6 * rulesProb + 0.4 * prob;
  const isPhishing = blended >= 0.5;
  const confidence = isPhishing
    ? clamp(Math.round(blended * 100), 50, 99)
    : clamp(Math.round((1 - blended) * 100), 50, 99);

  return {
    ...verdict,
    isPhishing,
    confidence,
    verdict: isPhishing ? 'Phishing' : 'Safe',
    mlAvailable: true,
    mlProbability: Number(prob.toFixed(4)),
    triggeredRules: [
      ...rules.triggeredRules,
      `On-device ML model (p=${prob.toFixed(2)})`,
    ],
  };
}

/** Probability from the trained model, or null when it did not load. */
export function predictProbability(url) {
  const model = models().phishing;
  if (!model) return null;

  const features = buildFeatures(url);
  if (model.kind === 'logistic_regression') {
    let z = model.bias;
    const n = Math.min(features.length, model.weights.length);
    for (let i = 0; i < n; i++) z += features[i] * model.weights[i];
    return sigmoid(z);
  }
  return randomForestProba(model.trees, features);
}

/**
 * The 12-feature vector. Must stay byte-for-byte in step with
 * `PhishingMlService._buildFeatures` and `ml/train_phishing.py` — the weights
 * were fitted against this exact ordering and scaling, so a reordered or
 * differently-normalised feature does not degrade the model gracefully, it
 * makes the output meaningless.
 */
export function buildFeatures(rawUrl) {
  const url = rawUrl.trim().toLowerCase();
  const hostOnly = url
    .replace(/^https?:\/\//, '')
    .split('/')[0]
    .split('?')[0];

  const count = (s, ch) => (s.match(new RegExp(`\\${ch}`, 'g')) ?? []).length;
  const digits = (url.match(/[0-9]/g) ?? []).length;
  const digitRatio = url.length === 0 ? 0 : digits / url.length;

  const hasIp = /^\d{1,3}(\.\d{1,3}){3}/.test(hostOnly);
  const hasHttps = url.startsWith('https://');
  const subdomainDepth = Math.max(0, count(hostOnly, '.') - 1);

  const badTlds = [
    '.xyz', '.tk', '.ml', '.ga', '.cf', '.click', '.top',
    '.loan', '.gq', '.pw', '.buzz', '.fun', '.link',
  ];
  const hasBadTld = badTlds.some((t) => hostOnly.endsWith(t));

  const phishingWords = [
    'login', 'verify', 'otp', 'kyc', 'aadhaar',
    'update', 'secure', 'confirm', 'reward', 'recharge',
  ];
  const hasPhishingWord = phishingWords.some((w) => url.includes(w));

  const brands = [
    'paytm', 'phonepe', 'gpay', 'sbi', 'hdfc',
    'icici', 'amazon', 'flipkart', 'jio', 'airtel',
  ];
  const hasBrandSpoof = brands.some(
    (b) =>
      url.includes(b) &&
      !hostOnly.endsWith(`${b}.com`) &&
      !hostOnly.endsWith(`${b}.in`),
  );

  const queryLen = url.includes('?') ? url.slice(url.indexOf('?') + 1).length : 0;
  const c01 = (v) => clamp(v, 0, 1);

  return [
    c01(url.length === 0 ? 0 : Math.log(url.length) / 8),
    c01(count(hostOnly, '-') / 10),
    c01(count(hostOnly, '.') / 10),
    c01(digitRatio),
    url.includes('@') ? 1 : 0,
    hasIp ? 1 : 0,
    hasHttps ? 1 : 0,
    c01(subdomainDepth / 5),
    hasBadTld ? 1 : 0,
    hasPhishingWord ? 1 : 0,
    hasBrandSpoof ? 1 : 0,
    c01(queryLen / 100),
  ];
}

/** Scan every URL found in a block of text — the SMS/email paste flow. */
export function analyzeText(text) {
  const found = urls.extractUrls(text);
  const results = found.map((url) => analyzeUrl(url));
  const phishing = results.filter((r) => r.isPhishing);
  return {
    urlsFound: found.length,
    results,
    worst:
      phishing.length > 0
        ? phishing.reduce((a, b) => (b.confidence > a.confidence ? b : a))
        : null,
  };
}
