class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'CyberGuard AI';
  static const String appTagline = 'Intelligent Mobile Security';
  static const String channelName = 'com.cyberguard.ai/device';

  // Hive box names
  static const String scanResultsBox = 'scan_results';
  static const String alertsBox = 'alerts';
  static const String wifiScansBox = 'wifi_scans';
  static const String scoreHistoryBox = 'score_history';
  static const String settingsBox = 'settings';
  static const String appScanCacheBox = 'app_scan_cache';
  static const String prefsBox = 'prefs';

  // Hive type IDs
  static const int scanResultTypeId = 0;
  static const int alertTypeId = 1;
  static const int wifiScanTypeId = 2;
  static const int scoreEntryTypeId = 3;
  static const int settingsTypeId = 4;
  static const int appScanTypeId = 5;

  // API
  static const String hibpPasswordBase = 'https://api.pwnedpasswords.com/range/';
  static const String hibpBreachBase = 'https://haveibeenpwned.com/api/v3/breachedaccount/';
  static const String hibpUserAgent = 'CyberGuard-AI-App';

  // Notification channels
  static const String notifChannelId = 'cyberguard_alerts';
  static const String notifChannelName = 'CyberGuard Alerts';
  static const String notifChannelDesc = 'Security threat alerts and scan results';

  // Score thresholds
  static const int scoreSafeMin = 70;
  static const int scoreWarnMin = 40;

  // Scan limits
  static const int smsReadLimit = 20;
  static const int historyDisplayLimit = 50;
  static const int alertDisplayLimit = 100;

  // Animation durations (ms)
  static const int animFast = 150;
  static const int animNormal = 300;
  static const int animSlow = 600;
  static const int animScore = 1500;
  static const int animGradient = 800;
  static const int animStagger = 80;
  static const int animShap = 800;

  // Permission rationale
  static const String smsPermissionRationale =
      'CyberGuard AI needs to read your SMS messages to detect phishing links. Your messages are never sent to any server — all analysis happens locally on your device.';
  static const String locationPermissionRationale =
      'Android requires location permission to access Wi-Fi network details like SSID. CyberGuard AI uses this only to analyse your current network security — your location data is never stored or shared.';
  static const String packagePermissionRationale =
      'CyberGuard AI needs to see your installed apps to scan them for malware. App data is analysed locally — nothing is sent to external servers.';
  static const String notifPermissionRationale =
      'CyberGuard AI sends notifications when it detects threats so you can act immediately. You can customise notification types in Settings.';
}
