import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/app_info_model.dart';
import 'device_probe.dart';

/// The original Android implementation: one `MethodChannel` into
/// `MainActivity.kt`, which fronts `PackageManager`, `WifiManager`, the SMS
/// content provider and `BatteryManager`.
///
/// This is the reference behaviour every other probe is measured against — it
/// is the only host that can answer all eight questions.
class AndroidDeviceProbe implements DeviceProbe {
  static const _channel = MethodChannel(AppConstants.channelName);

  const AndroidDeviceProbe();

  @override
  Future<List<AppInfoModel>> getInstalledApps() async {
    try {
      final List result = await _channel.invokeMethod('getInstalledApps');
      return result
          .map((app) =>
              AppInfoModel.fromMap(Map<String, dynamic>.from(app as Map)))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get installed apps: ${e.message}');
    }
  }

  @override
  Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final result = await _channel
          .invokeMethod<dynamic>('getAppIcon', {'packageName': packageName});
      if (result == null) return null;
      if (result is Uint8List) return result;
      if (result is List<dynamic>) return Uint8List.fromList(result.cast<int>());
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getWifiDetails() async {
    try {
      final Map result = await _channel.invokeMethod('getWifiDetails');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to read Wi-Fi details: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, String>>> getRecentSms() async {
    try {
      final List result = await _channel.invokeMethod('getSmsMessages');
      return result.map((sms) => Map<String, String>.from(sms as Map)).toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to read SMS: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final Map result = await _channel.invokeMethod('getBatteryInfo');
      return Map<String, dynamic>.from(result);
    } on PlatformException {
      return {'level': -1, 'isCharging': false};
    }
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final Map result = await _channel.invokeMethod('getDeviceInfo');
      return Map<String, dynamic>.from(result);
    } on PlatformException {
      return {};
    }
  }

  @override
  Future<bool> openAppSettings(String packageName) async {
    try {
      await _channel
          .invokeMethod('openAppSettings', {'packageName': packageName});
      return true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> uninstallApp(String packageName) async {
    try {
      await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
      return true;
    } on PlatformException {
      return false;
    }
  }
}
