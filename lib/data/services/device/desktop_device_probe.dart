import 'dart:io';
import 'dart:typed_data';

import '../../../core/platform/app_platform.dart';
import '../../models/app_info_model.dart';
import 'desktop/linux_probe.dart';
import 'desktop/macos_probe.dart';
import 'desktop/windows_probe.dart';
import 'device_probe.dart';
import 'host_shell.dart';

/// Windows, macOS and Linux behind one [DeviceProbe].
///
/// The per-OS work lives in the three probes this delegates to; what stays here
/// is everything the desktops answer the same way — the host's address on the
/// network, whether traffic actually reaches the internet, battery and host
/// description — all of which `dart:io` can do without shelling out at all.
class DesktopDeviceProbe implements DeviceProbe {
  final WindowsProbe _windows;
  final MacosProbe _macos;
  final LinuxProbe _linux;

  const DesktopDeviceProbe({
    WindowsProbe windows = const WindowsProbe(),
    MacosProbe macos = const MacosProbe(),
    LinuxProbe linux = const LinuxProbe(),
  })  : _windows = windows,
        _macos = macos,
        _linux = linux;

  @override
  Future<List<AppInfoModel>> getInstalledApps() {
    if (Platform.isWindows) return _windows.getInstalledApps();
    if (Platform.isMacOS) return _macos.getInstalledApps();
    if (Platform.isLinux) return _linux.getInstalledApps();
    throw ProbeUnsupported(
      capability: 'installed apps',
      platform: AppPlatform.displayName,
      reason: 'Reading installed software is not supported on '
          '${AppPlatform.displayName}.',
    );
  }

  /// Desktop icons live in `.ico`/`.icns`/theme directories in formats Flutter
  /// cannot decode without a native decoder, so the App Scanner falls back to
  /// its generated letter avatar. The inventory data — name, publisher,
  /// capabilities, provenance — is unaffected.
  @override
  Future<Uint8List?> getAppIcon(String packageName) async => null;

  @override
  Future<Map<String, dynamic>> getWifiDetails() async {
    final Map<String, dynamic> details;
    if (Platform.isWindows) {
      details = await _windows.getWifiDetails();
    } else if (Platform.isMacOS) {
      details = await _macos.getWifiDetails();
    } else if (Platform.isLinux) {
      details = await _linux.getWifiDetails();
    } else {
      return {
        'status': 'error',
        'message': 'Wi-Fi analysis is not supported on '
            '${AppPlatform.displayName}.',
      };
    }

    if (details['status'] != 'connected') return details;

    // Both are host-level facts the per-OS probes have no reason to duplicate.
    final network = await Future.wait([
      localIpAddress(),
      hasInternetAccess(),
    ]);

    return {
      ...details,
      'ipAddress': network[0] as String,
      'hasInternet': network[1] as bool,
    };
  }

  @override
  Future<List<Map<String, String>>> getRecentSms() async {
    throw ProbeUnsupported(
      capability: 'SMS',
      platform: AppPlatform.displayName,
      reason: 'SMS scanning needs a phone. '
          '${AppPlatform.displayName} has no message inbox to read.',
    );
  }

  @override
  Future<Map<String, dynamic>> getBatteryInfo() async {
    if (Platform.isWindows) {
      final rows = await HostShell.powershellJson(
        r"Get-CimInstance Win32_Battery | Select-Object -First 1 "
        r"EstimatedChargeRemaining,BatteryStatus | ConvertTo-Json -Compress",
        timeout: const Duration(seconds: 10),
      );
      if (rows.isEmpty) return const {'level': -1, 'isCharging': false};
      return {
        'level': (rows.first['EstimatedChargeRemaining'] as num?)?.toInt() ?? -1,
        // Win32_Battery status 2 is "AC connected"; every other value means
        // the machine is running on the battery.
        'isCharging': (rows.first['BatteryStatus'] as num?)?.toInt() == 2,
      };
    }

    if (Platform.isMacOS) {
      final result = await HostShell.run('pmset', ['-g', 'batt'],
          timeout: const Duration(seconds: 8));
      final percent =
          RegExp(r'(\d{1,3})%').firstMatch(result.stdout)?.group(1);
      return {
        'level': int.tryParse(percent ?? '') ?? -1,
        'isCharging': result.stdout.contains('AC Power'),
      };
    }

    if (Platform.isLinux) {
      final result = await HostShell.run(
        '/bin/sh',
        [
          '-c',
          r'''cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1;
              cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1'''
        ],
        timeout: const Duration(seconds: 8),
      );
      final lines = result.lines;
      if (lines.isEmpty) return const {'level': -1, 'isCharging': false};
      return {
        'level': int.tryParse(lines.first) ?? -1,
        'isCharging': lines.length > 1 && lines[1] == 'Charging',
      };
    }

    return const {'level': -1, 'isCharging': false};
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async => {
        'platform': AppPlatform.displayName,
        'osVersion': Platform.operatingSystemVersion,
        'hostname': Platform.localHostname,
        'cores': Platform.numberOfProcessors,
        'locale': Platform.localeName,
      };

  /// Opens the OS's own management UI for installed software. Which page that
  /// is differs per platform — Windows has a global list, macOS and Linux only
  /// have a file manager — so this reveals the app rather than pretending to
  /// show a per-app settings screen that does not exist.
  @override
  Future<bool> openAppSettings(String packageName) async {
    if (Platform.isWindows) {
      final result = await HostShell.run(
          'cmd', ['/c', 'start', '', 'ms-settings:appsfeatures']);
      return result.ok;
    }
    if (Platform.isMacOS) {
      final result = await HostShell.run('open', ['-R', packageName]);
      return result.ok;
    }
    if (Platform.isLinux) {
      final result = await HostShell.run('xdg-open', [packageName]);
      return result.ok;
    }
    return false;
  }

  /// Uninstalling is deliberately not automated.
  ///
  /// On Android the platform channel hands the request to the system's own
  /// uninstall dialog, so the user still confirms and the OS still does the
  /// work. There is no equivalent on the desktops — removing software means
  /// running an installer's uninstall string, `rm -rf` on a bundle, or a
  /// package manager as root. A security scanner deleting files based on a
  /// heuristic score is not a trade this app should make, so the App Scanner
  /// shows the app in the OS's own manager instead.
  @override
  Future<bool> uninstallApp(String packageName) => openAppSettings(packageName);

  // ── Shared host facts ────────────────────────────────────────────────────

  /// This machine's address on the local network.
  ///
  /// Loopback and link-local addresses are skipped: neither tells the user
  /// anything about the network they are connected to.
  static Future<String> localIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.isLoopback) continue;
          if (address.address.startsWith('169.254.')) continue;
          return address.address;
        }
      }
    } catch (_) {
      // Permission-denied enumerating interfaces (hardened sandbox).
    }
    return '0.0.0.0';
  }

  /// Whether traffic actually leaves the network.
  ///
  /// A TCP connect rather than a DNS lookup, because a captive portal answers
  /// DNS perfectly well while blocking everything else — and a captive portal
  /// is precisely the situation the Wi-Fi module exists to warn about. Port 443
  /// on a public resolver is the least surprising thing to reach for: it is not
  /// a tracking endpoint and it carries no request payload.
  static Future<bool> hasInternetAccess() async {
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        443,
        timeout: const Duration(seconds: 4),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
