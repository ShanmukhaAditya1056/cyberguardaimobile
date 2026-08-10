import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';
import '../../core/platform/app_platform.dart';
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

/// Action-button ids, shared by every platform's notification payload.
const _actionView = 'view';
const _actionDismiss = 'dismiss';
const _actionViewReport = 'view_report';

/// Apple requires the set of action buttons to be declared up front as a
/// *category*, registered at initialisation, and referenced by id when the
/// notification is posted — unlike Android, where the actions travel with each
/// notification. These two ids cover the two shapes this app posts.
const _darwinThreatCategory = 'cyberguard_threat';
const _darwinScanCategory = 'cyberguard_scan';

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

  /// True once the host's notification backend is up. False on Windows, which
  /// the pinned plugin version has no implementation for — callers still call
  /// the `show*` helpers unconditionally and they simply return.
  static bool get isAvailable => _initialized;

  static Future<void> init() async {
    if (_initialized) return;

    // Windows notifications arrived in a later major version of the plugin
    // than the one this app pins, and initialising it there throws out of the
    // platform interface. Alerts are still recorded and still shown in-app;
    // only the OS-level toast is missing.
    if (!AppPlatform.canPostNotifications) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Permissions are requested explicitly below rather than by the plugin at
    // initialisation, so the OS prompt appears when the user has already seen
    // the app rather than during the first frame of the splash screen.
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _darwinThreatCategory,
          actions: [
            DarwinNotificationAction.plain(
              _actionView,
              'View Details',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              _actionDismiss,
              'Dismiss',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
        DarwinNotificationCategory(
          _darwinScanCategory,
          actions: [
            DarwinNotificationAction.plain(
              _actionViewReport,
              'View Report',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    const linuxInit = LinuxInitializationSettings(
      defaultActionName: 'Open CyberGuard',
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: linuxInit,
    );

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

  /// Android 13+ and both Apple platforms gate notifications behind a runtime
  /// prompt. Linux's freedesktop backend has no such concept, so
  /// `resolvePlatformSpecificImplementation` returns null there and this is a
  /// no-op — which is why every call below is null-safe rather than branched
  /// on the platform.
  static Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
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
    if (!_initialized || !_alertsEnabled) return;
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
      iOS: _darwinThreat,
      macOS: _darwinThreat,
      linux: _linuxThreat,
    );
    await _plugin.show(id, title, body, details, payload: target);
  }

  /// A confirmed threat is exactly what iOS's time-sensitive level exists for:
  /// it breaks through Focus modes and the summary. Anything less and a
  /// phishing warning waits in a digest until the morning.
  static const _darwinThreat = DarwinNotificationDetails(
    categoryIdentifier: _darwinThreatCategory,
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  static const _darwinWarning = DarwinNotificationDetails(
    categoryIdentifier: _darwinThreatCategory,
    presentAlert: true,
    presentBadge: true,
    presentSound: false,
  );

  static const _darwinScan = DarwinNotificationDetails(
    categoryIdentifier: _darwinScanCategory,
    presentAlert: true,
    presentBadge: false,
    presentSound: false,
  );

  static const _linuxThreat = LinuxNotificationDetails(
    urgency: LinuxNotificationUrgency.critical,
    category: LinuxNotificationCategory.deviceError,
    actions: [
      LinuxNotificationAction(key: _actionView, label: 'View Details'),
      LinuxNotificationAction(key: _actionDismiss, label: 'Dismiss'),
    ],
  );

  static const _linuxWarning = LinuxNotificationDetails(
    urgency: LinuxNotificationUrgency.normal,
    actions: [
      LinuxNotificationAction(key: _actionView, label: 'View Details'),
      LinuxNotificationAction(key: _actionDismiss, label: 'Dismiss'),
    ],
  );

  static const _linuxScan = LinuxNotificationDetails(
    urgency: LinuxNotificationUrgency.low,
    actions: [
      LinuxNotificationAction(key: _actionViewReport, label: 'View Report'),
    ],
  );

  static Future<void> showWarning({
    required String title,
    required String body,
    int id = 2,
    String target = NotifTarget.alerts,
  }) async {
    if (!_initialized || !_alertsEnabled) return;
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
      iOS: _darwinWarning,
      macOS: _darwinWarning,
      linux: _linuxWarning,
    );
    await _plugin.show(id, title, body, details, payload: target);
  }

  static Future<void> showScanComplete({
    required String title,
    required String body,
    int id = 3,
  }) async {
    if (!_initialized || !_alertsEnabled) return;
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
      iOS: _darwinScan,
      macOS: _darwinScan,
      linux: _linuxScan,
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
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
