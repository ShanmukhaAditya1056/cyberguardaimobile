// Runs the desktop probes against the machine executing this script and
// prints what they found.
//
//   dart run tool/probe_report.dart
//
// Why this exists: the desktop probes read the output of tools the OS ships
// (`netsh`, `system_profiler`, `nmcli`, the registry), and those formats vary
// by OS version and system language. Unit tests can pin the parsers against
// captured samples, but only a run on real hardware proves the samples were
// right. This is that run — and because the probes carry no Flutter imports,
// it needs the plain Dart VM rather than a full Flutter toolchain, so it works
// on a machine that cannot yet build the app.
//
// Read-only throughout: it enumerates and reports, and changes nothing.

import 'dart:io';

import 'package:cyberguard_ai/core/constants/threat_patterns.dart';
import 'package:cyberguard_ai/core/utils/permission_analyzer.dart';
import 'package:cyberguard_ai/data/models/app_info_model.dart';
import 'package:cyberguard_ai/data/services/device/desktop/linux_probe.dart';
import 'package:cyberguard_ai/data/services/device/desktop/macos_probe.dart';
import 'package:cyberguard_ai/data/services/device/desktop/windows_probe.dart';

Future<void> main(List<String> args) async {
  final verbose = args.contains('-v') || args.contains('--verbose');

  _heading('Host');
  print('  OS        ${Platform.operatingSystem} '
      '${Platform.operatingSystemVersion}');
  print('  Locale    ${Platform.localeName}');
  print('  Dart      ${Platform.version.split(' ').first}');

  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    print('\nThis tool only covers the desktop probes. '
        'Nothing to do on ${Platform.operatingSystem}.');
    exit(0);
  }

  final failures = <String>[];

  // ── Wi-Fi ────────────────────────────────────────────────────────────────
  _heading('Wi-Fi probe');
  final wifiStopwatch = Stopwatch()..start();
  try {
    final wifi = await _wifiDetails();
    wifiStopwatch.stop();
    print('  took      ${wifiStopwatch.elapsedMilliseconds} ms');
    print('  status    ${wifi['status']}');

    if (wifi['status'] == 'connected') {
      final ssid = wifi['ssid'] as String? ?? '';
      final bssid = wifi['bssid'] as String? ?? '';
      // The SSID and BSSID identify the user's home or office network, so they
      // are masked by default — this output is the kind of thing that ends up
      // pasted into a bug report.
      print('  ssid      ${verbose ? ssid : _maskSsid(ssid)}');
      print('  bssid     ${verbose ? bssid : _maskMac(bssid)}');
      print('  rssi      ${wifi['rssi']} dBm');
      print('  security  ${wifi['securityLabel']}  '
          '(encrypted: ${wifi['isSecured']})');
      print('  frequency ${wifi['frequency']} MHz');
      print('  linkSpeed ${wifi['linkSpeed']} Mbps');

      _expect(failures, 'SSID was read', ssid.isNotEmpty);
      _expect(failures, 'BSSID looks like a MAC',
          RegExp(r'^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$').hasMatch(bssid));
      _expect(failures, 'RSSI is a plausible dBm value',
          (wifi['rssi'] as int) <= -20 && (wifi['rssi'] as int) >= -100);
      _expect(failures, 'security mode was identified',
          wifi['securityLabel'] != 'Unknown');
      _expect(failures, 'frequency resolved to a band',
          (wifi['frequency'] as int) > 2000);
    } else {
      print('  message   ${wifi['message']}');
      print('\n  Not connected over Wi-Fi, so the parsers could not be '
          'exercised.\n  Connect to a Wi-Fi network and run this again.');
    }
  } catch (e) {
    wifiStopwatch.stop();
    failures.add('Wi-Fi probe threw: $e');
    print('  FAILED    $e');
  }

  // ── Installed software ───────────────────────────────────────────────────
  _heading('Inventory probe');
  final invStopwatch = Stopwatch()..start();
  try {
    final apps = await _installedApps();
    invStopwatch.stop();
    print('  took      ${invStopwatch.elapsedMilliseconds} ms');
    print('  found     ${apps.length} apps');

    _expect(failures, 'inventory is not empty', apps.isNotEmpty);
    _expect(failures, 'inventory completed inside 60 s',
        invStopwatch.elapsed < const Duration(seconds: 60));

    if (apps.isNotEmpty) {
      final trusted = apps.where((a) => a.isFromTrustedStore).length;
      final withPerms = apps.where((a) => a.permissions.isNotEmpty).length;
      print('  trusted   $trusted  '
          '(${(trusted / apps.length * 100).toStringAsFixed(0)}%)');
      print('  with declared capabilities  $withPerms');

      _expect(failures, 'at least one app has a name',
          apps.any((a) => a.appName.trim().isNotEmpty));
      // If nothing at all maps to a permission, the capability translation is
      // silently producing empty vectors and every app scores zero.
      _expect(failures, 'capability mapping produced permissions',
          withPerms > 0);

      // ── Capability frequency ───────────────────────────────────────────
      //
      // The single most useful number here. A capability that a large share of
      // an ordinary machine declares cannot also be a red flag: mapping
      // Windows' `runFullTrust` (62% of MSIX packages) onto Android's
      // device-admin permission flagged 37% of a clean machine before it was
      // caught. Anything above ~20% below deserves the same scrutiny.
      final capCounts = <String, int>{};
      for (final a in apps) {
        for (final p in a.permissions) {
          final short = p.split('.').last;
          capCounts[short] = (capCounts[short] ?? 0) + 1;
        }
      }
      if (capCounts.isNotEmpty) {
        // Severity comes from the same table the risk engine scores against,
        // so "how alarming is this" is not re-guessed here.
        final severityOf = <String, String>{
          for (final e in ThreatPatterns.dangerousPermissions.entries)
            e.key.split('.').last: e.value,
        };
        // Frequency alone is not the smell — INTERNET is declared by a third
        // of any machine and contributes nothing to the score, because it is
        // not in the dangerous-permission table at all. The problem is a
        // capability that is *both* widespread and scored as serious, which is
        // exactly what `runFullTrust` → BIND_DEVICE_ADMIN was.
        const alarming = {'critical', 'high'};

        print('\n  Capability frequency (severity from the risk engine):');
        final ranked = capCounts.entries.toList()
          ..sort((x, y) => y.value.compareTo(x.value));
        final suspects = <String>[];
        for (final e in ranked) {
          final pct = e.value / apps.length * 100;
          final severity = severityOf[e.key] ?? 'unscored';
          final isSuspect = pct >= 20 && alarming.contains(severity);
          if (isSuspect) suspects.add(e.key);
          print('    ${e.value.toString().padLeft(4)}  '
              '(${pct.toStringAsFixed(0).padLeft(2)}%)  '
              '${severity.padRight(9)} ${e.key}'
              '${isSuspect ? '  <-- widespread AND scored serious' : ''}');
        }

        if (suspects.isNotEmpty) {
          failures.add(
              'miscalibrated capability mapping: ${suspects.join(', ')}');
          print('\n    ${suspects.length} capability/-ies are declared by 20%+ of '
              'installed software\n    yet scored as high or critical. A '
              'capability most software has cannot\n    also be a red flag — '
              'check the mapping in desktop_capabilities.dart.');
        }
      }

      // Score them and show the riskiest, which is what the App Scanner does.
      final scored = apps
          .map((a) => (
                app: a,
                risk: PermissionAnalyzer.analyze(a.permissions,
                    isFromTrustedStore: a.isFromTrustedStore),
              ))
          .toList()
        ..sort((x, y) => y.risk.riskScore.compareTo(x.risk.riskScore));

      print('\n  Highest-risk entries:');
      for (final entry in scored.take(verbose ? 15 : 6)) {
        final name = entry.app.appName;
        print('    ${entry.risk.riskScore.toString().padLeft(3)}  '
            '${entry.risk.riskLevel.padRight(8)} '
            '${name.length > 42 ? '${name.substring(0, 39)}...' : name}');
        if (verbose && entry.app.permissions.isNotEmpty) {
          for (final p in entry.app.permissions) {
            print('           · ${p.split('.').last}');
          }
        }
      }

      print('\n  Sample of what was read:');
      for (final a in apps.take(verbose ? 20 : 5)) {
        print('    ${a.appName}');
        print('      version   ${a.versionName.isEmpty ? '—' : a.versionName}');
        print('      source    ${a.installSourceLabel}');
        print('      caps      ${a.permissions.isEmpty ? '—' : a.permissions.map((p) => p.split('.').last).join(', ')}');
      }
    }
  } catch (e, stack) {
    invStopwatch.stop();
    failures.add('Inventory probe threw: $e');
    print('  FAILED    $e');
    if (verbose) print(stack);
  }

  // ── Verdict ──────────────────────────────────────────────────────────────
  _heading('Result');
  if (failures.isEmpty) {
    print('  All probe checks passed on ${Platform.operatingSystem}.');
    exit(0);
  }
  for (final f in failures) {
    print('  FAIL  $f');
  }
  print('\n  ${failures.length} check(s) failed. Re-run with --verbose for '
      'raw detail.');
  exit(1);
}

Future<Map<String, dynamic>> _wifiDetails() {
  if (Platform.isWindows) return const WindowsProbe().getWifiDetails();
  if (Platform.isMacOS) return const MacosProbe().getWifiDetails();
  return const LinuxProbe().getWifiDetails();
}

Future<List<AppInfoModel>> _installedApps() {
  if (Platform.isWindows) return const WindowsProbe().getInstalledApps();
  if (Platform.isMacOS) return const MacosProbe().getInstalledApps();
  return const LinuxProbe().getInstalledApps();
}

void _expect(List<String> failures, String what, bool ok) {
  print('  ${ok ? 'ok  ' : 'FAIL'}      $what');
  if (!ok) failures.add(what);
}

String _maskSsid(String ssid) {
  if (ssid.isEmpty) return '(empty)';
  if (ssid.length <= 2) return '${ssid[0]}*';
  return '${ssid[0]}${'*' * (ssid.length - 2)}${ssid[ssid.length - 1]}'
      '  (${ssid.length} chars, pass --verbose to show)';
}

String _maskMac(String mac) {
  if (mac.isEmpty) return '(empty)';
  final parts = mac.split(RegExp('[:-]'));
  if (parts.length != 6) return mac;
  // Vendor prefix is not identifying; the device half is.
  return '${parts.take(3).join(':')}:**:**:**';
}

void _heading(String title) {
  print('\n$title');
  print('${'─' * title.length}');
}
