import 'package:flutter/widgets.dart';

/// Stable automation identifiers for end-to-end testing.
///
/// Flutter renders its entire UI into a single Android `FlutterView`, so an
/// Appium/UiAutomator2 driver sees one opaque surface unless the widget tree
/// publishes a semantics tree. [SemanticsProperties.identifier] is mapped by
/// the engine onto `AccessibilityNodeInfo.viewIdResourceName`, which surfaces
/// in UiAutomator2 as the element's **resource-id** — the most stable locator
/// Appium has. Every id below is therefore addressable from a test as
/// `//*[@resource-id="cg_dashboard_scan_fab"]`.
///
/// These identifiers are inert at runtime: they cost one semantics node each,
/// carry no user-visible text, and are never localised. Do not rename one
/// without updating the matching page object in `automation/pages/`.
class AutoId {
  AutoId._();

  // ── Splash ────────────────────────────────────────────────────────────
  static const splashRoot = 'cg_splash_root';
  static const splashLogo = 'cg_splash_logo';

  // ── Onboarding ────────────────────────────────────────────────────────
  static const onboardingRoot = 'cg_onboarding_root';
  static const onboardingPager = 'cg_onboarding_pager';
  static const onboardingSkip = 'cg_onboarding_skip';
  static const onboardingNext = 'cg_onboarding_next';

  // ── Login ─────────────────────────────────────────────────────────────
  // Sign-in is mandatory whenever Firebase is configured, so the suite has to
  // be able to get through this screen to reach anything else.
  static const loginRoot = 'cg_login_root';
  static const loginEmail = 'cg_login_email';
  static const loginPassword = 'cg_login_password';
  static const loginSubmit = 'cg_login_submit';
  static const loginGoogle = 'cg_login_google';
  static const loginTabSignIn = 'cg_login_tab_signin';
  static const loginTabRegister = 'cg_login_tab_register';
  static const loginError = 'cg_login_error';
  static const loginUnavailable = 'cg_login_unavailable';

  // ── Dashboard ─────────────────────────────────────────────────────────
  static const dashboardRoot = 'cg_dashboard_root';
  static const dashboardScoreRing = 'cg_dashboard_score_ring';
  static const dashboardScoreValue = 'cg_dashboard_score_value';
  static const dashboardScanFab = 'cg_dashboard_scan_fab';
  static const dashboardAlertsBtn = 'cg_dashboard_alerts_btn';
  static const dashboardSettingsBtn = 'cg_dashboard_settings_btn';
  static const dashboardModuleGrid = 'cg_dashboard_module_grid';
  static const dashboardDefenseGrid = 'cg_dashboard_defense_grid';

  /// Module tiles are generated from a list; suffix with the route slug so
  /// each tile is individually addressable (`cg_dashboard_module_phishing`).
  static String dashboardModule(String slug) => 'cg_dashboard_module_$slug';
  static String defenseTile(String slug) => 'cg_dashboard_defense_$slug';

  // ── Phishing scanner ──────────────────────────────────────────────────
  static const phishingRoot = 'cg_phishing_root';
  static const phishingTabUrl = 'cg_phishing_tab_url';
  static const phishingTabSms = 'cg_phishing_tab_sms';
  static const phishingUrlInput = 'cg_phishing_url_input';
  static const phishingPasteBtn = 'cg_phishing_paste_btn';
  static const phishingScanBtn = 'cg_phishing_scan_btn';
  static const phishingQrBtn = 'cg_phishing_qr_btn';
  static const phishingResultCard = 'cg_phishing_result_card';
  static const phishingRiskBadge = 'cg_phishing_risk_badge';
  static const phishingSmsLoadBtn = 'cg_phishing_sms_load_btn';
  static const phishingSmsScanAllBtn = 'cg_phishing_sms_scan_all_btn';
  static const phishingEmptyState = 'cg_phishing_empty_state';

  // ── QR scanner ────────────────────────────────────────────────────────
  static const qrRoot = 'cg_qr_root';
  static const qrCloseBtn = 'cg_qr_close_btn';
  static const qrGalleryBtn = 'cg_qr_gallery_btn';

  // ── Malware scanner ───────────────────────────────────────────────────
  static const malwareRoot = 'cg_malware_root';
  static const malwareScanBtn = 'cg_malware_scan_btn';
  static const malwareAppList = 'cg_malware_app_list';
  static const malwareEmptyState = 'cg_malware_empty_state';
  static String malwareAppRow(int i) => 'cg_malware_app_row_$i';

  // ── App detail ────────────────────────────────────────────────────────
  static const appDetailRoot = 'cg_app_detail_root';
  static const appDetailRiskBadge = 'cg_app_detail_risk_badge';
  static const appDetailPermList = 'cg_app_detail_perm_list';

  // ── Breach monitor ────────────────────────────────────────────────────
  static const breachRoot = 'cg_breach_root';
  static const breachEmailInput = 'cg_breach_email_input';
  static const breachCheckBtn = 'cg_breach_check_btn';
  static const breachResultCard = 'cg_breach_result_card';
  static const breachEmptyState = 'cg_breach_empty_state';

  // ── Wi-Fi scanner ─────────────────────────────────────────────────────
  static const wifiRoot = 'cg_wifi_root';
  static const wifiScanBtn = 'cg_wifi_scan_btn';
  static const wifiTrustScore = 'cg_wifi_trust_score';
  static const wifiEmptyState = 'cg_wifi_empty_state';

  // ── Alerts ────────────────────────────────────────────────────────────
  static const alertsRoot = 'cg_alerts_root';
  static const alertsList = 'cg_alerts_list';
  static const alertsClearBtn = 'cg_alerts_clear_btn';
  static const alertsEmptyState = 'cg_alerts_empty_state';
  static String alertRow(int i) => 'cg_alerts_row_$i';

  // ── Threat fusion ─────────────────────────────────────────────────────
  static const fusionRoot = 'cg_fusion_root';
  static const fusionUrlInput = 'cg_fusion_url_input';
  static const fusionScanBtn = 'cg_fusion_scan_btn';
  static const fusionVerdictCard = 'cg_fusion_verdict_card';

  // ── Arbitration log ───────────────────────────────────────────────────
  static const arbitrationRoot = 'cg_arbitration_root';
  static const arbitrationList = 'cg_arbitration_list';
  static const arbitrationEmptyState = 'cg_arbitration_empty_state';

  // ── Predictive risk ───────────────────────────────────────────────────
  static const riskRoot = 'cg_risk_root';
  static const riskForecastCard = 'cg_risk_forecast_card';
  static const riskChart = 'cg_risk_chart';

  // ── Screenshot scanner ────────────────────────────────────────────────
  static const screenshotRoot = 'cg_screenshot_root';
  static const screenshotPickBtn = 'cg_screenshot_pick_btn';
  static const screenshotVerdictCard = 'cg_screenshot_verdict_card';

  // ── Link interceptor warning ──────────────────────────────────────────
  static const interceptRoot = 'cg_intercept_root';
  static const interceptProceedBtn = 'cg_intercept_proceed_btn';
  static const interceptBlockBtn = 'cg_intercept_block_btn';

  // ── Settings ──────────────────────────────────────────────────────────
  static const settingsRoot = 'cg_settings_root';
  static const settingsRealTimeAlerts = 'cg_settings_realtime_alerts';
  static const settingsClipboardScan = 'cg_settings_clipboard_scan';
  static const settingsWifiAutoScan = 'cg_settings_wifi_auto_scan';
  static const settingsLiveSmsGuard = 'cg_settings_live_sms_guard';
  static const settingsLinkInterceptor = 'cg_settings_link_interceptor';
  static const settingsCloudIntel = 'cg_settings_cloud_intel';
  static const settingsLinkHistory = 'cg_settings_link_history';
  static const settingsLanguage = 'cg_settings_language';
  static const settingsScanFrequency = 'cg_settings_scan_frequency';
  static const settingsHibpInput = 'cg_settings_hibp_input';
  static const settingsHibpSave = 'cg_settings_hibp_save';
  static const settingsHibpClear = 'cg_settings_hibp_clear';
  static const settingsExportPdf = 'cg_settings_export_pdf';
  static const settingsExportCsv = 'cg_settings_export_csv';
  static const settingsReset = 'cg_settings_reset';
  static const settingsVersion = 'cg_settings_version';

  // ── Shared widgets ────────────────────────────────────────────────────
  static const backBtn = 'cg_back_btn';
  static const errorState = 'cg_error_state';
  static const loadingShimmer = 'cg_loading_shimmer';
}

/// Attaches a stable automation [id] to [child] for Appium/UiAutomator2.
///
/// Set [container] for tappable targets: it forces the wrapper to own a
/// semantics node with real bounds, so a driver can resolve the resource-id
/// to a rect and tap it. Leave it false for pure read targets (text, badges)
/// so the node merges naturally and screen readers are unaffected.
Widget autoId(String id, Widget child, {bool container = false}) {
  return Semantics(
    identifier: id,
    container: container,
    child: child,
  );
}
