import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../models/app_info_model.dart';

class PlatformChannelService {
  static const _channel = MethodChannel(AppConstants.channelName);

  /// Get all real installed non-system apps from Android PackageManager
  Future<List<AppInfoModel>> getInstalledApps() async {
    try {
      final List result = await _channel.invokeMethod('getInstalledApps');
      return result
          .map((app) => AppInfoModel.fromMap(Map<String, dynamic>.from(app as Map)))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get installed apps: ${e.message}');
    }
  }

  /// Get real app icon as PNG bytes
  Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
          'getAppIcon', {'packageName': packageName});
      if (result == null) return null;
      if (result is Uint8List) return result;
      if (result is List<dynamic>) return Uint8List.fromList(result.cast<int>());
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Get real Wi-Fi details from Android WifiManager
  Future<Map<String, dynamic>> getWifiDetails() async {
    try {
      final Map result = await _channel.invokeMethod('getWifiDetails');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to get Wi-Fi details: ${e.message}');
    }
  }

  /// Get real recent SMS messages (requires READ_SMS permission)
  Future<List<Map<String, String>>> getRecentSms() async {
    try {
      final List result = await _channel.invokeMethod('getSmsMessages');
      return result
          .map((sms) => Map<String, String>.from(sms as Map))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get SMS: ${e.message}');
    }
  }

  /// Get battery info
  Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final Map result = await _channel.invokeMethod('getBatteryInfo');
      return Map<String, dynamic>.from(result);
    } on PlatformException {
      return {'level': -1, 'isCharging': false};
    }
  }

  /// Get device info
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final Map result = await _channel.invokeMethod('getDeviceInfo');
      return Map<String, dynamic>.from(result);
    } on PlatformException {
      return {};
    }
  }

  /// Open the Android system Settings → App info page for a package
  Future<bool> openAppSettings(String packageName) async {
    try {
      await _channel
          .invokeMethod('openAppSettings', {'packageName': packageName});
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Launch the system uninstall confirmation dialog for a package
  Future<bool> uninstallApp(String packageName) async {
    try {
      await _channel
          .invokeMethod('uninstallApp', {'packageName': packageName});
      return true;
    } on PlatformException {
      return false;
    }
  }
}
