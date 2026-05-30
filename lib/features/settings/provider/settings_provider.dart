import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/services/hive_service.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier() : super(HiveService.getSettings()) {
    _load();
  }

  void _load() {
    state = HiveService.getSettings();
  }

  Future<void> setRealTimeAlerts(bool value) async {
    state = state.copyWith(realTimeAlerts: value);
    await HiveService.saveSettings(state);
  }

  Future<void> setClipboardScan(bool value) async {
    state = state.copyWith(clipboardScan: value);
    await HiveService.saveSettings(state);
  }

  Future<void> setWifiAutoScan(bool value) async {
    state = state.copyWith(wifiAutoScan: value);
    await HiveService.saveSettings(state);
  }

  Future<void> setAutoScanFrequency(int hours) async {
    state = state.copyWith(autoScanFrequency: hours.toString());
    await HiveService.saveSettings(state);
  }

  Future<void> setHibpApiKey(String key) async {
    state = state.copyWith(hibpApiKey: key);
    await HiveService.saveSettings(state);
  }

  Future<void> clearHibpApiKey() async {
    state = state.copyWith(hibpApiKey: '');
    await HiveService.saveSettings(state);
  }

  Future<void> resetAll() async {
    state = SettingsModel(
      realTimeAlerts: true,
      clipboardScan: true,
      autoScanFrequency: '24',
      wifiAutoScan: false,
      hibpApiKey: '',
      onboardingComplete: true,
    );
    await HiveService.saveSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (_) => SettingsNotifier(),
);
