import 'dart:typed_data';

import 'package:cyberguard_ai/data/services/threat_intel/safe_browsing_source.dart';
import 'package:cyberguard_ai/data/services/threat_intel/threat_intel_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal canned-response adapter so we can exercise the Safe Browsing
/// response parsing without any network access.
class _FakeAdapter implements HttpClientAdapter {
  final String body;
  final int status;
  _FakeAdapter(this.body, {this.status = 200});

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

SafeBrowsingSource sourceWith(String body, {int status = 200}) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(body, status: status);
  return SafeBrowsingSource(dio: dio, apiKey: 'test-key');
}

void main() {
  group('SafeBrowsingSource.lookup', () {
    test('empty body ⇒ safe verdict, available', () async {
      final v = await sourceWith('{}').lookup('http://example.com');
      expect(v.available, isTrue);
      expect(v.maliciousScore, 0);
      expect(v.level, ThreatLevel.safe);
    });

    test('SOCIAL_ENGINEERING match ⇒ critical, high score', () async {
      final v = await sourceWith(
        '{"matches":[{"threatType":"SOCIAL_ENGINEERING"}]}',
      ).lookup('http://phish.test');
      expect(v.maliciousScore, greaterThanOrEqualTo(90));
      expect(v.level, ThreatLevel.critical);
      expect(v.trustWeight, TrustWeights.googleSafeBrowsing);
      expect(v.reasons.first, contains('phishing'));
    });

    test('network failure ⇒ unavailable (never counts as safe)', () async {
      final v = await sourceWith('boom', status: 500).lookup('http://x.test');
      // A 500 is surfaced by Dio as a failure; verdict must be unavailable.
      expect(v.available, isFalse);
    });

    test('missing API key ⇒ unavailable', () async {
      final src = SafeBrowsingSource(dio: Dio(), apiKey: '');
      final v = await src.lookup('http://x.test');
      expect(v.available, isFalse);
    });
  });
}
