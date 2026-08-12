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

    await sweepExpired();

    _initialized = true;
  }

  // ── Retention ─────────────────────────────────────────────────────────────

  /// Drops history older than [AppConstants.retentionDays] from every box that
  /// accumulates over time. Runs once per launch, after the boxes are open.
  ///
  /// Existing installs can be carrying an unbounded backlog from before any of
  /// this existed, so this also trims each box back to its cap — that first
  /// sweep is the one that reclaims real space.
  static Future<void> sweepExpired() async {
    final cutoff =
        DateTime.now().subtract(const Duration(days: AppConstants.retentionDays));

    await _dropOlderThan<ScanResultModel>(_scanBox, cutoff, (r) => r.timestamp);
    await _dropOlderThan<AlertModel>(_alertsBox, cutoff, (a) => a.timestamp);
    await _dropOlderThan<WifiScanModel>(_wifiBox, cutoff, (s) => s.timestamp);
    await _dropOlderThan<ScoreEntryModel>(_scoreBox, cutoff, (e) => e.date);

    await _trimToCap<ScanResultModel>(
        _scanBox, AppConstants.maxScanResults, (r) => r.timestamp,
        force: true);
    await _trimToCap<AlertModel>(
        _alertsBox, AppConstants.maxAlerts, (a) => a.timestamp,
        force: true);
    await _trimToCap<WifiScanModel>(
        _wifiBox, AppConstants.maxWifiScans, (s) => s.timestamp,
        force: true);
    await _trimToCap<ScoreEntryModel>(
        _scoreBox, AppConstants.maxScoreEntries, (e) => e.date,
        force: true);
  }

  static Future<void> _dropOlderThan<T>(
    Box<T> box,
    DateTime cutoff,
    DateTime Function(T) stamp,
  ) async {
    final doomed = <dynamic>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null && stamp(value).isBefore(cutoff)) doomed.add(key);
    }
    if (doomed.isNotEmpty) await box.deleteAll(doomed);
  }

  /// Trims [box] down to its newest [cap] entries.
  ///
  /// Sorting is the expensive part, so on the write path this no-ops until the
  /// box is [AppConstants.pruneSlack] past the cap — the cost is paid once
  /// every `pruneSlack` writes rather than on every single one. [force] skips
  /// that hysteresis for the launch sweep.
  static Future<void> _trimToCap<T>(
    Box<T> box,
    int cap,
    DateTime Function(T) stamp, {
    bool force = false,
  }) async {
    final threshold = force ? cap : cap + AppConstants.pruneSlack;
    if (box.length <= threshold) return;

    final entries = <(dynamic, DateTime)>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null) entries.add((key, stamp(value)));
    }
    entries.sort((a, b) => b.$2.compareTo(a.$2)); // newest first

    final doomed = entries.skip(cap).map((e) => e.$1).toList();
    if (doomed.isNotEmpty) await box.deleteAll(doomed);
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

  /// Records a module's score after that module has actually run.
  ///
  /// This is the write the dashboard tiles read on their next load. Without
  /// it the tiles kept reporting `SettingsModel`'s default of 85 no matter
  /// what any scanner found — scanning a device full of dangerous apps left
  /// the Malware tile reading 85, and the Wi-Fi tile only ever moved because
  /// the dashboard's own quick scan happened to write it.
  ///
  /// `lastScanDate` is stamped here too, because a module producing a score
  /// *is* the app having scanned; leaving that to the caller is how the two
  /// drifted apart.
  static Future<void> updateModuleScore(String module, int score) async {
    final s = getSettings();
    final clamped = score.clamp(0, 100);
    await saveSettings(
      s.copyWith(
        phishingScore: module == 'phishing' ? clamped : null,
        malwareScore: module == 'malware' ? clamped : null,
        breachScore: module == 'breach' ? clamped : null,
        wifiScore: module == 'wifi' ? clamped : null,
        lastScanDate: DateTime.now(),
      ),
    );
  }

  // ── Scan Results ──────────────────────────────────────────────────────────

  static Box<ScanResultModel> get _scanBox =>
      Hive.box<ScanResultModel>(AppConstants.scanResultsBox);

  static Future<void> saveScanResult(ScanResultModel result) async {
    await _scanBox.put(result.id, result);
    await _trimToCap<ScanResultModel>(
        _scanBox, AppConstants.maxScanResults, (r) => r.timestamp);
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
    await _trimToCap<AlertModel>(
        _alertsBox, AppConstants.maxAlerts, (a) => a.timestamp);
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

  /// Flips every unread alert in one write.
  ///
  /// The previous version called `alert.save()` per alert, which is a separate
  /// disk transaction each — hundreds of them for a busy backlog, on the UI
  /// isolate. `putAll` commits the batch once.
  static Future<void> markAllAlertsRead() async {
    final updates = <dynamic, AlertModel>{};
    for (final key in _alertsBox.keys) {
      final alert = _alertsBox.get(key);
      if (alert != null && !alert.isRead) {
        alert.isRead = true;
        updates[key] = alert;
      }
    }
    if (updates.isNotEmpty) await _alertsBox.putAll(updates);
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
    await _trimToCap<WifiScanModel>(
        _wifiBox, AppConstants.maxWifiScans, (s) => s.timestamp);
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
    await _trimToCap<ScoreEntryModel>(
        _scoreBox, AppConstants.maxScoreEntries, (e) => e.date);
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
