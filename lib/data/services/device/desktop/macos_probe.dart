import 'dart:convert';

import '../../../models/app_info_model.dart';
import '../host_shell.dart';
import 'desktop_capabilities.dart';

/// What [MacosProbe.classifySource] concluded about one bundle.
class MacosSource {
  /// Signed by Apple's review or by an identified developer.
  final bool trusted;

  /// Whether it is known to live outside `/Applications`. False when
  /// provenance was not reported at all — see [MacosProbe.classifySource].
  final bool outsideManagedDir;

  /// Synthetic installer id, so `AppInfoModel.isFromTrustedStore` keeps
  /// driving the shared risk engine's trust discount.
  final String installerId;

  /// Shown verbatim under "Install Source" in the App Scanner.
  final String label;

  const MacosSource({
    required this.trusted,
    required this.outsideManagedDir,
    required this.installerId,
    required this.label,
  });
}

/// macOS implementation of the inventory and Wi-Fi probes.
///
/// This is the closest analogue to Android of the three desktops. Every bundle
/// declares the privacy-sensitive resources it touches in its `Info.plist` as
/// `NS…UsageDescription` keys — the same declaration an Android app makes in
/// its manifest, checked by the same kind of store review — and macOS records
/// where each app came from, so both halves of the Android risk model
/// (declared permissions, install provenance) have real inputs here.
class MacosProbe {
  const MacosProbe();

  // ── Installed software ───────────────────────────────────────────────────

  Future<List<AppInfoModel>> getInstalledApps() async {
    // Independent commands, so pay for the slowest rather than the sum.
    // system_profiler is the slow one — it can take 20 s on a full disk.
    final results = await Future.wait([
      HostShell.run(
        'system_profiler',
        // Deliberately the default detail level rather than `mini`. The trust
        // decision below turns entirely on `obtained_from`, and `mini` is
        // documented only as "no personal information" — it does not guarantee
        // which fields survive. Losing that one field would silently mark
        // every application on the machine as unsigned.
        ['SPApplicationsDataType', '-json'],
        timeout: const Duration(seconds: 90),
      ),
      _readUsageDescriptions(),
      _readLaunchItems(),
    ]);

    final profile = results[0] as ShellResult;
    final usageKeys = results[1] as Map<String, List<String>>;
    final launchItems = results[2] as _LaunchItems;

    if (!profile.ok || profile.stdout.trim().isEmpty) return const [];

    final List<dynamic> apps;
    try {
      final decoded = jsonDecode(profile.stdout) as Map<String, dynamic>;
      apps = decoded['SPApplicationsDataType'] as List<dynamic>? ?? const [];
    } on FormatException {
      return const [];
    }

    final out = <AppInfoModel>[];
    for (final entry in apps) {
      if (entry is! Map) continue;
      final app = Map<String, dynamic>.from(entry);
      final path = (app['path'] as String? ?? '').trim();
      if (path.isEmpty) continue;

      // Apple's own bundles are part of the OS, not the user's attack surface,
      // and listing 200 of them would bury the apps that matter.
      //
      // An *absent* `obtained_from` is distinct from a reported "unknown": the
      // first means system_profiler did not tell us, the second means it looked
      // and found no signature. Collapsing them — as an `?? 'unknown'` default
      // does — is the same mistake that marked half the Windows inventory as
      // sideloaded, so the two are kept apart here and resolved in _toAppInfo.
      final obtainedFrom = app['obtained_from'] as String?;
      if (obtainedFrom == 'apple') continue;
      if (path.startsWith('/System/')) continue;

      out.add(_toAppInfo(app, path, obtainedFrom, usageKeys, launchItems));
    }

    out.sort(
        (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return out;
  }

  AppInfoModel _toAppInfo(
    Map<String, dynamic> app,
    String path,
    String? obtainedFrom,
    Map<String, List<String>> usageKeys,
    _LaunchItems launchItems,
  ) {
    final name = (app['_name'] as String? ?? 'Unknown').trim();
    final source = classifySource(obtainedFrom: obtainedFrom, path: path);

    final permissions = DesktopCapabilities.toAndroidPermissions(
      macosUsageKeys: usageKeys['$path/Contents/Info.plist'] ?? const [],
      autostart: launchItems.autostartPaths.any(path.startsWith) ||
          launchItems.autostartNames.contains(name),
      runsSystemService: launchItems.daemonPaths.any(path.startsWith),
      unsignedBinary: !source.trusted,
      installedOutsideManagedDir: source.outsideManagedDir,
    );

    return AppInfoModel(
      packageName: path,
      appName: name,
      versionName: (app['version'] as String? ?? '').trim(),
      targetSdk: DesktopCapabilities.neutralTargetSdk,
      minSdk: DesktopCapabilities.neutralMinSdk,
      installTime: _parseIsoDate(app['lastModified'] as String?),
      updateTime: _parseIsoDate(app['lastModified'] as String?),
      permissions: permissions,
      apkSize: 0,
      installerPackage: source.installerId,
      sourceLabel: source.label,
    );
  }

  /// Where a bundle came from, and whether that is trustworthy.
  ///
  /// `identified_developer` means a valid Developer ID signature that passed
  /// notarisation — Apple has seen and scanned the binary. With the App Store
  /// that is the macOS equivalent of "came from a trusted store".
  ///
  /// The case worth being careful about is a *missing* `obtained_from`, which
  /// is not the same as a reported `unknown`. Absence means system_profiler
  /// did not answer; treating it as "unsigned" is precisely the bug that
  /// mislabelled half the Windows inventory. It is reported as indeterminate
  /// instead: untrusted enough to forgo the store discount, but never used to
  /// assert that the app can install other software.
  static MacosSource classifySource({
    required String? obtainedFrom,
    required String path,
  }) {
    final outsideApplications = !path.startsWith('/Applications/') &&
        !path.startsWith('/System/Applications/');

    switch (obtainedFrom) {
      case 'mac_app_store':
        return const MacosSource(
          trusted: true,
          outsideManagedDir: false,
          installerId: DesktopCapabilities.storeInstallerId,
          label: 'Mac App Store',
        );
      case 'identified_developer':
        return MacosSource(
          trusted: true,
          outsideManagedDir: false,
          installerId: DesktopCapabilities.managedInstallerId,
          label: 'Identified developer (notarised)',
        );
      case 'web_download':
        return MacosSource(
          trusted: false,
          outsideManagedDir: outsideApplications,
          installerId: '',
          label: 'Downloaded from the web, not notarised',
        );
      case 'unknown':
        return MacosSource(
          trusted: false,
          outsideManagedDir: outsideApplications,
          installerId: '',
          label: 'Unsigned or ad-hoc signed',
        );
      default:
        // Field absent, or a value Apple added after this was written.
        return const MacosSource(
          trusted: false,
          outsideManagedDir: false,
          installerId: '',
          label: 'Provenance not reported by macOS',
        );
    }
  }

  /// Every `NS…UsageDescription` key declared by every installed bundle, keyed
  /// by Info.plist path.
  ///
  /// Done as one `grep` over all the plists rather than `plutil` per bundle:
  /// on a machine with 150 apps that is one process instead of 150, and it
  /// takes well under a second. `grep -a` is what makes it work — half of
  /// these plists are in Apple's binary format, but key *names* are stored as
  /// literal strings there too, so the same pattern matches either encoding.
  Future<Map<String, List<String>>> _readUsageDescriptions() async {
    const script = r'''
find /Applications ~/Applications -maxdepth 4 -name Info.plist \
     -path '*/Contents/Info.plist' -print0 2>/dev/null |
  xargs -0 grep -a -o -H -E 'NS[A-Za-z]+UsageDescription' 2>/dev/null |
  sort -u
''';
    final result = await HostShell.run(
      '/bin/sh',
      ['-c', script],
      timeout: const Duration(seconds: 30),
    );

    final map = <String, List<String>>{};
    for (final line in result.lines) {
      // grep -H prefixes `path:` — split on the last colon so a path
      // containing one is still handled correctly.
      final idx = line.lastIndexOf(':');
      if (idx <= 0) continue;
      final path = line.substring(0, idx);
      final key = line.substring(idx + 1);
      if (!key.startsWith('NS')) continue;
      (map[path] ??= <String>[]).add(key);
    }
    return map;
  }

  /// Launch agents, launch daemons and login items.
  ///
  /// The distinction matters: an agent runs as the signed-in user at login
  /// (persistence), a daemon runs as root before anyone logs in (persistence
  /// *and* full privilege), and they are scored differently.
  Future<_LaunchItems> _readLaunchItems() async {
    const script = r'''
for d in ~/Library/LaunchAgents /Library/LaunchAgents; do
  grep -a -h -o -E '/[A-Za-z0-9 ._/-]+\.app' "$d"/*.plist 2>/dev/null
done | sort -u | sed 's/^/AGENT /'
grep -a -h -o -E '/[A-Za-z0-9 ._/-]+\.app' /Library/LaunchDaemons/*.plist 2>/dev/null |
  sort -u | sed 's/^/DAEMON /'
osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null |
  tr ',' '\n' | sed 's/^ *//;s/^/LOGIN /'
''';
    final result = await HostShell.run(
      '/bin/sh',
      ['-c', script],
      timeout: const Duration(seconds: 20),
    );

    final autostartPaths = <String>{};
    final daemonPaths = <String>{};
    final autostartNames = <String>{};

    for (final line in result.lines) {
      if (line.startsWith('AGENT ')) {
        autostartPaths.add(line.substring(6).trim());
      } else if (line.startsWith('DAEMON ')) {
        final path = line.substring(7).trim();
        daemonPaths.add(path);
        autostartPaths.add(path);
      } else if (line.startsWith('LOGIN ')) {
        final name = line.substring(6).trim();
        if (name.isNotEmpty) autostartNames.add(name);
      }
    }

    return _LaunchItems(autostartPaths, daemonPaths, autostartNames);
  }

  static int _parseIsoDate(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
  }

  // ── Wi-Fi ────────────────────────────────────────────────────────────────

  /// `system_profiler SPAirPortDataType -json` is the supported way to read the
  /// current network on modern macOS. The `airport` binary that most tooling
  /// still reaches for was deprecated in Monterey and removed in Sonoma 14.4,
  /// so it is not used at all here.
  Future<Map<String, dynamic>> getWifiDetails() async {
    final result = await HostShell.run(
      'system_profiler',
      ['SPAirPortDataType', '-json'],
      timeout: const Duration(seconds: 20),
    );

    if (!result.ok || result.stdout.trim().isEmpty) {
      return {
        'status': 'error',
        'message': 'Could not read the Wi-Fi interface from system_profiler.',
      };
    }

    Map<String, dynamic>? current;
    bool sawInterface = false;
    try {
      final decoded = jsonDecode(result.stdout) as Map<String, dynamic>;
      final interfaces =
          decoded['SPAirPortDataType'] as List<dynamic>? ?? const [];
      for (final entry in interfaces) {
        if (entry is! Map) continue;
        final airports =
            entry['spairport_airport_interfaces'] as List<dynamic>? ?? const [];
        for (final iface in airports) {
          if (iface is! Map) continue;
          sawInterface = true;
          final network = iface['spairport_current_network_information'];
          if (network is Map) {
            current = Map<String, dynamic>.from(network);
            break;
          }
        }
        if (current != null) break;
      }
    } on FormatException {
      return {
        'status': 'error',
        'message': 'Unexpected system_profiler output.',
      };
    }

    if (!sawInterface) {
      return {
        'status': 'not_connected',
        'message': 'No Wi-Fi interface found on this Mac. '
            'Connect over Wi-Fi to analyse the network.',
      };
    }
    if (current == null) {
      return {
        'status': 'not_connected',
        'message': 'Not connected to a Wi-Fi network. Connect first, then scan.',
      };
    }

    final security = _mapSecurityMode(
        current['spairport_security_mode'] as String? ?? '');

    return {
      'status': 'connected',
      'ssid': (current['_name'] as String? ?? '').trim(),
      // macOS 14 redacts the BSSID unless the app holds Location access. The
      // Evil Twin check degrades to "first seen" rather than firing a false
      // alarm — see WifiRepository, which treats an empty BSSID as unchanged.
      'bssid': (current['spairport_network_bssid'] as String? ?? '')
          .trim()
          .toLowerCase(),
      'rssi': _parseSignal(current['spairport_signal_noise'] as String?),
      'linkSpeed': _parseRate(current['spairport_network_rate']),
      'frequency': _parseChannelFrequency(
          current['spairport_network_channel'] as String?),
      'isSecured': security.$1,
      'securityLabel': security.$2,
    };
  }

  /// system_profiler reports the mode as a localisation key, e.g.
  /// `spairport_security_mode_wpa2_personal`, which is stable across languages.
  static (bool, String) _mapSecurityMode(String mode) {
    final key = mode.replaceFirst('spairport_security_mode_', '');
    return switch (key) {
      'none' => (false, 'Open (no encryption)'),
      'wep' => (false, 'WEP (broken encryption)'),
      'wpa_personal' || 'wpa_personal_mixed' => (true, 'WPA'),
      'wpa2_personal' || 'wpa2_personal_mixed' => (true, 'WPA2 Personal'),
      'wpa3_personal' => (true, 'WPA3 Personal'),
      'wpa3_transition' => (true, 'WPA2/WPA3 Transition'),
      'wpa2_enterprise' || 'wpa3_enterprise' => (true, 'WPA Enterprise'),
      // An unrecognised mode is assumed encrypted: see WifiParsing.pickSecurity
      // for why the fallback must not be "open".
      _ => (true, mode.isEmpty ? 'Unknown' : key),
    };
  }

  /// `spairport_signal_noise` reads `-52 dBm / -92 dBm`; the first value is RSSI.
  static int _parseSignal(String? raw) {
    if (raw == null) return -100;
    final match = RegExp(r'(-\d{1,3})\s*dBm').firstMatch(raw);
    if (match == null) return -100;
    return int.tryParse(match.group(1)!) ?? -100;
  }

  static int _parseRate(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) {
      return int.tryParse(RegExp(r'\d+').firstMatch(raw)?.group(0) ?? '') ?? 0;
    }
    return 0;
  }

  /// `spairport_network_channel` reads `149 (5GHz, 80MHz)`. The band in
  /// parentheses is more reliable than deriving it from the channel number,
  /// since 6 GHz channel numbers overlap with 5 GHz ones.
  static int _parseChannelFrequency(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final channel =
        int.tryParse(RegExp(r'^\d+').firstMatch(raw.trim())?.group(0) ?? '');
    if (channel == null) return 0;

    if (raw.contains('6GHz')) return 5950 + channel * 5;
    if (raw.contains('5GHz')) return 5000 + channel * 5;
    if (raw.contains('2GHz')) {
      return channel == 14 ? 2484 : 2407 + channel * 5;
    }
    return 0;
  }
}

class _LaunchItems {
  final Set<String> autostartPaths;
  final Set<String> daemonPaths;
  final Set<String> autostartNames;

  const _LaunchItems(
      this.autostartPaths, this.daemonPaths, this.autostartNames);
}
