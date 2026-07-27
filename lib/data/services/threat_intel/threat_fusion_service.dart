import 'threat_intel_source.dart';

/// The explainable output of arbitration — Feature 4 (Threat Fusion) and
/// Feature 2 (Detection Disagreement) both surface this.
class FusionResult {
  /// Unified 0-100 threat score.
  final int unifiedScore;

  /// Band the [unifiedScore] falls into.
  final ThreatLevel level;

  /// 0..1 — how much the contributing sources agree. Low confidence ⇒ the UI
  /// should hedge ("possible") rather than assert.
  final double confidence;

  /// Every source's verdict that participated (available ones only), kept for
  /// source-attribution UI.
  final List<SourceVerdict> verdicts;

  /// True when a trusted source overrode a low local score (the arbitration
  /// rule). [overrideReason] explains why.
  final bool overrideApplied;
  final String? overrideReason;

  /// True when sources materially disagreed (e.g. one says safe, another says
  /// dangerous) — drives the "Detection Conflict Found" UI.
  final bool hasConflict;

  /// Plain-language bullet points assembled from the contributing sources.
  final List<String> explanation;

  const FusionResult({
    required this.unifiedScore,
    required this.level,
    required this.confidence,
    required this.verdicts,
    required this.explanation,
    this.overrideApplied = false,
    this.overrideReason,
    this.hasConflict = false,
  });

  bool get isMalicious => level.isMalicious;

  /// Sources that flagged this as malicious, highest trust first — used for
  /// "Blocked · trusted threat intelligence override" attribution.
  List<SourceVerdict> get flaggingSources => verdicts
      .where((v) => v.level.isMalicious)
      .toList()
    ..sort((a, b) => b.trustWeight.compareTo(a.trustWeight));

  Map<String, dynamic> toJson() => {
        'unifiedScore': unifiedScore,
        'level': level.name,
        'confidence': confidence,
        'overrideApplied': overrideApplied,
        'overrideReason': overrideReason,
        'hasConflict': hasConflict,
        'explanation': explanation,
        'verdicts': verdicts.map((v) => v.toJson()).toList(),
      };

  factory FusionResult.fromJson(Map<String, dynamic> j) => FusionResult(
        unifiedScore: (j['unifiedScore'] as num).toInt(),
        level: ThreatLevel.values.byName(j['level'] as String),
        confidence: (j['confidence'] as num).toDouble(),
        verdicts: (j['verdicts'] as List)
            .map((e) =>
                SourceVerdict.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        explanation:
            (j['explanation'] as List).map((e) => e.toString()).toList(),
        overrideApplied: j['overrideApplied'] as bool? ?? false,
        overrideReason: j['overrideReason'] as String?,
        hasConflict: j['hasConflict'] as bool? ?? false,
      );
}

/// Reconciles multiple [ThreatIntelSource] verdicts into one [FusionResult].
///
/// Algorithm (Features 2 + 4):
///   1. Query all enabled sources in parallel; drop unavailable ones.
///   2. Trust- and confidence-weighted mean of each source's malicious score.
///   3. Arbitration override: if any source with trustWeight ≥
///      [TrustWeights.trustedOverrideThreshold] reports a malicious verdict
///      with sufficient confidence, the final score is floored into the
///      Dangerous/Critical band even if the local model said "safe".
///   4. Conflict + confidence calculation for the explainable report.
///
/// Stateless and pure given its inputs, so it is trivially unit-testable.
class ThreatFusionService {
  /// A trusted source must be at least this sure before it can override.
  static const double kOverrideMinConfidence = 0.6;

  /// And report at least this malicious score to trigger an override.
  static const int kOverrideMinScore = 70;

  const ThreatFusionService();

  /// Query [sources] for [url] and fuse the results.
  Future<FusionResult> analyze(
    String url,
    List<ThreatIntelSource> sources,
  ) async {
    final enabled = sources.where((s) => s.isEnabled).toList();
    final results = await Future.wait(
      enabled.map((s) async {
        try {
          return await s.lookup(url);
        } catch (e) {
          return SourceVerdict.unavailable(s.name, s.trustWeight,
              reason: 'Lookup error: $e');
        }
      }),
    );
    return fuse(results);
  }

  /// Pure fusion over already-collected verdicts. Exposed separately so tests
  /// (and the arbitration UI) can drive it with fixed inputs.
  FusionResult fuse(List<SourceVerdict> all) {
    final verdicts = all.where((v) => v.available).toList();

    if (verdicts.isEmpty) {
      return const FusionResult(
        unifiedScore: 0,
        level: ThreatLevel.safe,
        confidence: 0,
        verdicts: [],
        explanation: ['No detection source was available.'],
      );
    }

    // ── 1. Trust × confidence weighted mean ──────────────────────────────
    double weightedSum = 0;
    double weightTotal = 0;
    for (final v in verdicts) {
      final w = v.trustWeight * v.confidence;
      weightedSum += w * v.maliciousScore;
      weightTotal += w;
    }
    var score = weightTotal == 0 ? 0 : (weightedSum / weightTotal).round();

    // ── 2. Arbitration override ──────────────────────────────────────────
    bool overrideApplied = false;
    String? overrideReason;
    final trustedFlags = verdicts.where((v) =>
        v.trustWeight >= TrustWeights.trustedOverrideThreshold &&
        v.maliciousScore >= kOverrideMinScore &&
        v.confidence >= kOverrideMinConfidence);

    if (trustedFlags.isNotEmpty) {
      final top = trustedFlags.reduce(
          (a, b) => a.trustWeight >= b.trustWeight ? a : b);
      // Floor into at least Dangerous; Critical if the flag itself is critical.
      final flooredBand = top.level == ThreatLevel.critical
          ? ThreatLevel.critical
          : ThreatLevel.dangerous;
      if (score < flooredBand.floorScore) {
        score = flooredBand.floorScore;
        overrideApplied = true;
        overrideReason =
            'Trusted threat intelligence override — ${top.sourceName} '
            '(trust ${top.trustWeight}) flagged this as ${top.level.label}.';
      }
    }

    score = score.clamp(0, 100);
    final level = ThreatLevel.fromScore(score);

    // ── 3. Conflict detection ────────────────────────────────────────────
    final maliciousVerdicts = verdicts.where((v) => v.level.isMalicious);
    final safeVerdicts = verdicts.where((v) => !v.level.isMalicious);
    final hasConflict =
        maliciousVerdicts.isNotEmpty && safeVerdicts.isNotEmpty;

    // ── 4. Confidence: agreement-weighted. Sources that agree with the final
    //       verdict raise confidence; dissenters lower it. ─────────────────
    final agreeing = verdicts
        .where((v) => v.level.isMalicious == level.isMalicious)
        .toList();
    final agreementRatio = agreeing.length / verdicts.length;
    final meanConfidence = verdicts.isEmpty
        ? 0.0
        : verdicts.map((v) => v.confidence).reduce((a, b) => a + b) /
            verdicts.length;
    var confidence = (agreementRatio * 0.6) + (meanConfidence * 0.4);
    if (overrideApplied) {
      // A trusted override is high-confidence by construction.
      confidence = confidence.clamp(0.75, 1.0);
    }

    // ── 5. Explainable report ────────────────────────────────────────────
    final explanation = <String>[];
    if (overrideApplied && overrideReason != null) {
      explanation.add(overrideReason);
    }
    for (final v in verdicts..sort((a, b) => b.trustWeight.compareTo(a.trustWeight))) {
      final headline = v.reasons.isNotEmpty ? v.reasons.first : v.level.label;
      explanation.add('${v.sourceName}: ${v.level.label} — $headline');
    }

    return FusionResult(
      unifiedScore: score,
      level: level,
      confidence: confidence.clamp(0.0, 1.0),
      verdicts: verdicts,
      explanation: explanation,
      overrideApplied: overrideApplied,
      overrideReason: overrideReason,
      hasConflict: hasConflict,
    );
  }
}
