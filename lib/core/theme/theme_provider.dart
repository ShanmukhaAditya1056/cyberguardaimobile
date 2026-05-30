import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/hive_service.dart';

/// Persisted app theme mode. Stored as a plain string in the lightweight
/// `prefs` Hive box so adding it does NOT require re-generating any Hive
/// adapter for the existing SettingsModel.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final raw = HiveService.getPref(_key);
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      default:
        // Light by default — the app's brand look is the Zomato-style
        // light theme. Users can opt into dark via Settings.
        return ThemeMode.light;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await HiveService.setPref(_key, switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    });
  }

  Future<void> toggle() async {
    // Cycles system → light → dark → system, but the toggle in Settings
    // calls `set(...)` directly so this is mostly for quick access.
    await set(switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((_) => ThemeModeNotifier());
