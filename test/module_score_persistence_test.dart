import 'dart:io';

import 'package:cyberguard_ai/core/constants/app_constants.dart';
import 'package:cyberguard_ai/data/models/alert_model.dart';
import 'package:cyberguard_ai/data/models/scan_result_model.dart';
import 'package:cyberguard_ai/data/models/score_entry_model.dart';
import 'package:cyberguard_ai/data/models/settings_model.dart';
import 'package:cyberguard_ai/data/models/wifi_scan_model.dart';
import 'package:cyberguard_ai/data/services/hive_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Scanning has to move the tile.
///
/// It did not. Nothing persisted a module score except the dashboard's own
/// Wi-Fi quick scan, so running the Malware, Phishing or Breach scanner left
/// its tile reporting SettingsModel's default of 85 for ever — a device full
/// of dangerous apps still read "85 / 100, protected".
///
/// `updateModuleScore` is the single write those paths now share, and these
/// pin the two properties that matter: the right module moves, and the others
/// do not.

late Directory _tmp;

void main() {
  setUpAll(() async {
    _tmp = await Directory.systemTemp.createTemp('cg_scores_');
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
    await Hive.openBox<SettingsModel>(AppConstants.settingsBox);
    await Hive.box<SettingsModel>(AppConstants.settingsBox).clear();
  });

  test('writing one module leaves the other three alone', () async {
    await HiveService.updateModuleScore('malware', 32);
    final s = HiveService.getSettings();

    expect(s.malwareScore, 32);
    expect(s.phishingScore, 85, reason: 'untouched modules keep their value');
    expect(s.breachScore, 85);
    expect(s.wifiScore, 85);
  });

  test('each module writes its own field', () async {
    await HiveService.updateModuleScore('phishing', 10);
    await HiveService.updateModuleScore('malware', 20);
    await HiveService.updateModuleScore('breach', 30);
    await HiveService.updateModuleScore('wifi', 40);

    final s = HiveService.getSettings();
    expect(s.phishingScore, 10);
    expect(s.malwareScore, 20);
    expect(s.breachScore, 30);
    expect(s.wifiScore, 40);
  });

  test('a score is stamped with the time it was measured', () async {
    expect(HiveService.getSettings().lastScanDate, isNull);

    await HiveService.updateModuleScore('wifi', 70);

    final stamped = HiveService.getSettings().lastScanDate;
    expect(stamped, isNotNull);
    // A module producing a score *is* the app having scanned. Leaving that to
    // the caller is how the tile and the "last scan" line drifted apart.
    expect(DateTime.now().difference(stamped!).inSeconds, lessThan(5));
  });

  test('out-of-range values are clamped rather than stored raw', () async {
    await HiveService.updateModuleScore('wifi', 140);
    expect(HiveService.getSettings().wifiScore, 100);

    await HiveService.updateModuleScore('wifi', -20);
    expect(HiveService.getSettings().wifiScore, 0);
  });

  test('an unknown module name changes nothing', () async {
    await HiveService.updateModuleScore('malware', 44);
    await HiveService.updateModuleScore('not_a_module', 1);

    final s = HiveService.getSettings();
    expect(s.malwareScore, 44);
    expect(s.phishingScore, 85);
    expect(s.wifiScore, 85);
    expect(s.breachScore, 85);
  });
}
