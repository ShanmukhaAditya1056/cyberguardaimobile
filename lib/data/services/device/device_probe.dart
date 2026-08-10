import 'dart:typed_data';

import '../../models/app_info_model.dart';

/// Everything the app needs to learn from the host operating system.
///
/// On Android every one of these is a `MethodChannel` hop into Kotlin. The
/// desktops answer the same questions by shelling out to the tools the OS
/// already ships (`netsh`, `nmcli`, `system_profiler`, the registry), and iOS
/// answers most of them with "not permitted" because its sandbox forbids one
/// app from inspecting another.
///
/// Keeping all of that behind one interface is what lets the repositories,
/// providers and screens stay platform-agnostic: they ask for installed apps
/// and get either a real inventory or [ProbeUnsupported], never a
/// `MissingPluginException` from three layers down.
abstract class DeviceProbe {
  /// Installed third-party software, newest first.
  ///
  /// Throws [ProbeUnsupported] where the OS has no such API.
  Future<List<AppInfoModel>> getInstalledApps();

  /// The app's icon as PNG bytes, or null when it cannot be extracted.
  Future<Uint8List?> getAppIcon(String packageName);

  /// The connected network, in the shape `WifiRepository` consumes:
  ///
  /// ```
  /// status      one of connected | wifi_off | not_connected |
  ///             permission_required | location_off | error
  /// ssid        network name, '' when redacted
  /// bssid       access-point MAC, '' when unavailable
  /// rssi        signal in dBm (negative)
  /// linkSpeed   Mbps
  /// frequency   MHz
  /// ipAddress   this host's address on the network
  /// isSecured   true unless the network is provably open
  /// hasInternet reachability probe result
  /// message     human-readable detail, only when status != connected
  /// ```
  Future<Map<String, dynamic>> getWifiDetails();

  /// Recent inbox messages as `{address, body, date}` maps.
  ///
  /// Throws [ProbeUnsupported] anywhere but Android.
  Future<List<Map<String, String>>> getRecentSms();

  /// `{level: 0-100, isCharging: bool}`. `level` is -1 when unknown.
  Future<Map<String, dynamic>> getBatteryInfo();

  /// Free-form host description — model, OS version, manufacturer.
  Future<Map<String, dynamic>> getDeviceInfo();

  /// Open the OS settings/details page for an installed app.
  /// Returns false when the host cannot do it.
  Future<bool> openAppSettings(String packageName);

  /// Launch the OS uninstall flow. Returns false when the host cannot do it.
  Future<bool> uninstallApp(String packageName);
}

/// Thrown when a probe method has no implementation on the current OS.
///
/// This is a normal, expected outcome — the App Scanner on iOS, the SMS guard
/// on Windows — not a bug. Callers surface [reason] to the user verbatim.
class ProbeUnsupported implements Exception {
  final String capability;
  final String platform;
  final String reason;

  const ProbeUnsupported({
    required this.capability,
    required this.platform,
    required this.reason,
  });

  @override
  String toString() => reason;
}
