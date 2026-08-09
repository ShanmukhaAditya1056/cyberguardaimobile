import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/app_info_model.dart';
import 'desktop_device_probe.dart';
import 'device_probe.dart';

/// iOS implementation.
///
/// iOS answers fewer of these questions than any other host, and that is by
/// design rather than by omission:
///
///  * **Installed apps** — there is no API. `canOpenURL:` can test a hardcoded
///    scheme list, which Apple rejects apps for using as an enumeration
///    workaround, and it would return a list of guesses rather than an
///    inventory. The App Scanner is hidden on iOS instead of shown empty.
///  * **SMS** — no public read API exists. What iOS does offer is the SMS
///    *filter* extension, which is a separate app target that never sees the
///    message content the host app could exfiltrate. That is a real port, not
///    a probe method, and is out of scope here.
///  * **Wi-Fi identity** — SSID and BSSID need the
///    `com.apple.developer.networking.wifi-info` entitlement, which requires an
///    approved request against a paid account. Without it `CNCopyCurrentNetworkInfo`
///    returns nil, so the module runs its reachability half only.
///
/// Everything the sandbox does permit — reachability, DNS health, latency,
/// captive-portal detection — is answered here in pure Dart.
class IosDeviceProbe implements DeviceProbe {
  const IosDeviceProbe();

  @override
  Future<List<AppInfoModel>> getInstalledApps() async {
    throw const ProbeUnsupported(
      capability: 'installed apps',
      platform: 'iOS',
      reason: 'iOS does not let one app see what else is installed. '
          'App Scanner is available in the Android build.',
    );
  }

  @override
  Future<Uint8List?> getAppIcon(String packageName) async => null;

  @override
  Future<List<Map<String, String>>> getRecentSms() async {
    throw const ProbeUnsupported(
      capability: 'SMS',
      platform: 'iOS',
      reason: 'iOS has no API for reading messages. '
          'SMS Guard is available in the Android build.',
    );
  }

  /// Network state without the Wi-Fi entitlement.
  ///
  /// `identityAvailable: false` is the contract with `WifiRepository`: it means
  /// SSID, BSSID, signal strength and encryption are genuinely unknown rather
  /// than absent, so the repository must score the network on its reachability
  /// checks alone instead of reporting an unnamed, unencrypted, weak-signal
  /// network that does not exist.
  @override
  Future<Map<String, dynamic>> getWifiDetails() async {
    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity.contains(ConnectivityResult.none)) {
      return {
        'status': 'not_connected',
        'message': 'No network connection. Connect to Wi-Fi, then scan.',
      };
    }
    if (!connectivity.contains(ConnectivityResult.wifi)) {
      return {
        'status': 'not_connected',
        'message': 'You are on mobile data, not Wi-Fi. '
            'Connect to a Wi-Fi network to analyse it.',
      };
    }

    final network = await Future.wait([
      DesktopDeviceProbe.localIpAddress(),
      DesktopDeviceProbe.hasInternetAccess(),
    ]);

    return {
      'status': 'connected',
      'identityAvailable': false,
      'ssid': '',
      'bssid': '',
      'rssi': 0,
      'linkSpeed': 0,
      'frequency': 0,
      'isSecured': true,
      'securityLabel': 'Not visible to apps on iOS',
      'ipAddress': network[0] as String,
      'hasInternet': network[1] as bool,
    };
  }

  @override
  Future<Map<String, dynamic>> getBatteryInfo() async =>
      const {'level': -1, 'isCharging': false};

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async => {
        'platform': 'iOS',
        'osVersion': Platform.operatingSystemVersion,
        'cores': Platform.numberOfProcessors,
        'locale': Platform.localeName,
      };

  @override
  Future<bool> openAppSettings(String packageName) async => false;

  @override
  Future<bool> uninstallApp(String packageName) async => false;
}
