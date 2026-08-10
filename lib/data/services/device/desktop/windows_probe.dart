import '../../../models/app_info_model.dart';
import '../host_shell.dart';
import 'desktop_capabilities.dart';
import 'wifi_parsing.dart';

/// What [WindowsProbe.classifySource] concluded about one program.
class WindowsSource {
  /// Whether it came from somewhere with real accountability — the Store, a
  /// managed directory with a named publisher, or a valid Authenticode
  /// signature. Drives the trust discount in `PermissionAnalyzer`.
  final bool trusted;

  /// Whether it is known to live outside the managed program directories.
  ///
  /// False when the location is simply unknown. The distinction matters: this
  /// flag combined with an invalid signature is what attaches
  /// `REQUEST_INSTALL_PACKAGES`, so asserting it on absent evidence
  /// manufactures a finding.
  final bool outsideManagedDir;

  /// Shown verbatim under "Install Source" in the App Scanner.
  final String label;

  const WindowsSource({
    required this.trusted,
    required this.outsideManagedDir,
    required this.label,
  });
}

/// Windows implementation of the inventory and Wi-Fi probes.
///
/// Software inventory comes from the two places Windows actually records it:
/// the `Uninstall` registry hives (everything installed by an MSI or a classic
/// setup.exe) and the MSIX/Store package database. Those two sets barely
/// overlap, and only the second declares capabilities, so both are read and
/// merged.
class WindowsProbe {
  const WindowsProbe();

  // ── Installed software ───────────────────────────────────────────────────

  /// One PowerShell invocation returns both halves of the inventory plus the
  /// autostart set. Spawning PowerShell costs the better part of a second, so
  /// everything that needs it is batched into this single script rather than
  /// paid for three times.
  static const _inventoryScript = r'''
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# Command lines registered to run at logon, from both the Run keys and the
# startup folder. Matched against install locations further down.
$autostart = @(Get-CimInstance Win32_StartupCommand |
  ForEach-Object { $_.Command }) -join ' | '

# Services that run with full machine privileges. A third-party app that
# installs one has a persistent, elevated foothold.
$svcPaths = @(Get-CimInstance Win32_Service |
  Where-Object { $_.StartName -eq 'LocalSystem' -and $_.PathName } |
  ForEach-Object { $_.PathName }) -join ' | '

$rows = New-Object System.Collections.ArrayList

$roots = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

foreach ($root in $roots) {
  foreach ($k in (Get-ItemProperty $root)) {
    if (-not $k.DisplayName) { continue }
    # SystemComponent=1 marks redistributables and driver bundles that never
    # appear in Settings; listing them would bury the user's real software.
    if ($k.SystemComponent -eq 1) { continue }
    $loc = if ($k.InstallLocation) { $k.InstallLocation } else { '' }
    $null = $rows.Add([pscustomobject]@{
      id            = $k.PSChildName
      name          = $k.DisplayName
      publisher     = if ($k.Publisher) { $k.Publisher } else { '' }
      version       = if ($k.DisplayVersion) { $k.DisplayVersion } else { '' }
      location      = $loc
      installDate   = if ($k.InstallDate) { $k.InstallDate } else { '' }
      sizeKb        = if ($k.EstimatedSize) { [int]$k.EstimatedSize } else { 0 }
      source        = 'registry'
      capabilities  = @()
      autostart     = ($loc -and $autostart.Contains($loc))
      systemService = ($loc -and $svcPaths.Contains($loc))
    })
  }
}

foreach ($p in (Get-AppxPackage)) {
  if ($p.IsFramework -or $p.SignatureKind -eq 'System') { continue }
  $caps = @()
  try {
    $mf = Join-Path $p.InstallLocation 'AppxManifest.xml'
    if (Test-Path $mf) {
      [xml]$x = Get-Content $mf -Raw
      $caps = @($x.Package.Capabilities.ChildNodes |
        ForEach-Object { $_.Name } | Where-Object { $_ })
    }
  } catch { }
  $null = $rows.Add([pscustomobject]@{
    id            = $p.PackageFamilyName
    name          = $p.Name
    publisher     = $p.Publisher
    version       = $p.Version
    location      = $p.InstallLocation
    installDate   = ''
    sizeKb        = 0
    source        = 'msix'
    capabilities  = $caps
    # A Store package is launched by the shell, never by a Run key, and cannot
    # register a LocalSystem service — both are false by construction.
    autostart     = $false
    systemService = $false
  })
}

$rows | ConvertTo-Json -Depth 4 -Compress
''';

  /// Authenticode status for the executables under a set of install paths.
  ///
  /// Deliberately not run over the whole inventory: `Get-AuthenticodeSignature`
  /// hashes and chain-validates each file, which takes tens of seconds across a
  /// typical Program Files. Only the paths the caller already considers
  /// unusual — installed outside the managed program directories — are checked,
  /// which is where an unsigned binary is actually informative.
  static String _signatureScript(List<String> paths) {
    final quoted = paths.map((p) => "'${p.replaceAll("'", "''")}'").join(',');
    return '''
\$ErrorActionPreference = 'SilentlyContinue'
\$ProgressPreference = 'SilentlyContinue'
@($quoted) | ForEach-Object {
  \$dir = \$_
  \$exe = Get-ChildItem -LiteralPath \$dir -Filter *.exe -File -ErrorAction SilentlyContinue |
    Select-Object -First 1
  \$valid = \$false
  if (\$exe) {
    \$sig = Get-AuthenticodeSignature -LiteralPath \$exe.FullName
    \$valid = (\$sig.Status -eq 'Valid')
  }
  [pscustomobject]@{ location = \$dir; signed = \$valid }
} | ConvertTo-Json -Depth 3 -Compress
''';
  }

  Future<List<AppInfoModel>> getInstalledApps() async {
    final rows = await HostShell.powershellJson(
      _inventoryScript,
      timeout: const Duration(seconds: 45),
    );
    if (rows.isEmpty) return const [];

    // Everything under the two managed program directories went through an
    // installer that Windows tracks. Anything else — a folder in AppData, on a
    // second drive, in the user profile — is the desktop equivalent of a
    // sideloaded APK, and is the only subset worth paying signature checks for.
    final unmanaged = <String>[];
    for (final row in rows) {
      final location = (row['location'] as String? ?? '').trim();
      if (location.isEmpty) continue;
      if (row['source'] != 'registry') continue;
      if (_isManagedLocation(location)) continue;
      unmanaged.add(location);
    }

    final signed = <String, bool>{};
    if (unmanaged.isNotEmpty) {
      final capped = unmanaged.take(40).toList();
      final sigRows = await HostShell.powershellJson(
        _signatureScript(capped),
        timeout: const Duration(seconds: 40),
      );
      for (final row in sigRows) {
        final location = row['location'] as String?;
        if (location != null) signed[location] = row['signed'] == true;
      }
    }

    return rows.map((row) => _toAppInfo(row, signed)).toList()
      ..sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
  }

  static bool _isManagedLocation(String location) {
    final lower = location.toLowerCase();
    return lower.startsWith(r'c:\program files') ||
        lower.startsWith(r'c:\windows');
  }

  AppInfoModel _toAppInfo(Map<String, dynamic> row, Map<String, bool> signed) {
    final name = (row['name'] as String? ?? 'Unknown').trim();
    final location = (row['location'] as String? ?? '').trim();
    final publisher = (row['publisher'] as String? ?? '').trim();
    final isMsix = row['source'] == 'msix';
    final capabilities = (row['capabilities'] as List<dynamic>? ?? const [])
        .map((c) => c.toString())
        .toList();

    final source = classifySource(
      isMsix: isMsix,
      location: location,
      publisher: publisher,
      signatureValid: signed[location],
    );

    final permissions = DesktopCapabilities.toAndroidPermissions(
      msixCapabilities: capabilities,
      autostart: row['autostart'] == true,
      runsSystemService: row['systemService'] == true,
      unsignedBinary: !source.trusted,
      installedOutsideManagedDir: source.outsideManagedDir,
    );

    return AppInfoModel(
      packageName: (row['id'] as String? ?? name),
      appName: name,
      versionName: (row['version'] as String? ?? '').trim(),
      // Windows has no SDK-level concept; the ML feature extractor is fed the
      // neutral defaults documented in DesktopCapabilities.
      targetSdk: DesktopCapabilities.neutralTargetSdk,
      minSdk: DesktopCapabilities.neutralMinSdk,
      installTime: _parseInstallDate(row['installDate'] as String?),
      updateTime: _parseInstallDate(row['installDate'] as String?),
      permissions: permissions,
      apkSize: ((row['sizeKb'] as num?)?.toInt() ?? 0) * 1024,
      installerPackage: source.trusted
          ? (isMsix
              ? DesktopCapabilities.storeInstallerId
              : DesktopCapabilities.managedInstallerId)
          : '',
      sourceLabel: source.label,
    );
  }

  /// Where a Windows program came from, and whether that is trustworthy.
  ///
  /// Split out from [_toAppInfo] because it is the subtlest decision the
  /// probe makes and it drives both the trust discount the risk engine applies
  /// and the text the user reads. See [WindowsSource] for the rules.
  static WindowsSource classifySource({
    required bool isMsix,
    required String location,
    required String publisher,
    required bool? signatureValid,
  }) {
    if (isMsix) {
      // Distributed and signed by Microsoft.
      return const WindowsSource(
        trusted: true,
        outsideManagedDir: false,
        label: 'Microsoft Store (MSIX)',
      );
    }

    // `InstallLocation` being blank is common, not suspicious: on a real
    // machine 38 of 72 registry entries omitted it, because plenty of MSI
    // installers never write the value. Treating that as "not in Program
    // Files, and no signature on file" marked more than half the inventory as
    // sideloaded. An absent location is *unknown*, so fall back to the
    // publisher — the attribution Windows itself relies on when there is
    // nothing else — and assert nothing about where it lives.
    if (location.isEmpty) {
      return WindowsSource(
        trusted: publisher.isNotEmpty,
        outsideManagedDir: false,
        label: publisher.isEmpty
            ? 'Installer (no publisher recorded)'
            : 'Installer, signed by $publisher',
      );
    }

    if (_isManagedLocation(location)) {
      // Landed in a managed directory *and* named a publisher — the same two
      // things Windows shows to justify a UAC prompt.
      return WindowsSource(
        trusted: publisher.isNotEmpty,
        outsideManagedDir: false,
        label: publisher.isEmpty
            ? 'Program Files (no publisher recorded)'
            : 'Program Files, published by $publisher',
      );
    }

    // Somewhere else entirely — AppData, a second drive, the user profile.
    // This is the subset worth paying an Authenticode check for, and the only
    // one where a missing signature is genuinely informative.
    final valid = signatureValid ?? false;
    return WindowsSource(
      trusted: valid,
      outsideManagedDir: true,
      label: valid
          ? 'Outside Program Files, signature valid'
          : 'Outside Program Files, unsigned',
    );
  }

  /// Registry `InstallDate` is a bare `yyyyMMdd` string; anything else is
  /// treated as unknown rather than guessed at.
  static int _parseInstallDate(String? raw) {
    if (raw == null || raw.length != 8) return 0;
    final year = int.tryParse(raw.substring(0, 4));
    final month = int.tryParse(raw.substring(4, 6));
    final day = int.tryParse(raw.substring(6, 8));
    if (year == null || month == null || day == null) return 0;
    if (month < 1 || month > 12 || day < 1 || day > 31) return 0;
    return DateTime(year, month, day).millisecondsSinceEpoch;
  }

  // ── Wi-Fi ────────────────────────────────────────────────────────────────

  /// `netsh wlan show interfaces` is the only tool that reports the BSSID and
  /// the negotiated cipher, but every one of its labels is translated on a
  /// localised Windows. So the output is read by the *shape of the values*
  /// rather than by label text — see [WifiParsing] — and the one field that
  /// approach cannot recover, link speed, is taken from `Get-NetAdapter`,
  /// whose property names are invariant.
  Future<Map<String, dynamic>> getWifiDetails() async {
    final netsh = await HostShell.run(
      'netsh',
      ['wlan', 'show', 'interfaces'],
      timeout: const Duration(seconds: 10),
    );

    if (!netsh.ok) {
      // No WLAN service at all: a desktop on Ethernet, or a VM.
      return {
        'status': 'not_connected',
        'message': 'No Wi-Fi adapter found on this PC. '
            'Connect over Wi-Fi to analyse the network.',
      };
    }

    final fields = WifiParsing.parseColonBlock(netsh.stdout);
    final ssid = WifiParsing.pickSsid(fields);
    final bssid = WifiParsing.pickBssid(fields);
    final signalPercent = WifiParsing.pickPercentage(fields);
    final security = WifiParsing.pickSecurity(fields);
    final channel = WifiParsing.pickChannel(fields);

    // netsh prints the adapter block with a "disconnected" state and no BSSID
    // when the radio is on but unassociated.
    if (bssid == null && ssid == null) {
      final radioOff = netsh.stdout.toLowerCase().contains('hardware') ||
          fields.isEmpty;
      return {
        'status': radioOff ? 'wifi_off' : 'not_connected',
        'message': radioOff
            ? 'The Wi-Fi radio is switched off. Turn it on and scan again.'
            : 'Not connected to a Wi-Fi network. Connect first, then scan.',
      };
    }

    final linkSpeed = await _linkSpeedMbps();

    return {
      'status': 'connected',
      'ssid': ssid ?? '',
      'bssid': bssid ?? '',
      'rssi': WifiParsing.percentToRssi(signalPercent),
      'linkSpeed': linkSpeed,
      'frequency': WifiParsing.channelToFrequency(channel),
      'isSecured': security.isSecured,
      'securityLabel': security.label,
    };
  }

  /// Negotiated receive rate in Mbps, or 0 when no wireless adapter reports one.
  Future<int> _linkSpeedMbps() async {
    final rows = await HostShell.powershellJson(
      r"Get-NetAdapter -Physical | "
      r"Where-Object { $_.PhysicalMediaType -like '*802.11*' -and "
      r"$_.Status -eq 'Up' } | "
      r"Select-Object -First 1 -Property @{n='mbps';"
      r"e={[int]($_.Speed / 1000000)}} | ConvertTo-Json -Compress",
      timeout: const Duration(seconds: 12),
    );
    if (rows.isEmpty) return 0;
    return (rows.first['mbps'] as num?)?.toInt() ?? 0;
  }
}
