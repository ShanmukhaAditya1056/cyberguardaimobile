'use strict';

/**
 * URL corpus for the phishing suite.
 *
 * ── Why the expected verdicts here are safe to assert on ────────────────────
 *
 * `PhishingRepository.analyzeUrl` scores a URL with a rules engine, then
 * blends that with an on-device logistic-regression model:
 *
 *     blended = 0.6 * rulesProb + 0.4 * modelProb      (phishing when >= 0.5)
 *
 * The model is real (assets/models/phishing_weights.json, 8000 samples), so a
 * mid-range rules score can be flipped either way by the model. Two classes of
 * URL are nevertheless deterministic, and those are the only ones this file
 * asserts a verdict on:
 *
 *  1. WHITELISTED domains. `analyzeUrl` returns from the whitelist branch
 *     *before* the ML blend runs, so the verdict is always safe/confidence 96.
 *
 *  2. Rules score >= 67. Then rulesProb >= 0.835, so even with modelProb = 0
 *     the blend is >= 0.501 and the verdict stays phishing.
 *
 * Anything between those bounds is listed under `ambiguous` and is only ever
 * asserted to "produce some verdict without crashing" — claiming to know the
 * answer there would be inventing a result.
 *
 * Rule weights (lib/data/repositories/phishing_repository.dart):
 *   IP address 35 | suspicious TLD 25 | phishing keyword 15 | encoding 15
 *   long URL 8 | >2 subdomains 12 | brand impersonation 20 | odd pattern 10
 *   "@" in URL 30 | >=3 hyphens in domain 6 each | URL > 100 chars 10
 *   phishing when score >= 35; confidence = 50 + score/2
 */

/** Whitelisted — bypasses the ML blend entirely. Always safe. */
const SAFE_WHITELISTED = [
  { url: 'https://www.google.com', note: 'google.com in safeDomains' },
  { url: 'https://amazon.in', note: 'amazon.in in safeDomains' },
  { url: 'https://www.sbi.co.in', note: 'sbi.co.in in safeDomains' },
  { url: 'https://uidai.gov.in', note: 'uidai.gov.in in safeDomains' },
  { url: 'https://myaadhaar.uidai.gov.in', note: 'subdomain of whitelisted uidai.gov.in' },
  { url: 'https://github.com', note: 'github.com in safeDomains' },
  { url: 'https://paytm.com', note: 'paytm.com in safeDomains' },
  { url: 'https://www.irctc.co.in', note: 'irctc.co.in in safeDomains' },
  { url: 'https://incometax.gov.in', note: 'incometax.gov.in in safeDomains' },
  { url: 'https://www.flipkart.com', note: 'flipkart.com in safeDomains' },
];

/**
 * Rules score >= 67, so the ML blend cannot flip them. Each entry documents
 * the arithmetic so a future rule-weight change makes the intent obvious.
 */
const DANGEROUS_DETERMINISTIC = [
  {
    url: 'http://192.168.1.50/aadhaar-verify/otp-confirm',
    score: 70,
    breakdown: 'IP 35 + keyword aadhaar-verify 15 + brand aadhaar 20',
  },
  {
    url: 'https://sbi-alert-verify-now-secure.xyz/kyc-update',
    score: 84,
    breakdown: 'TLD .xyz 25 + keyword sbi-alert 15 + brand sbi 20 + 4 hyphens 24',
  },
  {
    url: 'https://paytm-verify-kyc-update-now.tk/login',
    score: 84,
    breakdown: 'TLD .tk 25 + keyword paytm-verify 15 + brand paytm 20 + 4 hyphens 24',
  },
  {
    url: 'http://secure-hdfc-netbanking-login-verify.ml/account-suspended',
    score: 84,
    breakdown: 'TLD .ml 25 + keyword secure-hdfc 15 + brand hdfc 20 + 4 hyphens 24',
  },
  {
    url: 'https://amazon.in@claim-prize-winner-now.click/reward-claim',
    score: 100,
    breakdown: '"@" 30 + TLD .click 25 + keyword claim-prize 15 + brand amazon 20 + 4 hyphens 24 (clamped)',
  },
  {
    url: 'http://192.168.0.99/upi-block/pan-verify?redirect=free-recharge',
    score: 70,
    breakdown: 'IP 35 + keyword upi-block 15 + brand upi 20',
  },
  {
    url: 'https://icici-bank-alert-verify-account.ga/e-kyc',
    score: 84,
    breakdown: 'TLD .ga 25 + keyword bank-alert 15 + brand icici 20 + 4 hyphens 24',
  },
  {
    url: 'https://jio-free-recharge-claim-offer.gq/lucky-winner',
    score: 84,
    breakdown: 'TLD .gq 25 + keyword free-recharge 15 + brand jio 20 + 4 hyphens 24',
  },
];

/**
 * Real rule triggers, but the total lands under the deterministic bar — the
 * model gets a genuine vote. Assert only that a verdict renders.
 */
const AMBIGUOUS = [
  { url: 'https://random-site.xyz/page', note: 'suspicious TLD only (25)' },
  { url: 'https://a.b.c.d.example.com/', note: 'excessive subdomains (12)' },
  { url: 'https://example.com/%2e%2e%2f%2e%2e%2f', note: 'encoding tricks (15)' },
  { url: 'https://verify-account.info/', note: 'TLD 25 + keyword 15 = 40' },
];

/** No rule fires. Not whitelisted either, so the model decides. */
const NEUTRAL = [
  { url: 'https://example.com', note: 'no rule triggers' },
  { url: 'https://wikipedia.org', note: 'no rule triggers' },
  { url: 'https://openstreetmap.org', note: 'no rule triggers' },
];

/** Inputs that must not crash the scanner or produce a verdict. */
const MALFORMED = [
  { input: '', note: 'empty string' },
  { input: '   ', note: 'whitespace only' },
  { input: 'not a url at all', note: 'free text' },
  { input: 'http://', note: 'scheme with no host' },
  { input: 'https://', note: 'scheme with no host' },
  { input: '://missing-scheme.com', note: 'malformed scheme' },
  { input: 'ftp://files.example.com/x', note: 'non-http scheme' },
  { input: 'javascript:alert(1)', note: 'script pseudo-scheme' },
  { input: 'data:text/html,<h1>hi</h1>', note: 'data URI' },
  { input: 'https://' + 'a'.repeat(300) + '.com', note: 'very long host' },
  { input: 'https://exa mple.com', note: 'space inside host' },
  { input: 'https://例え.テスト', note: 'internationalised domain' },
  { input: 'HTTPS://GOOGLE.COM', note: 'uppercase scheme + host' },
  { input: '  https://google.com  ', note: 'leading/trailing whitespace' },
];

/**
 * Payload-shaped inputs. The scanner treats input as an opaque string and does
 * no SQL/JS evaluation, so the requirement here is simply "handled as text,
 * no crash, no injection into the UI".
 */
const INJECTION_SHAPED = [
  { input: "'; DROP TABLE scans;--", note: 'SQL-shaped' },
  { input: '<script>alert(1)</script>', note: 'HTML/JS-shaped' },
  { input: '{{7*7}}', note: 'template-shaped' },
  { input: '../../../../etc/passwd', note: 'path traversal shaped' },
  { input: '${jndi:ldap://x/a}', note: 'JNDI-shaped' },
  { input: 'https://example.com/?q=<img src=x onerror=alert(1)>', note: 'XSS in query' },
  { input: '%00', note: 'null byte' },
  { input: '‮moc.elpmaxe//:sptth', note: 'right-to-left override' },
];

module.exports = {
  SAFE_WHITELISTED,
  DANGEROUS_DETERMINISTIC,
  AMBIGUOUS,
  NEUTRAL,
  MALFORMED,
  INJECTION_SHAPED,
};
