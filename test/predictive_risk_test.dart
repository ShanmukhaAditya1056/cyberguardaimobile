import 'package:cyberguard_ai/data/services/predictive_risk_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svc = PredictiveRiskService();

  group('PredictiveRiskService.assess', () {
    test('no signals → low risk, zero score', () {
      final a = svc.assess(const RiskSignals());
      expect(a.riskScore, 0);
      expect(a.band, RiskBand.low);
      expect(a.factors, isEmpty);
      expect(a.recommendations, isNotEmpty);
    });

    test('breach + phishing + malware → high risk', () {
      final a = svc.assess(const RiskSignals(
        phishingHits: 3,
        malwareDetections: 2,
        breachActive: true,
        unknownWifi: 2,
      ));
      expect(a.riskScore, greaterThanOrEqualTo(67));
      expect(a.band, RiskBand.high);
      // Highest-contributing factor is listed first.
      expect(a.factors.first.contribution,
          greaterThanOrEqualTo(a.factors.last.contribution));
    });

    test('score is capped at 100', () {
      final a = svc.assess(const RiskSignals(
        phishingHits: 99,
        suspiciousSms: 99,
        unknownWifi: 99,
        malwareDetections: 99,
        interceptorBlocks: 99,
        breachActive: true,
        securityScoreDelta: -99,
      ));
      expect(a.riskScore, 100);
    });

    test('breach drives credential-theft forecast up', () {
      final a = svc.assess(const RiskSignals(breachActive: true, phishingHits: 2));
      final credential = a.forecast
          .firstWhere((f) => f.category == ForecastCategory.credentialTheft);
      expect(credential.likelihood, isNot(RiskBand.low));
    });

    test('forecast always has the three spec categories', () {
      final a = svc.assess(const RiskSignals(malwareDetections: 1));
      expect(a.forecast.map((f) => f.category), containsAll(const [
        ForecastCategory.phishing,
        ForecastCategory.credentialTheft,
        ForecastCategory.malware,
      ]));
    });
  });
}
