import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createChannels();
    _initialized = true;
  }

  static Future<void> _createChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Critical alerts channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'cyberguard_critical',
        'Critical Threats',
        description: 'Immediate security threat alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF2D6B),
      ),
    );

    // Warning channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'cyberguard_warning',
        'Security Warnings',
        description: 'Security warning notifications',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    );

    // Info channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notifChannelId,
        AppConstants.notifChannelName,
        description: AppConstants.notifChannelDesc,
        importance: Importance.defaultImportance,
        playSound: false,
      ),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap — navigate to relevant screen
    // This would integrate with GoRouter in a real app
  }

  static Future<void> showCriticalThreat({
    required String title,
    required String body,
    int id = 1,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'cyberguard_critical',
        'Critical Threats',
        channelDescription: 'Immediate security threat alerts',
        importance: Importance.max,
        priority: Priority.max,
        color: Color(0xFFFF2D6B),
        enableVibration: true,
        playSound: true,
        actions: [
          AndroidNotificationAction('view', 'View Details'),
          AndroidNotificationAction('dismiss', 'Dismiss'),
        ],
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  static Future<void> showWarning({
    required String title,
    required String body,
    int id = 2,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'cyberguard_warning',
        'Security Warnings',
        channelDescription: 'Security warning notifications',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFFFFB84D),
        enableVibration: true,
        playSound: false,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  static Future<void> showScanComplete({
    required String title,
    required String body,
    int id = 3,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notifChannelId,
        AppConstants.notifChannelName,
        channelDescription: AppConstants.notifChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFF4AE88A),
        actions: [
          AndroidNotificationAction('view_report', 'View Report'),
        ],
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  static Future<void> showPhishingDetected(String url) async {
    await showCriticalThreat(
      title: 'Phishing Link Detected',
      body:
          'Suspicious URL found: ${url.length > 50 ? url.substring(0, 50) + '...' : url}',
      id: 10,
    );
  }

  static Future<void> showMalwareFound(String appName) async {
    await showCriticalThreat(
      title: 'Malicious App Detected',
      body: '$appName has been flagged as potentially dangerous',
      id: 11,
    );
  }

  static Future<void> showBreachFound(String emailMasked) async {
    await showCriticalThreat(
      title: 'Data Breach Found',
      body: 'Your account $emailMasked appears in known data breaches',
      id: 12,
    );
  }

  static Future<void> showUnsafeWifi(String ssid) async {
    await showWarning(
      title: 'Unsafe Wi-Fi Network',
      body: 'Network "$ssid" has security issues',
      id: 13,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
