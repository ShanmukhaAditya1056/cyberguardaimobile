import 'hive_service.dart';

/// Lightweight feature flags for the Smart Link Interceptor.
///
/// Stored in the existing string [prefsBox] (via [HiveService.getPref]) rather
/// than the typed `SettingsModel`, so adding interceptor settings needs no
/// Hive schema migration or code generation.
///
/// PRIVACY DEFAULTS (matter — they encode the app's promise):
///   * [interceptorEnabled]  → true   (protect by default)
///   * [linkHistoryEnabled]  → false  (no URL is ever persisted unless opted-in)
///   * [cloudIntelEnabled]   → false  (no data leaves the device unless opted-in)
class InterceptorPrefs {
  InterceptorPrefs._();

  static const _kInterceptorEnabled = 'interceptor_enabled';
  static const _kLinkHistoryEnabled = 'interceptor_link_history';
  static const _kCloudIntelEnabled = 'interceptor_cloud_intel';

  static bool _read(String key, bool fallback) {
    final v = HiveService.getPref(key);
    if (v == null) return fallback;
    return v == 'true';
  }

  static Future<void> _write(String key, bool value) =>
      HiveService.setPref(key, value ? 'true' : 'false');

  static bool get interceptorEnabled => _read(_kInterceptorEnabled, true);
  static Future<void> setInterceptorEnabled(bool v) =>
      _write(_kInterceptorEnabled, v);

  static bool get linkHistoryEnabled => _read(_kLinkHistoryEnabled, false);
  static Future<void> setLinkHistoryEnabled(bool v) =>
      _write(_kLinkHistoryEnabled, v);

  static bool get cloudIntelEnabled => _read(_kCloudIntelEnabled, false);
  static Future<void> setCloudIntelEnabled(bool v) =>
      _write(_kCloudIntelEnabled, v);
}
