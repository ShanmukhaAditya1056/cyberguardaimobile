import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/alert_model.dart';
import '../models/scan_result_model.dart';
import '../models/score_entry_model.dart';
import '../models/settings_model.dart';
import '../models/wifi_scan_model.dart';

class HiveService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    // Register all adapters
    if (!Hive.isAdapterRegistered(AppConstants.scanResultTypeId)) {
      Hive.registerAdapter(ScanResultModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.alertTypeId)) {
      Hive.registerAdapter(AlertModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.wifiScanTypeId)) {
      Hive.registerAdapter(WifiScanModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.scoreEntryTypeId)) {
      Hive.registerAdapter(ScoreEntryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.settingsTypeId)) {
      Hive.registerAdapter(SettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.appScanTypeId)) {
      Hive.registerAdapter(AppScanModelAdapter());
    }

    try {
      await _openAllBoxes();
    } catch (_) {
      // Stale on-disk data from an older schema. Wipe everything and retry.
      await _wipeAllBoxes();
      await _openAllBoxes();
    }

    _initialized = true;
  }

  static Future<void> _openAllBoxes() async {
    await Hive.openBox<ScanResultModel>(AppConstants.scanResultsBox);
    await Hive.openBox<AlertModel>(AppConstants.alertsBox);
    await Hive.openBox<WifiScanModel>(AppConstants.wifiScansBox);
    await Hive.openBox<ScoreEntryModel>(AppConstants.scoreHistoryBox);
    await Hive.openBox<SettingsModel>(AppConstants.settingsBox);
    await Hive.openBox<AppScanModel>(AppConstants.appScanCacheBox);
    await Hive.openBox<String>(AppConstants.prefsBox);
  }

  /// Simple typed access to the lightweight string-prefs box.
  static String? getPref(String key) =>
      Hive.box<String>(AppConstants.prefsBox).get(key);

  static Future<void> setPref(String key, String value) =>
      Hive.box<String>(AppConstants.prefsBox).put(key, value);

  static Future<void> _wipeAllBoxes() async {
    await Hive.close();
    for (final name in [
      AppConstants.scanResultsBox,
      AppConstants.alertsBox,
      AppConstants.wifiScansBox,
      AppConstants.scoreHistoryBox,
      AppConstants.settingsBox,
      AppConstants.appScanCacheBox,
      AppConstants.prefsBox,
    ]) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  static Box<SettingsModel> get _settingsBox =>
      Hive.box<SettingsModel>(AppConstants.settingsBox);

  static SettingsModel getSettings() {
    return _settingsBox.get('settings') ?? SettingsModel();
  }

  static Future<void> saveSettings(SettingsModel settings) async {
    await _settingsBox.put('settings', settings);
  }

  // ── Scan Results ──────────────────────────────────────────────────────────

  static Box<ScanResultModel> get _scanBox =>
      Hive.box<ScanResultModel>(AppConstants.scanResultsBox);

  static Future<void> saveScanResult(ScanResultModel result) async {
    await _scanBox.put(result.id, result);
  }

  static List<ScanResultModel> getScanResults({String? type}) {
    final all = _scanBox.values.toList();
    if (type != null) {
      return all.where((r) => r.type == type).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return all..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> deleteScanResult(String id) async {
    await _scanBox.delete(id);
  }

  static int getTotalScans() => _scanBox.length;

  static int getThreatCount() =>
      _scanBox.values.where((r) => r.isThreat).length;

  // ── Alerts ────────────────────────────────────────────────────────────────

  static Box<AlertModel> get _alertsBox =>
      Hive.box<AlertModel>(AppConstants.alertsBox);

  static Future<void> saveAlert(AlertModel alert) async {
    await _alertsBox.put(alert.id, alert);
  }

  static List<AlertModel> getAlerts() {
    return _alertsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> markAlertRead(String id) async {
    final alert = _alertsBox.get(id);
    if (alert != null) {
      alert.isRead = true;
      await alert.save();
    }
  }

  static Future<void> deleteAlert(String id) async {
    await _alertsBox.delete(id);
  }

  static Future<void> clearAlerts() async {
    await _alertsBox.clear();
  }

  static int getUnreadAlertCount() =>
      _alertsBox.values.where((a) => !a.isRead).length;

  // ── Wi-Fi Scans ───────────────────────────────────────────────────────────

  static Box<WifiScanModel> get _wifiBox =>
      Hive.box<WifiScanModel>(AppConstants.wifiScansBox);

  static Future<void> saveWifiScan(WifiScanModel scan) async {
    await _wifiBox.put(scan.timestamp.millisecondsSinceEpoch.toString(), scan);
  }

  static List<WifiScanModel> getWifiScans() {
    return _wifiBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static WifiScanModel? getLastWifiScan() {
    final scans = getWifiScans();
    return scans.isNotEmpty ? scans.first : null;
  }

  static String? getStoredBssid(String ssid) {
    final scans = _wifiBox.values.where((s) => s.ssid == ssid).toList();
    if (scans.isEmpty) return null;
    scans.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return scans.first.bssid;
  }

  static List<WifiScanModel> getWifiHistory() {
    return getWifiScans();
  }

  static Future<void> clearWifiHistory() async {
    await _wifiBox.clear();
  }

  // ── Score History ──────────────────────────────────────────────────────────

  static Box<ScoreEntryModel> get _scoreBox =>
      Hive.box<ScoreEntryModel>(AppConstants.scoreHistoryBox);

  static Future<void> saveScoreEntry(ScoreEntryModel entry) async {
    final key = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
    await _scoreBox.put(key, entry);
  }

  static List<ScoreEntryModel> getScoreHistory({int days = 7}) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    return _scoreBox.values.where((e) => e.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── App Scan Cache ─────────────────────────────────────────────────────────

  static Box<AppScanModel> get _appScanBox =>
      Hive.box<AppScanModel>(AppConstants.appScanCacheBox);

  static Future<void> saveAppScan(AppScanModel scan) async {
    await _appScanBox.put(scan.packageName, scan);
  }

  static AppScanModel? getAppScan(String packageName) =>
      _appScanBox.get(packageName);

  static List<AppScanModel> getAllAppScans() => _appScanBox.values.toList();

  static Future<void> clearAppScans() async => _appScanBox.clear();

  // ── Clear All ──────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await _scanBox.clear();
    await _alertsBox.clear();
    await _wifiBox.clear();
    await _scoreBox.clear();
    await _appScanBox.clear();
    // Keep settings
  }
}
