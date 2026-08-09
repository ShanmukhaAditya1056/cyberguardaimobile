import 'package:flutter_test/flutter_test.dart';

import 'package:cyberguard_ai/core/utils/permission_analyzer.dart';
import 'package:cyberguard_ai/data/models/app_info_model.dart';
import 'package:cyberguard_ai/data/services/device/desktop/desktop_capabilities.dart';
import 'package:cyberguard_ai/data/services/device/desktop/macos_probe.dart';
import 'package:cyberguard_ai/data/services/device/desktop/windows_probe.dart';

/// The desktop probes translate each OS's permission vocabulary into the
/// `android.permission.*` strings the risk engine was built and trained on.
/// These tests hold that mapping to two rules: it must produce permissions the
/// engine actually recognises (otherwise a desktop app silently scores zero),
/// and it must not invent authority an app was never granted.
void main() {
  group('mapping produces permissions the risk engine recognises', () {
    test('a macOS bundle declaring camera + mic scores above a bare one', () {
      final none = PermissionAnalyzer.analyze(
        DesktopCapabilities.toAndroidPermissions(),
      );
      final invasive = PermissionAnalyzer.analyze(
        DesktopCapabilities.toAndroidPermissions(macosUsageKeys: [
          'NSCameraUsageDescription',
          'NSMicrophoneUsageDescription',
          'NSContactsUsageDescription',
        ]),
      );
      expect(none.riskScore, 0);
      expect(invasive.riskScore, greaterThan(none.riskScore));
      expect(invasive.dangerousPerms, isNotEmpty);
    });

    test('screen recording maps onto the accessibility-abuse signal', () {
      // Screen capture plus synthetic events is what macOS stalkerware asks
      // for, and it is the same abuse Android's accessibility service enables.
      final result = PermissionAnalyzer.analyze(
        DesktopCapabilities.toAndroidPermissions(
          macosUsageKeys: ['NSScreenCaptureUsageDescription'],
        ),
      );
      expect(
        result.shapReasons.any((r) => r.contains('Accessibility')),
        isTrue,
      );
    });

    test('MSIX allowElevation maps onto device-admin authority', () {
      // Requesting administrator rights is rare enough to mean something.
      final result = PermissionAnalyzer.analyze(
        DesktopCapabilities.toAndroidPermissions(
          msixCapabilities: ['allowElevation'],
        ),
      );
      expect(
        result.shapReasons.any((r) => r.contains('Device administrator')),
        isTrue,
      );
    });

    test('MSIX packageManagement maps onto install authority', () {
      expect(
        DesktopCapabilities.toAndroidPermissions(
          msixCapabilities: ['packageManagement'],
        ),
        ['android.permission.REQUEST_INSTALL_PACKAGES'],
      );
    });

    test('Snap classic confinement is treated the same way', () {
      final result = PermissionAnalyzer.analyze(
        DesktopCapabilities.toAndroidPermissions(snapPlugs: ['classic']),
      );
      expect(
        result.dangerousPerms.any((p) => p.permission.contains('DEVICE_ADMIN')),
        isTrue,
      );
    });
  });

  group('calibration against a real Windows inventory', () {
    // Every expectation in this group was derived from running
    // `dart run tool/probe_report.dart` on a real machine (161 installed
    // programs, 89 of them MSIX). The first three assertions each pin a bug
    // that survived unit testing and only showed up against real data.

    test('runFullTrust is not treated as device-admin authority', () {
      // It sounds alarming — "outside the MSIX sandbox" — but on Windows it is
      // simply how a packaged Win32 app runs, present in 62% of installed MSIX
      // packages including Chrome, Edge and Teams. Equating it with
      // BIND_DEVICE_ADMIN (rare on Android, scored critical) flagged 37% of an
      // ordinary machine as having device-admin rights.
      expect(
        DesktopCapabilities.toAndroidPermissions(
          msixCapabilities: ['runFullTrust'],
        ),
        isEmpty,
      );
    });

    test('a typical Store app declares nothing alarming', () {
      // The exact capability set WhatsApp Desktop ships with. Before the
      // runFullTrust fix this produced BIND_DEVICE_ADMIN.
      final permissions = DesktopCapabilities.toAndroidPermissions(
        msixCapabilities: [
          'runFullTrust',
          'internetClient',
          'unvirtualizedResources',
          'appLicensing',
        ],
      );
      expect(permissions, ['android.permission.INTERNET']);

      final result =
          PermissionAnalyzer.analyze(permissions, isFromTrustedStore: true);
      expect(result.riskLevel, 'low');
    });

    test('a blank InstallLocation is unknown, not sideloaded', () {
      // 38 of 72 registry entries on the test machine omitted InstallLocation
      // — MSI installers routinely do not write it. Treating absence as
      // evidence marked more than half the inventory as sideloaded.
      final source = WindowsProbe.classifySource(
        isMsix: false,
        location: '',
        publisher: 'Igor Pavlov',
        signatureValid: null,
      );
      expect(source.trusted, isTrue);
      expect(source.outsideManagedDir, isFalse,
          reason: 'nothing was checked, so nothing may be asserted');
      expect(source.label, contains('Igor Pavlov'));
    });

    test('an unknown location with no publisher is untrusted but not accused',
        () {
      final source = WindowsProbe.classifySource(
        isMsix: false,
        location: '',
        publisher: '',
        signatureValid: null,
      );
      expect(source.trusted, isFalse);
      // Still must not attract REQUEST_INSTALL_PACKAGES: we know nothing about
      // where it lives.
      expect(source.outsideManagedDir, isFalse);
      expect(
        DesktopCapabilities.toAndroidPermissions(
          unsignedBinary: !source.trusted,
          installedOutsideManagedDir: source.outsideManagedDir,
        ),
        isEmpty,
      );
    });

    test('an unsigned binary in AppData is correctly distrusted', () {
      // Matches what the probe found for mongosh, independently confirmed
      // unsigned via Get-AuthenticodeSignature.
      final source = WindowsProbe.classifySource(
        isMsix: false,
        location: r'C:\Users\someone\AppData\Local\Programs\mongosh\',
        publisher: '',
        signatureValid: false,
      );
      expect(source.trusted, isFalse);
      expect(source.outsideManagedDir, isTrue);
      expect(source.label, contains('unsigned'));
      expect(
        DesktopCapabilities.toAndroidPermissions(
          unsignedBinary: !source.trusted,
          installedOutsideManagedDir: source.outsideManagedDir,
        ),
        ['android.permission.REQUEST_INSTALL_PACKAGES'],
      );
    });

    test('a signed binary outside Program Files is trusted', () {
      // Discord and Burp Suite both live in AppData with valid signatures.
      final source = WindowsProbe.classifySource(
        isMsix: false,
        location: r'C:\Users\someone\AppData\Local\Discord',
        publisher: '',
        signatureValid: true,
      );
      expect(source.trusted, isTrue);
      expect(source.label, contains('signature valid'));
    });

    test('the source label never names an Android store on Windows', () {
      // The synthetic installer ids are Android's, so that the shared risk
      // engine keeps working — but they must not reach the user. Before this,
      // 89 programs were labelled "Google Play Store" on a Windows machine.
      final labels = [
        WindowsProbe.classifySource(
            isMsix: true, location: r'C:\X', publisher: 'MS', signatureValid: null),
        WindowsProbe.classifySource(
            isMsix: false, location: '', publisher: 'Acme', signatureValid: null),
        WindowsProbe.classifySource(
            isMsix: false,
            location: r'C:\Program Files\Acme',
            publisher: 'Acme',
            signatureValid: null),
        WindowsProbe.classifySource(
            isMsix: false,
            location: r'C:\Users\x\AppData\Local\Acme',
            publisher: '',
            signatureValid: false),
      ].map((s) => s.label);

      for (final label in labels) {
        expect(label, isNotEmpty);
        expect(label.toLowerCase(), isNot(contains('play store')));
        expect(label.toLowerCase(), isNot(contains('galaxy')));
        expect(label.toLowerCase(), isNot(contains('android')));
      }
    });

    test('sourceLabel overrides the Android-derived label when present', () {
      final app = AppInfoModel(
        packageName: 'x',
        appName: 'X',
        versionName: '1',
        targetSdk: 33,
        minSdk: 23,
        installTime: 0,
        updateTime: 0,
        permissions: const [],
        apkSize: 0,
        installerPackage: DesktopCapabilities.storeInstallerId,
        sourceLabel: 'Microsoft Store (MSIX)',
      );
      expect(app.installSourceLabel, 'Microsoft Store (MSIX)');
      // The trust signal still rides on installerPackage, unchanged.
      expect(app.isFromTrustedStore, isTrue);
    });

    test('an Android app with no sourceLabel keeps the original label', () {
      final app = AppInfoModel(
        packageName: 'com.example',
        appName: 'Example',
        versionName: '1',
        targetSdk: 33,
        minSdk: 23,
        installTime: 0,
        updateTime: 0,
        permissions: const [],
        apkSize: 0,
        installerPackage: 'com.android.vending',
      );
      expect(app.installSourceLabel, 'Google Play Store');
    });
  });

  group('macOS and Linux, audited against the Windows findings', () {
    // The three Windows defects were each a *class* of mistake, not a one-off.
    // These pin the equivalent decisions on the other two desktops. They were
    // written before either probe has been run on real hardware, so they
    // encode the reasoning rather than measured data — see
    // `dart run tool/probe_report.dart`.

    test('macOS: an absent obtained_from is indeterminate, not unsigned', () {
      // system_profiler may simply not report the field. Treating that as
      // "unsigned" is what mislabelled half the Windows inventory.
      final source =
          MacosProbe.classifySource(obtainedFrom: null, path: '/Applications/X.app');
      expect(source.trusted, isFalse, reason: 'no discount without evidence');
      expect(source.outsideManagedDir, isFalse,
          reason: 'nothing was established about where it lives');
      expect(source.label, contains('not reported'));
      // Crucially, must not manufacture an install-software capability.
      expect(
        DesktopCapabilities.toAndroidPermissions(
          unsignedBinary: !source.trusted,
          installedOutsideManagedDir: source.outsideManagedDir,
        ),
        isEmpty,
      );
    });

    test('macOS: a reported "unknown" is different from an absent field', () {
      // Here macOS looked and found no signature — that is real evidence.
      final reported = MacosProbe.classifySource(
        obtainedFrom: 'unknown',
        path: '/Users/x/Downloads/Sketchy.app',
      );
      expect(reported.trusted, isFalse);
      expect(reported.outsideManagedDir, isTrue);
      expect(reported.label, contains('Unsigned'));
    });

    test('macOS: notarised and App Store bundles get the trust discount', () {
      for (final from in ['mac_app_store', 'identified_developer']) {
        final source =
            MacosProbe.classifySource(obtainedFrom: from, path: '/Applications/X.app');
        expect(source.trusted, isTrue, reason: from);
        expect(source.installerId, isNotEmpty, reason: from);
      }
    });

    test('macOS: labels never name an Android store', () {
      for (final from in [
        'mac_app_store',
        'identified_developer',
        'web_download',
        'unknown',
        null,
      ]) {
        final label =
            MacosProbe.classifySource(obtainedFrom: from, path: '/Applications/X.app')
                .label
                .toLowerCase();
        expect(label, isNot(contains('play store')));
        expect(label, isNot(contains('android')));
      }
    });

    test('Linux: a hand-installed app is not accused of installing software', () {
      // A loose .desktop entry has unverifiable provenance — which the empty
      // installer id already expresses. Asserting both capability flags on top
      // attached REQUEST_INSTALL_PACKAGES to every such app.
      final permissions = DesktopCapabilities.toAndroidPermissions(
        unsignedBinary: true,
        installedOutsideManagedDir: false,
      );
      expect(permissions, isEmpty);
    });

    test('Linux: unverifiable provenance still forgoes the trust discount', () {
      final app = AppInfoModel(
        packageName: '/home/u/.local/share/applications/x.desktop',
        appName: 'Hand installed',
        versionName: '',
        targetSdk: DesktopCapabilities.neutralTargetSdk,
        minSdk: DesktopCapabilities.neutralMinSdk,
        installTime: 0,
        updateTime: 0,
        permissions: const [],
        apkSize: 0,
        installerPackage: '',
        sourceLabel: 'Installed by hand (no repository, no sandbox)',
      );
      expect(app.isFromTrustedStore, isFalse);
      expect(app.installSourceLabel, contains('by hand'));
    });
  });

  group('mapping does not invent authority', () {
    test('an unrecognised declaration is dropped, not guessed at', () {
      final permissions = DesktopCapabilities.toAndroidPermissions(
        msixCapabilities: ['someFutureCapability'],
        macosUsageKeys: ['NSMadeUpUsageDescription'],
        snapPlugs: ['not-a-real-plug'],
        flatpakPermissions: ['nonsense=value'],
      );
      expect(permissions, isEmpty);
    });

    test('two declarations meaning the same thing count once', () {
      // Photo library and downloads folder both map to "reads your files".
      // Counting both would inflate the permission score for an app that has
      // one capability, not two.
      final permissions = DesktopCapabilities.toAndroidPermissions(
        macosUsageKeys: [
          'NSPhotoLibraryUsageDescription',
          'NSDownloadsFolderUsageDescription',
          'NSDocumentsFolderUsageDescription',
        ],
      );
      expect(permissions,
          ['android.permission.READ_EXTERNAL_STORAGE']);
    });

    test('a sandboxed binary is not flagged as an installer', () {
      // REQUEST_INSTALL_PACKAGES stands for "can drop other software onto the
      // machine". It should attach only when the app is both unsigned and
      // living outside the managed program directories — either alone is
      // common and benign.
      expect(
        DesktopCapabilities.toAndroidPermissions(
          unsignedBinary: true,
          installedOutsideManagedDir: false,
        ),
        isEmpty,
      );
      expect(
        DesktopCapabilities.toAndroidPermissions(
          unsignedBinary: false,
          installedOutsideManagedDir: true,
        ),
        isEmpty,
      );
      expect(
        DesktopCapabilities.toAndroidPermissions(
          unsignedBinary: true,
          installedOutsideManagedDir: true,
        ),
        ['android.permission.REQUEST_INSTALL_PACKAGES'],
      );
    });

    test('autostart alone is persistence, not privilege', () {
      final permissions =
          DesktopCapabilities.toAndroidPermissions(autostart: true);
      expect(permissions, ['android.permission.RECEIVE_BOOT_COMPLETED']);
    });

    test('a LocalSystem service is both persistence and privilege', () {
      final permissions =
          DesktopCapabilities.toAndroidPermissions(runsSystemService: true);
      expect(permissions, contains('android.permission.BIND_DEVICE_ADMIN'));
      expect(permissions, contains('android.permission.FOREGROUND_SERVICE'));
    });
  });

  group('synthetic installer ids drive the trusted-store discount', () {
    AppInfoModel appWith(String installer) => AppInfoModel(
          packageName: 'test',
          appName: 'Test',
          versionName: '1.0',
          targetSdk: DesktopCapabilities.neutralTargetSdk,
          minSdk: DesktopCapabilities.neutralMinSdk,
          installTime: 0,
          updateTime: 0,
          permissions: const [],
          apkSize: 0,
          installerPackage: installer,
        );

    test('store and managed ids are recognised as trusted', () {
      expect(appWith(DesktopCapabilities.storeInstallerId).isFromTrustedStore,
          isTrue);
      expect(appWith(DesktopCapabilities.managedInstallerId).isFromTrustedStore,
          isTrue);
    });

    test('an empty installer id is untrusted', () {
      expect(appWith('').isFromTrustedStore, isFalse);
    });

    test('trust caps the score for an otherwise alarming app', () {
      final permissions = DesktopCapabilities.toAndroidPermissions(
        macosUsageKeys: [
          'NSCameraUsageDescription',
          'NSMicrophoneUsageDescription',
          'NSContactsUsageDescription',
          'NSScreenCaptureUsageDescription',
          'NSSystemAdministrationUsageDescription',
        ],
        autostart: true,
      );
      final untrusted =
          PermissionAnalyzer.analyze(permissions, isFromTrustedStore: false);
      final trusted =
          PermissionAnalyzer.analyze(permissions, isFromTrustedStore: true);

      expect(untrusted.riskScore, greaterThan(trusted.riskScore));
      // A notarised or store-distributed app must not exceed "medium" on
      // declared permissions alone — otherwise every video-conferencing app on
      // the machine reads as critical.
      expect(trusted.riskLevel, anyOf('low', 'medium'));
    });
  });
}
