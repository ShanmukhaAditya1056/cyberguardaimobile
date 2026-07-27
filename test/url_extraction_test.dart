import 'package:cyberguard_ai/core/utils/url_extractor.dart';
import 'package:cyberguard_ai/data/repositories/phishing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlExtractor.extractUrls — multi-label domains', () {
    test('scheme-less .gov.in domain is captured in full (not truncated)', () {
      final urls =
          UrlExtractor.extractUrls('Update your KYC at myaadhaar.uidai.gov.in now');
      expect(urls, contains('myaadhaar.uidai.gov.in'));
      // Must NOT be the truncated form that broke the whitelist.
      expect(urls.any((u) => u == 'myaadhaar.uidai'), isFalse);
    });

    test('.co.in domain with a path is captured in full', () {
      final urls = UrlExtractor.extractUrls('Book at irctc.co.in/booking today');
      expect(urls.any((u) => u.startsWith('irctc.co.in')), isTrue);
    });

    test('https URLs still work', () {
      final urls = UrlExtractor.extractUrls('see https://uidai.gov.in/portal');
      expect(urls.first, startsWith('https://uidai.gov.in'));
    });
  });

  group('PhishingRepository — official Aadhaar link is not phishing', () {
    final repo = PhishingRepository();

    test('myaadhaar.uidai.gov.in is whitelisted (regression)', () {
      final r = repo.analyzeUrl('myaadhaar.uidai.gov.in');
      expect(r.isPhishing, isFalse);
    });

    test('uidai.gov.in subdomains stay safe', () {
      expect(repo.analyzeUrl('resident.uidai.gov.in').isPhishing, isFalse);
      expect(repo.analyzeUrl('https://incometax.gov.in').isPhishing, isFalse);
    });

    test('genuine phishing is still flagged', () {
      expect(repo.analyzeUrl('paytm-kyc-verify.xyz').isPhishing, isTrue);
    });
  });
}
