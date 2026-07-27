import 'package:dio/dio.dart';

import '../../../core/config/api_keys.dart';
import '../interceptor_prefs.dart';
import 'threat_intel_source.dart';

/// Live Google Safe Browsing v4 source.
///
/// Uses the **Lookup API** (`threatMatches:find`), which sends the full URL to
/// Google. Because of that, this source is doubly gated:
///   1. an API key must be present ([ApiKeys.googleSafeBrowsing]), and
///   2. the user must have turned on cloud threat intelligence
///      ([InterceptorPrefs.cloudIntelEnabled], default OFF).
/// With the default privacy posture it never runs and no URL leaves the device.
///
/// UPGRADE PATH: the privacy-preserving **Update API** keeps a local hash-prefix
/// database and only ever sends 32-bit SHA-256 prefixes (full URL never sent),
/// mirroring the app's HIBP k-Anonymity model. Swapping the [lookup] body for
/// that flow is the planned hardening step; the [ThreatIntelSource] contract
/// stays identical so nothing else changes.
class SafeBrowsingSource implements ThreatIntelSource {
  static const _endpoint =
      'https://safebrowsing.googleapis.com/v4/threatMatches:find';

  final Dio _dio;
  final String _apiKey;

  SafeBrowsingSource({Dio? dio, String? apiKey})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            )),
        _apiKey = apiKey ?? ApiKeys.googleSafeBrowsing;

  @override
  String get name => 'Google Safe Browsing';

  @override
  int get trustWeight => TrustWeights.googleSafeBrowsing;

  @override
  bool get requiresNetwork => true;

  @override
  bool get isEnabled =>
      _apiKey.isNotEmpty && InterceptorPrefs.cloudIntelEnabled;

  @override
  Future<SourceVerdict> lookup(String url) async {
    if (_apiKey.isEmpty) {
      return SourceVerdict.unavailable(name, trustWeight,
          reason: 'No Safe Browsing API key configured');
    }
    try {
      final resp = await _dio.post(
        _endpoint,
        queryParameters: {'key': _apiKey},
        data: {
          'client': {
            'clientId': 'cyberguard-ai',
            'clientVersion': '2.0.0',
          },
          'threatInfo': {
            'threatTypes': [
              'MALWARE',
              'SOCIAL_ENGINEERING',
              'UNWANTED_SOFTWARE',
              'POTENTIALLY_HARMFUL_APPLICATION',
            ],
            'platformTypes': ['ANY_PLATFORM'],
            'threatEntryTypes': ['URL'],
            'threatEntries': [
              {'url': url},
            ],
          },
        },
      );

      final body = resp.data;
      final matches = (body is Map ? body['matches'] : null) as List?;

      if (matches == null || matches.isEmpty) {
        // Empty body ⇒ Google has no listing for this URL.
        return SourceVerdict(
          sourceName: name,
          trustWeight: trustWeight,
          maliciousScore: 0,
          confidence: 0.9,
          reasons: const ['No Safe Browsing match'],
        );
      }

      final threatType =
          (matches.first as Map)['threatType']?.toString() ?? 'THREAT';
      return SourceVerdict(
        sourceName: name,
        trustWeight: trustWeight,
        maliciousScore: _scoreFor(threatType),
        confidence: 0.97,
        reasons: ['Listed by Safe Browsing: ${_readable(threatType)}'],
      );
    } on DioException catch (e) {
      return SourceVerdict.unavailable(name, trustWeight,
          reason: 'Safe Browsing request failed: ${e.type.name}');
    } catch (e) {
      return SourceVerdict.unavailable(name, trustWeight,
          reason: 'Safe Browsing error: $e');
    }
  }

  int _scoreFor(String threatType) {
    switch (threatType) {
      case 'SOCIAL_ENGINEERING': // phishing / deceptive
      case 'MALWARE':
        return 97;
      case 'POTENTIALLY_HARMFUL_APPLICATION':
        return 88;
      case 'UNWANTED_SOFTWARE':
        return 80;
      default:
        return 85;
    }
  }

  String _readable(String threatType) {
    switch (threatType) {
      case 'SOCIAL_ENGINEERING':
        return 'deceptive / phishing site';
      case 'MALWARE':
        return 'malware';
      case 'POTENTIALLY_HARMFUL_APPLICATION':
        return 'potentially harmful application';
      case 'UNWANTED_SOFTWARE':
        return 'unwanted software';
      default:
        return threatType.toLowerCase().replaceAll('_', ' ');
    }
  }
}
