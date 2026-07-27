/// Threat-intelligence source abstraction.
///
/// This is the contract every detection engine implements — the on-device
/// ML model, plus (opt-in, off by default) external reputation services
/// such as Google Safe Browsing, VirusTotal, OpenPhish and PhishTank.
///
/// The [ThreatFusionService] consumes a list of these and reconciles their
/// verdicts into a single [FusionResult]. Keeping the contract narrow means
/// a new source (e.g. a real SafeBrowsingSource once an API key exists) can
/// be dropped in without touching any caller.
///
/// PRIVACY: a source that performs network egress MUST honour
/// [requiresNetwork] + [isEnabled] so the orchestration layer can keep all
/// analysis on-device until the user explicitly opts in.
library;

/// Canonical 4-level threat taxonomy shared across the fusion engine and UI.
/// Maps directly onto the unified 0-100 score bands from the spec.
enum ThreatLevel {
  safe, // 0-30
  suspicious, // 31-60
  dangerous, // 61-80
  critical; // 81-100

  static ThreatLevel fromScore(int score) {
    if (score >= 81) return ThreatLevel.critical;
    if (score >= 61) return ThreatLevel.dangerous;
    if (score >= 31) return ThreatLevel.suspicious;
    return ThreatLevel.safe;
  }

  /// Inclusive lower bound of this band on the 0-100 scale.
  int get floorScore => switch (this) {
        ThreatLevel.safe => 0,
        ThreatLevel.suspicious => 31,
        ThreatLevel.dangerous => 61,
        ThreatLevel.critical => 81,
      };

  String get label => switch (this) {
        ThreatLevel.safe => 'Safe',
        ThreatLevel.suspicious => 'Suspicious',
        ThreatLevel.dangerous => 'Dangerous',
        ThreatLevel.critical => 'Critical',
      };

  bool get isMalicious =>
      this == ThreatLevel.dangerous || this == ThreatLevel.critical;
}

/// One source's opinion about a single URL/domain.
///
/// [maliciousScore] is normalised 0-100 (higher = more dangerous).
/// [confidence] is 0..1 — how sure this source is of its own verdict; the
/// fusion engine weights low-confidence opinions down.
class SourceVerdict {
  final String sourceName;

  /// Trust weight from the arbitration policy (Safe Browsing = 10 … CyberGuard
  /// AI = 7). Copied onto the verdict so the explainable report is
  /// self-contained.
  final int trustWeight;

  final int maliciousScore;
  final double confidence;
  final List<String> reasons;

  /// True when the source actually produced an opinion. A source that is
  /// disabled, offline, rate-limited or errored returns `available: false`
  /// and is excluded from fusion (it never silently counts as "safe").
  final bool available;

  /// Whether this verdict was served from the local cache rather than a
  /// fresh lookup — surfaced in the report for transparency.
  final bool fromCache;

  const SourceVerdict({
    required this.sourceName,
    required this.trustWeight,
    required this.maliciousScore,
    required this.confidence,
    required this.reasons,
    this.available = true,
    this.fromCache = false,
  });

  ThreatLevel get level => ThreatLevel.fromScore(maliciousScore);

  /// A source that didn't or couldn't respond. Excluded from fusion.
  factory SourceVerdict.unavailable(
    String sourceName,
    int trustWeight, {
    String reason = 'Source unavailable',
  }) =>
      SourceVerdict(
        sourceName: sourceName,
        trustWeight: trustWeight,
        maliciousScore: 0,
        confidence: 0,
        reasons: [reason],
        available: false,
      );

  Map<String, dynamic> toJson() => {
        'source': sourceName,
        'trustWeight': trustWeight,
        'maliciousScore': maliciousScore,
        'confidence': confidence,
        'level': level.name,
        'reasons': reasons,
        'available': available,
        'fromCache': fromCache,
      };

  factory SourceVerdict.fromJson(Map<String, dynamic> j) => SourceVerdict(
        sourceName: j['source'] as String,
        trustWeight: (j['trustWeight'] as num).toInt(),
        maliciousScore: (j['maliciousScore'] as num).toInt(),
        confidence: (j['confidence'] as num).toDouble(),
        reasons: (j['reasons'] as List).map((e) => e.toString()).toList(),
        available: j['available'] as bool? ?? true,
        fromCache: j['fromCache'] as bool? ?? false,
      );
}

/// Implemented by every detection engine the fusion layer can query.
abstract class ThreatIntelSource {
  /// Human-readable name shown in conflict / attribution reports.
  String get name;

  /// Arbitration trust weight (see [TrustWeights]).
  int get trustWeight;

  /// True if this source sends any data off-device. Network sources stay
  /// dormant until [isEnabled] flips on via explicit user consent.
  bool get requiresNetwork;

  /// Whether the user has enabled this source. On-device sources are always
  /// enabled; network sources default to `false`.
  bool get isEnabled;

  /// Produce a verdict for [url]. Implementations must never throw — wrap
  /// failures as [SourceVerdict.unavailable] so one flaky source can't sink
  /// the whole fusion.
  Future<SourceVerdict> lookup(String url);
}

/// Arbitration trust weights from the spec. Higher = more authoritative.
class TrustWeights {
  TrustWeights._();

  static const int googleSafeBrowsing = 10;
  static const int virusTotal = 9;
  static const int openPhish = 8;
  static const int phishTank = 8;
  static const int cyberGuardAi = 7;
  static const int domainReputation = 6;
  static const int sslAnalyzer = 5;
  static const int screenshotAnalyzer = 5;

  /// A source at or above this weight can override a "safe" local verdict
  /// (arbitration rule from Feature 2).
  static const int trustedOverrideThreshold = 8;
}
