# Platform support

CyberGuard AI runs on six platforms from one codebase, plus a separate MERN
stack for the browser. This document is the honest account of what works where,
why the gaps exist, and how to build each target.

- [Feature matrix](#feature-matrix)
- [Why the gaps exist](#why-the-gaps-exist)
- [How the platform layer works](#how-the-platform-layer-works)
- [Building each platform](#building-each-platform)
- [Known limitations](#known-limitations)

---

## Feature matrix

| Module | Android | iOS | Windows | macOS | Linux | Web (MERN) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| Phishing URL scanner | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Phishing in pasted text | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Live SMS guard | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| QR scanner (camera) | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ |
| QR scanner (from image) | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ |
| Installed-app scanner | ✅ | ❌ | ✅ | ✅ | ✅ | ⚠️ manual |
| Wi-Fi analysis (full) | ✅ | ❌ | ✅ | ✅ | ✅ | ⚠️ manual |
| Wi-Fi reachability only | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Breach monitor | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Screenshot scanner | ✅ | ✅ | ❌ | ❌ | ❌ | ⚠️ paste text |
| Smart Link Interceptor | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Threat fusion / risk / arbitration | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Local notifications | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Unified score + history | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| PDF / CSV export | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Firebase sign-in | ✅ | ✅ | ❌ | ✅ | ❌ | n/a (JWT) |

✅ full · ⚠️ works from user-supplied input · ❌ not available

Nothing marked ❌ is a stub or a placeholder screen. A module the host cannot
run is dropped from the dashboard, and its route resolves to a screen that says
which OS restriction is responsible and where the feature does work.

---

## Why the gaps exist

Every gap below is an OS restriction, not unfinished work.

**Live SMS guard — Android only.** iOS has no public API for reading messages
at all. What it does offer is an SMS *filter* extension, which is a separate
app target that never sees message content the host app could exfiltrate —
a real port rather than a flag flip, and out of scope here. Desktops have no
inbox.

**Installed-app scanner — not on iOS.** iOS deliberately does not let one app
learn what else is installed. `canOpenURL:` can test a hardcoded scheme list,
which Apple rejects apps for using as an enumeration workaround, and it would
return a list of guesses rather than an inventory.

**Wi-Fi identity — not on iOS.** SSID and BSSID require the
`com.apple.developer.networking.wifi-info` entitlement, which needs an approved
request against a paid account. Without it `CNCopyCurrentNetworkInfo` returns
nil. The module still runs its reachability half (DNS health, latency,
captive-portal probe) and says explicitly that it could not see the network,
capping the trust score below the "low risk" band so an unverifiable network is
never presented as clean.

**Screenshot OCR — mobile only.** Google ships ML Kit for Android and iOS and
nothing else. The alternative would be uploading screenshots to a cloud OCR
service — and a screenshot is the single input most likely to contain a bank
balance or an OTP, so that trade is not available to this app.

**QR scanning — no Windows or Linux.** `mobile_scanner` has no implementation
there, for either the camera or the image decoder. Those platforms point the
user at the Phishing scanner instead, which runs the same engine on the link.

**Smart Link Interceptor — Android only.** Vetting a tapped link before the
browser sees it requires holding the system default-browser role. Only Android
hands that to a third-party app.

**Notifications — not on Windows.** `flutter_local_notifications` added Windows
support in a later major version than the one this app pins. Alerts are still
recorded and still visible in the Alerts screen; only the OS-level toast is
missing.

**Firebase sign-in — not on Windows or Linux.** `firebase_core` resolves an
implementation there, but only Android and Apple read credentials from a
bundled config file. Windows and Linux need explicit `FirebaseOptions` from the
FlutterFire CLI, which this repo does not carry. `Firebase.initializeApp()`
throws, `AuthService` reports itself unconfigured, and the route guard stands
down — exactly as it does on a checkout with no Firebase project. **Desktop
builds therefore run without a sign-in gate.**

---

## How the platform layer works

Two files carry the whole design.

**`lib/core/platform/app_platform.dart`** declares what the current host can
do, as compile-time facts answered synchronously so widgets can branch during
`build`. Screens and the router check `AppPlatform.canReadSms`,
`canEnumerateInstalledApps`, `canRunOcr` and friends rather than testing
`Platform.isAndroid` inline — so adding a platform means editing one file, not
hunting for scattered OS checks.

**`lib/data/services/device/device_probe.dart`** is the single interface for
everything the app learns from the OS. Four implementations sit behind it:

| Probe | How it answers |
|---|---|
| `AndroidDeviceProbe` | One `MethodChannel` into `MainActivity.kt` — the original implementation, unchanged |
| `DesktopDeviceProbe` | Shells out to tools the OS already ships, per platform |
| `IosDeviceProbe` | The narrow set the sandbox permits, in pure Dart |
| `_NullDeviceProbe` | Backstop for an unrecognised host |

`PlatformChannelService` keeps its original public API and picks the right
probe, so every repository and provider that called it still does, unchanged.

### Desktop scanning, without native plugins

No C++ or Swift was written. Each desktop answers the same questions using
tools it already has:

| | Windows | macOS | Linux |
|---|---|---|---|
| **Inventory** | `Uninstall` registry hives + `Get-AppxPackage` | `system_profiler SPApplicationsDataType` | `flatpak list`, `snap list`, XDG desktop entries |
| **Permissions** | MSIX manifest capabilities | `NS…UsageDescription` keys, read with one `grep` over every bundle's Info.plist | Flatpak sandbox metadata, connected Snap plugs |
| **Provenance** | Authenticode signature + install location | `obtained_from` (App Store / notarised / unknown) | Repository origin, or none for a loose `.desktop` file |
| **Persistence** | `Win32_StartupCommand`, LocalSystem services | LaunchAgents, LaunchDaemons, login items | XDG autostart, enabled systemd units |
| **Wi-Fi** | `netsh wlan show interfaces` + `Get-NetAdapter` | `system_profiler SPAirPortDataType` | `nmcli`, falling back to `iw` |

Every one of these calls goes through `HostShell`, which passes arguments as a
list with `runInShell: false` (so nothing a user types can be re-parsed as
shell syntax), bounds every call with a timeout, and treats a missing binary as
a normal outcome rather than an error.

### Speaking one risk vocabulary

`DesktopCapabilities` translates each OS's permission model into the
`android.permission.*` strings the risk engine was built and trained on. A
macOS `NSMicrophoneUsageDescription` and an Android `RECORD_AUDIO` are the same
declaration made to two different app stores; an MSIX `webcam` capability is
`CAMERA`; Snap's `classic` confinement means "no sandbox at all", which maps to
device-admin authority.

Calibration matters as much as correspondence. MSIX's `runFullTrust` also means
"outside the sandbox", but on Windows it is how a packaged Win32 app runs —
present in 62% of installed packages — so mapping it to a permission that is
rare and alarming on Android flagged a third of an ordinary machine. It is
deliberately unmapped; `allowElevation`, which is genuinely uncommon, is not.

The alternative — a second risk engine per OS — would mean four copies of
`PermissionAnalyzer` and a feature extractor that never saw the training data
the Android one was fitted on. Mappings that have no honest equivalent are
dropped rather than approximated; `test/desktop_capabilities_test.dart` pins
that nothing invents authority an app was never granted.

### Locale-robust parsing

`netsh` translates every one of its labels on a non-English Windows, so
`WifiParsing` identifies values by *shape* rather than by label text: a MAC
address is a BSSID whatever the label says, `72%` is a signal quality,
`WPA2-Personal` is a cipher. The app ships in four languages, and a Wi-Fi
module that silently reported "Unknown" on a Hindi install would be worse than
useless. Pinned by `test/wifi_parsing_test.dart`.

One rule holds throughout: **an unrecognised security mode is assumed
encrypted.** Telling someone on WPA3 that their network is open, because their
OS phrased the mode unexpectedly, is how a security tool teaches people to
ignore it.

### Verifying a probe against real hardware

```bash
dart run tool/probe_report.dart          # add --verbose for full detail
```

Runs the probe for whichever desktop it is executed on and reports what it
found, with pass/fail checks on each field. It needs only the **plain Dart
VM** — the probes carry no Flutter imports — so it works on a machine that
cannot yet build the app (no Visual Studio, no Xcode). SSIDs and BSSIDs are
masked unless `--verbose` is passed, since this output tends to end up in bug
reports.

This is not a substitute for the unit tests; it is the step that catches what
unit tests structurally cannot. Parsers pinned against captured samples only
prove the samples were transcribed correctly. Running against 161 real
installed programs found three defects that all the unit tests had passed:

| Defect | Symptom | Fix |
|---|---|---|
| `runFullTrust` mapped to `BIND_DEVICE_ADMIN` | 37% of an ordinary machine flagged with device-admin rights — the capability is present in 62% of MSIX packages, including Chrome and Teams | Dropped from the mapping; `allowElevation` (genuinely rare) kept |
| Blank `InstallLocation` treated as sideloaded | 38 of 72 registry entries omit it, so more than half the inventory was marked untrusted and given `REQUEST_INSTALL_PACKAGES` | Absence is unknown, not incriminating: falls back to publisher, asserts nothing about location |
| Android installer ids reaching the UI | 89 programs labelled "Google Play Store" on a Windows machine | `AppInfoModel.sourceLabel` carries a host-written label; the shared trust signal still rides on `installerPackage` |

After the fixes: `BIND_DEVICE_ADMIN` 37% → 6%, `REQUEST_INSTALL_PACKAGES`
25% → 9%, and the only two untrusted programs were genuinely unsigned binaries
in AppData. Each is pinned by a regression test in
`test/desktop_capabilities_test.dart`.

**The macOS and Linux probes have not had this treatment on real hardware
yet.** Run the tool on each and expect to find comparable issues — the Windows
parsers looked correct too.

### Continuous integration

`.github/workflows/cross-platform.yml` covers what one developer machine
cannot:

| Job | Runner | What it proves |
|---|---|---|
| `analyze` | Linux | `flutter analyze` clean, full unit suite passes |
| `web` | Linux + Mongo service | Server suite, the e2e harness, and the client build |
| `build` | one per platform | Android, Linux, Windows, macOS and iOS all compile |
| `probe` | Linux, Windows, macOS | Runs `probe_report.dart` on each real OS |

The `build` matrix is `fail-fast: false` so one broken target does not hide the
state of the other four. The `probe` job is `continue-on-error` — a CI runner
has no Wi-Fi adapter and an arbitrary software inventory, so its value is the
logged output, which catches parser breakage when a runner image updates the OS
tools underneath us.

This is also the practical way to build the platforms you have no machine for:
push a branch and read the matrix.

---

## Building each platform

All six share `flutter pub get` first.

### Android

```bash
flutter build apk --release          # or: flutter run
```

Unchanged. See the main [README](../README.md).

### iOS

Requires macOS with Xcode 15+.

```bash
cd ios && pod install && cd ..
flutter build ios --release
```

- Deployment target is **15.5**, set in both the Xcode project and the Podfile.
  ML Kit's pod requires it; the two must agree or CocoaPods warns on every pod.
- Bundle id is `com.cyberguard.ai`, matching the Android `applicationId`, so
  one Firebase project can serve both.
- Camera and photo-library usage strings are in `ios/Runner/Info.plist`. Apple
  rejects builds whose wording does not name the concrete use.
- For sign-in, drop `GoogleService-Info.plist` into `ios/Runner/`. Without it
  the app builds and runs with auth unconfigured.

### macOS

```bash
flutter build macos --release
```

**App Sandbox is off**, in both `Release.entitlements` and
`DebugProfile.entitlements`. The sandbox forbids a process from exec'ing
another binary, and the App Scanner is built entirely on that — under the
sandbox both headline modules on this platform would be permanently empty.

The cost is that this build cannot ship through the Mac App Store. It is
distributed directly instead, signed with a Developer ID and notarised — the
same route every macOS security tool takes, for the same reason. Hardened
Runtime stays on, so the binary is still checked at launch.

### Windows

```bash
flutter build windows --release
```

Two prerequisites, both needing administrator rights:

1. **Developer Mode**, which Flutter needs to symlink plugins —
   `start ms-settings:developers`. Without it the build stops with "Building
   with plugins requires symlink support".
2. **Visual Studio** with the **"Desktop development with C++"** workload,
   including all default components. Without it: "Unable to find suitable
   Visual Studio toolchain." The Build Tools SKU is enough; the full IDE is
   not required.

Confirm both with `flutter doctor`.

### Linux

```bash
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev \
                 libsecret-1-dev libjsoncpp-dev
flutter build linux --release
```

`libsecret-1-dev` is required at build time by `flutter_secure_storage_linux`,
which holds the Hive encryption key.

For the fullest inventory, install NetworkManager (`nmcli`) for Wi-Fi and have
`flatpak` / `snap` present. Each is optional — the probe degrades to what is
available rather than failing.

### Web (MERN)

A separate stack, not Flutter web. See [`web/README.md`](../web/README.md).

```bash
cd web
npm install
cp server/.env.example server/.env    # then set JWT_SECRET
npm run dev                           # API :4000, client :5173
```

> **`web/` is not Flutter's web directory.** Flutter web is deliberately not
> enabled — running `flutter create --platforms=web .` would write
> `web/index.html` into this folder and collide with the MERN app.

---

## Known limitations

**Desktop app icons.** `.ico`/`.icns`/theme icons are in formats Flutter cannot
decode without a native decoder, so the App Scanner falls back to its generated
letter avatar. Inventory data — name, publisher, capabilities, provenance — is
unaffected.

**Desktop uninstall is not automated.** On Android the platform channel hands
the request to the system's own uninstall dialog. There is no desktop
equivalent that does not mean running an installer's uninstall string or `rm
-rf` on a bundle. A security scanner deleting files on a heuristic score is not
a trade this app makes, so "Uninstall" reveals the app in the OS's own manager
instead.

**Windows signature checks are sampled.** `Get-AuthenticodeSignature`
chain-validates each file, which takes tens of seconds across a full Program
Files. Only apps installed *outside* the managed program directories are
checked, capped at 40 — that is where an unsigned binary is actually
informative.

**macOS BSSID may be redacted.** macOS 14 hides it unless the app holds
Location access. The Evil Twin check then degrades to "first seen" rather than
firing a false alarm.

**No dark theme anywhere.** The app ships a light theme only (dark was retired
pending a redesign) and the web client matches. An unreviewed dark mode on a
security tool risks a red "danger" chip landing on a background that makes it
read as calm.
