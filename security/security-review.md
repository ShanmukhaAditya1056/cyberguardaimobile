# CyberGuard AI — Mobile Application Security Review

**Application:** CyberGuard AI (`com.cyberguard.ai`)
**Version:** 2.0.0+1 (pubspec) — see MOB-011
**Platform:** Flutter 3.41.8 / Android (single platform; no iOS target present)
**Assessment date:** 2026-07-27
**Assessment type:** White-box static review of the full source tree + Android manifest and Gradle configuration
**Standards applied:** OWASP MASVS v2, OWASP Mobile Top 10 (2024), CWE

---

## Scope and method

### What was assessed

The complete application source: 116 Dart files (`lib/`), 4 Kotlin sources
(`android/app/src/main/kotlin/`), the Android manifest, network security
configuration, Gradle build configuration, and the bundled ML model assets.

### Scope correction — there is no backend

The original assessment brief specified a backend security audit: endpoint
inventory, SAST/DAST across controllers and routes, JWT/session handling, RBAC
and IDOR testing, ORM injection analysis, and a 100-VU load test.

**None of that applies to this application.** CyberGuard AI is a fully
on-device Flutter app. It has no server component, no controllers, no routes,
no database server, no ORM, no authentication system, no user accounts and no
session management. Detection runs locally: a rules engine plus a logistic
regression model shipped as JSON in `assets/models/`.

The application makes exactly two categories of outbound request, both to
third-party services it does not own:

| Service | Purpose | Gate |
|---|---|---|
| `safebrowsing.googleapis.com` | URL reputation lookup | API key **and** user-enabled cloud intel (default **off**) |
| `haveibeenpwned.com` / `api.pwnedpasswords.com` | Breach lookup | User-supplied API key; password check uses k-anonymity |

This review therefore assesses what actually exists: the client-side attack
surface. Where a brief item has no counterpart in this application, it is
listed in [Not applicable](#not-applicable-items) with the reason, rather than
being silently dropped or answered with a fabricated finding.

### Testing not performed, and why

**No dynamic load testing was carried out against the live endpoints.** The
only remote endpoints belong to Google and Have I Been Pwned. Directing 100+
concurrent virtual users at either would constitute abuse of third-party
production infrastructure, would breach both providers' acceptable-use terms,
and would result in the project's API credentials being revoked. Equivalent
coverage is provided by `automation/performance/k6-load-test.js`, which drives
the same request/response contracts against a local mock and refuses to run
against a non-localhost host.

---

## Findings summary

| Severity | Count |
|---|---:|
| Critical | 0 |
| High | 3 |
| Medium | 5 |
| Low | 4 |
| Informational | 3 |
| **Total** | **15** |

| ID | Severity | Title | MASVS | CWE |
|---|---|---|---|---|
| MOB-001 | High | Release builds are signed with the debug keystore | MASVS-CODE-1 | CWE-798 |
| MOB-002 | High | Third-party API key compiled into the APK as a string constant | MASVS-STORAGE-1 | CWE-798 |
| MOB-003 | High | User-supplied HIBP API key stored in plaintext, despite a secure-storage dependency being present | MASVS-STORAGE-1 | CWE-312 |
| MOB-004 | Medium | All local Hive databases are unencrypted | MASVS-STORAGE-1 | CWE-312 |
| MOB-005 | Medium | Android backup is enabled by default, exposing unencrypted local data | MASVS-STORAGE-2 | CWE-530 |
| MOB-006 | Medium | Code shrinking and obfuscation disabled in release builds | MASVS-RESILIENCE-3 | CWE-656 |
| MOB-007 | Medium | No certificate pinning on outbound HTTPS | MASVS-NETWORK-2 | CWE-295 |
| MOB-008 | Medium | `QUERY_ALL_PACKAGES` grants a full installed-app inventory | MASVS-PRIVACY-1 | CWE-250 |
| MOB-009 | Low | Exported activity accepts arbitrary `http`/`https` VIEW intents from any app | MASVS-PLATFORM-1 | CWE-926 |
| MOB-010 | Low | SMS read permissions expand the privacy blast radius | MASVS-PRIVACY-1 | CWE-359 |
| MOB-011 | Low | Displayed version string does not match the build version | MASVS-CODE-2 | CWE-1059 |
| MOB-012 | Low | No root, emulator or tamper detection | MASVS-RESILIENCE-1 | CWE-919 |
| MOB-013 | Info | No integrity verification on bundled ML model assets | MASVS-RESILIENCE-4 | CWE-345 |
| MOB-014 | Info | Debug logging present in production code paths | MASVS-STORAGE-3 | CWE-532 |
| MOB-015 | Info | No automated dependency vulnerability scanning configured | MASVS-CODE-3 | CWE-1104 |

---

## Positive findings

These are called out because they are load-bearing and easy to regress:

1. **Cleartext traffic is disabled** (`android:usesCleartextTraffic="false"` plus
   an explicit `network_security_config.xml` with
   `cleartextTrafficPermitted="false"`). User-added CAs are not trusted; only
   the system trust store is.
2. **HIBP password lookups use k-anonymity correctly** — only a 5-character
   SHA-1 prefix leaves the device, and `Add-Padding: true` is set, which
   defeats response-size correlation. This is the reference implementation of
   that API.
3. **Cloud threat intelligence is off by default** and enabling it requires an
   explicit confirmation dialog. With the default posture, no URL ever leaves
   the device. `SafeBrowsingSource.isEnabled` gates on both a configured key
   and the user preference.
4. **The SMS receiver is registered dynamically, not in the manifest**, so it
   is only live while the app runs and sidesteps Android 14 implicit-broadcast
   restrictions.
5. **`BootReceiver` checks user opt-in** before starting the foreground
   service, so a fresh install never runs a background service unannounced.
6. **`api_keys.dart` is correctly gitignored and was never committed** —
   verified against the full history (`git log --all`, and a `AIza` pattern
   sweep across every reachable commit both returned empty).
7. **The link interceptor deliberately does not set `autoVerify`**, so the app
   never silently becomes the default handler; the user must choose it.

---

## Detailed findings

### MOB-001 — Release builds are signed with the debug keystore

- **Severity:** High
- **MASVS:** MASVS-CODE-1 · **CWE-798** (Use of Hard-coded Credentials)
- **File:** `android/app/build.gradle:33-37`

**Evidence**

```gradle
buildTypes {
    release {
        signingConfig signingConfigs.debug   // <-- release signed with debug key
        minifyEnabled false
        shrinkResources false
    }
}
```

**Description**

The `release` build type is configured to sign with `signingConfigs.debug`. The
Android debug keystore is generated with a well-known password (`android`),
key alias (`androiddebugkey`) and key password (`android`), and on many systems
is shared across every project on the machine.

**Exploitation scenario**

Anyone who obtains the APK can re-sign a modified build with the same publicly
known debug key. Android's update mechanism trusts signature continuity, so a
tampered build is indistinguishable from a genuine one to a sideloading user.
An attacker could inject code that exfiltrates intercepted SMS content — the
app holds `READ_SMS` — and distribute it as a legitimate update.

**Impact**

No supply-chain integrity guarantee whatsoever. Google Play refuses
debug-signed uploads, so the app in this state also cannot be published.

**Remediation**

1. Create a release keystore and keep it out of version control.
2. Read credentials from `android/key.properties` (already gitignored).

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

3. In CI, inject the keystore from an encrypted secret; never commit it.

**Verification**

```bash
flutter build apk --release
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
# The certificate DN must not read "CN=Android Debug, O=Android, C=US"
```

---

### MOB-002 — Third-party API key compiled into the APK as a string constant

- **Severity:** High
- **MASVS:** MASVS-STORAGE-1 · **CWE-798**
- **File:** `lib/core/config/api_keys.dart:12`

**Evidence**

```dart
static const String googleSafeBrowsing = 'AIzaSy****************************REDACTED';
```

The live key value is deliberately redacted in this report because this report
is published to GitHub Pages. The key is present in the working tree.

**Description**

The Google Safe Browsing key is a Dart `const`, so it is embedded verbatim in
the compiled artifact. `const` strings survive into the app snapshot and are
recoverable with `strings` or any APK decompiler. MOB-006 (no obfuscation)
makes this trivial rather than merely feasible.

**Exploitation scenario**

```bash
unzip -o app-release.apk -d extracted/
strings extracted/lib/*/libapp.so | grep -oE 'AIza[0-9A-Za-z_-]{35}'
```

An extracted key can be used to make Safe Browsing requests billed against the
project's quota, exhausting it and disabling the feature for real users.

**Mitigating factors (genuine, and they matter here)**

- The file is gitignored and **was never committed** — confirmed against the
  full history, so this is not a public leak.
- The source comment already directs the developer to apply an Android app
  restriction and an API restriction in Google Cloud Console.

**Impact**

Quota theft and denial of the reputation feature. Not a user-data breach: the
Safe Browsing key grants no access to user information.

**Remediation**

1. **Apply the key restrictions the comment already recommends** — this is the
   single highest-value action. In Google Cloud Console restrict the key to the
   Safe Browsing API *and* to the Android app's package name and release SHA-1
   fingerprint. A restricted key extracted from the APK is unusable elsewhere.
2. Inject at build time rather than committing a placeholder:
   ```bash
   flutter build apk --release --dart-define=SAFE_BROWSING_KEY=$SAFE_BROWSING_KEY
   ```
   ```dart
   static const String googleSafeBrowsing =
       String.fromEnvironment('SAFE_BROWSING_KEY');
   ```
3. Longer term, migrate to the Safe Browsing **Update API**, which keeps a
   local hash-prefix database and never transmits the full URL. The source
   already documents this as the planned path, and it removes both the privacy
   cost and the per-lookup quota pressure.

**Verification**

```bash
strings build/app/outputs/flutter-apk/app-release.apk | grep -c 'AIza'   # expect 0
```

---

### MOB-003 — HIBP API key stored in plaintext despite a secure-storage dependency

- **Severity:** High
- **MASVS:** MASVS-STORAGE-1 · **CWE-312** (Cleartext Storage of Sensitive Information)
- **Files:** `lib/data/models/settings_model.dart:20`,
  `lib/features/settings/provider/settings_provider.dart:35`,
  `lib/data/services/hive_service.dart:52`

**Evidence**

```dart
// settings_model.dart
@HiveField(4)
late String hibpApiKey;          // persisted as a plain string

// hive_service.dart — no encryptionCipher on any box
await Hive.openBox<SettingsModel>(AppConstants.settingsBox);
```

`flutter_secure_storage: ^9.0.0` is declared in `pubspec.yaml` but a
repository-wide search returns **zero** usages:

```bash
$ grep -rn "FlutterSecureStorage" lib/
$ # (no output)
```

**Description**

The user's Have I Been Pwned API key — a paid credential — is written to an
unencrypted Hive box in the app's private data directory. The project already
depends on `flutter_secure_storage`, which wraps the Android Keystore, but
never uses it. The correct tool is present and unused.

**Exploitation scenario**

1. On a rooted device or an emulator:
   `adb shell run-as com.cyberguard.ai cat files/settings.hive` reveals the key
   in cleartext.
2. Combined with MOB-005 (backup enabled), `adb backup` extracts it from an
   **unrooted** device.
3. Any malware with the same UID, or a device-level backup exfiltration,
   recovers the credential.

**Impact**

Theft of a paid third-party credential belonging to the user, chargeable to
their account.

**Remediation**

Move the key to the dependency that is already installed:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _hibpKey = 'hibp_api_key';

  static Future<void> setHibpKey(String value) =>
      _storage.write(key: _hibpKey, value: value);

  static Future<String?> hibpKey() => _storage.read(key: _hibpKey);

  static Future<void> clear() => _storage.delete(key: _hibpKey);
}
```

Then remove `hibpApiKey` from `SettingsModel`, bump the Hive schema, and
migrate any existing stored value on first launch after the update.

**Verification**

```bash
adb shell run-as com.cyberguard.ai cat files/settings.hive | strings | grep -i '<your-key>'
# expect no match after remediation
```

---

### MOB-004 — All local Hive databases are unencrypted

- **Severity:** Medium
- **MASVS:** MASVS-STORAGE-1 · **CWE-312**
- **File:** `lib/data/services/hive_service.dart:48-54`

**Evidence**

```dart
await Hive.openBox<ScanResultModel>(AppConstants.scanResultsBox);
await Hive.openBox<AlertModel>(AppConstants.alertsBox);
await Hive.openBox<WifiScanModel>(AppConstants.wifiScansBox);
await Hive.openBox<ScoreEntryModel>(AppConstants.scoreHistoryBox);
await Hive.openBox<SettingsModel>(AppConstants.settingsBox);
await Hive.openBox<AppScanModel>(AppConstants.appScanCacheBox);
await Hive.openBox<String>(AppConstants.prefsBox);
```

No box is opened with an `encryptionCipher`. Hive supports AES-256 via
`HiveAesCipher` and it is not used anywhere.

**Description**

Seven boxes store data in cleartext. Their contents are more sensitive than a
generic cache:

| Box | Contents | Sensitivity |
|---|---|---|
| `scanResultsBox` | Every URL the user scanned | Browsing history |
| `alertsBox` | Threat alerts, truncated URLs | Browsing history |
| `wifiScansBox` | SSID/BSSID of networks joined | Location history — a BSSID resolves to a physical address via public geolocation databases |
| `scoreHistoryBox` | Security posture over time | Behavioural profile |
| `appScanCacheBox` | Full installed-app inventory | Device fingerprint; reveals banking, dating, health apps |
| `settingsBox` | Includes the HIBP API key | Credential (see MOB-003) |

The Wi-Fi and installed-app data are the concerning ones. A BSSID list is
effectively a location trail, and an installed-app inventory is a strong
device fingerprint that can reveal medical or financial circumstances.

**Impact**

Physical device compromise, a rooted device, or backup extraction yields a
browsing history, a location trail and a complete app inventory in cleartext.

**Remediation**

```dart
// Key generated once, stored in the Android Keystore via flutter_secure_storage.
Future<List<int>> _encryptionKey() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final existing = await storage.read(key: 'hive_key');
  if (existing != null) return base64Url.decode(existing);
  final key = Hive.generateSecureKey();
  await storage.write(key: 'hive_key', value: base64UrlEncode(key));
  return key;
}

final cipher = HiveAesCipher(await _encryptionKey());
await Hive.openBox<ScanResultModel>(
  AppConstants.scanResultsBox,
  encryptionCipher: cipher,
);
```

Apply the cipher to every box. Ship a one-time migration that reads the
existing plaintext boxes, rewrites them encrypted, and deletes the originals —
without it, existing users lose their history on upgrade.

---

### MOB-005 — Android backup enabled by default

- **Severity:** Medium
- **MASVS:** MASVS-STORAGE-2 · **CWE-530** (Exposure of Backup File)
- **File:** `android/app/src/main/AndroidManifest.xml` (`<application>`)

**Evidence**

The `<application>` element declares no `android:allowBackup`,
`android:fullBackupContent` or `android:dataExtractionRules`. Android defaults
`allowBackup` to **true**.

**Description**

With backup enabled and no extraction rules, the entire app data directory —
every unencrypted Hive box from MOB-004 and the plaintext HIBP key from
MOB-003 — is eligible for Android Auto Backup to the user's Google Drive and
for local `adb backup` extraction.

**Exploitation scenario**

On a device with USB debugging enabled and no root:

```bash
adb backup -f cg.ab com.cyberguard.ai
dd if=cg.ab bs=1 skip=24 | zlib-flate -uncompress | tar xvf -
strings apps/com.cyberguard.ai/f/settings.hive
```

This yields the API key, scan history, Wi-Fi BSSID list and installed-app
inventory from an unrooted device.

**Impact**

Turns a local-storage weakness into a remotely exploitable one via cloud
backup, and a physically exploitable one via `adb`.

**Remediation**

For a security application, opting out entirely is defensible:

```xml
<application
    android:allowBackup="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    ...>
```

If backup is desired for usability, exclude the sensitive stores. Create
`android/app/src/main/res/xml/data_extraction_rules.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="file" path="settings.hive"/>
        <exclude domain="file" path="scan_results.hive"/>
        <exclude domain="file" path="wifi_scans.hive"/>
        <exclude domain="file" path="app_scan_cache.hive"/>
        <exclude domain="sharedpref" path="."/>
    </cloud-backup>
    <device-transfer>
        <exclude domain="file" path="settings.hive"/>
    </device-transfer>
</data-extraction-rules>
```

---

### MOB-006 — Code shrinking and obfuscation disabled in release builds

- **Severity:** Medium
- **MASVS:** MASVS-RESILIENCE-3 · **CWE-656** (Reliance on Security Through Obscurity — inverted: none is applied)
- **File:** `android/app/build.gradle:35-36`

**Evidence**

```gradle
release {
    minifyEnabled false
    shrinkResources false
}
```

**Description**

R8 is disabled, so the release APK retains full class names, method names and
resource names. Flutter's Dart code is separately unobfuscated unless
`--obfuscate --split-debug-info` is passed, which the build does not do.

This is what turns MOB-002 from theoretical to trivial: extracting the API key
is a single `strings` invocation.

**Impact**

Reverse engineering is effortless. Detection logic, the rules engine's
thresholds and the whitelist are all readable, which lets an attacker craft
URLs that score just under the 35-point phishing threshold.

**Remediation**

```gradle
release {
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```

Add `android/app/proguard-rules.pro`:

```proguard
# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit text recognition
-keep class com.google.mlkit.** { *; }

# App's own platform-channel entry points, reached reflectively from Dart
-keep class com.cyberguard.ai.MainActivity { *; }
-keep class com.cyberguard.ai.PhishingGuardService { *; }
-keep class com.cyberguard.ai.SmsReceiver { *; }
-keep class com.cyberguard.ai.BootReceiver { *; }
```

And obfuscate the Dart layer:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

Retain `build/symbols` — without it, release crash reports are unreadable.

---

### MOB-007 — No certificate pinning on outbound HTTPS

- **Severity:** Medium
- **MASVS:** MASVS-NETWORK-2 · **CWE-295** (Improper Certificate Validation)
- **Files:** `lib/data/services/threat_intel/safe_browsing_source.dart:29-34`,
  `lib/data/services/hibp_service.dart`

**Evidence**

```dart
_dio = dio ?? Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
```

No `badCertificateCallback`, no pinned fingerprints, no custom
`HttpClientAdapter`.

**Description**

Connections rely solely on the platform trust store. The
`network_security_config.xml` correctly limits trust to system CAs — user-added
certificates are **not** trusted, which already defeats casual Burp/mitmproxy
interception on non-rooted devices. That is a meaningful control and is why
this is Medium rather than High.

What remains unmitigated: a compromised or coerced public CA, or an attacker
with system-store write access on a rooted device.

**Impact**

An attacker positioned to obtain a certificate from any trusted CA could
intercept HIBP requests, which carry the user's API key in the `hibp-api-key`
header, and could tamper with Safe Browsing verdicts to make a malicious URL
appear clean.

**Remediation**

Pin the SPKI hashes of the leaf or intermediate certificates:

```dart
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/io.dart';

const _pinnedSpki = <String>{
  'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // primary
  'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // backup — required
};

Dio buildPinnedDio() {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => false;
    return client;
  };
  dio.interceptors.add(InterceptorsWrapper(
    onResponse: (response, handler) {
      final cert = response.requestOptions.extra['certificate'] as X509Certificate?;
      if (cert != null) {
        final spki = base64.encode(sha256.convert(cert.der).bytes);
        if (!_pinnedSpki.contains('sha256/$spki')) {
          return handler.reject(DioException(
            requestOptions: response.requestOptions,
            message: 'Certificate pin mismatch',
          ));
        }
      }
      handler.next(response);
    },
  ));
  return dio;
}
```

**Always pin a backup key.** A single pin becomes an outage the day the
provider rotates. Both `SafeBrowsingSource` and `HibpService` already accept an
injected `Dio`, so this change is contained.

---

### MOB-008 — `QUERY_ALL_PACKAGES` grants a full installed-app inventory

- **Severity:** Medium
- **MASVS:** MASVS-PRIVACY-1 · **CWE-250** (Execution with Unnecessary Privileges)
- **File:** `android/app/src/main/AndroidManifest.xml`

**Evidence**

```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"
    tools:ignore="QueryAllPackagesPermission"/>
```

**Description**

`QUERY_ALL_PACKAGES` is one of Google Play's *restricted* permissions. It
requires a submitted declaration and an approved use case, and Play rejects
apps that use it without one.

The functional need is genuine — the malware scanner must enumerate installed
packages to score them. But the resulting inventory is a strong device
fingerprint that can reveal a user's bank, health conditions, dating activity
and political affiliation, and it is stored unencrypted (MOB-004).

**Impact**

Play policy rejection risk, plus a high-value privacy dataset held in
cleartext on-device.

**Remediation**

1. Submit the Play Console permission declaration; "malware/security scanner"
   is an approved use case, so this is a paperwork step, not a redesign.
2. Prefer a `<queries>` element if the full inventory is not strictly needed.
3. Encrypt `appScanCacheBox` (MOB-004).
4. Store only a salted hash of each package name where the scanner only needs
   identity comparison rather than the readable name.

---

### MOB-009 — Exported activity accepts arbitrary `http`/`https` VIEW intents

- **Severity:** Low
- **MASVS:** MASVS-PLATFORM-1 · **CWE-926** (Improper Export of Android Components)
- **File:** `android/app/src/main/AndroidManifest.xml`

**Evidence**

```xml
<activity android:name=".MainActivity" android:exported="true" ...>
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="http"/>
        <data android:scheme="https"/>
    </intent-filter>
    <intent-filter>
        <action android:name="android.intent.action.SEND"/>
        <data android:mimeType="text/plain"/>
    </intent-filter>
</activity>
```

**Description**

Any installed app, and any web page, can launch `MainActivity` with an
arbitrary URL or text payload. This is inherent to the Smart Link Interceptor
feature — the app must be launchable from the "Open with" chooser — so it is
by design.

The residual risk is input handling: the received URL flows into
`UrlExtractor.normalize` and the interceptor screen. The corresponding
malformed-input tests (`TC_PHISH_M001`–`M014`) exercise this path and confirm
no crash on malformed, oversized or payload-shaped input.

**Impact**

Low. A malicious app can spam the interceptor screen (local UI nuisance) but
cannot reach privileged functionality — the activity performs no
security-sensitive action based on the intent alone.

**Remediation**

1. Continue to validate and length-cap incoming URIs before processing.
2. Do not add `android:autoVerify="true"` — the current choice to require
   explicit user selection is correct and should be preserved.
3. Consider rate-limiting interceptor screen launches to blunt UI spam.

---

### MOB-010 — SMS read permissions expand the privacy blast radius

- **Severity:** Low
- **MASVS:** MASVS-PRIVACY-1 · **CWE-359** (Exposure of Private Information)
- **File:** `android/app/src/main/AndroidManifest.xml`

**Evidence**

```xml
<uses-permission android:name="android.permission.READ_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
```

**Description**

SMS permissions are Play-restricted and grant access to the full message
store — including banking OTPs, 2FA codes and private correspondence. The
functional justification (scanning SMS for phishing) is legitimate and is a
core product feature.

**Mitigating factors**

- `SmsReceiver` is registered dynamically rather than in the manifest, so it is
  only active while the app is running.
- Scanning is performed on-device in Kotlin; message bodies are not transmitted.
- `PhishingGuardService` is `android:exported="false"`.

**Impact**

Low as implemented, but it raises the consequence of any other compromise: an
attacker who achieves code execution in this app inherits SMS access, which is
sufficient to defeat SMS-based 2FA.

**Remediation**

1. Submit the Play SMS permission declaration ("anti-fraud/security" is an
   approved use case).
2. Never persist message bodies; scan and discard. Confirm no `AlertModel`
   description retains full SMS text.
3. Redact OTP-shaped digit sequences before any body reaches a log or alert.

---

### MOB-011 — Displayed version string does not match the build version

- **Severity:** Low
- **MASVS:** MASVS-CODE-2 · **CWE-1059** (Insufficient Technical Documentation)
- **Files:** `lib/features/settings/view/settings_screen.dart:523`, `pubspec.yaml:3`

**Evidence**

```dart
_AboutRow(l.settingsAboutVersion, '1.0.0'),   // hardcoded literal
```

```yaml
version: 2.0.0+1                               # pubspec
```

**Description**

The About screen reports 1.0.0 while the build is 2.0.0+1. `package_info_plus`
is already a dependency and exposes the real value.

**Impact**

Low security impact, real operational impact: a user reporting a bug quotes the
wrong version, and incident response cannot tell which build is affected.

**Remediation**

```dart
final info = await PackageInfo.fromPlatform();
_AboutRow(l.settingsAboutVersion, '${info.version}+${info.buildNumber}');
```

---

### MOB-012 — No root, emulator or tamper detection

- **Severity:** Low
- **MASVS:** MASVS-RESILIENCE-1 · **CWE-919**
- **Scope:** Application-wide

**Description**

The app performs no integrity self-checks. For a security product this is a
notable gap: users most in need of protection are also those most likely to be
running a compromised device.

**Impact**

On a rooted device all storage findings (MOB-003, MOB-004) become trivially
exploitable, and the app cannot warn the user.

**Remediation**

Detect and **warn** rather than block — blocking punishes legitimate power
users and is bypassed easily anyway:

```dart
// package: freerasp / flutter_jailbreak_detection
if (await FlutterJailbreakDetection.jailbroken) {
  showBanner('This device appears to be rooted. Local threat data '
             'cannot be fully protected.');
}
```

Pair with Play Integrity API for server-verifiable attestation if a backend is
ever added.

---

### MOB-013 — No integrity verification on bundled ML model assets

- **Severity:** Informational
- **MASVS:** MASVS-RESILIENCE-4 · **CWE-345** (Insufficient Verification of Data Authenticity)
- **Files:** `assets/models/*.json`, `lib/data/services/phishing_ml_service.dart:48`

**Evidence**

```dart
final raw = await rootBundle.loadString(assetPath);
final json = jsonDecode(raw) as Map<String, dynamic>;
// weights are used directly; no checksum or signature check
```

**Description**

Model weights are loaded from the asset bundle with no integrity check.
Assets inside a signed APK are protected by the APK signature — which is
exactly why MOB-001 matters. With release builds signed by a public debug key,
an attacker can repackage the APK with `phishing_weights.json` altered so the
classifier returns "safe" for their phishing domains, and the app has no way to
notice.

**Impact**

Only reachable through APK tampering. Fixing MOB-001 largely closes it.

**Remediation**

Embed an expected SHA-256 for each model and verify on load:

```dart
const _expectedSha256 = 'a3f5...';
final bytes = await rootBundle.load(assetPath);
final digest = sha256.convert(bytes.buffer.asUint8List()).toString();
if (digest != _expectedSha256) {
  _loadError = 'Model integrity check failed';
  return;                       // fall back to the rules engine
}
```

---

### MOB-014 — Debug logging present in production code paths

- **Severity:** Informational
- **MASVS:** MASVS-STORAGE-3 · **CWE-532** (Insertion of Sensitive Information into Log File)

**Evidence**

10 `print`/`debugPrint` call sites across `lib/`.

**Description**

`print` output reaches logcat in release builds. On Android 11+ apps cannot
read each other's logs, so the exposure is limited to physical/ADB access —
hence Informational rather than a finding with real reach. The risk is that a
future edit adds a URL or SMS body to one of these statements.

**Remediation**

Route logging through a level-aware wrapper that compiles out in release:

```dart
void logDebug(String message) {
  if (kDebugMode) debugPrint(message);
}
```

Add a lint rule (`avoid_print: true` in `analysis_options.yaml`) so this cannot
regress.

---

### MOB-015 — No automated dependency vulnerability scanning

- **Severity:** Informational
- **MASVS:** MASVS-CODE-3 · **CWE-1104** (Use of Unmaintained Third Party Components)

**Description**

The repository contains no `.github/workflows/` at the time of assessment and
no dependency scanning. `pubspec.yaml` declares 40+ direct dependencies,
several of which reach sensitive surfaces (`mobile_scanner` for camera,
`google_mlkit_text_recognition` for OCR, `flutter_secure_storage`,
`permission_handler`).

**Remediation**

Adopt the workflow supplied with this assessment
(`.github/workflows/security-review.yml`), which runs `flutter pub outdated`,
Gitleaks, Trivy and Semgrep on every push. See `security/dependency-report.md`
for the current dependency posture.

---

## Not applicable items

The assessment brief specified backend testing that has no counterpart in this
application. These are recorded rather than omitted, so the coverage claim is
auditable:

| Brief item | Why it does not apply |
|---|---|
| Endpoint inventory (`endpoint-inventory.xlsx`) | No server; no routes or controllers exist. The two outbound third-party calls are documented in [Scope](#scope-and-method). |
| SQL / NoSQL injection (60 test cases) | No SQL or NoSQL database. Hive is a local key-value store with a typed Dart API and no query language to inject into. |
| Authentication testing (30 cases) | The app has no login, no accounts and no credentials of its own. |
| Authorization / RBAC / IDOR (40 cases) | No server-side objects, no roles, no multi-tenancy. There is exactly one local user. |
| JWT security (20 cases) | No tokens are issued, parsed or validated anywhere in the codebase. |
| Session management (20 cases) | No sessions exist. |
| Server-side rate limiting (15 cases) | No server to rate-limit. Client-side throttling of third-party calls is a separate concern and is partially handled by `ThreatCache`. |
| SSRF / XXE / template injection | No server-side request construction from user input; no XML parsing; no template engine. |
| Mass assignment | No request-body deserialisation into persisted server models. |
| CORS / security headers | No HTTP responses are served by this application. |
| 100-VU baseline load test against production | Targets would be Google and HIBP — third-party services that must not be load-tested. Covered instead against a local mock; see [Testing not performed](#testing-not-performed-and-why). |

Client-side analogues of the injection and validation categories **were**
tested — `TC_PHISH_M001`–`M014` (malformed input) and `TC_PHISH_I001`–`I008`
(payload-shaped input) confirm the scanner treats all input as opaque text.

---

## Risk rating

**Overall security posture: Moderate.**

The application's *design* is notably privacy-conscious — correct k-anonymity,
default-off cloud lookups with an explicit consent gate, no cleartext traffic,
dynamically-registered SMS receiver, on-device inference. These are choices a
careless implementation would get wrong, and they were got right.

The weaknesses are concentrated in **build configuration and data-at-rest**,
not in application logic. MOB-001 (debug signing), MOB-002 (embedded key) and
MOB-006 (no obfuscation) are all one-line Gradle or build-flag changes.
MOB-003 and MOB-004 are contained refactors made easier by the fact that the
right dependency is already installed.

For a student project, the gap between the security *thinking* on display and
the security *configuration* is the headline: the hard parts were done well and
the mechanical parts were left at their defaults.

**Security score: 68/100**

| Category | Score | Note |
|---|---:|---|
| Data storage | 11/25 | Unencrypted boxes, plaintext credential, backup enabled |
| Cryptography | 16/20 | Correct k-anonymity and SHA-1 prefixing; no storage encryption |
| Network security | 15/20 | Cleartext disabled, system-CA-only trust; no pinning |
| Platform interaction | 13/15 | Well-reasoned exports; broad but justified permissions |
| Code quality & build | 8/20 | Debug signing and no obfuscation dominate |

---

## Remediation priority

| Order | Finding | Effort | Rationale |
|---|---|---|---|
| 1 | MOB-001 | ~30 min | Blocks any legitimate release; enables MOB-013 |
| 2 | MOB-002 (key restrictions) | ~15 min | Console-only change; neutralises key extraction |
| 3 | MOB-005 | ~15 min | Single manifest attribute; closes remote reach of MOB-003/4 |
| 4 | MOB-006 | ~1 hour | Gradle + ProGuard rules; makes extraction non-trivial |
| 5 | MOB-003 | ~2 hours | Dependency already present |
| 6 | MOB-004 | ~4 hours | Needs a data migration for existing users |
| 7 | MOB-007 | ~3 hours | Pin with a backup key, or accept the risk explicitly |
| 8 | MOB-008 / MOB-010 | — | Play Console declarations before publishing |

Items 1–4 total roughly two hours and remove all three High findings.
