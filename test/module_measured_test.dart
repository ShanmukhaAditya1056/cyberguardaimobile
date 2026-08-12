import 'dart:io';

import 'package:cyberguard_ai/core/constants/app_constants.dart';
import 'package:cyberguard_ai/data/models/alert_model.dart';
import 'package:cyberguard_ai/data/models/scan_result_model.dart';
import 'package:cyberguard_ai/data/models/score_entry_model.dart';
import 'package:cyberguard_ai/data/models/settings_model.dart';
import 'package:cyberguard_ai/data/models/wifi_scan_model.dart';
import 'package:cyberguard_ai/data/services/hive_service.dart';
import 'package:cyberguard_ai/features/dashboard/provider/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// A module tile must never show a score it did not measure.
///
/// `SettingsModel` defaults every module score to 85 and persists it, so a
/// fresh install has four plausible-looking numbers that came from nowhere.
/// Rendering those as findings tells someone they are protected on the
/// strength of a default value, which is the single most damaging thing a
/// security tool can get wrong.
///
/// `measuredModules` is what separates "measured 85" from "never ran", and
/// these pin its derivation. Note it deliberately does *not* come from a
/// stored flag — it is recomputed from the scans that exist, so clearing
/// history correctly takes the tiles back to "not scanned".

late Directory _tmp;

ScanResultModel _scan(String type) => ScanResultModel(
      id: '$type-1',
      type: type,
      input: 'x',
      verdict: 'safe',
      confidence: 50,
      shapReasons: const [],
      timestamp: DateTime.now(),
    );

WifiScanModel _wifi() => WifiScanModel(
      ssid: 'net',
      bssid: '00:11:22:33:44:55',
      rssi: -50,
      trustScore: 80,
      riskLevel: 'safe',
      checks: const <String>[],
      timestamp: DateTime.now(),
      ipAddress: '192.168.0.2',
      frequency: 2400,
      linkSpeed: 100,
    );

void main() {
  setUpAll(() async {
    _tmp = await Directory.systemTemp.createTemp('cg_measured_');
    Hive.init(_tmp.path);
    Hive
      ..registerAdapter(ScanResultModelAdapter())
      ..registerAdapter(AlertModelAdapter())
      ..registerAdapter(WifiScanModelAdapter())
      ..registerAdapter(ScoreEntryModelAdapter())
      ..registerAdapter(SettingsModelAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await _tmp.delete(recursive: true);
  });

  setUp(() async {
    await Hive.openBox<ScanResultModel>(AppConstants.scanResultsBox);
    await Hive.openBox<AlertModel>(AppConstants.alertsBox);
    await Hive.openBox<WifiScanModel>(AppConstants.wifiScansBox);
    await Hive.openBox<ScoreEntryModel>(AppConstants.scoreHistoryBox);
    await Hive.openBox<SettingsModel>(AppConstants.settingsBox);
    await Hive.box<ScanResultModel>(AppConstants.scanResultsBox).clear();
    await Hive.box<AlertModel>(AppConstants.alertsBox).clear();
    await Hive.box<WifiScanModel>(AppConstants.wifiScansBox).clear();
    await Hive.box<ScoreEntryModel>(AppConstants.scoreHistoryBox).clear();
    await Hive.box<SettingsModel>(AppConstants.settingsBox).clear();
  });

  Future<DashboardState> load() async {
    final notifier = DashboardNotifier();
    await notifier.loadDashboard();
    return notifier.state;
  }

  test('a fresh install has measured nothing, despite the stored 85s', () async {
    final state = await load();

    expect(state.measuredModules, isEmpty);
    // The scores are still 85 — that is what is persisted. The point is that
    // nothing in the set vouches for them, so the UI shows a dash instead.
    expect(state.phishingScore, 85);
  });

  test('a phishing scan marks only phishing as measured', () async {
    await HiveService.saveScanResult(_scan('phishing'));
    final state = await load();

    expect(state.measuredModules, {'phishing'});
    expect(state.measuredModules, isNot(contains('malware')));
    expect(state.measuredModules, isNot(contains('breach')));
    expect(state.measuredModules, isNot(contains('wifi')));
  });

  test('malware and breach scans each mark their own module', () async {
    await HiveService.saveScanResult(_scan('malware'));
    await HiveService.saveScanResult(_scan('breach'));
    final state = await load();

    expect(state.measuredModules, containsAll(<String>['malware', 'breach']));
    expect(state.measuredModules, isNot(contains('phishing')));
  });

  test('Wi-Fi is measured from its own box, not from scan results', () async {
    // Wi-Fi writes WifiScanModel rather than a ScanResultModel. Deriving the
    // set from the scan-results box alone would report Wi-Fi as never run no
    // matter how many networks had been analysed.
    await HiveService.saveWifiScan(_wifi());
    final state = await load();

    expect(state.measuredModules, contains('wifi'));
  });

  test('an intercepted link does not vouch for the phishing module', () async {
    // link_intercept is a real stored scan, but it is the interceptor's own
    // record rather than a run of the Phishing scanner, and it must not light
    // up a tile the user never opened.
    await HiveService.saveScanResult(_scan('link_intercept'));
    final state = await load();

    expect(state.measuredModules, isEmpty);
  });
}
