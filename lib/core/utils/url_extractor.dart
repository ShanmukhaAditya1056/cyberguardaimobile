import '../constants/threat_patterns.dart';

class UrlExtractor {
  UrlExtractor._();

  static final _urlRegex = RegExp(
    ThreatPatterns.urlPattern,
    caseSensitive: false,
    multiLine: true,
  );

  /// Extract all URLs from a text string
  static List<String> extractUrls(String text) {
    if (text.isEmpty) return [];
    final matches = _urlRegex.allMatches(text);
    return matches
        .map((m) => m.group(0)!.trim())
        .where((url) => url.length > 4)
        .toList();
  }

  /// Get domain from URL
  static String? getDomain(String url) {
    try {
      String cleaned = url;
      if (!cleaned.startsWith('http')) {
        cleaned = 'https://$cleaned';
      }
      final uri = Uri.tryParse(cleaned);
      if (uri == null) return null;
      String host = uri.host.toLowerCase();
      if (host.startsWith('www.')) host = host.substring(4);
      return host;
    } catch (_) {
      return null;
    }
  }

  /// Get TLD from domain
  static String? getTld(String domain) {
    final parts = domain.split('.');
    if (parts.length < 2) return null;
    return '.${parts.last}';
  }

  /// Normalize URL for analysis
  static String normalize(String url) {
    String u = url.trim().toLowerCase();
    if (!u.startsWith('http')) u = 'https://$u';
    return u;
  }

  /// Check if URL has suspicious encoded characters
  static bool hasEncodedTricks(String url) {
    return url.contains('%2F') ||
        url.contains('%3A') ||
        url.contains('@') ||
        url.contains('//') && url.indexOf('//') != url.lastIndexOf('//');
  }

  /// Check if URL uses IP address instead of domain
  static bool isIpAddress(String url) {
    final ipPattern = RegExp(r'https?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}');
    return ipPattern.hasMatch(url);
  }

  /// Count subdomains (many subdomains can indicate phishing)
  static int subdomainCount(String domain) {
    return domain.split('.').length - 2;
  }

  /// Check if URL is very long (phishing indicator)
  static bool isExcessivelyLong(String url) {
    return url.length > 100;
  }
}
