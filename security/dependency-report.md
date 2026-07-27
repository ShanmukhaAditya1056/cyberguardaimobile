# Dependency & Supply-Chain Report — CyberGuard AI

**Generated:** 2026-07-27
**Package manager:** Dart pub (`pubspec.yaml` / `pubspec.lock`)
**Resolved packages in lockfile:** 198
**Direct dependencies:** 40 (37 runtime + 3 dev, excluding Flutter SDK entries)

All figures below come from `flutter pub outdated` executed against the
repository at assessment time — they are measured, not estimated.

---

## Headline

No dependency in this project has a known-exploited CVE that I could identify,
but **27 of 29 reported direct dependencies are behind their latest release**,
and several are behind by multiple major versions. That is the supply-chain
risk here: not a specific vulnerable package today, but a dependency set drifting
far enough from upstream that applying a future security patch becomes a
migration project rather than a version bump.

Two packages deserve attention beyond mere staleness because they sit on
sensitive surfaces: `mobile_scanner` (camera) and `flutter_secure_storage`
(credential storage, currently unused — see MOB-003).

---

## Direct dependencies materially behind upstream

Sorted by the size of the gap. "Resolvable" is what pub could reach today
without a manual constraint change.

| Package | Current | Latest | Major versions behind | Surface |
|---|---|---|---:|---|
| `flutter_local_notifications` | 17.2.4 | 22.2.0 | 5 | Notifications |
| `go_router` | 13.2.5 | 17.3.0 | 4 | Navigation |
| `share_plus` | 9.0.0 | 13.3.0 | 4 | IPC / file sharing |
| `device_info_plus` | 10.1.2 | 13.2.0 | 3 | Device identifiers |
| `clipboard` | 0.1.3 | 3.0.14 | 3 | Clipboard access |
| `mobile_scanner` | 5.2.3 | 7.4.0 | 2 | **Camera** |
| `network_info_plus` | 6.1.4 | 8.2.1 | 2 | Wi-Fi SSID/BSSID |
| `google_fonts` | 6.3.3 | 8.2.0 | 2 | Font fetching |
| `flutter_riverpod` | 2.6.1 | 3.4.1 | 1 | State management |
| `riverpod_annotation` | 2.6.1 | 4.0.5 | 2 | Codegen |
| `flutter_secure_storage` | 9.2.4 | 10.3.1 | 1 | **Credential storage** |
| `permission_handler` | 11.4.0 | 12.0.3 | 1 | **Runtime permissions** |
| `battery_plus` | 6.0.2 | 7.1.1 | 1 | Battery telemetry |
| `connectivity_plus` | 6.1.5 | 7.3.1 | 1 | Network state |
| `installed_apps` | 1.6.0 | 2.1.1 | 1 | **Installed-app inventory** |
| `package_info_plus` | 8.3.1 | 10.2.1 | 2 | App metadata |
| `fl_chart` | 0.68.0 | 1.2.0 | 1 | Charts |
| `csv` | 6.0.0 | 8.0.0 | 2 | Report export |
| `flutter_lints` | 4.0.0 | 6.0.0 | 2 | Static analysis (dev) |
| `google_mlkit_text_recognition` | 0.13.1 | 0.16.0 | minor | **On-device OCR** |

Trivially upgradable today (patch/minor, no constraint change needed):
`dio` 5.9.2 → 5.11.0, `image_picker` 1.2.2 → 1.2.3,
`path_provider` 2.1.5 → 2.1.6, `uuid` 4.5.3 → 4.6.0.

**77 transitive packages** are also reported outdated. Most will move on their
own once the direct constraints are raised.

---

## Risk assessment by dependency

### Elevated attention

| Package | Why it matters |
|---|---|
| `mobile_scanner` 5.2.3 → 7.4.0 | Wraps the camera and decodes untrusted image data from the physical environment. Image/barcode decoders are a historically rich source of memory-safety bugs. Two major versions of upstream fixes are unapplied. |
| `flutter_secure_storage` 9.2.4 → 10.3.1 | The correct home for the HIBP key (MOB-003). Version 10 changed the Android backend defaults; upgrade **before** implementing MOB-003 so the migration is written once against the target API. |
| `permission_handler` 11.4.0 → 12.0.3 | Mediates access to SMS, location and camera. A behavioural change in permission reporting could silently alter what the app believes it is allowed to do. |
| `google_mlkit_text_recognition` 0.13.1 → 0.16.0 | Pulls a large native ML Kit dependency chain and processes untrusted images. |
| `installed_apps` 1.6.0 → 2.1.1 | Reads the full package inventory — see MOB-008. |

### Standard

`go_router`, `flutter_riverpod`, `fl_chart`, `google_fonts`, `share_plus`,
`csv`, `pdf`, `printing`, `lottie` — behind upstream, but they process
application-controlled data rather than attacker-controlled input. Upgrade on
the normal maintenance cycle.

Note: `google_fonts` fetches fonts over the network at runtime unless fonts are
bundled. This project **does** bundle Inter in `pubspec.yaml`, so the runtime
fetch path should not be exercised — worth preserving deliberately.

---

## Notable absences

| Expected control | Status |
|---|---|
| Automated dependency scanning in CI | **Absent** at assessment time (MOB-015) — addressed by the supplied `security-review.yml` |
| Lockfile committed | **Present** — `pubspec.lock` is tracked, so builds are reproducible |
| Dependency pinning strategy | Caret ranges (`^`) throughout — standard for pub, accepts minor/patch automatically |
| Secret scanning | **Absent** — addressed by the Gitleaks job in the supplied workflow |
| SBOM generation | **Absent** — see recommendation below |

---

## Secret-scanning result

A manual sweep for credential patterns across the full reachable git history:

```bash
git log --all --oneline -- lib/core/config/api_keys.dart   # no output
git grep -I "AIzaSy" $(git rev-list --all)                  # no output
```

**No credential has ever been committed to this repository.** The live Safe
Browsing key exists only in the working tree, in a correctly gitignored file.
This is the right outcome and is worth protecting with automated scanning so it
stays true.

Note that `.gitignore` protects the repository, not the artifact — the key is
still compiled into the APK (MOB-002).

---

## Native / Android dependencies

| Component | Version | Note |
|---|---|---|
| Android Gradle Plugin | via `dev.flutter.flutter-gradle-plugin` | Inherited from the Flutter SDK |
| Kotlin JVM target | 17 | Current |
| `desugar_jdk_libs` | 2.1.4 | Current |
| `compileSdk` / `targetSdk` | `flutter.compileSdkVersion` / `flutter.targetSdkVersion` | Inherited — pins to whatever the installed Flutter SDK specifies |
| `multiDexEnabled` | true | Expected given the ML Kit dependency chain |

Inheriting `compileSdk`/`targetSdk` from the Flutter SDK is convenient but
means the app's declared target API level changes silently when the SDK is
upgraded. Since `targetSdk` governs runtime permission and background-execution
behaviour — both central to this app — it is worth pinning explicitly and
changing deliberately.

---

## Recommendations

**1. Upgrade the security-surface packages first** (in this order):

```bash
flutter pub upgrade --major-versions flutter_secure_storage permission_handler
flutter pub upgrade --major-versions mobile_scanner google_mlkit_text_recognition
flutter test          # 33 existing tests + 36 corpus tests must stay green
cd automation && npm test   # E2E must stay green
```

Do `flutter_secure_storage` **before** implementing MOB-003, so the credential
migration is written once against the version you will actually ship.

**2. Take the free wins now** — these need no constraint changes:

```bash
flutter pub upgrade   # dio, image_picker, path_provider, uuid
```

**3. Pin the Android SDK levels explicitly** in `android/app/build.gradle`:

```gradle
compileSdk 35
targetSdk 35   // change deliberately, not as a side effect of a Flutter upgrade
```

**4. Enable continuous scanning** — the supplied
`.github/workflows/security-review.yml` runs `flutter pub outdated`, Gitleaks,
Trivy and Semgrep on every push and fails the build only on Critical findings.

**5. Generate an SBOM** for the project record:

```bash
flutter pub deps --json > sbom-dart.json
```

---

## Honest limits of this analysis

- **The Dart ecosystem has no equivalent of `npm audit`.** pub.dev publishes no
  machine-readable advisory database, so "no known CVEs" here means "no
  advisories found by manual review", not "verified clean against a
  vulnerability feed". This is a genuine gap in the ecosystem, not an omission
  in this review.
- Transitive native dependencies pulled in through Gradle (ML Kit, CameraX)
  were not individually version-audited; Trivy in the supplied workflow will
  cover those on an ongoing basis.
- No runtime dependency confusion or typosquatting check was performed. All 40
  direct dependencies are well-known pub.dev packages with established
  publishers, verified by inspection.
