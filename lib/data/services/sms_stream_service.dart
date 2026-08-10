import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../core/platform/app_platform.dart';
import '../../core/utils/url_extractor.dart';
import '../models/alert_model.dart';
import '../repositories/phishing_repository.dart';
import 'hive_service.dart';
import 'notification_service.dart';

/// Real-time SMS phishing monitor. Listens to the Kotlin BroadcastReceiver
/// via an EventChannel, extracts URLs from each incoming message, runs the
/// phishing engine, and surfaces alerts + notifications immediately.
///
/// Lifecycle:
///   • call [start] once SMS permission is granted (e.g. from settings)
///   • [stop] tears down the platform receiver and Dart subscription
class SmsStreamService {
  static const _methodChannel = MethodChannel('com.cyberguard.ai/device');
  static const _eventChannel = EventChannel('com.cyberguard.ai/sms_stream');
  static const _uuid = Uuid();

  static StreamSubscription? _sub;
  static final _repo = PhishingRepository();
  static bool _running = false;

  static bool get isRunning => _running;

  /// Whether this host has an SMS inbox to guard at all. The settings toggle
  /// reads this to decide between offering the switch and explaining why it is
  /// absent, so a user on Windows is never left wondering what they did wrong.
  static bool get isSupported => AppPlatform.canReadSms;

  static Future<bool> start() async {
    if (_running) return true;
    // iOS has no message-reading API and the desktops have no inbox; the
    // EventChannel below exists only in the Android build.
    if (!isSupported) return false;

    final status = await Permission.sms.request();
    if (!status.isGranted) return false;

    try {
      await _methodChannel.invokeMethod('startSmsListener');
    } on PlatformException {
      return false;
    }

    _sub = _eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (_) {},
      cancelOnError: false,
    );
    _running = true;
    return true;
  }

  static Future<void> stop() async {
    if (!_running) return;
    await _sub?.cancel();
    _sub = null;
    try {
      await _methodChannel.invokeMethod('stopSmsListener');
    } on PlatformException {
      // ignore
    }
    _running = false;
  }

  static Future<void> _onEvent(dynamic event) async {
    if (event is! Map) return;
    final address = (event['address'] ?? '').toString();
    final body = (event['body'] ?? '').toString();
    if (body.isEmpty) return;

    final urls = UrlExtractor.extractUrls(body);
    if (urls.isEmpty) return;

    bool anyPhishing = false;
    int worstConfidence = 0;
    String? worstUrl;
    String? topReason;

    for (final url in urls) {
      final result = await _repo.scanAndSave(url);
      if (result.isPhishing && result.confidence > worstConfidence) {
        anyPhishing = true;
        worstConfidence = result.confidence;
        worstUrl = url;
        topReason = result.triggeredRules.isNotEmpty
            ? result.triggeredRules.first
            : 'Suspicious URL pattern';
      }
    }

    if (anyPhishing && worstUrl != null) {
      final alert = AlertModel(
        id: _uuid.v4(),
        type: 'critical',
        title: 'Phishing SMS from $address',
        description:
            '${topReason ?? "Detected by on-device engine"}. Link: ${_truncate(worstUrl, 60)}',
        module: 'phishing',
        timestamp: DateTime.now(),
        actionData: worstUrl,
      );
      await HiveService.saveAlert(alert);
      await NotificationService.showPhishingDetected(worstUrl);
    }
  }

  static String _truncate(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n)}…';
}
