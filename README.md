# CyberGuard AI

> Intelligent, fully on-device mobile security assistant for Android.
> Phishing detection, malware analysis, breach monitoring, and Wi-Fi
> safety in one Flutter app — every scan runs locally, no data leaves
> the phone.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-Educational-blue)](#license)
[![Tests](https://img.shields.io/badge/flutter%20analyze-clean-success)](#quality)

---

## Table of contents

- [What it does](#what-it-does)
- [Why it exists](#why-it-exists)
- [Feature matrix](#feature-matrix)
- [Screens](#screens)
- [How it's built](#how-its-built)
- [On-device machine learning](#on-device-machine-learning)
- [Privacy guarantees](#privacy-guarantees)
- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [Deep dives](#deep-dives)
- [Credits](#credits)
- [License](#license)

---

## What it does

CyberGuard AI is a single app that protects an Indian smartphone user from
the four most common attack surfaces:

| Threat | What the app does |
|---|---|
| **Phishing URLs** | Paste / scan / SMS-detect any link; on-device classifier (12-feature LR + rules) gives a verdict with SHAP-style explanation. |
| **Phishing SMS** | Native Kotlin foreground service inspects every incoming SMS for phishing links and notifies in real time. |
| **Phishing QR codes** | Live camera scan and gallery upload; decoded URLs go through the same engine. |
| **Malicious apps** | Pulls every installed app's permission set, runs Random Forest + LightGBM + GNN ensemble, flags stalkerware / banking trojans / sideloaded droppers. |
| **Credential breaches** | HIBP k-Anonymity lookup for emails (only first 5 chars of SHA-1 leave the device); offline 10-breach fallback when no API key is configured. |
| **Unsafe Wi-Fi** | Reads the connected network's encryption, signal, DNS health, latency, and BSSID consistency; Isolation Forest flags anomalous networks. |

Everything is **on-device**. No telemetry, no cloud inference, no data
collection. The HIBP API call is the only network egress and it uses
k-Anonymity — your email is never transmitted in any form.

## Why it exists

Most consumer security apps in India are either:

- **Free + ad-loaded + privacy-violating** (sell your contact list, abuse
  Accessibility Service permission), or
- **Paid + cloud-based** (every URL you visit gets uploaded to a server)

This project shows there's a third option: **modern ML, ensemble
detection, and zero server dependency** — small enough to ship in a
~30 MB APK, accurate enough to compete with cloud services.

## Feature matrix

| # | Feature | Implementation | Status |
|---|---|---|---|
| 1 | Phishing URL scanner | 12-feature LR + 60-tree RF (JSON tree-walk) | ✓ |
| 2 | Phishing SMS guard (live) | Native Kotlin foreground service + BroadcastReceiver | ✓ |
| 3 | Phishing QR scanner | `mobile_scanner` (camera + gallery image decode) | ✓ |
| 4 | Malware app analyser | RF + LightGBM + GNN ensemble (35/40/25 weights) | ✓ |
| 5 | App permission deep-dive | SHAP feature explanations per app | ✓ |
| 6 | Breach monitor (email) | HIBP k-Anonymity API + offline DB fallback | ✓ |
| 7 | Wi-Fi safety scanner | 8-feature Isolation Forest + rules | ✓ |
| 8 | Real-time threat alerts | `flutter_local_notifications` + Hive log | ✓ |
| 9 | Unified security score | Weighted sum across 4 modules, 7-day history | ✓ |
| 10 | PDF / CSV report export | `pdf` + `csv` packages, share-sheet integration | ✓ |
| 11 | Onboarding flow | 5-screen Lottie-animated walkthrough | ✓ |
| 12 | 4-language localisation | English / हिन्दी / தமிழ் / తెలుగు via ARB | ✓ |
| 13 | k-Anonymity privacy | SHA-1 prefix lookup, never full hash | ✓ |
| 14 | Local-only storage | Hive (encrypted via `flutter_secure_storage`) | ✓ |
| 15 | Theme | Light theme (dark removed pending redesign) | ✓ |

## Screens

> Add screenshots to `docs/screens/` and update these paths.

| Dashboard | Phishing scanner | Malware scanner |
|---|---|---|
| ![](docs/screens/dashboard.png) | ![](docs/screens/phishing.png) | ![](docs/screens/malware.png) |

| Breach monitor | Wi-Fi analyser | Settings |
|---|---|---|
| ![](docs/screens/breach.png) | ![](docs/screens/wifi.png) | ![](docs/screens/settings.png) |

## How it's built

```
┌──────────────────────────────────────────────────────────────┐
│                   Flutter UI (Material 3)                    │
│  Dashboard · Phishing · Malware · Breach · Wi-Fi · Alerts   │
└──────────────────────────────────────────────────────────────┘
                            │
                  Riverpod StateNotifiers
                            │
┌──────────────────────────────────────────────────────────────┐
│                       Repositories                           │
│  Phishing · Malware · Breach · Wi-Fi (Dart, pure logic)     │
└──────────────────────────────────────────────────────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
  On-device ML       Hive (local DB)       Platform channels
  (JSON trees)       (encrypted)            (Kotlin native)
                                                  │
                                                  ▼
                                    Android APIs (WifiManager,
                                    PackageManager, SmsManager,
                                    NotificationManager)
```

Full details in [`ARCHITECTURE.md`](ARCHITECTURE.md).

## On-device machine learning

Six models, all trained from scratch in [`ml_training/`](ml_training/),
all running on the device with zero network calls:

| Model | Task | Test accuracy | Size on device |
|---|---|---|---|
| **DistilBERT** (multilingual) | Phishing URL classification | 100.00% | 541 MB *(server-side eval only)* |
| **Random Forest** | Malware permission classification | 99.17% | 761 KB |
| **LightGBM** | Malware permission classification | 99.46% | 852 KB |
| **GNN** (3-layer GCN) | Malware permission graph | 94.63% | exported as JSON |
| **Isolation Forest** | Wi-Fi anomaly detection | 2/3 anomalies caught | 843 KB |
| **Ensemble** (RF·LGBM·GNN) | Malware (35/40/25 weighted) | 98.15% | — |

Full confusion matrices, ROC curves, and SHAP plots are in
[`ML_EVALUATION.md`](ML_EVALUATION.md).

Why JSON tree-walk and not TFLite? Because the Python 3.12 + Windows
TFLite conversion stack is broken in five different ways
([details](ml_training/README.md#why-json-tree-walk-not-tflite-on-the-device)).
JSON exports give bit-identical decisions to the trained model, run in
Dart on the UI thread in under 10 ms, and ship as part of the APK's
`assets/models/` folder.

## Privacy guarantees

| Claim | Proof |
|---|---|
| "No data leaves your phone" | `Dio` is configured with zero base URLs; only HIBP `api.pwnedpasswords.com/range/{5-char-prefix}` is reachable. Verifiable in `lib/data/services/hibp_service.dart`. |
| "Passwords never transmitted" | k-Anonymity: SHA-1 the input, send only the first 5 chars, match the rest locally. Same protocol Google's Password Checkup uses. |
| "SMS never leaves the phone" | Phishing classification is 100% in native Kotlin (`PhishingGuardService.kt`); no Dart runtime is invoked during background scan. |
| "Storage is local + encrypted" | Hive boxes with `flutter_secure_storage`-managed AES key. |
| "No analytics" | No Firebase / Sentry / Crashlytics / Mixpanel dependencies in [`pubspec.yaml`](pubspec.yaml). |

See [`THREAT_MODEL.md`](THREAT_MODEL.md) for what we defend against and
what's explicitly out of scope.

## Getting started

### Prerequisites

- Flutter 3.x stable channel
- Android SDK with API level 34
- JDK 17 or 21 (the project pins Android Studio's bundled JBR via
  `android/gradle.properties`; JDK 25 is **not** supported by Flutter as
  of late 2025)
- A real Android device for Wi-Fi / SMS testing (emulator only works for
  phishing URL scanning)

### Build & run

```bash
git clone https://github.com/ShanmukhaAditya1056/cyberguardaimobile.git
cd cyberguardaimobile

# Pull deps + generate localisations
flutter pub get

# Run on a connected device
flutter run
```

The first build takes 2–4 minutes (Gradle 8.11.1, NDK download).
Subsequent builds are under 30 s.

### Optional: configure HIBP API key

The Breach Monitor falls back to a 10-breach offline DB without an API
key. For full coverage of 14B+ records, get a free key at
[haveibeenpwned.com/API/Key](https://haveibeenpwned.com/API/Key) and
paste it under Settings → Have I Been Pwned API Key.

### Re-train the ML models (optional)

```bash
cd ml_training
python -m venv .venv-ml
.venv-ml/Scripts/activate          # Windows
pip install -r requirements.txt

python scripts/01_collect_data.py
python scripts/05_train_random_forest.py
python scripts/06_train_lightgbm.py
python scripts/12_export_json.py   # ships JSON into assets/models/
```

Full pipeline in [`ml_training/README.md`](ml_training/README.md).

## Project structure

```
cyberguard_ai/
├── android/                      # Native Android (Kotlin)
│   └── app/src/main/kotlin/com/cyberguard/ai/
│       ├── MainActivity.kt       # Platform channel: Wi-Fi, packages
│       ├── PhishingGuardService.kt   # Foreground SMS scanner
│       └── SmsReceiver.kt        # SMS BroadcastReceiver
├── assets/
│   ├── animations/               # Lottie files
│   └── models/                   # JSON ML weights (~2.5 MB total)
├── lib/
│   ├── app.dart                  # Root MaterialApp + theme
│   ├── main.dart                 # Entry point + Hive init
│   ├── core/                     # Theme, utils, helpers
│   ├── data/                     # Repositories, services, models
│   │   ├── services/             # ML services, platform channel, Hive
│   │   ├── repositories/         # One per module
│   │   └── models/               # Data classes (Hive-annotated)
│   ├── features/                 # One folder per screen
│   │   ├── dashboard/
│   │   ├── phishing/
│   │   ├── malware/
│   │   ├── breach/
│   │   ├── wifi/
│   │   ├── alerts/
│   │   ├── settings/
│   │   ├── onboarding/
│   │   └── splash/
│   ├── l10n/                     # ARB files + generated localisations
│   └── shared/widgets/           # Reusable UI components
├── ml_training/                  # Python training pipeline (see its README)
├── ARCHITECTURE.md               # System design
├── THREAT_MODEL.md               # What we defend against
├── ML_EVALUATION.md              # Consolidated model metrics
└── README.md                     # This file
```

## Deep dives

| Document | What it covers |
|---|---|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Layered architecture, state management, native channels, on-device ML pipeline. |
| [`THREAT_MODEL.md`](THREAT_MODEL.md) | STRIDE analysis: who we defend against, attack surfaces in scope and out of scope, residual risks. |
| [`ML_EVALUATION.md`](ML_EVALUATION.md) | Per-model accuracy, precision/recall, confusion matrices, SHAP feature importance, ensemble weighting. |
| [`ml_training/README.md`](ml_training/README.md) | How every model was trained, dataset sources, reproducibility checklist. |

## Quality

- `flutter analyze` → **0 issues**
- 4 locales fully translated (en / hi / ta / te)
- All user-visible strings localised, no hardcoded copy in screens
- Material 3 theming, responsive layouts, accessibility-aware
  (`Semantics`, font-scale tested up to 1.5x)

## Credits

Built for a final-year B.Tech project. Models, datasets, and architecture
choices documented in the deep-dive files above.

- **HIBP** — Troy Hunt's [Have I Been Pwned](https://haveibeenpwned.com) API
- **HuggingFace `transformers`** — DistilBERT fine-tune
- **scikit-learn / LightGBM / torch-geometric** — model training
- **Flutter / Riverpod / Hive / mobile_scanner** — app frameworks
- **Lottie Files** — onboarding animations

## License

Educational use. Not for redistribution without permission. Datasets used
during training are under their respective original licenses (see
`ml_training/data/raw/`).
