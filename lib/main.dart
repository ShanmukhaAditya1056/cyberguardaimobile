import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/repositories/malware_repository.dart';
import 'data/repositories/phishing_repository.dart';
import 'data/services/hive_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/wifi_ml_service.dart';
import 'app.dart';

/// Singleton WiFi ML service so any provider can read its latest scan.
final wifiMlService = WifiMlService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialise notifications
  await NotificationService.init();

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
