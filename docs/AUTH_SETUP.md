<!-- See docs/REPO_HYGIENE.md for the guards that keep credentials and
     oversized files out of history. -->

# Enabling sign-in

Sign-in (email/password and "Continue with Google") is built on Firebase Auth
and is **optional at build time**. The repository carries no Firebase
credentials, so a clean checkout builds and runs with auth switched off — every
scanner is on-device and works without an account.

This document is the whole setup.

## What happens without configuration

`android/app/build.gradle` applies the `com.google.gms.google-services` plugin
**only when `android/app/google-services.json` exists**. That plugin aborts the
build when the file is missing, so applying it unconditionally would break a
clean checkout and CI for anyone without a Firebase project.

With no config:

| | |
|---|---|
| Build | succeeds (Gradle logs `google-services.json absent`) |
| `AuthService.init()` | catches the init failure, never throws |
| `AuthService.isConfigured` | `false` |
| Every auth call | returns `AuthFailure.notConfigured` |
| Login screen | shows an explanation instead of a form |
| Rest of the app | fully functional |

`test/auth_service_test.dart` pins this behaviour.

## Turning it on

1. **Create a Firebase project** at <https://console.firebase.google.com>.

2. **Register the Android app** with package name `com.cyberguard.ai`
   (must match `applicationId` in `android/app/build.gradle`).

3. **Add your signing SHA-1.** Google sign-in *will not work* without it —
   this is the single most common cause of an opaque `PlatformException`
   during `signInWithGoogle()`.

   Your debug keystore fingerprint on this machine is already:

   ```
   SHA-1   F5:EA:FA:0A:CA:2A:06:AA:74:E1:15:58:6D:72:86:F9:64:CC:1D:CC
   SHA-256 93:04:9C:15:D9:7C:3E:D9:04:6B:A3:BF:F3:0E:34:EB:2B:A0:9C:09:6B:19:1F:DA:62:D0:A7:56:F6:F0:84:01
   ```

   Paste the SHA-1 into Firebase console → Project settings → Your apps →
   Add fingerprint.

   Re-derive it any time with:

   ```bash
   keytool -list -v -alias androiddebugkey \
     -keystore ~/.android/debug.keystore -storepass android -keypass android
   ```

   Add the SHA-1 for **every** keystore you build with. Note that
   `android/app/build.gradle` currently signs release with `signingConfigs.debug`,
   so today the debug fingerprint above covers release too — that must change
   before you ship, and the real release fingerprint added here as well
   (plus the Play App Signing one if you use it).

4. **Enable the providers** in Firebase console → Authentication → Sign-in
   method: turn on **Email/Password** and **Google**.

5. **Download `google-services.json`** and place it at
   `android/app/google-services.json`. It is gitignored on purpose.

6. **Verify the config:**

   ```bash
   dart run tool/check_firebase_config.dart
   ```

   It checks that the file parses, that it contains an entry for
   `com.cyberguard.ai`, and that an OAuth client of the type Google sign-in
   needs is present — the three things that otherwise fail silently at
   runtime with an opaque error.

7. Rebuild. Gradle should log `google-services.json found — Firebase auth
   enabled`, and the login screen will show the form.

## Notes

- **Privacy posture.** The app tells users *"all analysis happens locally —
  nothing is sent to our servers."* That stays true of scanning: auth only ever
  transmits credentials to Firebase. If you extend this to sync scan data, the
  permission rationale strings in `lib/core/constants/app_constants.dart` and
  the `settingsLocalStorage` copy need revisiting.

- **Sign-in is not a gate.** Nothing redirects to `/login`. It is reachable
  from Settings → Account, and the screen always offers "Continue without an
  account". Making it mandatory would break the offline-first promise.

- **iOS** is not wired up. Add `GoogleService-Info.plist` and the reversed
  client ID URL scheme to `Info.plist` if you target iOS.
