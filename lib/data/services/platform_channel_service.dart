import 'package:flutter/services.dart';

import '../../core/platform/app_platform.dart';
import '../models/app_info_model.dart';
import 'device/android_device_probe.dart';
import 'device/desktop_device_probe.dart';
import 'device/device_probe.dart';
import 'device/ios_device_probe.dart';

export 'device/device_probe.dart' show ProbeUnsupported;

/// The app's single door to the host operating system.
///
/// This used to be a thin wrapper over one Android `MethodChannel`. It keeps
/// exactly that public shape — every repository and provider that called it
/// still does, unchanged — but now picks an implementation for the host it is
/// running on: Kotlin over a platform channel on Android, the OS's own
/// command-line tools on the three desktops, and the narrow set iOS's sandbox
/// permits on iPhone.
///
/// Calls that no host can satisfy throw [ProbeUnsupported], whose message is
/// written for the user rather than for a crash log. Check
/// [AppPlatform.canEnumerateInstalledApps] and friends before offering a
/// feature so that exception stays a backstop rather than the normal path.
class PlatformChannelService {
  final DeviceProbe _probe;

  PlatformChannelService() : _probe = _probeForHost();

  /// Injection point for tests, which run on the Dart VM where none of the
  /// real probes would work.
  const PlatformChannelService.withProbe(this._probe);

  static DeviceProbe _probeForHost() => switch (AppPlatform.current) {
        HostPlatform.android => const AndroidDeviceProbe(),
        HostPlatform.ios => const IosDeviceProbe(),
        HostPlatform.windows ||
        HostPlatform.macos ||
        HostPlatform.linux =>
          const DesktopDeviceProbe(),
        _ => const _NullDeviceProbe(),
      };

  /// Installed third-party software.
  Future<List<AppInfoModel>> getInstalledApps() => _probe.getInstalledApps();

  /// App icon as PNG bytes, or null when the host cannot extract one.
  Future<Uint8List?> getAppIcon(String packageName) =>
      _probe.getAppIcon(packageName);

  /// The connected network. See [DeviceProbe.getWifiDetails] for the shape.
  Future<Map<String, dynamic>> getWifiDetails() => _probe.getWifiDetails();

  /// Recent inbox messages. Android only.
  Future<List<Map<String, String>>> getRecentSms() => _probe.getRecentSms();

  Future<Map<String, dynamic>> getBatteryInfo() => _probe.getBatteryInfo();

  Future<Map<String, dynamic>> getDeviceInfo() => _probe.getDeviceInfo();

  Future<bool> openAppSettings(String packageName) =>
      _probe.openAppSettings(packageName);

  Future<bool> uninstallApp(String packageName) =>
      _probe.uninstallApp(packageName);
}

/// Stands in on a host none of the real probes claim, so an unexpected
/// platform degrades to "not supported here" rather than a null dereference.
class _NullDeviceProbe implements DeviceProbe {
  const _NullDeviceProbe();

  ProbeUnsupported _unsupported(String capability) => ProbeUnsupported(
        capability: capability,
        platform: AppPlatform.displayName,
        reason: '$capability is not available on ${AppPlatform.displayName}.',
      );

  @override
  Future<List<AppInfoModel>> getInstalledApps() async =>
      throw _unsupported('Installed app scanning');

  @override
  Future<Uint8List?> getAppIcon(String packageName) async => null;

  @override
  Future<Map<String, dynamic>> getWifiDetails() async => {
        'status': 'error',
        'message': 'Wi-Fi analysis is not available on '
            '${AppPlatform.displayName}.',
      };

  @override
  Future<List<Map<String, String>>> getRecentSms() async =>
      throw _unsupported('SMS scanning');

  @override
  Future<Map<String, dynamic>> getBatteryInfo() async =>
      const {'level': -1, 'isCharging': false};

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async => const {};

  @override
  Future<bool> openAppSettings(String packageName) async => false;

  @override
  Future<bool> uninstallApp(String packageName) async => false;
}
