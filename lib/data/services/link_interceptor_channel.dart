import 'package:flutter/services.dart';

/// A URL handed to CyberGuard by the OS because the user tapped a link (or
/// shared one) from another app — WhatsApp, Telegram, SMS, Gmail, a browser,
/// etc. [sourceApp] is the originating package's friendly label when Android
/// provides it ("the referrer"), otherwise null.
class InterceptedLink {
  final String url;
  final String? sourceApp;

  const InterceptedLink({required this.url, this.sourceApp});

  factory InterceptedLink.fromMap(Map<dynamic, dynamic> m) => InterceptedLink(
        url: (m['url'] as String?) ?? '',
        sourceApp: m['sourceApp'] as String?,
      );
}

/// Dart wrapper over the native link-interception channels.
///
///  * [getInitialLink] — the link that cold-started the app (tapped while the
///    app was not running). Consumed once.
///  * [stream] — links delivered while the app is already alive (warm starts,
///    `onNewIntent`).
///  * [openInBrowser] — hand a URL to a real browser, explicitly excluding
///    CyberGuard so "Continue Anyway" can't loop back into the interceptor.
class LinkInterceptorChannel {
  static const _method = MethodChannel('com.cyberguard.ai/link');
  static const _events = EventChannel('com.cyberguard.ai/link_stream');

  const LinkInterceptorChannel();

  /// The link that launched the app from a cold start, or null.
  Future<InterceptedLink?> getInitialLink() async {
    try {
      final res = await _method.invokeMethod<Map<dynamic, dynamic>>('getInitialLink');
      if (res == null || (res['url'] as String?)?.isEmpty != false) return null;
      return InterceptedLink.fromMap(res);
    } on PlatformException {
      return null;
    }
  }

  /// Links intercepted while the app is running.
  Stream<InterceptedLink> get stream => _events
      .receiveBroadcastStream()
      .where((e) => e is Map && (e['url'] as String?)?.isNotEmpty == true)
      .map((e) => InterceptedLink.fromMap(e as Map));

  /// Open [url] in an external browser, excluding our own app from the
  /// chooser. Returns false if no browser could handle it.
  Future<bool> openInBrowser(String url) async {
    try {
      final ok = await _method.invokeMethod<bool>('openInBrowser', {'url': url});
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Whether CyberGuard is currently the system default browser. On Android
  /// 12+ this must be true for tapped http/https links to reach the
  /// interceptor at all (the OS otherwise routes them straight to the default
  /// browser without offering a chooser).
  Future<bool> isDefaultBrowser() async {
    try {
      return await _method.invokeMethod<bool>('isDefaultBrowser') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Ask the OS to make CyberGuard the default browser. Returns true if the
  /// role is held after the request resolves. On Android 10+ this surfaces the
  /// system role dialog; on older devices it opens the default-apps settings
  /// and returns the (likely still-false) current state — re-query on resume.
  Future<bool> requestDefaultBrowser() async {
    try {
      return await _method.invokeMethod<bool>('requestDefaultBrowser') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
