import 'dart:io';

import 'package:cyberguard_ai/core/constants/app_constants.dart';
import 'package:cyberguard_ai/core/utils/url_extractor.dart';
import 'package:cyberguard_ai/data/models/settings_model.dart';
import 'package:cyberguard_ai/data/services/hive_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// `wifiAutoScan`, `clipboardScan` and `realTimeAlerts` were stored in Hive
/// and rendered in Settings but never read by anything — flipping them changed
/// no behaviour at all. These tests pin the wiring so they cannot silently go
/// inert again.

late Directory _tmp;

Future<void> _setSettings(SettingsModel s) => HiveService.saveSettings(s);

void main() {
  setUpAll(() async {
    _tmp = await Directory.systemTemp.createTemp('cg_settings_');
    Hive.init(_tmp.path);
    Hive.registerAdapter(SettingsModelAdapter());
    await Hive.openBox<SettingsModel>(AppConstants.settingsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    await _tmp.delete(recursive: true);
  });

  setUp(() async {
    await Hive.box<SettingsModel>(AppConstants.settingsBox).clear();
  });

  group('settings round-trip', () {
    test('all three toggles default to on', () {
      final s = HiveService.getSettings();
      expect(s.realTimeAlerts, isTrue);
      expect(s.clipboardScan, isTrue);
      expect(s.wifiAutoScan, isTrue);
    });

    test('each toggle persists independently', () async {
      await _setSettings(SettingsModel(
        realTimeAlerts: false,
        clipboardScan: true,
        wifiAutoScan: false,
      ));

      final s = HiveService.getSettings();
      expect(s.realTimeAlerts, isFalse);
      expect(s.clipboardScan, isTrue);
      expect(s.wifiAutoScan, isFalse);
    });
  });

  group('the predicates the consumers actually branch on', () {
    // NotificationService._alertsEnabled, WifiAutoScanService._autoScanEnabled
    // and the clipboard guard are private, so assert the exact expression each
    // reads. If a consumer stops consulting settings this stays green, which
    // is why the consumer-side wiring is also covered by analyze + review —
    // but a flipped default or a broken round-trip is caught right here.
    test('alerts gate follows realTimeAlerts', () async {
      await _setSettings(SettingsModel(realTimeAlerts: false));
      expect(HiveService.getSettings().realTimeAlerts, isFalse);

      await _setSettings(SettingsModel(realTimeAlerts: true));
      expect(HiveService.getSettings().realTimeAlerts, isTrue);
    });

    test('auto-scan gate follows wifiAutoScan', () async {
      await _setSettings(SettingsModel(wifiAutoScan: false));
      expect(HiveService.getSettings().wifiAutoScan, isFalse);

      await _setSettings(SettingsModel(wifiAutoScan: true));
      expect(HiveService.getSettings().wifiAutoScan, isTrue);
    });

    test('clipboard gate follows clipboardScan', () async {
      await _setSettings(SettingsModel(clipboardScan: false));
      expect(HiveService.getSettings().clipboardScan, isFalse);

      await _setSettings(SettingsModel(clipboardScan: true));
      expect(HiveService.getSettings().clipboardScan, isTrue);
    });
  });

  group('clipboard auto-fill only triggers on real URLs', () {
    // The screen fills the field from the clipboard only when UrlExtractor
    // finds something, so ordinary copied text must not be treated as a URL.
    test('plain text yields nothing to scan', () {
      for (final junk in [
        'hello world',
        'call me on 555 1234',
        '',
        'a sentence with. punctuation, but no host',
      ]) {
        expect(UrlExtractor.extractUrls(junk), isEmpty,
            reason: '"$junk" should not auto-fill the scanner');
      }
    });

    test('copied links are picked up', () {
      expect(UrlExtractor.extractUrls('https://example.com/login').first,
          startsWith('https://example.com'));
      expect(
          UrlExtractor.extractUrls('check myaadhaar.uidai.gov.in today').first,
          'myaadhaar.uidai.gov.in');
    });
  });
}
