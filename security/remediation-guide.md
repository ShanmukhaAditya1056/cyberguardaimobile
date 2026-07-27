# Remediation Guide — CyberGuard AI

Copy-paste fixes in priority order. **Steps 1–4 take about two hours and clear
every High finding.**

Re-run both test suites after each step:

```bash
flutter test                      # 69 Dart tests (33 existing + 36 corpus)
cd automation && npm test         # Appium E2E
```

---

## Step 1 — Stop signing releases with the debug key (MOB-001)

**~30 minutes. Do this first — nothing else about release integrity matters
until it is done.**

Generate a release keystore:

```bash
keytool -genkey -v -keystore ~/cyberguard-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias cyberguard
```

Create `android/key.properties` — **already gitignored, verify before writing**:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=cyberguard
storeFile=/absolute/path/to/cyberguard-release.jks
```

Edit `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile']
                ? file(keystoreProperties['storeFile'])
                : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release   // was: signingConfigs.debug
        }
    }
}
```

**Verify:**

```bash
flutter build apk --release
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
# must NOT show: CN=Android Debug, O=Android, C=US
```

**Back up the keystore somewhere durable.** Losing it means you can never
publish an update to the same Play listing.

---

## Step 2 — Restrict the Safe Browsing API key (MOB-002)

**~15 minutes, all in the browser. Highest value-per-minute fix in this guide.**

1. Get the release SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/cyberguard-release.jks -alias cyberguard | grep SHA1
   ```
2. Google Cloud Console → **APIs & Services → Credentials** → select the key.
3. **Application restrictions** → Android apps → add:
   - Package name: `com.cyberguard.ai`
   - SHA-1 fingerprint: from step 1
4. **API restrictions** → Restrict key → **Safe Browsing API** only.
5. Save.

An extracted key is now useless outside your signed app.

Then move it out of source, so a future contributor cannot commit it:

```dart
// lib/core/config/api_keys.dart
class ApiKeys {
  ApiKeys._();

  /// Injected at build time:
  ///   flutter build apk --release --dart-define=SAFE_BROWSING_KEY=$KEY
  /// Empty at runtime disables the source entirely, which is a safe default.
  static const String googleSafeBrowsing =
      String.fromEnvironment('SAFE_BROWSING_KEY');

  static const String virusTotal =
      String.fromEnvironment('VIRUSTOTAL_KEY');
}
```

**If the current key has ever been shared or pasted anywhere, rotate it now.**

**Verify:**

```bash
strings build/app/outputs/flutter-apk/app-release.apk | grep -c 'AIza'   # expect 0
```

---

## Step 3 — Close the backup extraction path (MOB-005)

**~15 minutes. One attribute; removes the unrooted `adb backup` path to every
storage finding.**

`android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="CyberGuard AI"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:allowBackup="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:usesCleartextTraffic="false"
    android:networkSecurityConfig="@xml/network_security_config">
```

Create `android/app/src/main/res/xml/data_extraction_rules.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="file" path="settings.hive"/>
        <exclude domain="file" path="scan_results.hive"/>
        <exclude domain="file" path="wifi_scans.hive"/>
        <exclude domain="file" path="app_scan_cache.hive"/>
        <exclude domain="file" path="alerts.hive"/>
        <exclude domain="sharedpref" path="."/>
    </cloud-backup>
    <device-transfer>
        <exclude domain="file" path="settings.hive"/>
        <exclude domain="file" path="scan_results.hive"/>
        <exclude domain="file" path="wifi_scans.hive"/>
        <exclude domain="file" path="app_scan_cache.hive"/>
    </device-transfer>
</data-extraction-rules>
```

**Verify:**

```bash
adb backup -f test.ab com.cyberguard.ai
# archive should contain no app data
```

---

## Step 4 — Enable shrinking and obfuscation (MOB-006)

**~1 hour, mostly spent verifying nothing broke.**

`android/app/build.gradle`:

```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                      'proguard-rules.pro'
    }
}
```

Create `android/app/proguard-rules.pro`:

```proguard
# ── Flutter engine ─────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── ML Kit text recognition ────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text** { *; }
-dontwarn com.google.mlkit.**

# ── Platform-channel entry points, reached reflectively ────────
-keep class com.cyberguard.ai.MainActivity { *; }
-keep class com.cyberguard.ai.PhishingGuardService { *; }
-keep class com.cyberguard.ai.SmsReceiver { *; }
-keep class com.cyberguard.ai.BootReceiver { *; }
-keep class com.cyberguard.ai.SmsBus { *; }

# ── Keep annotations used at runtime ───────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
```

Obfuscate the Dart layer too:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

**Keep `build/symbols`.** Without it, release stack traces are unreadable —
archive it alongside each release build.

**Verify:** install the release APK and run the full E2E suite against it. R8
stripping a class the platform channels need is the classic failure here, and
it only shows up at runtime:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
cd automation && npm test
```

---

## Step 5 — Move the HIBP key to secure storage (MOB-003)

**~2 hours. Upgrade `flutter_secure_storage` to 10.x first** so you write the
migration once against the version you will ship.

```bash
flutter pub upgrade --major-versions flutter_secure_storage
```

Create `lib/data/services/secure_key_store.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Credentials belong in the Android Keystore, not in a Hive box.
///
/// `encryptedSharedPreferences: true` routes storage through
/// EncryptedSharedPreferences, which is backed by the hardware keystore on
/// devices that have one.
class SecureKeyStore {
  SecureKeyStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _hibpKey = 'hibp_api_key';

  static Future<void> setHibpKey(String value) =>
      _storage.write(key: _hibpKey, value: value);

  static Future<String> hibpKey() async =>
      (await _storage.read(key: _hibpKey)) ?? '';

  static Future<void> clearHibpKey() => _storage.delete(key: _hibpKey);

  /// One-time move of a key written by an older build. Must run before the
  /// field is dropped from SettingsModel, or existing users silently lose it.
  static Future<void> migrateFromHive(String legacyValue) async {
    if (legacyValue.isEmpty) return;
    if ((await hibpKey()).isNotEmpty) return;
    await setHibpKey(legacyValue);
  }
}
```

Then:

1. Call `SecureKeyStore.migrateFromHive(settings.hibpApiKey)` once during
   `HiveService.init()`.
2. Remove `hibpApiKey` from `SettingsModel` and regenerate the adapter:
   `dart run build_runner build --delete-conflicting-outputs`
3. Update `settings_provider.dart` and `breach_screen.dart:58` to read through
   `SecureKeyStore`.

**Verify:**

```bash
adb shell run-as com.cyberguard.ai cat files/settings.hive | strings | grep -i '<your-key>'
# expect no match
```

Test `TC_SET_KEY_001` already asserts the key is not exposed in the view
hierarchy and will keep guarding this.

---

## Step 6 — Encrypt the Hive boxes (MOB-004)

**~4 hours — the only step that needs a real data migration.**

```dart
// lib/data/services/hive_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Generated once, then held in the Android Keystore. Losing it means losing
  /// the data, so it must never be regenerated on an existing install.
  static Future<List<int>> _encryptionKey() async {
    final existing = await _storage.read(key: 'hive_encryption_key');
    if (existing != null) return base64Url.decode(existing);

    final key = Hive.generateSecureKey();
    await _storage.write(
      key: 'hive_encryption_key',
      value: base64UrlEncode(key),
    );
    return key;
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();

    final cipher = HiveAesCipher(await _encryptionKey());

    await Hive.openBox<ScanResultModel>(
      AppConstants.scanResultsBox, encryptionCipher: cipher);
    await Hive.openBox<AlertModel>(
      AppConstants.alertsBox, encryptionCipher: cipher);
    await Hive.openBox<WifiScanModel>(
      AppConstants.wifiScansBox, encryptionCipher: cipher);
    await Hive.openBox<ScoreEntryModel>(
      AppConstants.scoreHistoryBox, encryptionCipher: cipher);
    await Hive.openBox<SettingsModel>(
      AppConstants.settingsBox, encryptionCipher: cipher);
    await Hive.openBox<AppScanModel>(
      AppConstants.appScanCacheBox, encryptionCipher: cipher);
    await Hive.openBox<String>(
      AppConstants.prefsBox, encryptionCipher: cipher);
  }
}
```

**The migration matters more than the cipher.** Opening an existing plaintext
box with a cipher throws. Ship this sequence, guarded by a one-time flag:

1. Open each box **unencrypted**, read all values into memory.
2. Close and delete the box from disk.
3. Reopen with the cipher and write the values back.
4. Set a `hive_encrypted_v1` flag so it never runs twice.

Test the upgrade path on a device that has real pre-upgrade data. A migration
that silently drops history is worse than the finding it fixes.

---

## Step 7 — Certificate pinning (MOB-007)

**~3 hours. Optional — decide deliberately.**

Pinning is not free: when a provider rotates certificates without warning, a
pinned app breaks in the field and only an app-store update fixes it. Google
and Cloudflare (HIBP) both rotate regularly.

**Always pin at least two keys** — one current, one backup — and keep a
kill-switch that disables pinning if you cannot ship an update fast enough.

Get the current SPKI pin:

```bash
openssl s_client -connect safebrowsing.googleapis.com:443 -servername safebrowsing.googleapis.com < /dev/null 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

Given that `network_security_config.xml` already excludes user-added CAs — which
defeats the realistic interception scenario — accepting this risk with a
documented decision is a legitimate outcome for a project of this scope.

---

## Step 8 — Quick wins

**MOB-011 — real version string (~10 min):**

```dart
// lib/features/settings/view/settings_screen.dart
final info = await PackageInfo.fromPlatform();
_AboutRow(l.settingsAboutVersion, '${info.version}+${info.buildNumber}');
```

**MOB-014 — guarded logging (~1 hour):**

```dart
// lib/core/utils/log.dart
import 'package:flutter/foundation.dart';

void logDebug(String message) {
  if (kDebugMode) debugPrint(message);
}
```

Then in `analysis_options.yaml`:

```yaml
linter:
  rules:
    avoid_print: true
```

**MOB-012 — root detection warning (~2 hours):**

```dart
if (await FlutterJailbreakDetection.jailbroken) {
  showBanner(
    'This device appears to be rooted. Locally stored threat data '
    'cannot be fully protected.',
  );
}
```

Warn, do not block — blocking punishes legitimate power users and is bypassed
trivially anyway.

---

## Step 9 — Play Console declarations (MOB-008, MOB-010)

Required **before publication**, not before release-building:

| Permission | Declaration | Approved use case |
|---|---|---|
| `QUERY_ALL_PACKAGES` | Play Console → App content → Sensitive app permissions | "Device security / antivirus scanner" |
| `READ_SMS` / `RECEIVE_SMS` | Play Console → App content → SMS/Call Log access | "Anti-fraud / anti-spam" |

Both are legitimate, documented use cases for this app. Prepare a short demo
video showing the feature that needs each permission — Play reviewers ask for
it.

---

## Verification checklist

Run before tagging a release:

```bash
# 1. Not debug-signed
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk \
  | grep -q "Android Debug" && echo "FAIL: debug signed" || echo "OK: release signed"

# 2. No API keys in the artifact
strings build/app/outputs/flutter-apk/app-release.apk | grep -c 'AIza'   # expect 0

# 3. Backup disabled
aapt dump badging build/app/outputs/flutter-apk/app-release.apk | grep -i backup

# 4. Obfuscation active
unzip -p build/app/outputs/flutter-apk/app-release.apk classes.dex \
  | strings | grep -c 'com.cyberguard.ai.features'   # expect 0

# 5. Local data not readable
adb shell run-as com.cyberguard.ai cat files/settings.hive | strings | head

# 6. Tests still green
flutter test
cd automation && npm test
```
