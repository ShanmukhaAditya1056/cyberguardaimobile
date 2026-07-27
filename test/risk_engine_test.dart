import 'package:cyberguard_ai/data/services/threat_intel/risk_engine.dart';
import 'package:cyberguard_ai/data/services/threat_intel/threat_fusion_service.dart';
import 'package:cyberguard_ai/data/services/threat_intel/threat_intel_source.dart';
import 'package:flutter_test/flutter_test.dart';

FusionResult fr(int score, {bool override = false}) => FusionResult(
      unifiedScore: score,
      level: ThreatLevel.fromScore(score),
      confidence: 0.8,
      verdicts: const [],
      explanation: const [],
      overrideApplied: override,
      overrideReason: override ? 'trusted override' : null,
    );

void main() {
  const engine = RiskEngine();

  group('RiskEngine.decide', () {
    test('safe band → allow', () {
      expect(engine.decide(fr(10)), LinkAction.allow);
      expect(engine.decide(fr(30)), LinkAction.allow);
    });

    test('suspicious band → warn', () {
      expect(engine.decide(fr(31)), LinkAction.warn);
      expect(engine.decide(fr(60)), LinkAction.warn);
    });

    test('dangerous band → warn', () {
      expect(engine.decide(fr(61)), LinkAction.warn);
      expect(engine.decide(fr(80)), LinkAction.warn);
    });

    test('critical band → block', () {
      expect(engine.decide(fr(81)), LinkAction.block);
      expect(engine.decide(fr(100)), LinkAction.block);
    });

    test('override is never silently allowed', () {
      // A dangerous-level override warns; a critical-level override blocks.
      expect(engine.decide(fr(61, override: true)), LinkAction.warn);
      expect(engine.decide(fr(95, override: true)), LinkAction.block);
    });
  });

  group('RiskEngine.build', () {
    test('attaches action + metadata to the risk record', () {
      final risk = engine.build(
        url: 'http://paytm-kyc-verify.xyz/login',
        domain: 'paytm-kyc-verify.xyz',
        sourceApp: 'WhatsApp',
        fusion: fr(94),
      );
      expect(risk.action, LinkAction.block);
      expect(risk.riskScore, 94);
      expect(risk.shouldWarn, isTrue);
      expect(risk.sourceApp, 'WhatsApp');
    });
  });
}
