/**
 * Port of `lib/data/services/screenshot_scam_classifier.dart` — Feature 3's
 * classifier half.
 *
 * The mobile app feeds this OCR output from a screenshot. A browser cannot run
 * ML Kit, and uploading screenshots to a cloud OCR service would defeat the
 * point of an offline scanner, so the web flow asks the user to paste the text
 * instead. The scoring below is identical either way.
 *
 * Emits stable identifiers rather than prose — the app localises these into
 * four languages.
 */

export const ScamCategory = {
  fakeBank: 'fakeBank',
  fakeUpi: 'fakeUpi',
  fakeOtp: 'fakeOtp',
  fakeLogin: 'fakeLogin',
  fakeKyc: 'fakeKyc',
  fakeLottery: 'fakeLottery',
  fakeInvestment: 'fakeInvestment',
  fakeSupport: 'fakeSupport',
  none: 'none',
};

const BRANDS = [
  'sbi', 'state bank', 'hdfc', 'icici', 'axis', 'kotak', 'paytm',
  'phonepe', 'google pay', 'gpay', 'amazon', 'flipkart', 'jio', 'airtel',
  'aadhaar', 'pan card', 'irctc', 'lic', 'income tax',
];

/**
 * Category → keywords and weight.
 *
 * Lottery and investment carry the highest weights (45, 42) because they have
 * essentially no legitimate use in a message someone screenshots for a second
 * opinion. Support wording is lowest (18) — "customer care" appears on plenty
 * of real bank pages, and weighting it heavily would flag them.
 */
const SIGNALS = [
  [ScamCategory.fakeOtp,
    ['enter otp', 'one time password', 'otp code', 'share otp', 'verify otp'], 35],
  [ScamCategory.fakeUpi,
    ['upi pin', 'enter upi', 'collect request', 'pay ₹', 'payment failed', 'refund processing'], 30],
  [ScamCategory.fakeBank,
    ['net banking', 'account suspended', 'account blocked', 'card number', 'cvv', 'debit card', 'credit card'], 30],
  [ScamCategory.fakeKyc,
    ['kyc', 'complete your kyc', 'kyc pending', 'kyc expired', 'update kyc', 're-kyc'], 30],
  [ScamCategory.fakeLogin,
    ['enter password', 'sign in to continue', 'login to verify', 'username and password', 'password expired'], 25],
  [ScamCategory.fakeLottery,
    ['you have won', 'congratulations', 'lottery', 'lucky winner', 'claim your prize', 'reward of'], 45],
  [ScamCategory.fakeInvestment,
    ['double your money', 'guaranteed returns', 'invest now', 'profit daily', 'trading signal'], 42],
  [ScamCategory.fakeSupport,
    ['customer care', 'helpline number', 'call now', 'support executive', 'toll free'], 18],
];

const URGENCY = [
  'urgent', 'immediately', 'within 24 hours', 'expire', 'last warning',
  'account will be', 'click here', 'act now',
];

const SCAM_THRESHOLD = 40;

export function classifyText(rawText) {
  const text = (rawText ?? '').toLowerCase();
  if (text.trim().length < 3) {
    return {
      scamProbability: 0,
      isScam: false,
      category: ScamCategory.none,
      detectedBrand: null,
      reasons: [{ type: 'noText' }],
      textPreview: '',
    };
  }

  const reasons = [];
  let score = 0;
  let top = ScamCategory.none;
  let topWeight = 0;

  for (const [category, keywords, weight] of SIGNALS) {
    const hit = keywords.find((k) => text.includes(k));
    if (!hit) continue;
    score += weight;
    reasons.push({ type: 'categoryHit', category, matched: hit });
    if (weight > topWeight) {
      topWeight = weight;
      top = category;
    }
  }

  // Brand impersonation amplifies, but only alongside an actual scam signal —
  // a screenshot that merely mentions "HDFC" is most likely a real bank page.
  const brand = BRANDS.find((b) => text.includes(b));
  let detectedBrand = null;
  if (brand) {
    detectedBrand = brand;
    if (score > 0) {
      score += 15;
      reasons.push({ type: 'brand', matched: brand });
    }
  }

  const urgent = URGENCY.find((u) => text.includes(u));
  if (urgent) {
    score += 10;
    reasons.push({ type: 'urgency', matched: urgent });
  }

  const scamProbability = Math.min(100, Math.max(0, score));
  if (reasons.length === 0) reasons.push({ type: 'noIndicators' });

  return {
    scamProbability,
    isScam: scamProbability >= SCAM_THRESHOLD,
    category: top,
    detectedBrand,
    reasons,
    textPreview: rawText.length > 280 ? `${rawText.slice(0, 280)}…` : rawText,
  };
}
