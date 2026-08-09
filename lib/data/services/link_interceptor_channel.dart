import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform/app_platform.dart';

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
/// Interception itself is Android-only: it depends on holding the system
/// default-browser role, which no other platform lets an app take. iOS routes
/// http/https to Safari with no chooser, and the desktops have no equivalent
/// role. [isSupported] reports that, the listening methods return nothing where
/// it is false, and [openInBrowser] still works everywhere — the app has
/// URLs to open regardless of whether it ever gets to vet them first.
class LinkInterceptorChannel {
  static const _method = MethodChannel('com.cyberguard.ai/link');
  static const _events = EventChannel('com.cyberguard.ai/link_stream');

  const LinkInterceptorChannel();

  static bool get isSupported => AppPlatform.canInterceptLinks;

  /// The link that launched the app from a cold start, or null.
  Future<InterceptedLink?> getInitialLink() async {
    if (!isSupported) return null;
    try {
      final res = await _method.invokeMethod<Map<dynamic, dynamic>>('getInitialLink');
      if (res == null || (res['url'] as String?)?.isEmpty != false) return null;
      return InterceptedLink.fromMap(res);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // The channel is registered by the Android host only. Reached if
      // isSupported ever drifts from what the build actually ships.
      return null;
    }
  }

  /// Links intercepted while the app is running.
  Stream<InterceptedLink> get stream {
    if (!isSupported) return const Stream<InterceptedLink>.empty();
    return _events
        .receiveBroadcastStream()
        .where((e) => e is Map && (e['url'] as String?)?.isNotEmpty == true)
        .map((e) => InterceptedLink.fromMap(e as Map));
  }

  /// Open [url] in an external browser. Returns false if nothing could handle
  /// it.
  ///
  /// Android goes through the native channel because it needs to exclude
  /// CyberGuard from the chooser — without that, an app holding the default
  /// browser role hands the link straight back to itself and the user is stuck
  /// in a loop between the warning screen and the interceptor. No other
  /// platform can hold that role, so there is no loop to break and
  /// `url_launcher` is the right tool.
  Future<bool> openInBrowser(String url) async {
    if (!isSupported) {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) return false;
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
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
    if (!isSupported) return false;
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
    if (!isSupported) return false;
    try {
      return await _method.invokeMethod<bool>('requestDefaultBrowser') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
