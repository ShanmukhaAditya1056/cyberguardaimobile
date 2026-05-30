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
}
