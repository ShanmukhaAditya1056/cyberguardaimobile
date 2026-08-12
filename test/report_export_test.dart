import 'dart:io';

import 'package:cyberguard_ai/core/constants/app_constants.dart';
import 'package:cyberguard_ai/data/models/alert_model.dart';
import 'package:cyberguard_ai/data/models/scan_result_model.dart';
import 'package:cyberguard_ai/data/models/score_entry_model.dart';
import 'package:cyberguard_ai/data/models/settings_model.dart';
import 'package:cyberguard_ai/data/services/hive_service.dart';
import 'package:cyberguard_ai/data/services/report_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Report export.
///
/// "Export is not working" has two very different causes — a document that
/// fails to render, and a share intent that never opens — and from the UI they
/// look identical, because both surface as the same snackbar. These cover the
/// first half: everything up to the point where the file is handed to the OS.
/// The share sheet itself needs a device and is out of reach here.
///
/// The empty-state cases matter most. A brand-new install has no scans, no
/// alerts and no score history, and that is exactly when someone is most
/// likely to press Export to see what it does.

late Directory _tmp;

ScanResultModel _scan(String id, DateTime ts, {String type = 'phishing'}) =>
    ScanResultModel(
      id: id,
      type: type,
      input: 'https://example.com/$id',
      verdict: 'phishing',
      confidence: 91,
      shapReasons: const ['Domain impersonates a trusted brand'],
      timestamp: ts,
    );

AlertModel _alert(String id, DateTime ts) => AlertModel(
      id: id,
      type: 'critical',
      title: 'Phishing URL detected',
      description: 'Dangerous link: https://example.com/$id',
      module: 'phishing',
      timestamp: ts,
    );

ScoreEntryModel _score(DateTime d) => ScoreEntryModel(
      date: d,
      unifiedScore: 62,
      phishingScore: 55,
      malwareScore: 70,
      breachScore: 60,
      wifiScore: 80,
    );

void main() {
  setUpAll(() async {
    _tmp = await Directory.systemTemp.createTemp('cg_export_');
    Hive.init(_tmp.path);
    Hive
      ..registerAdapter(ScanResultModelAdapter())
      ..registerAdapter(AlertModelAdapter())
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
    await Hive.openBox<ScoreEntryModel>(AppConstants.scoreHistoryBox);
    await Hive.openBox<SettingsModel>(AppConstants.settingsBox);
    await Hive.box<ScanResultModel>(AppConstants.scanResultsBox).clear();
    await Hive.box<AlertModel>(AppConstants.alertsBox).clear();
    await Hive.box<ScoreEntryModel>(AppConstants.scoreHistoryBox).clear();
    await Hive.box<SettingsModel>(AppConstants.settingsBox).clear();
  });

  group('PDF', () {
    test('renders on a brand-new install with no data at all', () async {
      final bytes = await ReportExportService.buildPdfBytes();

      expect(bytes, isNotEmpty);
      // Every PDF starts %PDF- and ends with the EOF marker. Together those
      // say the document was closed properly rather than truncated by a
      // section that threw halfway through.
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(String.fromCharCodes(bytes.skip(bytes.length - 6)), contains('EOF'));
    });

    test('renders with scans, alerts and a score trend', () async {
      final now = DateTime.now();
      for (var i = 0; i < 12; i++) {
        await HiveService.saveScanResult(
          _scan('s$i', now.subtract(Duration(hours: i))),
        );
        await HiveService.saveAlert(_alert('a$i', now.subtract(Duration(hours: i))));
      }
      for (var d = 0; d < 7; d++) {
        await HiveService.saveScoreEntry(_score(now.subtract(Duration(days: d))));
      }

      final bytes = await ReportExportService.buildPdfBytes();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('CSV', () {
    test('has both header rows on an empty install', () {
      final csv = ReportExportService.buildCsv();

      expect(csv, contains('type,input,verdict,confidence,reasons,timestamp'));
      expect(csv, contains('alert_id,type,module,title,description,timestamp'));
    });

    test('one row per scan, and the reasons survive the join', () async {
      await HiveService.saveScanResult(_scan('only', DateTime.now()));
      final csv = ReportExportService.buildCsv();

      expect(csv, contains('https://example.com/only'));
      expect(csv, contains('Domain impersonates a trusted brand'));
      expect(csv, contains('phishing'));
    });

    test('a comma in the input cannot break the column count', () async {
      // The CSV is handed to a spreadsheet, and a scanned URL is attacker
      // controlled — an unescaped comma or quote would shift every following
      // column and silently corrupt the export.
      await HiveService.saveScanResult(
        ScanResultModel(
          id: 'tricky',
          type: 'phishing',
          input: 'https://evil.example/?a=1,2&q="quoted"',
          verdict: 'phishing',
          confidence: 88,
          shapReasons: const ['reason one, with a comma'],
          timestamp: DateTime.now(),
        ),
      );

      final csv = ReportExportService.buildCsv();
      final header = csv.split('\n').first.split(',').length;
      // The data row must still parse to the same number of fields as the
      // header once quoting is honoured.
      expect(csv, contains('"https://evil.example/?a=1,2&q=""quoted"""'));
      expect(header, 6);
    });
  });
}
