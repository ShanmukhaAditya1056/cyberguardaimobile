import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/hive_service.dart';

/// Supported app locales. Order is what shows in the Settings picker.
const supportedLocales = <Locale>[
  Locale('en'),
  Locale('hi'),
  Locale('ta'),
  Locale('te'),
];

class LocaleNotifier extends StateNotifier<Locale?> {
  static const _key = 'locale';

  LocaleNotifier() : super(_loadInitial());

  static Locale? _loadInitial() {
    final raw = HiveService.getPref(_key);
    if (raw == null || raw.isEmpty || raw == 'system') return null;
    return Locale(raw);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    await HiveService.setPref(_key, locale?.languageCode ?? 'system');
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((_) => LocaleNotifier());
