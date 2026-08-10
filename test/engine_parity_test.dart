import 'package:flutter_test/flutter_test.dart';

import 'package:cyberguard_ai/core/utils/permission_analyzer.dart';
import 'package:cyberguard_ai/data/repositories/phishing_repository.dart';
import 'package:cyberguard_ai/data/services/malware_ml_service.dart';
import 'package:cyberguard_ai/data/services/wifi_ml_service.dart';

/// Anchors for the MERN port in `web/server/src/engines/`.
///
/// The web build re-implements these engines in JavaScript so the browser can
/// reach the same verdict as the phone. Nothing can assert that across two
/// languages in one process, so instead both sides pin the *same numbers* for
/// the same inputs: this file for Dart, `web/server/test/engines.test.js` for
/// Node. If either implementation drifts, one of the two fails and names the
/// scenario that moved.
///
/// The expectations below were read off the current engines rather than
/// derived by hand — they describe what the app does today, which is exactly
/// what the port has to match.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('phishing engine anchors', () {
    final repo = PhishingRepository();

    test('whitelisted bank domain is safe at confidence 96', () {
      final result = repo.analyzeUrl('https://onlinesbi.sbi');
      expect(result.isPhishing, isFalse);
      expect(result.confidence, 96);
      expect(result.triggeredRules, contains('Trusted domain whitelist'));
    });

    test('official Aadhaar portal is not flagged', () {
      expect(repo.analyzeUrl('https://myaadhaar.uidai.gov.in').isPhishing,
          isFalse);
    });

    test('IP-address login page is phishing', () {
      final result = repo.analyzeUrl('http://192.168.4.1/login.php');
      expect(result.isPhishing, isTrue);
      expect(
        result.triggeredRules.any((r) => r.contains('IP address')),
        isTrue,
      );
    });

    test('@ redirect trick is phishing', () {
      final result = repo.analyzeUrl('https://sbi.co.in@evil.tk/login');
      expect(result.isPhishing, isTrue);
      expect(result.triggeredRules.any((r) => r.contains('@')), isTrue);
    });

    test('encoding obfuscation is actually detected', () {
      // Regression: `hasEncodedTricks` tested for `%2F`/`%3A` while its only
      // caller lowercases first, so the rule scored nothing for the life of
      // the app. RFC 3986 allows either case in an escape sequence.
      final result =
          repo.analyzeUrl('https://redirect.tk/go?u=https%3A%2F%2Fevil.tk/login');
      expect(
        result.triggeredRules.any((r) => r.contains('encoding')),
        isTrue,
        reason: 'the percent-encoding rule must fire on lowercased input',
      );
    });

    test('first-party brand infrastructure is not called impersonation', () {
      // The impersonation rule matches a brand name anywhere in the URL, worth
      // 20. On its own that stays under the 35-point threshold, but the
      // encoding rule adds exactly 15 — so an OAuth redirect_uri on one of
      // these hosts lands precisely on the line. These are the real sign-in
      // and asset endpoints of brands the whitelist already protects.
      for (final url in [
        'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
            '?redirect_uri=https%3A%2F%2Fcontoso.com%2Fauth',
        'https://s3.amazonaws.com/bucket/file.pdf',
        'https://storage.googleapis.com/bucket/asset.png',
        'https://lh3.googleusercontent.com/a/photo.jpg',
      ]) {
        final result = repo.analyzeUrl(url);
        expect(result.isPhishing, isFalse, reason: url);
        expect(result.triggeredRules, contains('Trusted domain whitelist'),
            reason: url);
      }
    });

    test('a genuine brand spoof is still caught', () {
      // The whitelist additions must not have opened a hole: a lookalike host
      // that merely contains the brand string is still impersonation.
      for (final url in [
        'http://microsoftonline-verify.tk/login',
        'http://secure-amazonaws.top/signin',
      ]) {
        final result = repo.analyzeUrl(url);
        expect(result.isPhishing, isTrue, reason: url);
      }
    });

    test('confidence always lands inside the documented bands', () {
      for (final url in [
        'https://google.com',
        'http://1.2.3.4/verify-now',
        'https://ordinary-site.org/page',
      ]) {
        final c = repo.analyzeUrl(url).confidence;
        expect(c, inInclusiveRange(50, 99), reason: url);
      }
    });
  });

  group('permission analyzer anchors', () {
    const bankingTrojanPermissions = [
      'android.permission.READ_SMS',
      'android.permission.RECEIVE_SMS',
      'android.permission.SYSTEM_ALERT_WINDOW',
      'android.permission.BIND_ACCESSIBILITY_SERVICE',
      'android.permission.RECEIVE_BOOT_COMPLETED',
    ];

    test('sideloaded banking-trojan permission set scores 66 / high', () {
      final result = PermissionAnalyzer.analyze(
        bankingTrojanPermissions,
        isFromTrustedStore: false,
      );
      expect(result.riskScore, 66);
      expect(result.riskLevel, 'high');
    });

    test('the same set from a trusted store is capped at 40', () {
      final result = PermissionAnalyzer.analyze(
        bankingTrojanPermissions,
        isFromTrustedStore: true,
      );
      expect(result.riskScore, lessThanOrEqualTo(40));
      expect(result.riskScore,
          lessThan(PermissionAnalyzer.analyze(bankingTrojanPermissions).riskScore));
    });

    test('a clean app scores zero', () {
      final result =
          PermissionAnalyzer.analyze(['android.permission.INTERNET']);
      expect(result.riskScore, 0);
      expect(result.riskLevel, 'low');
    });
  });

  group('feature vector shapes', () {
    test('malware vector is 25 wide in the trained column order', () {
      final features = MalwareMlService.extractFeatures(
        permissions: const [
          'android.permission.READ_SMS',
          'android.permission.CAMERA',
        ],
        totalPermissions: 2,
        targetSdk: 33,
        minSdk: 23,
        apkSizeMb: 0,
        isSideloaded: true,
      );
      expect(features.length, MalwareMlService.kFeatureCount);
      expect(features[0], 1.0, reason: 'read_sms is column 0');
      expect(features[4], 1.0, reason: 'camera is column 4');
      expect(features[1], 0.0, reason: 'send_sms not declared');
      expect(features[20], 2.0, reason: 'total permission count');
      expect(features[24], 1.0, reason: 'sideloaded flag');
    });

    test('wifi vector is 8 wide in the trained column order', () {
      final features = WifiMlService.extractFeatures(
        rssi: -55,
        encryptionCode: 2,
        isPublic: false,
        dnsResponseMs: 40,
        frequencyGhz: 2.4,
      );
      expect(features.length, WifiMlService.kFeatureCount);
      expect(features[0], -55.0);
      expect(features[1], 2.0);
      expect(features[2], 0.0);
      expect(features[3], 40.0);
      expect(features[7], 2.4);
    });
  });
}
