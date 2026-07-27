/// Feature 5 — Predictive Risk Engine.
///
/// Pure, dependency-free scoring so it is fully unit-testable. The repository
/// gathers [RiskSignals] from on-device history (scans, alerts, Wi-Fi, app
/// analysis, breach status) and feeds them here; nothing leaves the device.
///
/// Unlike the *security score* (where higher = safer), the **personal risk
/// score** is inverted: higher = more likely to be attacked.
library;

/// Behavioural + environmental signals over the recent window (e.g. 7 days).
class RiskSignals {
  final int phishingHits; // phishing URLs flagged
  final int suspiciousSms; // phishing SMS detections
  final int unknownWifi; // low-trust / public / unencrypted networks used
  final int malwareDetections; // high/critical app scans
  final int interceptorBlocks; // links blocked by the interceptor
  final bool breachActive; // credentials found in a breach
  final int securityScoreDelta; // change in security score (− = worsening)

  const RiskSignals({
    this.phishingHits = 0,
    this.suspiciousSms = 0,
    this.unknownWifi = 0,
    this.malwareDetections = 0,
    this.interceptorBlocks = 0,
    this.breachActive = false,
    this.securityScoreDelta = 0,
  });
}

enum RiskBand {
  low,
  medium,
  high;

  static RiskBand fromScore(int score) {
    if (score >= 67) return RiskBand.high;
    if (score >= 34) return RiskBand.medium;
    return RiskBand.low;
  }
}

/// Kinds of contributing risk factors. The UI maps these to localized text;
/// the service stays language-agnostic.
enum RiskFactorType {
  phishing,
  sms,
  wifi,
  malware,
  interceptor,
  breach,
  trend,
}

/// Attack categories surfaced in the forecast (spec's three categories).
enum ForecastCategory { phishing, credentialTheft, malware }

/// Recommendation kinds, localized by the UI.
enum RecommendationType { breach, phishing, wifi, malware, interceptor, healthy }

/// One contributing reason behind the risk score. [value] is the count/points
/// the UI interpolates into the localized detail line.
class RiskFactor {
  final RiskFactorType type;
  final int value;
  final int contribution; // points added to the risk score
  const RiskFactor(this.type, this.value, this.contribution);
}

/// A forward-looking likelihood for one attack category.
class ThreatForecast {
  final ForecastCategory category;
  final RiskBand likelihood;
  const ThreatForecast(this.category, this.likelihood);
}

class RiskAssessment {
  final int riskScore; // 0-100, higher = more at risk
  final RiskBand band;
  final List<RiskFactor> factors;
  final List<ThreatForecast> forecast;
  final List<RecommendationType> recommendations;
  final DateTime generatedAt;

  const RiskAssessment({
    required this.riskScore,
    required this.band,
    required this.factors,
    required this.forecast,
    required this.recommendations,
    required this.generatedAt,
  });
}

class PredictiveRiskService {
  const PredictiveRiskService();

  // Per-signal caps (max points each can add to the 0-100 risk score).
  static const int _capPhishing = 22;
  static const int _capSms = 14;
  static const int _capWifi = 14;
  static const int _capMalware = 24;
  static const int _capInterceptor = 10;
  static const int _capBreach = 20;
  static const int _capTrend = 10;

  RiskAssessment assess(RiskSignals s) {
    final factors = <RiskFactor>[];
    int score = 0;

    void add(int points, RiskFactorType type, int value) {
      if (points <= 0) return;
      score += points;
      factors.add(RiskFactor(type, value, points));
    }

    add((s.phishingHits * 8).clamp(0, _capPhishing), RiskFactorType.phishing,
        s.phishingHits);
    add((s.suspiciousSms * 5).clamp(0, _capSms), RiskFactorType.sms,
        s.suspiciousSms);
    add((s.unknownWifi * 5).clamp(0, _capWifi), RiskFactorType.wifi,
        s.unknownWifi);
    add((s.malwareDetections * 12).clamp(0, _capMalware),
        RiskFactorType.malware, s.malwareDetections);
    add((s.interceptorBlocks * 5).clamp(0, _capInterceptor),
        RiskFactorType.interceptor, s.interceptorBlocks);
    if (s.breachActive) {
      add(_capBreach, RiskFactorType.breach, 0);
    }
    if (s.securityScoreDelta < 0) {
      add((-s.securityScoreDelta).clamp(0, _capTrend), RiskFactorType.trend,
          -s.securityScoreDelta);
    }

    score = score.clamp(0, 100);
    final band = RiskBand.fromScore(score);

    return RiskAssessment(
      riskScore: score,
      band: band,
      factors: factors..sort((a, b) => b.contribution.compareTo(a.contribution)),
      forecast: _forecast(s),
      recommendations: _recommendations(s),
      generatedAt: DateTime.now(),
    );
  }

  List<ThreatForecast> _forecast(RiskSignals s) {
    RiskBand band(int weight) => RiskBand.fromScore(weight.clamp(0, 100));
    final phishing = band(s.phishingHits * 22 +
        s.suspiciousSms * 14 +
        s.interceptorBlocks * 12);
    final credential = band((s.breachActive ? 45 : 0) +
        s.phishingHits * 12 +
        s.unknownWifi * 10);
    final malware =
        band(s.malwareDetections * 30 + (s.unknownWifi > 0 ? 10 : 0));
    return [
      ThreatForecast(ForecastCategory.phishing, phishing),
      ThreatForecast(ForecastCategory.credentialTheft, credential),
      ThreatForecast(ForecastCategory.malware, malware),
    ];
  }

  List<RecommendationType> _recommendations(RiskSignals s) {
    final recs = <RecommendationType>[];
    if (s.breachActive) recs.add(RecommendationType.breach);
    if (s.phishingHits > 0 || s.suspiciousSms > 0) {
      recs.add(RecommendationType.phishing);
    }
    if (s.unknownWifi > 0) recs.add(RecommendationType.wifi);
    if (s.malwareDetections > 0) recs.add(RecommendationType.malware);
    if (s.interceptorBlocks > 0) recs.add(RecommendationType.interceptor);
    if (recs.isEmpty) recs.add(RecommendationType.healthy);
    return recs;
  }
}
