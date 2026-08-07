// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CyberGuard AI';

  @override
  String get appTagline => 'Intelligent Security Assistant';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get alerts => 'Alerts';

  @override
  String get settings => 'Settings';

  @override
  String get phishingScanner => 'Phishing Scanner';

  @override
  String get appScanner => 'App Scanner';

  @override
  String get breachMonitor => 'Breach Monitor';

  @override
  String get wifiScanner => 'Wi-Fi Scanner';

  @override
  String get securityScore => 'Security Score';

  @override
  String get scanNow => 'Scan now';

  @override
  String get scanning => 'Scanning…';

  @override
  String get protected => 'Protected';

  @override
  String get atRisk => 'At Risk';

  @override
  String get critical => 'Critical';

  @override
  String lastScanned(String time) {
    return 'Last scanned $time';
  }

  @override
  String get neverScanned => 'Never scanned';

  @override
  String get protectionModules => 'Protection Modules';

  @override
  String get sevenDayScore => '7-Day Security Score';

  @override
  String get recentAlerts => 'Recent Alerts';

  @override
  String get seeAll => 'See All';

  @override
  String get noAlerts => 'No alerts yet';

  @override
  String get noAlertsDescription =>
      'Threats detected during scans will appear here';

  @override
  String get notifications => 'Notifications';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get languageTamil => 'தமிழ் (Tamil)';

  @override
  String get languageTelugu => 'తెలుగు (Telugu)';

  @override
  String get exportPdf => 'Export as PDF';

  @override
  String get exportCsv => 'Export as CSV';

  @override
  String get exportPdfSubtitle =>
      'Branded report with score, threats and trends';

  @override
  String get exportCsvSubtitle => 'Raw scan + alert data for spreadsheets';

  @override
  String get reports => 'Reports & Export';

  @override
  String get liveSmsGuard => 'Live SMS Phishing Guard';

  @override
  String get liveSmsGuardSubtitle =>
      'Auto-scan every incoming SMS for phishing links';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String get checkBreach => 'Check Now';

  @override
  String get enterEmail => 'Enter your email address';

  @override
  String get enterPassword => 'Enter a password to test';

  @override
  String get noBreachFound => 'No breaches found';

  @override
  String breachesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count breaches found',
      one: '1 breach found',
    );
    return '$_temp0';
  }

  @override
  String get onboardAiSecurityTitle => 'AI-powered security 🛡️';

  @override
  String get onboardAiSecurityDesc =>
      'On-device machine learning detects phishing, malware, and breaches — all in real time, none of your data leaves your phone.';

  @override
  String get onboardPhishingTitle => 'Phishing detection 🔗';

  @override
  String get onboardPhishingDesc =>
      'Paste any link or scan your SMS to spot phishing attempts targeting banking, UPI, and OTPs — explained simply.';

  @override
  String get onboardMalwareTitle => 'Malware scanner 🐞';

  @override
  String get onboardMalwareDesc =>
      'Deep-scan installed apps using permission graph analysis to find hidden spyware, trojans, and stalkerware.';

  @override
  String get onboardBreachTitle => 'Breach monitor 🔐';

  @override
  String get onboardBreachDesc =>
      'Check 14B+ leaked records. Your email and password are hashed locally and never sent in full.';

  @override
  String get onboardPermsTitle => 'Just a few permissions 🙏';

  @override
  String get onboardPermsDesc =>
      'We need SMS, location, and notification access. All scans stay on this device — nothing is sent to any server.';

  @override
  String get onboardContinue => 'Continue';

  @override
  String get onboardGrantStart => 'Grant permissions & start';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get scoreGreetingProtected => 'You\'re protected';

  @override
  String get scoreGreetingAtRisk => 'A few things to check ⚠️';

  @override
  String get scoreGreetingCritical => 'Action needed 🚨';

  @override
  String get scoreGreetingFirstScan => 'Hi there 👋';

  @override
  String get scoreHeadlineProtected => 'Everything looks healthy';

  @override
  String get scoreHeadlineAtRisk => 'Take a quick look';

  @override
  String get scoreHeadlineCritical => 'Critical issues found';

  @override
  String get scoreHeadlineFirstScan => 'Let\'s secure your phone';

  @override
  String get permSmsTitle => 'SMS Access Needed';

  @override
  String get permSmsRationale =>
      'CyberGuard AI needs to read your SMS messages to detect phishing links. Your messages are never sent to any server — all analysis happens locally on your device.';

  @override
  String get permLocationTitle => 'Location Access Needed';

  @override
  String get permLocationRationale =>
      'Android requires location permission to access Wi-Fi network details like SSID. CyberGuard AI uses this only to analyse your current network security — your location data is never stored or shared.';

  @override
  String get permNotifTitle => 'Notifications';

  @override
  String get permNotifRationale =>
      'CyberGuard AI sends notifications when it detects threats so you can act immediately. You can customise notification types in Settings.';

  @override
  String get permAllowButton => 'Allow Permission';

  @override
  String get permNotNow => 'Not Now';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogConfirm => 'Confirm';

  @override
  String get dialogClearAll => 'Clear All';

  @override
  String get dialogReset => 'Reset';

  @override
  String get dialogDelete => 'Delete';

  @override
  String get dialogClose => 'Close';

  @override
  String get breachInputTitle => 'Check if your data was leaked';

  @override
  String get breachInputSubtitle =>
      'We check across 12+ billion leaked records';

  @override
  String get breachTabEmail => 'Email';

  @override
  String get breachTabPhone => 'Phone Number';

  @override
  String get breachInputHintEmail => 'Enter your email address';

  @override
  String get breachInputHintPhone => 'Enter your 10-digit number';

  @override
  String get breachPrivacyFooter =>
      'k-Anonymity protected · Your data never leaves this device';

  @override
  String get breachNoBreaches => 'No breaches found';

  @override
  String get breachNoBreachesEmailDesc =>
      'Good news! Your email wasn\'t found in any known data breach.';

  @override
  String get breachNoBreachesPhoneDesc =>
      'Good news! This phone number wasn\'t found in any known data breach.';

  @override
  String get breachCheckedCount => 'Checked 12,454,308,593 records';

  @override
  String get breachStayProtected => 'Stay protected';

  @override
  String get breachTipUnique => 'Use unique passwords for each account';

  @override
  String get breach2FA => 'Enable two-factor authentication';

  @override
  String get breachPwManager => 'Use a password manager';

  @override
  String get breachOfflineBannerTitle =>
      'Showing results from offline database';

  @override
  String get breachOfflineBannerBody =>
      'These are real historical breaches but the match is derived from a local hash of your email, not a live HIBP lookup. Configure a free HIBP API key in Settings for live verification.';

  @override
  String get breachFoundEmail =>
      'Your email was exposed in the following breaches:';

  @override
  String get breachFoundPhone =>
      'This number was exposed in the following breaches:';

  @override
  String breachAccountsAffected(String count) {
    return '$count accounts affected';
  }

  @override
  String get breachCompromisedData => 'COMPROMISED DATA';

  @override
  String get breachWhatToDo => 'What should I do?';

  @override
  String get breachStep1 =>
      'Change passwords on every site where you reused this credential.';

  @override
  String get breachStep2 =>
      'Enable two-factor authentication, ideally with an authenticator app.';

  @override
  String get breachStep3 =>
      'Watch for phishing emails impersonating the breached service.';

  @override
  String get breachStep4 =>
      'Consider a password manager to keep unique passwords per account.';

  @override
  String get breachPastChecks => 'Past checks';

  @override
  String get breachStatusSafe => 'Safe';

  @override
  String get breachStatusBreached => 'Breached';

  @override
  String get breachPrivacyTitle => 'How we protect your privacy';

  @override
  String get breachPrivacyStep1 => 'Your input is hashed on your device.';

  @override
  String get breachPrivacyStep2 =>
      'Only the first 5 characters of the hash are sent to HIBP.';

  @override
  String get breachPrivacyStep3 => 'Thousands of matching hashes come back.';

  @override
  String get breachPrivacyStep4 =>
      '100% of the match check happens locally on your device.';

  @override
  String get qrScanTitle => 'Scan QR';

  @override
  String get qrUploadFromGallery => 'Upload from gallery';

  @override
  String get qrPointAtCode =>
      'Point at any QR · scanned URLs are checked locally';

  @override
  String get qrNotAUrl => 'Not a URL';

  @override
  String get qrNotAUrlBody => 'The QR code contained text, not a link:';

  @override
  String get qrPhishingDetected => 'Phishing QR detected';

  @override
  String get qrSafeLink => 'Safe link';

  @override
  String get qrScanAnother => 'Scan another';

  @override
  String get qrViewDetails => 'View details';

  @override
  String qrConfidence(int count) {
    return '$count% confidence';
  }

  @override
  String get qrCameraUnavailable =>
      'Camera unavailable. Grant camera permission and try again.';

  @override
  String get qrOpenSettings => 'Open settings';

  @override
  String get qrNoCodeInImage => 'No QR code found in this image.';

  @override
  String get scoreSuffix => '/100';

  @override
  String get scoreLabel => 'score';

  @override
  String scannedAgo(String time) {
    return 'Scanned $time';
  }

  @override
  String get dashboardRefreshed => 'Dashboard refreshed';

  @override
  String dashboardRefreshedWithWifi(int score) {
    return 'Dashboard refreshed · Wi-Fi trust $score/100';
  }

  @override
  String get moduleTitlePhishing => 'Phishing';

  @override
  String get moduleSubtitlePhishing => 'URL & SMS scanner';

  @override
  String get moduleTitleMalware => 'Malware';

  @override
  String get moduleSubtitleMalware => 'App security';

  @override
  String get moduleTitleBreach => 'Breach';

  @override
  String get moduleSubtitleBreach => 'Data leak monitor';

  @override
  String get moduleTitleWifi => 'Wi-Fi';

  @override
  String get moduleSubtitleWifi => 'Network analyser';

  @override
  String get statTotalScans => 'Total Scans';

  @override
  String get statThreats => 'Threats';

  @override
  String get statLastScan => 'Last Scan';

  @override
  String get statNever => 'Never';

  @override
  String get settingRealTimeAlerts => 'Real-time Alerts';

  @override
  String get settingRealTimeAlertsSub =>
      'Get notified when threats are detected';

  @override
  String get settingClipboardScan => 'Clipboard Scan';

  @override
  String get settingClipboardScanSub => 'Scan URLs copied to clipboard';

  @override
  String get settingWifiAutoScan => 'Auto Wi-Fi Scan';

  @override
  String get settingWifiAutoScanSub => 'Scan on network change';

  @override
  String get smsPermissionDenied =>
      'SMS permission denied — cannot start live scan';

  @override
  String get settingsAutoScanFrequency => 'Auto Scan Frequency';

  @override
  String settingsBackgroundScanEvery(int hours) {
    return 'Background scan every ${hours}h';
  }

  @override
  String get settingsHibpTitle => 'Have I Been Pwned API Key';

  @override
  String get settingsHibpDesc =>
      'Required for email breach checks. Get your free key at haveibeenpwned.com/API/Key';

  @override
  String get settingsHibpPasteHint => 'Paste your API key here…';

  @override
  String get settingsHibpSave => 'Save Key';

  @override
  String get settingsHibpSaved => 'API key saved';

  @override
  String get settingsHibpConfigured => 'API key configured';

  @override
  String get settingsPrivacy => 'Privacy & Data';

  @override
  String get settingsKAnon => 'k-Anonymity Protocol';

  @override
  String get settingsKAnonDesc =>
      'Passwords are never sent to any server. Only the first 5 characters of the SHA-1 hash are transmitted. Your credentials never leave your device.';

  @override
  String get settingsLocalStorage => 'Local Storage Only';

  @override
  String get settingsLocalStorageDesc =>
      'All scan results and history are stored locally on your device using encrypted Hive storage. No data is sent to our servers.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsAboutEngine => 'Detection Engine';

  @override
  String get settingsAboutSources => 'Data Sources';

  @override
  String get settingsAboutModel => 'AI Model';

  @override
  String get settingsDangerZone => 'Danger Zone';

  @override
  String get settingsResetDesc =>
      'Reset all settings to defaults. This will not delete scan history.';

  @override
  String get settingsResetBtn => 'Reset Settings';

  @override
  String get settingsResetTitle => 'Reset Settings';

  @override
  String get settingsResetBody =>
      'All settings will be restored to defaults. Continue?';

  @override
  String get exportGenerating => 'Generating PDF report…';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get alertsMarkAllRead => 'Mark all read';

  @override
  String alertsNoFilter(String filter) {
    return 'No $filter alerts';
  }

  @override
  String get alertsTryDifferent => 'Try a different filter';

  @override
  String get alertsClearTitle => 'Clear All Alerts';

  @override
  String get alertsClearBody => 'This will permanently delete all alerts.';

  @override
  String get alertsFilterAll => 'All';

  @override
  String get alertsFilterPhishing => 'Phishing';

  @override
  String get alertsFilterMalware => 'Malware';

  @override
  String get alertsFilterBreach => 'Breach';

  @override
  String get alertsFilterWifi => 'Wi-Fi';

  @override
  String get malwareIssuesFound => 'Issues found ⚠️';

  @override
  String get malwareAppSecurity => 'App security 🛡️';

  @override
  String get malwareTapToScan => 'Tap scan to analyse your apps';

  @override
  String malwareAppsThreats(int apps, int threats) {
    String _temp0 = intl.Intl.pluralLogic(
      threats,
      locale: localeName,
      other: 'threats',
      one: 'threat',
    );
    return '$apps apps · $threats $_temp0';
  }

  @override
  String malwareLastScan(String time) {
    return 'Last scan $time';
  }

  @override
  String get malwareScanNow => 'Scan apps now';

  @override
  String malwareAnalysing(String name) {
    return 'Analysing $name…';
  }

  @override
  String malwareEtaSec(String sec) {
    return '~${sec}s';
  }

  @override
  String malwareProgress(int progress, int total) {
    return '$progress / $total apps';
  }

  @override
  String get malwareRiskCritical => 'Critical';

  @override
  String get malwareRiskHigh => 'High';

  @override
  String get malwareRiskMedium => 'Medium';

  @override
  String get malwareRiskLow => 'Low';

  @override
  String get malwareSearch => 'Search apps…';

  @override
  String get malwareNoAppsTitle => 'No apps found';

  @override
  String get malwareNoAppsSub => 'Tap Scan to analyse your installed apps';

  @override
  String get malwareNoMatchTitle => 'No apps match filter';

  @override
  String get malwareNoMatchSub => 'Try a different filter or search term';

  @override
  String malwarePermsVerified(int count) {
    return '$count permissions • Verified';
  }

  @override
  String malwarePermsSideloaded(int count) {
    return '$count permissions • Sideloaded';
  }

  @override
  String get phishingUrlTab => '🔗  URL Scanner';

  @override
  String get phishingSmsTab => '💬  SMS Scanner';

  @override
  String get phishingCheckLink => 'Check a link 🔍';

  @override
  String get phishingPasteHint => 'Paste any URL — we\'ll scan it locally';

  @override
  String get phishingPaste => 'Paste';

  @override
  String get phishingScanNow => 'Scan now';

  @override
  String get phishingScanHistory => 'Scan History';

  @override
  String phishingScans(int count) {
    return '$count scans';
  }

  @override
  String get phishingNoScansTitle => 'No scans yet';

  @override
  String get phishingNoScansSub => 'URLs you scan will appear here';

  @override
  String get phishingAnalysingTitle => 'AI Analysing URL';

  @override
  String get phishingAnalysingSub =>
      'Checking TLD, keywords, patterns, and structure';

  @override
  String get phishingVerdictPhishing => 'PHISHING';

  @override
  String get phishingVerdictSafe => 'SAFE';

  @override
  String get phishingConfidence => 'Confidence';

  @override
  String get phishingWhyFlagged => 'Why AI flagged this';

  @override
  String get phishingHowItWorks => 'How Phishing Detection Works';

  @override
  String get phishingHowItWorksBody =>
      'CyberGuard AI uses on-device rule-based detection with SHAP explainability to identify phishing URLs. Analysis includes TLD reputation, keyword matching, URL structure, and brand impersonation checks. All analysis is done locally — your URLs never leave your device.';

  @override
  String get phishingGotIt => 'Got it';

  @override
  String get phishingSmsTitle => 'SMS Phishing 📨';

  @override
  String get phishingSmsSub => 'We scan your messages locally';

  @override
  String get phishingSmsLoad => 'Load SMS';

  @override
  String get phishingSmsScanAll => 'Scan All';

  @override
  String get phishingSmsNoneTitle => 'No SMS loaded';

  @override
  String get phishingSmsNoneSub =>
      'Tap \"Load SMS\" to fetch your recent messages';

  @override
  String get phishingSmsUnknown => 'Unknown';

  @override
  String get phishingSmsSuspicious => 'SUSPICIOUS';

  @override
  String get phishingSmsLinksScannedSafe => 'Links Scanned — Safe';

  @override
  String get phishingSmsLinksSuspicious => 'Suspicious Links Found!';

  @override
  String phishingSmsScanLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'links',
      one: 'link',
    );
    return 'Scan $count $_temp0';
  }

  @override
  String get phishingSmsNoUrls => 'No URLs found in this message';

  @override
  String get wifiClearHistoryTooltip => 'Clear history';

  @override
  String get wifiClearTitle => 'Clear History';

  @override
  String get wifiClearBody => 'Remove all Wi-Fi scan history?';

  @override
  String get wifiClear => 'Clear';

  @override
  String get wifiScanThis => 'Scan this network';

  @override
  String get wifiScanning => 'Scanning network…';

  @override
  String get wifiScanningSub => 'Analysing security in real-time';

  @override
  String get wifiNoScan => 'No scan yet';

  @override
  String get wifiNoScanSub => 'Tap Scan Network to analyse your Wi-Fi';

  @override
  String get wifiUnknownSsid => 'Unknown SSID';

  @override
  String wifiTrust(int score) {
    return 'Trust: $score%';
  }

  @override
  String get wifiTrustScore => 'Trust Score';

  @override
  String get wifiSignal => 'Signal';

  @override
  String get wifiBand => 'Band';

  @override
  String get wifiSpeed => 'Speed';

  @override
  String get wifiEncrypted => 'Encrypted';

  @override
  String get wifiYes => 'Yes';

  @override
  String get wifiNo => 'No';

  @override
  String get wifiSecurityChecks => 'Security Checks';

  @override
  String wifiChecksPassed(int passed, int total) {
    return '$passed/$total passed';
  }

  @override
  String get wifiCheckEncryption => 'Encryption';

  @override
  String get wifiCheckSignalStrength => 'Signal Strength';

  @override
  String get wifiCheckDnsHealth => 'DNS Health';

  @override
  String get wifiCheckEvilTwin => 'Evil Twin Detection';

  @override
  String get wifiCheckLatency => 'Network Latency';

  @override
  String get wifiCheckModernBand => 'Modern Band (5GHz)';

  @override
  String get wifiEncDescYes => 'Network uses WPA2/WPA3 encryption';

  @override
  String get wifiEncDescNo => 'Open network — traffic is unencrypted';

  @override
  String wifiDnsDescYes(int ms) {
    return 'DNS resolved in ${ms}ms';
  }

  @override
  String get wifiDnsDescNo => 'DNS resolution failed — possible interception';

  @override
  String wifiBssidDesc(String bssid) {
    return 'BSSID $bssid matches stored record';
  }

  @override
  String wifiLatencyDesc(int ms) {
    return 'Latency: ${ms}ms';
  }

  @override
  String get wifiLatencyDescNone => 'Latency not measured';

  @override
  String get wifiBandDesc5 => 'Using 5GHz band — less interference';

  @override
  String get wifiBandDesc24 => 'Using 2.4GHz band — more interference';

  @override
  String wifiSignalDesc(int rssi, String label) {
    return 'Signal: $rssi dBm ($label)';
  }

  @override
  String get wifiNetworkDetails => 'Network Details';

  @override
  String get wifiDetailSsid => 'SSID';

  @override
  String get wifiDetailBssid => 'BSSID';

  @override
  String get wifiDetailIp => 'IP Address';

  @override
  String get wifiDetailFrequency => 'Frequency';

  @override
  String get wifiDetailBand => 'Band';

  @override
  String get wifiDetailLinkSpeed => 'Link Speed';

  @override
  String get wifiDetailSignal => 'Signal';

  @override
  String get wifiDetailDnsLatency => 'DNS Latency';

  @override
  String get wifiDetailScanned => 'Scanned';

  @override
  String get wifiUnknown => 'Unknown';

  @override
  String get wifiNA => 'N/A';

  @override
  String get cyberDefense => 'Cyber Defense';

  @override
  String get defenseThreatFusion => 'Threat Fusion';

  @override
  String get defenseScreenshotScan => 'Screenshot Scan';

  @override
  String get defensePredictiveRisk => 'Predictive Risk';

  @override
  String get defenseArbitrationLog => 'Arbitration Log';

  @override
  String get linkProtection => 'Link Protection';

  @override
  String get linkInterceptorTitle => 'Smart Link Interceptor';

  @override
  String get linkInterceptorSub =>
      'Scan links you open from other apps before they load';

  @override
  String get cloudIntelTitle => 'Cloud threat intelligence';

  @override
  String get cloudIntelSub =>
      'Check links against Google Safe Browsing (sends the tapped link to Google). Off by default.';

  @override
  String get saveLinkHistoryTitle => 'Save link history';

  @override
  String get saveLinkHistorySub =>
      'Store scanned links on this device. Off = nothing is kept.';

  @override
  String get defaultBrowserTitle => 'Set CyberGuard as default browser';

  @override
  String get defaultBrowserSub =>
      'Required to check links before they open. CyberGuard scans each link, then hands safe ones to your browser.';

  @override
  String get defaultBrowserActive =>
      'CyberGuard is your default browser — tapped links are protected.';

  @override
  String get defaultBrowserSetCta => 'Set as Default Browser';

  @override
  String get cloudIntelDialogTitle => 'Enable cloud threat intelligence?';

  @override
  String get cloudIntelDialogBody =>
      'When on, intercepted links are checked against Google Safe Browsing. The link you tapped is sent to Google for this check. Nothing else leaves your device. You can turn this off anytime.';

  @override
  String get commonEnable => 'Enable';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get threatBandSafe => 'Safe (0-30)';

  @override
  String get threatBandSuspicious => 'Suspicious (31-60)';

  @override
  String get threatBandDangerous => 'Dangerous (61-80)';

  @override
  String get threatBandCritical => 'Critical (81-100)';

  @override
  String get threatLevelSafe => 'Safe';

  @override
  String get threatLevelSuspicious => 'Suspicious';

  @override
  String get threatLevelDangerous => 'Dangerous';

  @override
  String get threatLevelCritical => 'Critical';

  @override
  String confidencePct(int pct) {
    return 'confidence $pct%';
  }

  @override
  String get warnDangerousTitle => 'Dangerous Website Detected';

  @override
  String get warnSuspiciousTitle => 'Suspicious Website';

  @override
  String get warnRiskScore => 'RISK SCORE';

  @override
  String get warnOverrideDefault =>
      'Blocked by trusted threat intelligence override.';

  @override
  String get warnConflict =>
      'Detection sources disagreed — verdict reconciled by arbitration.';

  @override
  String get warnDestination => 'DESTINATION';

  @override
  String warnVia(String app) {
    return 'via $app';
  }

  @override
  String get warnWhyFlagged => 'WHY THIS IS FLAGGED';

  @override
  String get warnSources => 'INTELLIGENCE SOURCES';

  @override
  String get warnGoBack => 'Go Back (Recommended)';

  @override
  String get warnContinue => 'Continue Anyway';

  @override
  String get warnReport => 'Report this link';

  @override
  String get warnReported => 'Reported. Thank you.';

  @override
  String get warnOpenDangerousTitle => 'Open a dangerous site?';

  @override
  String get warnOpenDangerousBody =>
      'CyberGuard rated this link as high-risk. Opening it could expose your credentials or device. Continue at your own risk?';

  @override
  String get warnOpenAnyway => 'Open anyway';

  @override
  String get warnPrivacyNote =>
      'No URLs are stored unless you enable link history in Settings.';

  @override
  String get fusionTitle => 'Threat Fusion Scan';

  @override
  String get fusionPrompt => 'Check a link across all intelligence sources';

  @override
  String get fusionRunScan => 'Run Fusion Scan';

  @override
  String get fusionUnified => 'UNIFIED';

  @override
  String get fusionSourceAttribution => 'SOURCE ATTRIBUTION';

  @override
  String get fusionExplanation => 'EXPLANATION';

  @override
  String get fusionConflict => 'Sources disagreed — reconciled by arbitration.';

  @override
  String fusionTrust(int weight) {
    return 'trust $weight';
  }

  @override
  String get arbitrationTitle => 'Arbitration Log';

  @override
  String get arbitrationClear => 'Clear log';

  @override
  String get arbitrationEmptyTitle => 'No conflicts yet';

  @override
  String get arbitrationEmptyBody =>
      'When detection sources disagree or a trusted source overrides CyberGuard, the decision is recorded here.';

  @override
  String arbitrationOverride(String level) {
    return 'Trusted override → $level';
  }

  @override
  String arbitrationConflictTitle(String level) {
    return 'Source conflict → $level';
  }

  @override
  String get riskTitle => 'Predictive Risk';

  @override
  String get riskNoData => 'No data';

  @override
  String get riskBandLow => 'Low';

  @override
  String get riskBandMedium => 'Medium';

  @override
  String get riskBandHigh => 'High';

  @override
  String riskSuffix(String band) {
    return '$band RISK';
  }

  @override
  String get riskForecastTitle => 'Threat Forecast';

  @override
  String get riskTimelineTitle => '7-Day Risk Timeline';

  @override
  String riskWhyTitle(String band) {
    return 'Why your risk is $band';
  }

  @override
  String get riskRecommendations => 'Recommendations';

  @override
  String get forecastPhishing => 'Phishing Attack';

  @override
  String get forecastCredentialTheft => 'Credential Theft';

  @override
  String get forecastMalware => 'Malware Infection';

  @override
  String get rfPhishingTitle => 'Phishing links encountered';

  @override
  String rfPhishingDetail(int count) {
    return '$count flagged in the last 7 days';
  }

  @override
  String get rfSmsTitle => 'Suspicious SMS received';

  @override
  String rfSmsDetail(int count) {
    return '$count phishing SMS detected';
  }

  @override
  String get rfWifiTitle => 'Unknown Wi-Fi networks used';

  @override
  String rfWifiDetail(int count) {
    return '$count low-trust networks connected';
  }

  @override
  String get rfMalwareTitle => 'Risky apps installed';

  @override
  String rfMalwareDetail(int count) {
    return '$count high-risk apps detected';
  }

  @override
  String get rfInterceptTitle => 'Links blocked recently';

  @override
  String rfInterceptDetail(int count) {
    return '$count dangerous links intercepted';
  }

  @override
  String get rfBreachTitle => 'Credentials in a known breach';

  @override
  String get rfBreachDetail => 'Your account appears in breached data';

  @override
  String get rfTrendTitle => 'Security score declining';

  @override
  String rfTrendDetail(int pts) {
    return 'Protection dropped $pts pts recently';
  }

  @override
  String get recBreach =>
      'Change passwords for breached accounts and enable 2FA.';

  @override
  String get recPhishing =>
      'Avoid tapping links in unexpected messages; verify the sender.';

  @override
  String get recWifi =>
      'Avoid sensitive logins on public Wi-Fi; use a trusted network.';

  @override
  String get recMalware =>
      'Review and uninstall high-risk apps; install only from Play Store.';

  @override
  String get recInterceptor =>
      'Keep the Smart Link Interceptor enabled for ongoing protection.';

  @override
  String get recHealthy =>
      'You\'re in good shape — keep CyberGuard protections enabled.';

  @override
  String get screenshotTitle => 'Screenshot Scanner';

  @override
  String get screenshotPrompt => 'Scan a suspicious page screenshot';

  @override
  String get screenshotDesc =>
      'Detects fake bank, UPI, OTP, login, KYC, lottery and support scams. Images are analysed on-device.';

  @override
  String get screenshotGallery => 'Gallery';

  @override
  String get screenshotCamera => 'Camera';

  @override
  String get screenshotScam => 'SCAM';

  @override
  String get screenshotLooksClean => 'Looks clean';

  @override
  String screenshotBrand(String brand) {
    return 'Brand referenced: $brand';
  }

  @override
  String get screenshotIndicators => 'INDICATORS';

  @override
  String get screenshotExtractedText => 'EXTRACTED TEXT';

  @override
  String get scamFakeBank => 'Fake bank page';

  @override
  String get scamFakeUpi => 'Fake UPI / payment page';

  @override
  String get scamFakeOtp => 'Fake OTP request';

  @override
  String get scamFakeLogin => 'Fake login page';

  @override
  String get scamFakeKyc => 'Fake KYC form';

  @override
  String get scamFakeLottery => 'Lottery / prize scam';

  @override
  String get scamFakeInvestment => 'Investment scam';

  @override
  String get scamFakeSupport => 'Fake customer support';

  @override
  String get scamNone => 'No scam indicators';

  @override
  String scamReasonCategory(String category, String matched) {
    return '$category: \"$matched\"';
  }

  @override
  String scamReasonBrand(String brand) {
    return 'Brand referenced: $brand';
  }

  @override
  String scamReasonUrgency(String word) {
    return 'Urgency / pressure wording: \"$word\"';
  }

  @override
  String get scamReasonNoIndicators =>
      'No scam indicators detected in the text';

  @override
  String get scamReasonNoText => 'No readable text found in the image';

  @override
  String get authTitle => 'Sign in to CyberGuard AI';

  @override
  String get authSubtitle => 'Sync your security settings across devices';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Create Account';

  @override
  String get authPassword => 'Password';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'New here? Create an account';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authOr => 'or';

  @override
  String get authContinueOffline => 'Continue without an account';

  @override
  String get authResetSent =>
      'If that address is registered, a reset link is on its way.';

  @override
  String get authUnavailableTitle => 'Sign-in isn\'t set up in this build';

  @override
  String get authUnavailableBody =>
      'This copy of the app was built without Firebase credentials, so accounts are unavailable. Everything else works offline as usual.';

  @override
  String get authErrInvalidEmail => 'That email address doesn\'t look right';

  @override
  String get authErrWrongPassword => 'Incorrect email or password';

  @override
  String get authErrUserNotFound => 'No account found for that email';

  @override
  String get authErrEmailInUse => 'An account already exists for that email';

  @override
  String get authErrWeakPassword => 'Use at least 6 characters';

  @override
  String get authErrNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get authErrUnknown => 'Something went wrong. Please try again.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String authSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authCreateAccountTitle => 'Create your account';

  @override
  String get authHeroTagline => 'Your phone\'s security, in one place';

  @override
  String get authTabSignIn => 'Sign In';

  @override
  String get authTabRegister => 'Register';

  @override
  String get authSecuredNote => 'Protected by end-to-end encrypted sign-in';

  @override
  String get authSigningIn => 'Signing you in…';
}
