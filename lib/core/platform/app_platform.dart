import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// The operating system the Flutter build is running on.
///
/// **iOS is modelled here but is not a shipped target.** The `ios/` directory
/// was removed — see docs/PLATFORMS.md — so `HostPlatform.ios` cannot occur at
/// runtime and [IosDeviceProbe] is unreachable. Both are kept deliberately:
/// the capability answers below are the researched, correct ones for iOS, and
/// discarding them would mean re-deriving which APIs the sandbox permits if
/// the target is ever restored. Restoring it needs no change to this file.
///
/// CyberGuard started as an Android-only app, so a lot of its value comes from
/// APIs that simply do not exist elsewhere — reading the SMS inbox, enumerating
/// every installed package, standing in front of the system browser. Rather
/// than let those calls fail at the platform-channel boundary and surface as an
/// opaque `MissingPluginException`, every feature that depends on the host OS
/// is declared here and checked before it is offered.
enum HostPlatform { android, ios, windows, macos, linux, web, unknown }

/// Static description of what the current host can and cannot do.
///
/// Nothing here performs I/O or asks for a permission — these are compile-time
/// facts about the platform, answered synchronously so that widgets can branch
/// on them during `build`. Whether the *user* has granted a capability is a
/// separate question, handled by `PermissionService`.
class AppPlatform {
  AppPlatform._();

  static final HostPlatform current = _detect();

  static HostPlatform _detect() {
    if (kIsWeb) return HostPlatform.web;
    if (Platform.isAndroid) return HostPlatform.android;
    if (Platform.isIOS) return HostPlatform.ios;
    if (Platform.isWindows) return HostPlatform.windows;
    if (Platform.isMacOS) return HostPlatform.macos;
    if (Platform.isLinux) return HostPlatform.linux;
    return HostPlatform.unknown;
  }

  static bool get isAndroid => current == HostPlatform.android;
  static bool get isIOS => current == HostPlatform.ios;
  static bool get isWindows => current == HostPlatform.windows;
  static bool get isMacOS => current == HostPlatform.macos;
  static bool get isLinux => current == HostPlatform.linux;
  static bool get isWeb => current == HostPlatform.web;

  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Human-readable name used in the UI when explaining why a module is
  /// unavailable ("App Scanner is not available on iOS").
  static String get displayName => switch (current) {
        HostPlatform.android => 'Android',
        HostPlatform.ios => 'iOS',
        HostPlatform.windows => 'Windows',
        HostPlatform.macos => 'macOS',
        HostPlatform.linux => 'Linux',
        HostPlatform.web => 'Web',
        HostPlatform.unknown => 'this platform',
      };

  // ── Capabilities ─────────────────────────────────────────────────────────

  /// Whether the installed-software inventory can be read.
  ///
  /// Android goes through `PackageManager`. The three desktops each expose an
  /// equivalent (registry uninstall keys, `/Applications`, XDG desktop entries)
  /// which `DesktopDeviceProbe` reads. iOS deliberately has no such API — the
  /// sandbox forbids one app from learning what else is installed — so the
  /// App Scanner module is hidden there rather than shown empty.
  static bool get canEnumerateInstalledApps => isAndroid || isDesktop;

  /// Whether the *connected* network's SSID/BSSID/encryption can be inspected.
  ///
  /// iOS restricts this to apps holding the `com.apple.developer.networking
  /// .wifi-info` entitlement, which requires a paid account and an approved
  /// request, so the Wi-Fi module falls back to the reachability-only checks
  /// (DNS health, latency, captive-portal probe) that need no entitlement.
  static bool get canReadWifiIdentity => isAndroid || isDesktop;

  /// The reachability half of the Wi-Fi module — DNS resolution, latency and
  /// the captive-portal probe — works from any host with a socket.
  static bool get canProbeNetworkHealth => !isWeb;

  /// Reading the SMS inbox and receiving live SMS broadcasts. Android only:
  /// iOS has no public message-reading API at all, and desktops have no inbox.
  static bool get canReadSms => isAndroid;

  /// Standing in for the system browser so tapped links can be vetted first.
  /// Requires the Android default-browser role.
  static bool get canInterceptLinks => isAndroid;

  /// Live camera QR scanning. `mobile_scanner` ships Android, iOS and macOS
  /// implementations; Windows and Linux have none, so those hosts get the
  /// decode-from-image path instead.
  static bool get canScanQrLive => isAndroid || isIOS || isMacOS;

  /// Decoding a QR out of a picked image file. Available everywhere the
  /// scanner plugin is, which is every host except Windows and Linux.
  static bool get canDecodeQrFromImage => canScanQrLive;

  /// On-device OCR for the Screenshot Scanner. Google ML Kit is a mobile-only
  /// SDK — there is no desktop build of it, official or otherwise.
  static bool get canRunOcr => isMobile;

  /// Whether an image can be chosen from disk. True everywhere: `image_picker`
  /// endorses `image_picker_windows`/`_macos`/`_linux`, which delegate to the
  /// native file dialog. Note that `ImageSource.camera` is still mobile-only —
  /// the desktop implementations open a file picker regardless of the source
  /// requested.
  static bool get canPickImageFile => !isWeb;

  /// Local notifications. `flutter_local_notifications` covers Android, iOS,
  /// macOS and Linux. Windows support landed in a later major version than the
  /// one this app pins, so Windows shows in-app banners only.
  static bool get canPostNotifications => !isWindows && !isWeb;

  /// Runtime permission prompts. `permission_handler` endorses Android, iOS
  /// and Windows only — asking it for a status on macOS or Linux raises
  /// `MissingPluginException` rather than returning "denied". Windows is
  /// excluded here anyway: its implementation covers a handful of UWP-era
  /// permissions the app does not use, and the desktop model grants file and
  /// network access to a process when it launches.
  static bool get hasRuntimePermissions => isMobile;

  /// Firebase Auth.
  ///
  /// `firebase_core` resolves an implementation on Windows and macOS as well
  /// as the two mobile platforms, but only Android and Apple read their
  /// credentials from a bundled config file (`google-services.json` /
  /// `GoogleService-Info.plist`). Windows and Linux need explicit
  /// `FirebaseOptions` generated by the FlutterFire CLI, which this repo does
  /// not carry — so `Firebase.initializeApp()` throws there, `AuthService`
  /// reports itself unconfigured, and the route guard stands down exactly as
  /// it does on a checkout with no Firebase project at all.
  static bool get supportsFirebaseAuth => isMobile || isMacOS;

  /// Whether the OS composes its own window chrome that the app must not try
  /// to draw under. Used to skip the Android edge-to-edge setup.
  static bool get hasSystemUiOverlays => isMobile;

  /// Orientation locking only means something on a handheld.
  static bool get canLockOrientation => isMobile;

  /// Modules the current host cannot run at all, keyed by the route segment
  /// used in `app_router.dart`. The dashboard greys these out and the router
  /// redirects away from them.
  static Set<String> get unavailableModules => {
        if (!canEnumerateInstalledApps) 'malware',
        if (!canRunOcr) 'screenshot',
        if (!canInterceptLinks) 'intercept',
      };

  static bool isModuleAvailable(String module) =>
      !unavailableModules.contains(module);
}
