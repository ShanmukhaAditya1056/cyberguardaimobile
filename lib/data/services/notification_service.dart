import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';
import 'hive_service.dart';

/// Semantic destinations carried in a notification payload. The router layer
/// (see `app.dart`) maps these to real paths so the data layer stays free of
/// route knowledge.
class NotifTarget {
  static const alerts = 'alerts';
  static const phishing = 'phishing';
  static const malware = 'malware';
  static const breach = 'breach';
  static const wifi = 'wifi';
  static const report = 'report';
}

/// Android action-button ids.
const _actionView = 'view';
const _actionDismiss = 'dismiss';
const _actionViewReport = 'view_report';

/// Runs on a background isolate when an action that does *not* open the UI is
/// tapped (currently only "Dismiss"). Registering it is what makes Android's
/// ActionBroadcastReceiver path work at all — without a background handler the
/// plugin has nothing to dispatch to and every action button silently no-ops.
/// The dismissal itself is done by `cancelNotification: true` on the action.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Destination requested by the most recent notification tap, waiting to be
  /// consumed once the router is on a real screen. A cold-start tap arrives
  /// before `runApp`, and splash/onboarding both `context.go` on their own, so
  /// navigation cannot happen at handler time.
  static String? _pendingTarget;

  /// Bumped on every navigation request so `CyberGuardApp` can listen, mirroring
  /// the Smart Link Interceptor's navToken.
  static final ValueNotifier<int> navToken = ValueNotifier<int>(0);

  /// Reads the pending destination without clearing it.
  static String? peekPendingTarget() => _pendingTarget;

  /// Reads and clears the pending destination.
  static String? consumePendingTarget() {
    final target = _pendingTarget;
    _pendingTarget = null;
    return target;
  }

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    // Create notification channels
    await _createChannels();
    await _requestPermission();

    // A tap that cold-starts the app is never delivered to the callback above,
    // so pick it up explicitly.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final response = launch!.notificationResponse;
      if (response != null) _handleResponse(response);
    }

    _initialized = true;
  }

  static Future<void> _requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
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

  static void _onNotificationTapped(NotificationResponse response) =>
      _handleResponse(response);

  static void _handleResponse(NotificationResponse response) {
    // "Dismiss" only clears the notification — `cancelNotification: true` on
    // the action already did that, so there is nothing left to route to.
    if (response.actionId == _actionDismiss) return;

    final target = response.payload;
    if (target == null || target.isEmpty) return;

    _pendingTarget = target;
    navToken.value++;
  }

  /// Honours the "Real-time Alerts" switch in Settings.
  ///
  /// The toggle was stored but never read, so turning it off changed nothing.
  /// It gates threat notifications only — alerts are still recorded and stay
  /// visible in the Alerts screen, because silencing a security app's
  /// notifications should not also hide its findings.
  static bool get _alertsEnabled {
    try {
      return HiveService.getSettings().realTimeAlerts;
    } catch (_) {
      // Settings box not open yet (very early startup) — fail open so a
      // threat is never silently dropped.
      return true;
    }
  }

  static Future<void> showCriticalThreat({
    required String title,
    required String body,
    int id = 1,
    String target = NotifTarget.alerts,
  }) async {
    if (!_alertsEnabled) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'cyberguard_critical',
        'Critical Threats',
        channelDescription: 'Immediate security threat alerts',
        importance: Importance.max,
        priority: Priority.max,
        color: const Color(0xFFFF2D6B),
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(body),
        actions: const [
          // `showsUserInterface: true` routes the tap through MainActivity
          // instead of the background broadcast receiver, so the app actually
          // opens and the foreground handler receives the payload.
          AndroidNotificationAction(
            _actionView,
            'View Details',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _actionDismiss,
            'Dismiss',
            cancelNotification: true,
          ),
        ],
      ),
    );
    await _plugin.show(id, title, body, details, payload: target);
  }

  static Future<void> showWarning({
    required String title,
    required String body,
    int id = 2,
    String target = NotifTarget.alerts,
  }) async {
    if (!_alertsEnabled) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'cyberguard_warning',
        'Security Warnings',
        channelDescription: 'Security warning notifications',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFFFFB84D),
        enableVibration: true,
        playSound: false,
        styleInformation: BigTextStyleInformation(body),
        actions: const [
          AndroidNotificationAction(
            _actionView,
            'View Details',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _actionDismiss,
            'Dismiss',
            cancelNotification: true,
          ),
        ],
      ),
    );
    await _plugin.show(id, title, body, details, payload: target);
  }

  static Future<void> showScanComplete({
    required String title,
    required String body,
    int id = 3,
  }) async {
    if (!_alertsEnabled) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notifChannelId,
        AppConstants.notifChannelName,
        channelDescription: AppConstants.notifChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFF4AE88A),
        actions: [
          AndroidNotificationAction(
            _actionViewReport,
            'View Report',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
    );
    await _plugin.show(id, title, body, details, payload: NotifTarget.report);
  }

  static Future<void> showPhishingDetected(String url) async {
    await showCriticalThreat(
      title: 'Phishing Link Detected',
      body:
          'Suspicious URL found: ${url.length > 50 ? url.substring(0, 50) + '...' : url}',
      id: 10,
      target: NotifTarget.phishing,
    );
  }

  static Future<void> showMalwareFound(String appName) async {
    await showCriticalThreat(
      title: 'Malicious App Detected',
      body: '$appName has been flagged as potentially dangerous',
      id: 11,
      target: NotifTarget.malware,
    );
  }

  static Future<void> showBreachFound(String emailMasked) async {
    await showCriticalThreat(
      title: 'Data Breach Found',
      body: 'Your account $emailMasked appears in known data breaches',
      id: 12,
      target: NotifTarget.breach,
    );
  }

  static Future<void> showUnsafeWifi(String ssid) async {
    await showWarning(
      title: 'Unsafe Wi-Fi Network',
      body: 'Network "$ssid" has security issues',
      id: 13,
      target: NotifTarget.wifi,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
