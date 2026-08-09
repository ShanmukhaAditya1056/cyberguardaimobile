import '../../../models/app_info_model.dart';
import '../host_shell.dart';
import 'desktop_capabilities.dart';
import 'wifi_parsing.dart';

/// Linux implementation of the inventory and Wi-Fi probes.
///
/// Linux has three overlapping notions of "an installed application" and only
/// two of them declare permissions:
///
///  * **Flatpak** and **Snap** both sandbox the app and publish exactly what it
///    is allowed to reach — the closest thing on any desktop to an Android
///    manifest, and the richest input this probe has.
///  * A **distribution package** (`dpkg`/`rpm`) is signed by a repository the
///    user already trusts but has no sandbox at all, so it is scored as
///    trusted-but-unconstrained.
///  * A **loose desktop entry** — a `.desktop` file in the user's home pointing
///    at a binary the user downloaded — has neither signature nor sandbox. That
///    is the Linux shape of a sideloaded APK and is scored accordingly.
class LinuxProbe {
  const LinuxProbe();

  // ── Installed software ───────────────────────────────────────────────────

  Future<List<AppInfoModel>> getInstalledApps() async {
    final results = await Future.wait([
      _readFlatpaks(),
      _readSnaps(),
      _readLooseDesktopEntries(),
    ]);

    final apps = <AppInfoModel>[
      for (final batch in results) ...batch,
    ];

    // A Flatpak and a distro package of the same program both ship a desktop
    // entry, so drop anything the sandboxed passes already reported.
    final seen = <String>{};
    final deduped = <AppInfoModel>[];
    for (final app in apps) {
      final key = app.appName.toLowerCase();
      if (!seen.add(key)) continue;
      deduped.add(app);
    }

    deduped.sort(
        (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return deduped;
  }

  /// Flatpak apps and their sandbox holes.
  ///
  /// Permissions are read from each app's `metadata` file rather than by
  /// running `flatpak info --show-permissions` per app: the files are already
  /// on disk in a known layout, so one `grep` replaces one process per
  /// installed app.
  Future<List<AppInfoModel>> _readFlatpaks() async {
    final listing = await HostShell.run(
      'flatpak',
      ['list', '--app', '--columns=application,name,version,origin'],
      timeout: const Duration(seconds: 20),
    );
    if (!listing.ok || listing.lines.isEmpty) return const [];

    const permScript = r'''
for root in /var/lib/flatpak/app "$HOME/.local/share/flatpak/app"; do
  [ -d "$root" ] || continue
  for dir in "$root"/*/current/active; do
    [ -f "$dir/metadata" ] || continue
    id=$(printf '%s' "$dir" | sed -E 's#.*/app/([^/]+)/current/active#\1#')
    sed -n '/^\[Context\]/,/^\[/p' "$dir/metadata" |
      grep -E '^(shared|sockets|devices|filesystems|features)=' |
      while IFS='=' read -r key vals; do
        printf '%s\n' "$vals" | tr ';,' '\n\n' | while read -r v; do
          [ -n "$v" ] && printf '%s\t%s=%s\n' "$id" "$key" "$v"
        done
      done
  done
done
''';
    final permsResult = await HostShell.run(
      '/bin/sh',
      ['-c', permScript],
      timeout: const Duration(seconds: 25),
    );

    // metadata writes `shared=network`, `sockets=pulseaudio`,
    // `filesystems=home`; the capability table is keyed the way `flatpak
    // override` spells them (`share=network`, `socket=pulseaudio`), so
    // normalise the plural section names to the singular CLI form.
    const sectionAlias = {
      'shared': 'share',
      'sockets': 'socket',
      'devices': 'device',
      'filesystems': 'filesystem',
      'features': 'feature',
    };

    final perms = <String, List<String>>{};
    for (final line in permsResult.lines) {
      final parts = line.split('\t');
      if (parts.length != 2) continue;
      final pair = parts[1].split('=');
      if (pair.length != 2) continue;
      final section = sectionAlias[pair[0]] ?? pair[0];
      (perms[parts[0]] ??= <String>[]).add('$section=${pair[1]}');
    }

    final apps = <AppInfoModel>[];
    for (final line in listing.lines) {
      final cols = line.split('\t');
      if (cols.length < 2) continue;
      final id = cols[0].trim();
      final name = cols[1].trim();
      if (id.isEmpty) continue;

      // flathub and the distro's own remote are curated and signed. A remote
      // the user added by hand is not, and is treated as an unknown source.
      final origin = cols.length > 3 ? cols[3].trim() : '';
      final trusted = origin == 'flathub' || origin == 'fedora';

      apps.add(AppInfoModel(
        packageName: id,
        appName: name.isEmpty ? id : name,
        versionName: cols.length > 2 ? cols[2].trim() : '',
        targetSdk: DesktopCapabilities.neutralTargetSdk,
        minSdk: DesktopCapabilities.neutralMinSdk,
        installTime: 0,
        updateTime: 0,
        permissions: DesktopCapabilities.toAndroidPermissions(
          flatpakPermissions: perms[id] ?? const [],
        ),
        apkSize: 0,
        installerPackage:
            trusted ? DesktopCapabilities.storeInstallerId : '',
        sourceLabel: origin.isEmpty
            ? 'Flatpak (unknown remote)'
            : 'Flatpak from $origin',
      ));
    }
    return apps;
  }

  /// Snap apps and their connected interfaces.
  ///
  /// Only *connected* plugs are counted. A snap can declare `camera` and never
  /// have it granted; scoring the declaration rather than the connection would
  /// flag apps for access they do not actually hold.
  Future<List<AppInfoModel>> _readSnaps() async {
    final results = await Future.wait([
      HostShell.run('snap', ['list'], timeout: const Duration(seconds: 20)),
      HostShell.run('snap', ['connections'],
          timeout: const Duration(seconds: 20)),
    ]);
    final listing = results[0];
    final connections = results[1];
    if (!listing.ok || listing.lines.length < 2) return const [];

    // `snap connections` columns: Interface | Plug | Slot | Notes.
    // Plug reads `<snap>:<plug-name>`; a Slot of `-` means unconnected.
    final plugs = <String, List<String>>{};
    for (final line in connections.lines.skip(1)) {
      final cols = line.split(RegExp(r'\s+'));
      if (cols.length < 3) continue;
      if (cols[2] == '-') continue;
      final plug = cols[1].split(':');
      if (plug.length != 2) continue;
      (plugs[plug[0]] ??= <String>[]).add(cols[0]);
    }

    final apps = <AppInfoModel>[];
    for (final line in listing.lines.skip(1)) {
      final cols = line.split(RegExp(r'\s+'));
      if (cols.length < 2) continue;
      final name = cols[0];
      if (name.isEmpty) continue;

      final notes = cols.length > 5 ? cols[5] : '';
      final isClassic = notes.contains('classic');
      final snapPlugs = <String>[
        ...?plugs[name],
        // Classic confinement removes the sandbox altogether, which the
        // capability table maps to full device authority.
        if (isClassic) 'classic',
      ];

      apps.add(AppInfoModel(
        packageName: name,
        appName: name,
        versionName: cols[1],
        targetSdk: DesktopCapabilities.neutralTargetSdk,
        minSdk: DesktopCapabilities.neutralMinSdk,
        installTime: 0,
        updateTime: 0,
        permissions:
            DesktopCapabilities.toAndroidPermissions(snapPlugs: snapPlugs),
        apkSize: 0,
        // The Snap Store reviews and signs every revision, so even a
        // classic-confinement snap counts as store-distributed. Its lack of a
        // sandbox is already reflected in the permissions above.
        installerPackage: DesktopCapabilities.storeInstallerId,
        sourceLabel: isClassic
            ? 'Snap Store (classic confinement — no sandbox)'
            : 'Snap Store (confined)',
      ));
    }
    return apps;
  }

  /// Desktop entries the user installed by hand, plus what autostarts.
  ///
  /// System-wide entries under `/usr/share/applications` come from signed
  /// repository packages and are skipped — the interesting set is
  /// `~/.local/share/applications`, where an AppImage or a downloaded tarball
  /// registers itself with no signature and no sandbox.
  Future<List<AppInfoModel>> _readLooseDesktopEntries() async {
    const script = r'''
dir="$HOME/.local/share/applications"
[ -d "$dir" ] || exit 0
for f in "$dir"/*.desktop; do
  [ -f "$f" ] || continue
  name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
  exec_line=$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)
  [ -n "$name" ] && printf 'APP\t%s\t%s\t%s\n' "$f" "$name" "$exec_line"
done
for adir in "$HOME/.config/autostart" /etc/xdg/autostart; do
  [ -d "$adir" ] || continue
  for f in "$adir"/*.desktop; do
    [ -f "$f" ] || continue
    name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
    [ -n "$name" ] && printf 'AUTOSTART\t%s\n' "$name"
  done
done
systemctl list-unit-files --type=service --state=enabled --no-legend --no-pager 2>/dev/null |
  awk '{print "SERVICE\t" $1}'
''';
    final result = await HostShell.run(
      '/bin/sh',
      ['-c', script],
      timeout: const Duration(seconds: 25),
    );

    final autostart = <String>{};
    final services = <String>{};
    final entries = <(String path, String name, String exec)>[];

    for (final line in result.lines) {
      final cols = line.split('\t');
      switch (cols.first) {
        case 'APP' when cols.length >= 3:
          entries.add((cols[1], cols[2], cols.length > 3 ? cols[3] : ''));
        case 'AUTOSTART' when cols.length >= 2:
          autostart.add(cols[1].toLowerCase());
        case 'SERVICE' when cols.length >= 2:
          services.add(cols[1].replaceAll('.service', '').toLowerCase());
      }
    }

    return entries.map((entry) {
      final (path, name, exec) = entry;
      final lowerName = name.toLowerCase();
      return AppInfoModel(
        packageName: path,
        appName: name,
        versionName: '',
        targetSdk: DesktopCapabilities.neutralTargetSdk,
        minSdk: DesktopCapabilities.neutralMinSdk,
        installTime: 0,
        updateTime: 0,
        permissions: DesktopCapabilities.toAndroidPermissions(
          autostart: autostart.contains(lowerName),
          runsSystemService: services.contains(lowerName),
          // Both flags were previously asserted unconditionally here, which
          // made the pair's AND meaningless and attached "can install other
          // software" to every hand-installed program on the machine. That is
          // the same over-broad mapping that flagged a quarter of a Windows
          // inventory.
          //
          // What is actually known about a loose desktop entry is that its
          // provenance is unverifiable — and that is already expressed by the
          // empty `installerPackage` below, which withholds the trusted-store
          // discount. Claiming a specific capability on top double-counts the
          // same single fact.
          unsignedBinary: true,
          installedOutsideManagedDir: false,
        ),
        apkSize: 0,
        // No signature, no sandbox, no repository: unknown provenance, which
        // is what an empty installer id means to AppInfoModel.
        installerPackage: '',
        sourceLabel: 'Installed by hand (no repository, no sandbox)',
      );
    }).where((app) => app.appName.isNotEmpty).toList();
  }

  // ── Wi-Fi ────────────────────────────────────────────────────────────────

  /// NetworkManager first, since it reports the BSSID and the security mode in
  /// one machine-readable line. `iw` is the fallback for systems that do not
  /// run NetworkManager — it gives signal in real dBm but no security mode.
  Future<Map<String, dynamic>> getWifiDetails() async {
    final nmcli = await _viaNmcli();
    if (nmcli != null) return nmcli;

    final iw = await _viaIw();
    if (iw != null) return iw;

    return {
      'status': 'error',
      'message': 'Could not read Wi-Fi state. Install NetworkManager (nmcli) '
          'or the iw tools to enable network analysis.',
    };
  }

  Future<Map<String, dynamic>?> _viaNmcli() async {
    final result = await HostShell.run(
      'nmcli',
      [
        '-t',
        '-f',
        'ACTIVE,SSID,BSSID,SIGNAL,SECURITY,FREQ,RATE',
        'dev',
        'wifi',
      ],
      timeout: const Duration(seconds: 15),
    );
    if (!result.ok) return null;

    for (final line in result.lines) {
      final cols = _splitTerse(line);
      if (cols.length < 7 || cols[0] != 'yes') continue;

      final security = cols[4].trim();
      // nmcli leaves SECURITY empty for an open network — the one case where
      // an empty field is meaningful rather than missing.
      final isOpen = security.isEmpty || security == '--';

      return {
        'status': 'connected',
        'ssid': cols[1],
        'bssid': cols[2].toLowerCase(),
        'rssi': WifiParsing.percentToRssi(int.tryParse(cols[3])),
        'linkSpeed': _parseRate(cols[6]),
        'frequency': WifiParsing.parseFrequency(cols[5]),
        'isSecured': !isOpen && !security.toUpperCase().startsWith('WEP'),
        'securityLabel': isOpen
            ? 'Open (no encryption)'
            : security.toUpperCase().startsWith('WEP')
                ? 'WEP (broken encryption)'
                : security,
      };
    }

    // nmcli ran and listed networks, but none is active.
    return {
      'status': 'not_connected',
      'message': 'Not connected to a Wi-Fi network. Connect first, then scan.',
    };
  }

  Future<Map<String, dynamic>?> _viaIw() async {
    final link = await HostShell.run(
      '/bin/sh',
      ['-c', r'''iw dev 2>/dev/null | awk '/Interface/{print $2}' | while read -r i; do iw dev "$i" link; done'''],
      timeout: const Duration(seconds: 15),
    );
    if (!link.ok || link.stdout.trim().isEmpty) return null;
    if (link.stdout.contains('Not connected')) {
      return {
        'status': 'not_connected',
        'message': 'Not connected to a Wi-Fi network. Connect first, then scan.',
      };
    }

    final fields = WifiParsing.parseColonBlock(link.stdout);
    final ssid = WifiParsing.pickSsid(fields);
    // `iw dev … link` opens with "Connected to <bssid> (on wlan0)", which is
    // not a colon-delimited field, so read the MAC off that line directly.
    final bssidMatch = RegExp(r'Connected to ((?:[0-9a-f]{2}:){5}[0-9a-f]{2})',
            caseSensitive: false)
        .firstMatch(link.stdout);
    final signalMatch =
        RegExp(r'signal:\s*(-?\d+)\s*dBm').firstMatch(link.stdout);
    final freqMatch = RegExp(r'freq:\s*(\d+)').firstMatch(link.stdout);
    final rateMatch =
        RegExp(r'rx bitrate:\s*([\d.]+)\s*MBit/s').firstMatch(link.stdout);

    return {
      'status': 'connected',
      'ssid': ssid ?? '',
      'bssid': bssidMatch?.group(1)?.toLowerCase() ?? '',
      'rssi': int.tryParse(signalMatch?.group(1) ?? '') ?? -100,
      'linkSpeed': double.tryParse(rateMatch?.group(1) ?? '')?.round() ?? 0,
      'frequency': int.tryParse(freqMatch?.group(1) ?? '') ?? 0,
      // `iw link` does not report the cipher. Assuming "encrypted" is the safe
      // default here for the same reason as WifiParsing.pickSecurity: an
      // unfounded "this network is open" warning is worse than a missing one.
      'isSecured': true,
      'securityLabel': 'Unknown (nmcli not available)',
    };
  }

  /// nmcli's terse mode separates fields with `:` and backslash-escapes any
  /// colon inside a value — which every BSSID contains.
  static List<String> _splitTerse(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == r'\' && i + 1 < line.length) {
        buffer.write(line[++i]);
      } else if (ch == ':') {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }

  static int _parseRate(String raw) {
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}
