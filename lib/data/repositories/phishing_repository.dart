import 'package:uuid/uuid.dart';
import '../../core/constants/threat_patterns.dart';
import '../../core/utils/shap_explainer.dart';
import '../../core/utils/url_extractor.dart';
import '../models/alert_model.dart';
import '../models/scan_result_model.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/phishing_ml_service.dart';

class PhishingResult {
  final String url;
  final bool isPhishing;
  final int confidence;
  final List<ShapReason> shapReasons;
  final List<String> triggeredKeywords;
  final List<String> triggeredRules;

  const PhishingResult({
    required this.url,
    required this.isPhishing,
    required this.confidence,
    required this.shapReasons,
    required this.triggeredKeywords,
    required this.triggeredRules,
  });

  String get verdict => isPhishing ? 'Phishing' : 'Safe';
}

class PhishingRepository {
  static const _uuid = Uuid();
  static final PhishingMlService _ml = PhishingMlService();
  static bool _mlInitTried = false;

  /// Eagerly load the bundled .tflite model if present. Safe to call at
  /// app start — if the asset is missing, the service simply stays
  /// unavailable and the rules engine handles every URL.
  static Future<void> warmUpMl() async {
    if (_mlInitTried) return;
    _mlInitTried = true;
    await _ml.load();
  }

  /// One-line diagnostic for the dev console or Settings page:
  /// "ready" when the .tflite is loaded and inference is hot,
  /// otherwise the load-error string from the service.
  static String get runtimeMlStatus {
    if (_ml.isReady) return 'ready';
    return _ml.loadError ?? 'not initialised — call warmUpMl()';
  }

  /// Blends the rules engine score with the ML model probability when
  /// available. The rules engine remains the source of truth for SHAP
  /// reasoning so the UI always has something to explain.
  PhishingResult _withMlBoost(PhishingResult rules, String url) {
    if (!_ml.isReady) return rules;
    final prob = _ml.predict(url);
    if (prob == null) return rules;

    // Weighted blend: 60 % rules / 40 % model.
    final rulesProb = rules.isPhishing
        ? rules.confidence / 100.0
        : 1 - rules.confidence / 100.0;
    final blended = (0.6 * rulesProb) + (0.4 * prob);
    final isPhishing = blended >= 0.5;
    final confidence = isPhishing
        ? (blended * 100).round().clamp(50, 99)
        : ((1 - blended) * 100).round().clamp(50, 99);

    return PhishingResult(
      url: rules.url,
      isPhishing: isPhishing,
      confidence: confidence,
      shapReasons: rules.shapReasons,
      triggeredKeywords: rules.triggeredKeywords,
      triggeredRules: [
        ...rules.triggeredRules,
        'On-device ML model (p=${prob.toStringAsFixed(2)})',
      ],
    );
  }

  PhishingResult analyzeUrl(String rawUrl) {
    final url = UrlExtractor.normalize(rawUrl);
    final domain = UrlExtractor.getDomain(url) ?? '';
    final tld = UrlExtractor.getTld(domain) ?? '';

    final triggeredKeywords = <String>[];
    final triggeredRules = <String>[];
    double score = 0;

    // 1. Whitelist check (strongest safe signal)
    final isWhitelisted = ThreatPatterns.safeDomains.any((d) =>
        domain == d || domain.endsWith('.$d'));

    if (isWhitelisted) {
      return PhishingResult(
        url: url,
        isPhishing: false,
        confidence: 96,
        shapReasons: ShapExplainer.explainUrl(
          url,
          isSuspiciousTld: false,
          hasKeyword: false,
          keywords: [],
          isIpAddress: false,
          isWhitelisted: true,
          hasEncoding: false,
          isLong: false,
          subdomainCount: 0,
          isMismatch: false,
        ),
        triggeredKeywords: [],
        triggeredRules: ['Trusted domain whitelist'],
      );
    }

    // 2. IP address URL
    final isIpUrl = UrlExtractor.isIpAddress(url);
    if (isIpUrl) {
      score += 35;
      triggeredRules.add('IP address instead of domain');
    }

    // 3. Suspicious TLD
    final isSuspiciousTld = ThreatPatterns.suspiciousTlds
        .any((t) => domain.endsWith(t) || tld == t);
    if (isSuspiciousTld) {
      score += 25;
      triggeredRules.add('Suspicious TLD: $tld');
    }

    // 4. Phishing keywords in URL
    final urlLower = url.toLowerCase();
    for (final keyword in ThreatPatterns.indianPhishingKeywords) {
      if (urlLower.contains(keyword)) {
        triggeredKeywords.add(keyword);
        score += 15;
        break;
      }
    }
    if (triggeredKeywords.isNotEmpty) {
      triggeredRules.add('Phishing keywords: ${triggeredKeywords.take(3).join(", ")}');
    }

    // 5. URL encoding tricks
    final hasEncoding = UrlExtractor.hasEncodedTricks(url);
    if (hasEncoding) {
      score += 15;
      triggeredRules.add('URL encoding obfuscation');
    }

    // 6. Excessive length
    final isLong = UrlExtractor.isExcessivelyLong(url);
    if (isLong) {
      score += 8;
      triggeredRules.add('Excessively long URL');
    }

    // 7. Subdomain count
    final subCount = UrlExtractor.subdomainCount(domain);
    if (subCount > 2) {
      score += 12;
      triggeredRules.add('Excessive subdomains ($subCount)');
    }

    // 8. Brand impersonation check
    const brands = [
      'paytm', 'phonepe', 'sbi', 'hdfc', 'icici', 'axis',
      'amazon', 'flipkart', 'google', 'apple', 'microsoft',
      'jio', 'airtel', 'aadhaar', 'npci', 'upi',
    ];
    bool isMismatch = false;
    for (final brand in brands) {
      if (urlLower.contains(brand) &&
          !ThreatPatterns.safeDomains.any((d) => domain == d || domain.endsWith('.$d'))) {
        isMismatch = true;
        score += 20;
        triggeredRules.add('Impersonates $brand brand');
        break;
      }
    }

    // 9. Suspicious URL patterns
    for (final pattern in ThreatPatterns.suspiciousUrlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(url)) {
        score += 10;
        triggeredRules.add('Suspicious URL pattern');
        break;
      }
    }

    // 10. @ symbol in URL — browser ignores everything before @,
    // classic redirect trick. Extremely strong phishing signal.
    if (url.contains('@')) {
      score += 30;
      triggeredRules.add('"@" symbol used to hide the real domain');
    }

    // 11. Excessive hyphens in domain (e.g. secure-login-hdfc-india-verify)
    final hyphenCount = '-'.allMatches(domain).length;
    if (hyphenCount >= 3) {
      score += hyphenCount * 6;
      triggeredRules.add('Excessive hyphens in domain ($hyphenCount)');
    }

    // 12. Excessive overall URL length
    if (url.length > 100) {
      score += 10;
      triggeredRules.add('Unusually long URL (${url.length} chars)');
    }

    // Clamp score to 0-100
    score = score.clamp(0, 100);
    final isPhishing = score >= 35;

    // Confidence: phishing confidence = score, safe confidence = 100 - score
    int confidence;
    if (isPhishing) {
      confidence = (50 + score * 0.5).round().clamp(50, 99);
    } else {
      confidence = (100 - score).round().clamp(60, 99);
    }

    final shapReasons = ShapExplainer.explainUrl(
      url,
      isSuspiciousTld: isSuspiciousTld,
      hasKeyword: triggeredKeywords.isNotEmpty,
      keywords: triggeredKeywords,
      isIpAddress: isIpUrl,
      isWhitelisted: false,
      hasEncoding: hasEncoding,
      isLong: isLong,
      subdomainCount: subCount,
      isMismatch: isMismatch,
    );

    final rulesResult = PhishingResult(
      url: url,
      isPhishing: isPhishing,
      confidence: confidence,
      shapReasons: shapReasons,
      triggeredKeywords: triggeredKeywords,
      triggeredRules: triggeredRules,
    );

    return _withMlBoost(rulesResult, url);
  }

  Future<PhishingResult> scanAndSave(String url) async {
    final result = analyzeUrl(url);
    final id = _uuid.v4();

    final scanModel = ScanResultModel(
      id: id,
      type: 'phishing',
      input: url,
      verdict: result.isPhishing ? 'phishing' : 'safe',
      confidence: result.confidence,
      shapReasons: result.shapReasons.map((s) => s.feature).toList(),
      timestamp: DateTime.now(),
    );
    await HiveService.saveScanResult(scanModel);

    if (result.isPhishing) {
      final alert = AlertModel(
        id: _uuid.v4(),
        type: 'critical',
        title: 'Phishing URL Detected',
        description: 'Dangerous link: ${url.length > 60 ? url.substring(0, 60) + '...' : url}',
        module: 'phishing',
        timestamp: DateTime.now(),
      );
      await HiveService.saveAlert(alert);
      await NotificationService.showPhishingDetected(url);
    }

    return result;
  }

  List<ScanResultModel> getHistory() {
    return HiveService.getScanResults(type: 'phishing');
  }

  Future<void> deleteHistory(String id) async {
    await HiveService.deleteScanResult(id);
  }
}
