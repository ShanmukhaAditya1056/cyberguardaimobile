import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/repositories/malware_repository.dart';
import 'data/repositories/phishing_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/hive_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/wifi_auto_scan_service.dart';
import 'data/services/wifi_ml_service.dart';
import 'app.dart';

/// Singleton WiFi ML service so any provider can read its latest scan.
final wifiMlService = WifiMlService();

/// Inter and the three Noto Sans faces are bundled under the SIL Open Font
/// License, which requires the licence to travel with the binary. Registering
/// them here surfaces both texts in the standard `showLicensePage` sheet.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in const <(String, List<String>)>[
      ('assets/fonts/OFL-Inter.txt', ['Inter']),
      (
        'assets/fonts/OFL-NotoSans.txt',
        ['Noto Sans Devanagari', 'Noto Sans Tamil', 'Noto Sans Telugu'],
      ),
    ]) {
      final text = await rootBundle.loadString(entry.$1);
      yield LicenseEntryWithLineBreaks(entry.$2, text);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _registerFontLicenses();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full immersive edge-to-edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialise Hive
  await HiveService.init();

  // Optional: no-ops when the build has no google-services.json. Never throws,
  // so a missing Firebase project cannot stop the app from starting.
  await AuthService.init();

  // Initialise notifications
  await NotificationService.init();

  // Backs the "Auto Wi-Fi Scan" setting. Subscribing costs nothing while the
  // device stays put — the service only wakes on a connectivity change, and
  // re-reads the setting on each event.
  WifiAutoScanService.instance.start();

  // Warm up every on-device ML model. Each call no-ops if its asset is
  // missing, so a partial bundle never blocks app start.
  unawaited(PhishingRepository.warmUpMl());
  unawaited(MalwareRepository.warmUpMl());
  unawaited(wifiMlService.load());

  runApp(
    const ProviderScope(
      child: CyberGuardApp(),
    ),
  );
}
