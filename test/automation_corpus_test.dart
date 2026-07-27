import 'package:flutter_test/flutter_test.dart';
import 'package:cyberguard_ai/data/repositories/phishing_repository.dart';

/// Guards the Appium suite's URL corpus (`automation/data/urls.js`).
///
/// The E2E suite asserts hard verdicts for two classes of URL: whitelisted
/// domains (safe) and URLs whose rules score is high enough that the on-device
/// ML blend cannot flip them (dangerous). Both claims are properties of
/// `PhishingRepository`, so they belong in a fast Dart test rather than being
/// discovered as a 200-test Appium failure on an emulator.
///
/// If a rule weight changes and one of these flips, fix the corpus — do not
/// weaken this test.
void main() {
  final repo = PhishingRepository();

  group('Appium corpus — whitelisted URLs are always safe', () {
    const whitelisted = [
      'https://www.google.com',
      'https://amazon.in',
      'https://www.sbi.co.in',
      'https://uidai.gov.in',
      'https://myaadhaar.uidai.gov.in',
      'https://github.com',
      'https://paytm.com',
      'https://www.irctc.co.in',
      'https://incometax.gov.in',
      'https://www.flipkart.com',
    ];

    for (final url in whitelisted) {
      test(url, () {
        final result = repo.analyzeUrl(url);
        expect(result.isPhishing, isFalse,
            reason: '$url is whitelisted and must never be flagged');
        expect(result.confidence, 96,
            reason: 'whitelist branch returns a fixed confidence of 96');
      });
    }
  });

  group('Appium corpus — high-score URLs stay dangerous under the ML blend', () {
    const dangerous = [
      'http://192.168.1.50/aadhaar-verify/otp-confirm',
      'https://sbi-alert-verify-now-secure.xyz/kyc-update',
      'https://paytm-verify-kyc-update-now.tk/login',
      'http://secure-hdfc-netbanking-login-verify.ml/account-suspended',
      'https://amazon.in@claim-prize-winner-now.click/reward-claim',
      'http://192.168.0.99/upi-block/pan-verify?redirect=free-recharge',
      'https://icici-bank-alert-verify-account.ga/e-kyc',
      'https://jio-free-recharge-claim-offer.gq/lucky-winner',
    ];

    for (final url in dangerous) {
      test(url, () {
        final result = repo.analyzeUrl(url);
        expect(result.isPhishing, isTrue,
            reason: '$url must score >= 35 on rules alone');
        // The corpus only claims determinism for confidence >= 83, because
        // blended = 0.6 * rulesProb needs to clear 0.5 with modelProb = 0.
        expect(result.confidence, greaterThanOrEqualTo(83),
            reason:
                'rules confidence must be >= 83 so a 0.0 model probability '
                'still leaves the blend above the 0.5 phishing threshold');
      });
    }
  });

  group('Appium corpus — malformed input never throws', () {
    const malformed = [
      '',
      '   ',
      'not a url at all',
      'http://',
      'https://',
      '://missing-scheme.com',
      'ftp://files.example.com/x',
      'javascript:alert(1)',
      'data:text/html,<h1>hi</h1>',
      'https://exa mple.com',
      'HTTPS://GOOGLE.COM',
      '  https://google.com  ',
      "'; DROP TABLE scans;--",
      '<script>alert(1)</script>',
      '{{7*7}}',
      '../../../../etc/passwd',
      r'${jndi:ldap://x/a}',
      '%00',
    ];

    for (final input in malformed) {
      test('handles ${input.isEmpty ? '<empty>' : input}', () {
        expect(() => repo.analyzeUrl(input), returnsNormally);
      });
    }
  });
}
