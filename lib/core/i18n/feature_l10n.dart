import '../../data/services/predictive_risk_service.dart';
import '../../data/services/screenshot_scam_classifier.dart';
import '../../data/services/threat_intel/threat_intel_source.dart';
import '../../l10n/generated/app_localizations.dart';

/// Maps the language-agnostic enums emitted by the detection services onto
/// localized strings. Keeping this in one place means the services stay free
/// of UI/locale concerns and every screen localizes consistently.
extension FeatureL10n on AppLocalizations {
  // ── Threat taxonomy ──────────────────────────────────────────────────
  String threatLevelLabel(ThreatLevel level) => switch (level) {
        ThreatLevel.safe => threatLevelSafe,
        ThreatLevel.suspicious => threatLevelSuspicious,
        ThreatLevel.dangerous => threatLevelDangerous,
        ThreatLevel.critical => threatLevelCritical,
      };

  String threatBandLabel(ThreatLevel level) => switch (level) {
        ThreatLevel.safe => threatBandSafe,
        ThreatLevel.suspicious => threatBandSuspicious,
        ThreatLevel.dangerous => threatBandDangerous,
        ThreatLevel.critical => threatBandCritical,
      };

  // ── Predictive risk ──────────────────────────────────────────────────
  String riskBandLabel(RiskBand band) => switch (band) {
        RiskBand.low => riskBandLow,
        RiskBand.medium => riskBandMedium,
        RiskBand.high => riskBandHigh,
      };

  String forecastCategoryLabel(ForecastCategory c) => switch (c) {
        ForecastCategory.phishing => forecastPhishing,
        ForecastCategory.credentialTheft => forecastCredentialTheft,
        ForecastCategory.malware => forecastMalware,
      };

  String riskFactorTitle(RiskFactorType t) => switch (t) {
        RiskFactorType.phishing => rfPhishingTitle,
        RiskFactorType.sms => rfSmsTitle,
        RiskFactorType.wifi => rfWifiTitle,
        RiskFactorType.malware => rfMalwareTitle,
        RiskFactorType.interceptor => rfInterceptTitle,
        RiskFactorType.breach => rfBreachTitle,
        RiskFactorType.trend => rfTrendTitle,
      };

  String riskFactorDetail(RiskFactor f) => switch (f.type) {
        RiskFactorType.phishing => rfPhishingDetail(f.value),
        RiskFactorType.sms => rfSmsDetail(f.value),
        RiskFactorType.wifi => rfWifiDetail(f.value),
        RiskFactorType.malware => rfMalwareDetail(f.value),
        RiskFactorType.interceptor => rfInterceptDetail(f.value),
        RiskFactorType.breach => rfBreachDetail,
        RiskFactorType.trend => rfTrendDetail(f.value),
      };

  String recommendationText(RecommendationType r) => switch (r) {
        RecommendationType.breach => recBreach,
        RecommendationType.phishing => recPhishing,
        RecommendationType.wifi => recWifi,
        RecommendationType.malware => recMalware,
        RecommendationType.interceptor => recInterceptor,
        RecommendationType.healthy => recHealthy,
      };

  // ── Screenshot scanner ───────────────────────────────────────────────
  String scamCategoryLabel(ScamCategory c) => switch (c) {
        ScamCategory.fakeBank => scamFakeBank,
        ScamCategory.fakeUpi => scamFakeUpi,
        ScamCategory.fakeOtp => scamFakeOtp,
        ScamCategory.fakeLogin => scamFakeLogin,
        ScamCategory.fakeKyc => scamFakeKyc,
        ScamCategory.fakeLottery => scamFakeLottery,
        ScamCategory.fakeInvestment => scamFakeInvestment,
        ScamCategory.fakeSupport => scamFakeSupport,
        ScamCategory.none => scamNone,
      };

  String scamReasonText(ScamReason r) => switch (r.type) {
        ScamReasonType.categoryHit =>
          scamReasonCategory(scamCategoryLabel(r.category!), r.matched ?? ''),
        ScamReasonType.brand => scamReasonBrand(r.matched ?? ''),
        ScamReasonType.urgency => scamReasonUrgency(r.matched ?? ''),
        ScamReasonType.noIndicators => scamReasonNoIndicators,
        ScamReasonType.noText => scamReasonNoText,
      };
}
