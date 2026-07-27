import 'package:cyberguard_ai/data/services/threat_intel/threat_fusion_service.dart';
import 'package:cyberguard_ai/data/services/threat_intel/threat_intel_source.dart';
import 'package:flutter_test/flutter_test.dart';

SourceVerdict v({
  required String name,
  required int weight,
  required int score,
  required double conf,
  bool available = true,
}) =>
    SourceVerdict(
      sourceName: name,
      trustWeight: weight,
      maliciousScore: score,
      confidence: conf,
      reasons: ['test'],
      available: available,
    );

void main() {
  const fusion = ThreatFusionService();

  group('ThreatFusionService.fuse', () {
    test('no available sources → safe, zero score', () {
      final r = fusion.fuse([]);
      expect(r.unifiedScore, 0);
      expect(r.level, ThreatLevel.safe);
      expect(r.confidence, 0);
    });

    test('unavailable sources are excluded', () {
      final r = fusion.fuse([
        v(name: 'A', weight: 10, score: 90, conf: 0.9, available: false),
      ]);
      expect(r.verdicts, isEmpty);
      expect(r.level, ThreatLevel.safe);
    });

    test('single safe local verdict stays safe', () {
      final r = fusion.fuse([
        v(name: 'CyberGuard AI', weight: 7, score: 10, conf: 0.9),
      ]);
      expect(r.level, ThreatLevel.safe);
      expect(r.overrideApplied, isFalse);
    });

    test(
        'trusted source overrides a safe local verdict (Feature 2 arbitration)',
        () {
      final r = fusion.fuse([
        v(name: 'CyberGuard AI', weight: TrustWeights.cyberGuardAi, score: 10, conf: 0.9),
        v(name: 'Google Safe Browsing', weight: TrustWeights.googleSafeBrowsing, score: 95, conf: 0.95),
      ]);
      expect(r.overrideApplied, isTrue);
      expect(r.unifiedScore, greaterThanOrEqualTo(ThreatLevel.critical.floorScore));
      expect(r.level, ThreatLevel.critical);
      expect(r.overrideReason, contains('Google Safe Browsing'));
    });

    test('low-trust source cannot trigger an override', () {
      final r = fusion.fuse([
        v(name: 'CyberGuard AI', weight: 7, score: 5, conf: 0.95),
        v(name: 'SSL Analyzer', weight: TrustWeights.sslAnalyzer, score: 95, conf: 0.95),
      ]);
      // SSL Analyzer weight (5) is below the override threshold (8).
      expect(r.overrideApplied, isFalse);
    });

    test('disagreement between sources is flagged as a conflict', () {
      final r = fusion.fuse([
        v(name: 'CyberGuard AI', weight: 7, score: 80, conf: 0.8),
        v(name: 'Domain Reputation', weight: 6, score: 5, conf: 0.7),
      ]);
      expect(r.hasConflict, isTrue);
    });

    test('agreement raises confidence above a lone verdict', () {
      final agree = fusion.fuse([
        v(name: 'A', weight: 7, score: 85, conf: 0.8),
        v(name: 'B', weight: 8, score: 90, conf: 0.8),
      ]);
      final conflict = fusion.fuse([
        v(name: 'A', weight: 7, score: 85, conf: 0.8),
        v(name: 'B', weight: 6, score: 5, conf: 0.8),
      ]);
      expect(agree.confidence, greaterThan(conflict.confidence));
    });
  });
}
