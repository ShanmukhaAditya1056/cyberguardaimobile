import 'dart:io';

import 'package:cyberguard_ai/core/constants/app_constants.dart';
import 'package:cyberguard_ai/data/models/alert_model.dart';
import 'package:cyberguard_ai/data/models/scan_result_model.dart';
import 'package:cyberguard_ai/data/models/score_entry_model.dart';
import 'package:cyberguard_ai/data/models/wifi_scan_model.dart';
import 'package:cyberguard_ai/data/services/hive_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Retention guards. These boxes used to grow without limit, which cost disk
/// and — because getAlerts()/getScanResults() read and re-sort the whole box
/// on every call — made each read slower the longer the app was installed.
///
/// Pruning deletes user data, so the important assertions here are not just
/// "the box shrank" but "the newest rows survived and the oldest went".

late Directory _tmp;

AlertModel _alert(String id, DateTime ts) => AlertModel(
      id: id,
      type: 'warning',
      title: 'alert $id',
      description: 'd',
      module: 'phishing',
      timestamp: ts,
    );

ScanResultModel _scan(String id, DateTime ts) => ScanResultModel(
      id: id,
      type: 'phishing',
      input: 'https://example.com/$id',
      verdict: 'safe',
      confidence: 50,
      shapReasons: const [],
      timestamp: ts,
    );

WifiScanModel _wifi(DateTime ts) => WifiScanModel(
      ssid: 'net',
      bssid: '00:11:22:33:44:55',
      rssi: -50,
      trustScore: 80,
      riskLevel: 'safe',
      checks: const <String>[],
      timestamp: ts,
      ipAddress: '192.168.0.2',
      frequency: 2400,
      linkSpeed: 100,
    );

ScoreEntryModel _score(DateTime d) => ScoreEntryModel(
      date: d,
      unifiedScore: 70,
      phishingScore: 70,
      malwareScore: 70,
      breachScore: 70,
      wifiScore: 70,
    );

void main() {
  setUpAll(() async {
    _tmp = await Directory.systemTemp.createTemp('cg_retention_');
    Hive.init(_tmp.path);
    Hive
      ..registerAdapter(ScanResultModelAdapter())
      ..registerAdapter(AlertModelAdapter())
      ..registerAdapter(WifiScanModelAdapter())
      ..registerAdapter(ScoreEntryModelAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await _tmp.delete(recursive: true);
  });

  setUp(() async {
    // HiveService reads these by name, so opening them here is enough.
    await Hive.openBox<ScanResultModel>(AppConstants.scanResultsBox);
    await Hive.openBox<AlertModel>(AppConstants.alertsBox);
    await Hive.openBox<WifiScanModel>(AppConstants.wifiScansBox);
    await Hive.openBox<ScoreEntryModel>(AppConstants.scoreHistoryBox);
    await Hive.box<ScanResultModel>(AppConstants.scanResultsBox).clear();
    await Hive.box<AlertModel>(AppConstants.alertsBox).clear();
    await Hive.box<WifiScanModel>(AppConstants.wifiScansBox).clear();
    await Hive.box<ScoreEntryModel>(AppConstants.scoreHistoryBox).clear();
  });

  group('write-path capping', () {
    test('alerts stay bounded and keep the newest', () async {
      final base = DateTime(2026, 1, 1);
      final overshoot = AppConstants.maxAlerts + AppConstants.pruneSlack + 10;

      for (var i = 0; i < overshoot; i++) {
        await HiveService.saveAlert(_alert('a$i', base.add(Duration(minutes: i))));
      }

      final kept = HiveService.getAlerts();
      // Hysteresis means the write path holds the box between cap and
      // cap + slack; only the launch sweep forces it down to exactly cap.
      // cap + slack is the hard bound that matters for disk and read cost.
      expect(kept.length,
          lessThanOrEqualTo(AppConstants.maxAlerts + AppConstants.pruneSlack),
          reason: 'box grew past its hard bound');
      expect(kept.length, lessThan(overshoot),
          reason: 'nothing was pruned at all');

      // getAlerts() sorts newest first, and the newest write must survive.
      expect(kept.first.id, 'a${overshoot - 1}');
      // The very first (oldest) write must be gone.
      expect(kept.any((a) => a.id == 'a0'), isFalse,
          reason: 'oldest alert should have been pruned, not a newer one');
    });

    test('scan results stay bounded and keep the newest', () async {
      final base = DateTime(2026, 1, 1);
      final overshoot =
          AppConstants.maxScanResults + AppConstants.pruneSlack + 10;

      for (var i = 0; i < overshoot; i++) {
        await HiveService.saveScanResult(
            _scan('s$i', base.add(Duration(minutes: i))));
      }

      final kept = HiveService.getScanResults();
      expect(
          kept.length,
          lessThanOrEqualTo(
              AppConstants.maxScanResults + AppConstants.pruneSlack));
      expect(kept.length, lessThan(overshoot));
      expect(kept.first.id, 's${overshoot - 1}');
      expect(kept.any((r) => r.id == 's0'), isFalse);
    });

    test('pruning is amortised — it does not fire on every write', () async {
      final base = DateTime(2026, 1, 1);
      // Fill to exactly the cap, then add fewer rows than the slack.
      for (var i = 0; i < AppConstants.maxAlerts; i++) {
        await HiveService.saveAlert(_alert('a$i', base.add(Duration(minutes: i))));
      }
      final extra = AppConstants.pruneSlack - 1;
      for (var i = 0; i < extra; i++) {
        await HiveService.saveAlert(
            _alert('extra$i', base.add(Duration(days: 1, minutes: i))));
      }

      // Still inside the hysteresis window, so nothing has been trimmed yet.
      expect(Hive.box<AlertModel>(AppConstants.alertsBox).length,
          AppConstants.maxAlerts + extra);
    });
  });

  group('launch sweep', () {
    test('drops entries older than the retention window', () async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: AppConstants.retentionDays + 5));
      final fresh = now.subtract(const Duration(days: 1));

      final alerts = Hive.box<AlertModel>(AppConstants.alertsBox);
      await alerts.put('old', _alert('old', old));
      await alerts.put('fresh', _alert('fresh', fresh));

      final scans = Hive.box<ScanResultModel>(AppConstants.scanResultsBox);
      await scans.put('old', _scan('old', old));
      await scans.put('fresh', _scan('fresh', fresh));

      final wifi = Hive.box<WifiScanModel>(AppConstants.wifiScansBox);
      await wifi.put('old', _wifi(old));
      await wifi.put('fresh', _wifi(fresh));

      final scores = Hive.box<ScoreEntryModel>(AppConstants.scoreHistoryBox);
      await scores.put('old', _score(old));
      await scores.put('fresh', _score(fresh));

      await HiveService.sweepExpired();

      for (final box in [alerts, scans, wifi, scores]) {
        expect(box.containsKey('old'), isFalse,
            reason: '${box.name}: expired row survived the sweep');
        expect(box.containsKey('fresh'), isTrue,
            reason: '${box.name}: in-window row was wrongly deleted');
      }
    });

    test('trims a pre-existing backlog down to the cap', () async {
      // Simulates upgrading an install that predates any retention policy:
      // rows are written straight to the box, bypassing the capped setters.
      final alerts = Hive.box<AlertModel>(AppConstants.alertsBox);
      final base = DateTime.now().subtract(const Duration(days: 2));
      for (var i = 0; i < AppConstants.maxAlerts + 200; i++) {
        await alerts.put('a$i', _alert('a$i', base.add(Duration(seconds: i))));
      }
      expect(alerts.length, greaterThan(AppConstants.maxAlerts));

      await HiveService.sweepExpired();

      expect(alerts.length, AppConstants.maxAlerts);
      expect(alerts.containsKey('a0'), isFalse);
    });
  });

  group('batched writes', () {
    test('markAllAlertsRead flips every unread alert', () async {
      final base = DateTime(2026, 1, 1);
      for (var i = 0; i < 20; i++) {
        await HiveService.saveAlert(_alert('a$i', base.add(Duration(minutes: i))));
      }
      expect(HiveService.getUnreadAlertCount(), 20);

      await HiveService.markAllAlertsRead();

      expect(HiveService.getUnreadAlertCount(), 0);
      expect(HiveService.getAlerts().every((a) => a.isRead), isTrue);
    });
  });
}
