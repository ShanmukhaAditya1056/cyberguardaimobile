import '../../repositories/phishing_repository.dart';
import 'threat_intel_source.dart';

/// CyberGuard's own on-device verdict, expressed as a [ThreatIntelSource] so
/// it sits in the fusion engine alongside (future) external sources.
///
/// Wraps the existing [PhishingRepository] rules + ML blend — no new model,
/// no network. This is always enabled because it never leaves the device.
class LocalMlSource implements ThreatIntelSource {
  final PhishingRepository _repo;

  LocalMlSource([PhishingRepository? repo])
      : _repo = repo ?? PhishingRepository();

  @override
  String get name => 'CyberGuard AI';

  @override
  int get trustWeight => TrustWeights.cyberGuardAi;

  @override
  bool get requiresNetwork => false;

  @override
  bool get isEnabled => true;

  @override
  Future<SourceVerdict> lookup(String url) async {
    final r = _repo.analyzeUrl(url);

    // PhishingResult.confidence is confidence in the *verdict*; convert to a
    // 0-100 malicious score (high ⇒ dangerous).
    final maliciousScore =
        r.isPhishing ? r.confidence : (100 - r.confidence);

    final reasons = <String>[
      ...r.triggeredRules,
    ];
    if (reasons.isEmpty) {
      reasons.add(r.isPhishing ? 'Heuristic phishing indicators' : 'No risk indicators found');
    }

    return SourceVerdict(
      sourceName: name,
      trustWeight: trustWeight,
      maliciousScore: maliciousScore.clamp(0, 100),
      confidence: (r.confidence / 100.0).clamp(0.0, 1.0),
      reasons: reasons,
    );
  }
}
