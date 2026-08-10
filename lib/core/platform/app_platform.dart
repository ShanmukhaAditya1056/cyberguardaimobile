import 'dart:io' show Platform;

/// The operating system the Flutter build is running on.
///
/// CyberGuard ships two builds: this Flutter app, which targets **Android
/// only**, and the MERN web build under `web/`, which is a separate codebase
/// with its own UI and its own JavaScript ports of the detection engines. It
/// is not Flutter web, so `kIsWeb` is never true here.
///
/// [unknown] exists for the Dart VM, where `flutter test` runs and none of
/// `Platform.isAndroid` and friends report a device. Nothing user-facing
/// should reach it in a shipped build.
enum HostPlatform { android, unknown }

/// Static description of what the current host can and cannot do.
///
/// A lot of this app's value comes from Android APIs that have no equivalent
/// elsewhere — reading the SMS inbox, enumerating every installed package,
/// standing in front of the system browser. Every feature that depends on the
/// host OS is declared here and checked before it is offered, rather than
/// letting the call fail at the platform-channel boundary and surface as an
/// opaque `MissingPluginException`.
///
/// Nothing here performs I/O or asks for a permission — these are compile-time
/// facts about the platform, answered synchronously so that widgets can branch
/// on them during `build`. Whether the *user* has granted a capability is a
/// separate question, handled by `PermissionService`.
class AppPlatform {
  AppPlatform._();

  static final HostPlatform current = _detect();

  static HostPlatform _detect() =>
      Platform.isAndroid ? HostPlatform.android : HostPlatform.unknown;

  static bool get isAndroid => current == HostPlatform.android;

  /// Human-readable name used in the UI when explaining why a module is
  /// unavailable.
  static String get displayName =>
      isAndroid ? 'Android' : 'this platform';

  // ── Capabilities ─────────────────────────────────────────────────────────
  //
  // Each of these is `isAndroid` today, because Android is the only target.
  // They are kept as named questions rather than collapsed into one flag
  // because the call sites read as statements about the *feature* — "can this
  // host enumerate installed apps" — which is what a reader needs to know, and
  // because they are the seam a second target would be added at.

  /// Whether the installed-software inventory can be read, via `PackageManager`.
  static bool get canEnumerateInstalledApps => isAndroid;

  /// Whether the *connected* network's SSID/BSSID/encryption can be inspected.
  static bool get canReadWifiIdentity => isAndroid;

  /// The reachability half of the Wi-Fi module — DNS resolution, latency and
  /// the captive-portal probe. Needs only a socket.
  static bool get canProbeNetworkHealth => true;

  /// Reading the SMS inbox and receiving live SMS broadcasts.
  static bool get canReadSms => isAndroid;

  /// Standing in for the system browser so tapped links can be vetted first.
  /// Requires the Android default-browser role.
  static bool get canInterceptLinks => isAndroid;

  /// Live camera QR scanning, via `mobile_scanner`.
  static bool get canScanQrLive => isAndroid;

  /// Decoding a QR out of a picked image file.
  static bool get canDecodeQrFromImage => canScanQrLive;

  /// On-device OCR for the Screenshot Scanner, via Google ML Kit.
  static bool get canRunOcr => isAndroid;

  /// Whether an image can be chosen from disk, via `image_picker`.
  static bool get canPickImageFile => true;

  /// Local notifications, via `flutter_local_notifications`.
  static bool get canPostNotifications => true;

  /// Runtime permission prompts. `permission_handler` needs a platform
  /// implementation; asking it for a status where it has none raises
  /// `MissingPluginException` rather than returning "denied".
  static bool get hasRuntimePermissions => isAndroid;

  /// Firebase Auth. Android reads its credentials from a bundled
  /// `google-services.json`; without that file `Firebase.initializeApp()`
  /// throws, `AuthService` reports itself unconfigured, and the route guard
  /// stands down.
  static bool get supportsFirebaseAuth => isAndroid;

  /// Whether the OS composes its own window chrome that the app must not try
  /// to draw under. Drives the edge-to-edge setup.
  static bool get hasSystemUiOverlays => isAndroid;

  /// Orientation locking only means something on a handheld.
  static bool get canLockOrientation => isAndroid;
}
