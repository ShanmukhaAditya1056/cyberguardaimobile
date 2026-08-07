# Shipping a release

What must be true before this app goes to Play, and what is deliberately not
done yet.

## Blocking — must be done before the first upload

### 1. Release signing key

`android/app/build.gradle` signs release with the **debug** keystore whenever
`android/key.properties` is absent. That fallback keeps CI and local release
builds working, but it is not shippable: Play rejects debug-signed uploads, and
the debug key is public knowledge — anyone can forge a build that Android
treats as an update to yours.

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (gitignored):

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Gradle logs which path it took — `key.properties found — release will be signed
with the upload keystore`, or the debug fallback warning. Confirm the artifact:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

The DN must be yours, not `CN=Android Debug`.

**Back the keystore up.** Losing it means you can never update the app under
the same package name again.

### 2. Add the release SHA-1 to Firebase

Google sign-in is bound to the signing certificate. It currently works only
because release is debug-signed and the debug SHA-1 is registered. The moment
you sign with a real key, sign-in breaks unless you add that key's fingerprint
too:

```bash
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Firebase console → Project settings → Your apps → Add fingerprint. If you use
Play App Signing, add **that** SHA-1 as well — Play re-signs your upload, so
the certificate users receive is not the one you uploaded with.

### 3. Ship the App Bundle, not the APK

The universal APK carries native code for all three ABIs. Measured:

| Artifact | Size |
|---|---|
| Universal APK | 108 MB |
| **arm64-v8a split** | **44.7 MB** |
| armeabi-v7a split | 37.3 MB |

```bash
flutter build appbundle --release
```

CI already produces `app-release.aab`. A real device downloads roughly 58 %
less than the universal APK.

## Recommended, not blocking

### R8 / resource shrinking

`minifyEnabled` and `shrinkResources` are both **off**. Turning them on would
cut the APK meaningfully, but this app resolves ML Kit, Firebase and several
Flutter plugins reflectively, and shrinking without a tested keep-rule set
strips classes that only fail at runtime — the worst failure mode for a
security app. Worth doing, but only together with a device test pass.

### E2E against the shipping configuration

CI has no `google-services.json`, so the sign-in gate stands down there and the
Appium suite exercises an **ungated** app — not what users install. The job
summary states which mode ran. To close the gap, add repository secrets:

| Secret | Purpose |
|---|---|
| `GOOGLE_SERVICES_JSON` | switches CI to the gated build |
| `CG_TEST_EMAIL` | test account the suite signs in with |
| `CG_TEST_PASSWORD` | its password |

Create the test account in Firebase console → Authentication → Users.

## Device checklist

Nothing below has been exercised on hardware. Each is a change whose failure
mode is silent.

- [ ] **SMS guard.** Enable it in Settings, send an SMS containing a phishing
      link from another phone, confirm the warning notification. Then
      force-quit the app and repeat — the manifest receiver is supposed to
      start the process on its own. This replaced a foreground service; if the
      broadcast is not delivered, background scanning stops silently.
- [ ] **Google sign-in** — account chooser appears and completes.
- [ ] **Email sign-in and registration**, plus password reset.
- [ ] **Sign out** returns to the login screen and cannot be backed past.
- [ ] **Wi-Fi name** shows the real SSID; with Location off it explains why
      instead of showing "Unknown".
- [ ] **Hindi / Tamil / Telugu** render with no tofu boxes, including the
      language picker which shows all three scripts at once.
- [ ] **Clipboard auto-fill** on the phishing screen, with the Android 12+
      paste toast.
- [ ] **Retention** — the launch sweep on a device with existing history.

## Known gaps

- The Indic auth strings are a first pass and want a native-speaker review.
- First launch requires connectivity to sign in, even though every scanner
  runs on-device.
- `ml_training/` (data, notebooks, saved models) ships in the repo. It is not
  used by the app; it is the training pipeline behind `assets/models/`.
