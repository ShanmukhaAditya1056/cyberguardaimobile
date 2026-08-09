/// Translates each desktop OS's notion of "what this program is allowed to do"
/// into the `android.permission.*` vocabulary the rest of the app speaks.
///
/// The alternative — a second risk engine per OS — would mean maintaining four
/// copies of `PermissionAnalyzer`, `ThreatPatterns` and the RF/LGBM/GNN feature
/// extractor, and the desktop copies would never see the training data the
/// Android ones were fitted on. Mapping instead means one engine, one set of
/// weights, one SHAP explanation format.
///
/// The mappings below are only the ones that genuinely correspond. A macOS
/// `NSMicrophoneUsageDescription` and an Android `RECORD_AUDIO` are the same
/// declaration made to two different app stores, and an MSIX `webcam`
/// capability is the same as `CAMERA`. Where no honest equivalent exists the
/// signal is dropped rather than approximated — nothing here invents a
/// permission to make a score look decisive.
class DesktopCapabilities {
  DesktopCapabilities._();

  /// Fed to the malware feature extractor for hosts with no SDK-level concept.
  /// These are the same defaults `MalwareRepository` already used for Android
  /// apps whose SDK fields the platform channel did not report, so a desktop
  /// app is scored on its capabilities alone rather than being pushed up or
  /// down by a fabricated API level.
  static const int neutralTargetSdk = 33;
  static const int neutralMinSdk = 23;

  /// Synthetic installer ids, mirroring the `installerPackage` strings Android
  /// reports. `AppInfoModel.isFromTrustedStore` recognises the first two, so a
  /// Store/App Store/Flatpak app gets the same trust discount as a Play Store
  /// app and an unsigned binary in AppData gets none.
  static const String storeInstallerId = 'com.android.vending';
  static const String managedInstallerId = 'com.android.packageinstaller';

  // ── MSIX (Windows Store) ─────────────────────────────────────────────────

  static const Map<String, String> _msix = {
    'microphone': 'android.permission.RECORD_AUDIO',
    'webcam': 'android.permission.CAMERA',
    'location': 'android.permission.ACCESS_FINE_LOCATION',
    'backgroundMediaPlayback': 'android.permission.FOREGROUND_SERVICE',
    'internetClient': 'android.permission.INTERNET',
    'internetClientServer': 'android.permission.INTERNET',
    'privateNetworkClientServer': 'android.permission.INTERNET',
    'contacts': 'android.permission.READ_CONTACTS',
    'phoneCall': 'android.permission.CALL_PHONE',
    'phoneCallHistoryPublic': 'android.permission.READ_CALL_LOG',
    'chat': 'android.permission.READ_SMS',
    'chatSystem': 'android.permission.READ_SMS',
    'smsSend': 'android.permission.SEND_SMS',
    'broadFileSystemAccess': 'android.permission.MANAGE_EXTERNAL_STORAGE',
    'documentsLibrary': 'android.permission.READ_EXTERNAL_STORAGE',
    'picturesLibrary': 'android.permission.READ_EXTERNAL_STORAGE',
    'videosLibrary': 'android.permission.READ_EXTERNAL_STORAGE',
    'musicLibrary': 'android.permission.READ_EXTERNAL_STORAGE',
    'removableStorage': 'android.permission.WRITE_EXTERNAL_STORAGE',
    'userAccountInformation': 'android.permission.READ_PHONE_STATE',
    'appDiagnostics': 'android.permission.PACKAGE_USAGE_STATS',
    'inputInjectionBrokered': 'android.permission.BIND_ACCESSIBILITY_SERVICE',
    // Can install, update or remove other packages — the same authority
    // REQUEST_INSTALL_PACKAGES grants, and genuinely uncommon (13% of MSIX
    // packages on a typical machine).
    'packageManagement': 'android.permission.REQUEST_INSTALL_PACKAGES',
    // Can request administrator rights. Rare enough to be a real signal.
    'allowElevation': 'android.permission.BIND_DEVICE_ADMIN',

    // Deliberately NOT mapped: `runFullTrust`.
    //
    // It does mean "outside the MSIX sandbox", which sounds like device-admin
    // authority — but on Windows it is simply how a packaged Win32 app runs.
    // Measured on a real machine it appears in 62% of installed MSIX
    // packages, including Chrome, Edge and Teams. `BIND_DEVICE_ADMIN` is the
    // opposite: rare on Android, and scored critical (30 points) plus another
    // 30 from the behaviour heuristic. Equating a ubiquitous capability with
    // an alarming one flagged 37% of an ordinary machine, and a scanner that
    // flags a third of your software teaches you to ignore it.
  };

  // ── macOS (Info.plist usage descriptions + TCC services) ─────────────────

  static const Map<String, String> _macos = {
    'NSMicrophoneUsageDescription': 'android.permission.RECORD_AUDIO',
    'NSCameraUsageDescription': 'android.permission.CAMERA',
    'NSLocationUsageDescription': 'android.permission.ACCESS_FINE_LOCATION',
    'NSLocationWhenInUseUsageDescription':
        'android.permission.ACCESS_FINE_LOCATION',
    'NSLocationAlwaysAndWhenInUseUsageDescription':
        'android.permission.ACCESS_BACKGROUND_LOCATION',
    'NSContactsUsageDescription': 'android.permission.READ_CONTACTS',
    'NSCalendarsUsageDescription': 'android.permission.READ_CALENDAR',
    'NSRemindersUsageDescription': 'android.permission.READ_CALENDAR',
    'NSPhotoLibraryUsageDescription':
        'android.permission.READ_EXTERNAL_STORAGE',
    'NSDesktopFolderUsageDescription':
        'android.permission.READ_EXTERNAL_STORAGE',
    'NSDocumentsFolderUsageDescription':
        'android.permission.READ_EXTERNAL_STORAGE',
    'NSDownloadsFolderUsageDescription':
        'android.permission.READ_EXTERNAL_STORAGE',
    'NSRemovableVolumesUsageDescription':
        'android.permission.WRITE_EXTERNAL_STORAGE',
    'NSSystemAdministrationUsageDescription':
        'android.permission.BIND_DEVICE_ADMIN',
    // Screen recording and synthetic input are what stalkerware on macOS
    // actually asks for, and they are the same abuse Android's accessibility
    // service enables: observe everything, act as the user.
    'NSScreenCaptureUsageDescription':
        'android.permission.BIND_ACCESSIBILITY_SERVICE',
    'NSAccessibilityUsageDescription':
        'android.permission.BIND_ACCESSIBILITY_SERVICE',
    // UNVERIFIED — the first thing to check on a real Mac.
    //
    // Apple Events is how one app scripts another, which is genuinely what
    // macOS stalkerware uses to drive Messages or Mail. But it is also how
    // ordinary automation works, so it may be common enough that mapping it to
    // a critical Android permission repeats the `runFullTrust` mistake. It is
    // kept mapped because under-flagging a real surveillance channel is the
    // worse error, but `dart run tool/probe_report.dart` on a Mac now prints
    // capability frequency and will flag it if it exceeds 20%.
    'NSAppleEventsUsageDescription':
        'android.permission.BIND_ACCESSIBILITY_SERVICE',
    'NSSpeechRecognitionUsageDescription': 'android.permission.RECORD_AUDIO',
    'NSBluetoothAlwaysUsageDescription': 'android.permission.BLUETOOTH_CONNECT',
    'NSLocalNetworkUsageDescription': 'android.permission.INTERNET',
  };

  // ── Linux (Flatpak / Snap sandbox declarations) ──────────────────────────

  static const Map<String, String> _flatpak = {
    'device=all': 'android.permission.CAMERA',
    'device=dri': '',
    'share=network': 'android.permission.INTERNET',
    'socket=pulseaudio': 'android.permission.RECORD_AUDIO',
    'socket=x11': 'android.permission.SYSTEM_ALERT_WINDOW',
    'filesystem=home': 'android.permission.READ_EXTERNAL_STORAGE',
    'filesystem=host': 'android.permission.MANAGE_EXTERNAL_STORAGE',
    'talk-name=org.freedesktop.Flatpak': 'android.permission.BIND_DEVICE_ADMIN',
  };

  static const Map<String, String> _snap = {
    'camera': 'android.permission.CAMERA',
    'audio-record': 'android.permission.RECORD_AUDIO',
    'location-observe': 'android.permission.ACCESS_FINE_LOCATION',
    'location-control': 'android.permission.ACCESS_FINE_LOCATION',
    'network': 'android.permission.INTERNET',
    'network-manager': 'android.permission.INTERNET',
    'home': 'android.permission.READ_EXTERNAL_STORAGE',
    'removable-media': 'android.permission.WRITE_EXTERNAL_STORAGE',
    'system-files': 'android.permission.MANAGE_EXTERNAL_STORAGE',
    'contacts-service': 'android.permission.READ_CONTACTS',
    'calendar-service': 'android.permission.READ_CALENDAR',
    'screen-inhibit-control': 'android.permission.SYSTEM_ALERT_WINDOW',
    'desktop-launch': 'android.permission.SYSTEM_ALERT_WINDOW',
    // classic confinement is Snap's escape hatch: no sandbox at all.
    'classic': 'android.permission.BIND_DEVICE_ADMIN',
  };

  /// Cross-platform behavioural signals, applied on top of whatever the OS
  /// declares. These carry real weight in `PermissionAnalyzer._calcBehaviorScore`
  /// and in the RF/LGBM feature vector, so each maps to the Android permission
  /// that produces the same behaviour rather than to a made-up string.
  static const String _autostartPermission =
      'android.permission.RECEIVE_BOOT_COMPLETED';
  static const String _servicePermission =
      'android.permission.FOREGROUND_SERVICE';
  static const String _elevatedPermission =
      'android.permission.BIND_DEVICE_ADMIN';

  /// Builds the permission list for one desktop app.
  ///
  /// Pass whichever declaration set the host provides — `msixCapabilities` on
  /// Windows, `macosUsageKeys` on macOS, `flatpakPermissions`/`snapPlugs` on
  /// Linux — plus the behavioural flags, which every host can determine.
  static List<String> toAndroidPermissions({
    List<String> msixCapabilities = const [],
    List<String> macosUsageKeys = const [],
    List<String> flatpakPermissions = const [],
    List<String> snapPlugs = const [],
    bool autostart = false,
    bool runsSystemService = false,
    bool unsignedBinary = false,
    bool installedOutsideManagedDir = false,
  }) {
    // A set: two macOS keys can map to one Android permission (photo library
    // and downloads folder both mean "reads your files"), and counting that
    // twice would inflate the permission score.
    final permissions = <String>{};

    void addAll(List<String> declared, Map<String, String> table) {
      for (final item in declared) {
        final mapped = table[item];
        if (mapped != null && mapped.isNotEmpty) permissions.add(mapped);
      }
    }

    addAll(msixCapabilities, _msix);
    addAll(macosUsageKeys, _macos);
    addAll(flatpakPermissions, _flatpak);
    addAll(snapPlugs, _snap);

    if (autostart) permissions.add(_autostartPermission);
    if (runsSystemService) {
      permissions.add(_servicePermission);
      permissions.add(_elevatedPermission);
    }
    // An unsigned binary installed outside the managed program directories is
    // the desktop shape of a sideloaded dropper. It is reported through
    // `installerPackage` (which drives the trusted-store discount) rather than
    // as a permission, so only the install-anything capability is added here.
    if (unsignedBinary && installedOutsideManagedDir) {
      permissions.add('android.permission.REQUEST_INSTALL_PACKAGES');
    }

    return permissions.toList()..sort();
  }
}
