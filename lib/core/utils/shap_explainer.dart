class ShapReason {
  final String feature;
  final double contribution; // 0.0 to 1.0
  final bool positive; // true = phishing indicator, false = safe indicator

  const ShapReason({
    required this.feature,
    required this.contribution,
    required this.positive,
  });
}

class ShapExplainer {
  ShapExplainer._();

  /// Generate SHAP-like explanations for phishing URL detection
  static List<ShapReason> explainUrl(
    String url, {
    required bool isSuspiciousTld,
    required bool hasKeyword,
    required List<String> keywords,
    required bool isIpAddress,
    required bool isWhitelisted,
    required bool hasEncoding,
    required bool isLong,
    required int subdomainCount,
    required bool isMismatch,
  }) {
    final reasons = <ShapReason>[];

    if (isWhitelisted) {
      reasons.add(const ShapReason(
        feature: 'Trusted domain whitelist match',
        contribution: 0.85,
        positive: false,
      ));
      return reasons;
    }

    if (isIpAddress) {
      reasons.add(const ShapReason(
        feature: 'IP address used instead of domain',
        contribution: 0.9,
        positive: true,
      ));
    }

    if (isSuspiciousTld) {
      reasons.add(const ShapReason(
        feature: 'Suspicious top-level domain',
        contribution: 0.75,
        positive: true,
      ));
    }

    if (hasKeyword && keywords.isNotEmpty) {
      reasons.add(ShapReason(
        feature: 'Phishing keywords: ${keywords.take(3).join(", ")}',
        contribution: 0.8,
        positive: true,
      ));
    }

    if (hasEncoding) {
      reasons.add(const ShapReason(
        feature: 'URL encoding tricks detected',
        contribution: 0.65,
        positive: true,
      ));
    }

    if (isLong) {
      reasons.add(const ShapReason(
        feature: 'Excessively long URL (obfuscation)',
        contribution: 0.45,
        positive: true,
      ));
    }

    if (subdomainCount > 2) {
      reasons.add(ShapReason(
        feature: 'Excessive subdomains ($subdomainCount)',
        contribution: 0.5,
        positive: true,
      ));
    }

    if (isMismatch) {
      reasons.add(const ShapReason(
        feature: 'Domain name impersonates trusted brand',
        contribution: 0.88,
        positive: true,
      ));
    }

    if (reasons.isEmpty) {
      reasons.add(const ShapReason(
        feature: 'No known threat patterns detected',
        contribution: 0.2,
        positive: false,
      ));
    }

    // Sort by contribution descending
    reasons.sort((a, b) => b.contribution.compareTo(a.contribution));
    return reasons.take(5).toList();
  }
}
