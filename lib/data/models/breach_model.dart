class BreachModel {
  final String name;
  final String title;
  final String domain;
  final String breachDate;
  final int pwnCount;
  final List<String> dataClasses;
  final String description;
  final bool isVerified;
  final bool isSensitive;
  final bool isSpamList;

  const BreachModel({
    required this.name,
    required this.title,
    required this.domain,
    required this.breachDate,
    required this.pwnCount,
    required this.dataClasses,
    required this.description,
    this.isVerified = true,
    this.isSensitive = false,
    this.isSpamList = false,
  });

  factory BreachModel.fromJson(Map<String, dynamic> json) {
    return BreachModel(
      name: json['Name'] as String? ?? '',
      title: json['Title'] as String? ?? '',
      domain: json['Domain'] as String? ?? '',
      breachDate: json['BreachDate'] as String? ?? '',
      pwnCount: json['PwnCount'] as int? ?? 0,
      dataClasses: (json['DataClasses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: _stripHtml(json['Description'] as String? ?? ''),
      isVerified: json['IsVerified'] as bool? ?? true,
      isSensitive: json['IsSensitive'] as bool? ?? false,
      isSpamList: json['IsSpamList'] as bool? ?? false,
    );
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  String get formattedPwnCount {
    if (pwnCount >= 1000000000) {
      return '${(pwnCount / 1000000000).toStringAsFixed(1)}B';
    }
    if (pwnCount >= 1000000) {
      return '${(pwnCount / 1000000).toStringAsFixed(1)}M';
    }
    if (pwnCount >= 1000) {
      return '${(pwnCount / 1000).toStringAsFixed(1)}K';
    }
    return pwnCount.toString();
  }

  String get severity {
    if (dataClasses.any((d) =>
        d.toLowerCase().contains('password') ||
        d.toLowerCase().contains('credit') ||
        d.toLowerCase().contains('bank') ||
        d.toLowerCase().contains('social security'))) {
      return 'critical';
    }
    if (dataClasses.any((d) =>
        d.toLowerCase().contains('email') ||
        d.toLowerCase().contains('phone') ||
        d.toLowerCase().contains('address'))) {
      return 'high';
    }
    return 'medium';
  }
}

class BreachCheckResult {
  final String credential;
  final String credentialType; // 'email' or 'phone'
  final bool isBreached;
  final int breachCount; // password breach count from HIBP range API
  final List<BreachModel> breaches; // from breachedaccount API
  final DateTime checkedAt;
  final String hashPrefix;
  /// `'hibp'` when results came from the paid HIBP `/breachedaccount`
  /// endpoint, `'offline'` when they came from the embedded curated
  /// breach DB (no API key configured). UI shows a clear banner in the
  /// offline case so users know the result isn't live.
  final String source;

  const BreachCheckResult({
    required this.credential,
    required this.credentialType,
    required this.isBreached,
    required this.breachCount,
    required this.breaches,
    required this.checkedAt,
    this.source = 'hibp',
    required this.hashPrefix,
  });
}
