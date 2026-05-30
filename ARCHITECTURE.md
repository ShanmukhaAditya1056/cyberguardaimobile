# Architecture

> How CyberGuard AI is put together — from a button press in the UI all
> the way down to a SHAP-explained verdict from an on-device ML model.

## Table of contents

- [Goals](#goals)
- [System diagram](#system-diagram)
- [Layered breakdown](#layered-breakdown)
- [State management](#state-management)
- [On-device ML pipeline](#on-device-ml-pipeline)
- [Native Android integration](#native-android-integration)
- [Data persistence](#data-persistence)
- [Localisation](#localisation)
- [Threat alert flow](#threat-alert-flow)
- [Build pipeline](#build-pipeline)
- [Design decisions and trade-offs](#design-decisions-and-trade-offs)

---

## Goals

The architecture is shaped by three hard constraints:

1. **100 % on-device inference.** Every model verdict must be produced
   without a network call. The only egress allowed is HIBP, and even
   that uses k-Anonymity.
2. **Single APK ≤ 50 MB.** Rules out shipping a Transformer; forces
   tree-based models stored as JSON.
3. **Sub-100 ms UI thread budget.** Inference can't block the frame
   loop; the ML services are designed to return in under 10 ms.

Everything below is a consequence of those three rules.

## System diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                              UI Layer                                │
│                       (Flutter widgets, Material 3)                  │
│                                                                      │
│   Dashboard │ Phishing │ Malware │ Breach │ Wi-Fi │ Alerts │ Settings│
└────────┬─────────────────────────────────────────────────────────────┘
         │ ref.watch() / ref.read()
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         State Layer (Riverpod)                       │
│                                                                      │
│   DashboardNotifier │ PhishingNotifier │ MalwareNotifier │ ...       │
│   • Immutable State classes                                          │
│   • copyWith(...)-based updates                                      │
│   • Cross-provider sync (AlertsNotifier → DashboardNotifier)         │
└────────┬─────────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         Repository Layer                             │
│                                                                      │
│   PhishingRepository · MalwareRepository · BreachRepository · ...    │
│   • Pure Dart logic                                                  │
│   • Orchestrates services (ML + platform + storage)                  │
│   • Single source of truth for module results                        │
└────┬─────────────────┬───────────────────┬───────────────────┬───────┘
     │                 │                   │                   │
     ▼                 ▼                   ▼                   ▼
┌──────────┐   ┌──────────────┐   ┌─────────────────┐   ┌───────────────┐
│ ML Svc   │   │  Hive (DB)   │   │ Platform Channel│   │ External API  │
│ (Dart)   │   │  encrypted   │   │ ↓               │   │ (HIBP only)   │
│          │   │              │   │ MainActivity.kt │   │               │
│ tree-walk│   │ scan history │   │ ↓               │   │ k-Anonymity   │
│ JSON     │   │ alerts       │   │ WifiManager     │   │ SHA-1 prefix  │
│ models   │   │ settings     │   │ PackageManager  │   │               │
└──────────┘   └──────────────┘   │ SmsManager      │   └───────────────┘
                                  └─────────────────┘
                                          │
                                          ▼
                                  ┌─────────────────┐
                                  │ PhishingGuard   │
                                  │ Service.kt      │
                                  │ (foreground svc)│
                                  └─────────────────┘
```

## Layered breakdown

### 1. UI layer — `lib/features/`

One folder per screen, three files each:

```
features/phishing/
├── provider/phishing_provider.dart    # Riverpod StateNotifier
└── view/
    ├── phishing_screen.dart           # Main screen
    └── qr_scanner_screen.dart         # Sub-route
```

Widgets are **stateless wherever possible**. State lives in providers,
not in `StatefulWidget`s. The handful of `StatefulWidget`s that remain
exist only for animation controllers.

### 2. State layer — Riverpod `StateNotifier`

Every module has a `*Notifier` extending `StateNotifier<*State>`. The
state class is immutable and exposes a `copyWith(...)`. UI subscribes via
`ref.watch(provider)` and triggers actions via `ref.read(provider.notifier).method()`.

**Cross-provider syncing.** When an action in one provider must invalidate
another, the notifier holds a `Ref` and calls into the other provider
directly. Example: `AlertsNotifier.deleteAlert()` calls
`_ref.read(dashboardProvider.notifier).loadDashboard()` so the
notification badge and "Recent Alerts" card on the dashboard refresh
instantly.

### 3. Repository layer — `lib/data/repositories/`

Each repository takes services in its constructor and composes them.
This is where the actual business logic lives — the UI and providers
stay thin.

```dart
class PhishingRepository {
  final PhishingMlService _ml;
  final HiveService _storage;

  Future<PhishingResult> scanUrl(String url) async {
    final features = _ml.extractFeatures(url);
    final prediction = _ml.predict(features);   // <10 ms
    final result = PhishingResult(...);
    await _storage.saveScan(result);
    return result;
  }
}
```

Repositories are pure Dart, easy to unit-test without mocking the UI.

### 4. Service layer — `lib/data/services/`

| Service | Purpose |
|---|---|
| `phishing_ml_service.dart` | URL feature extraction + 60-tree RF inference |
| `malware_ml_service.dart` | App feature extraction + RF/LGBM ensemble |
| `malware_gnn_service.dart` | GNN message-passing inference (Dart port) |
| `wifi_ml_service.dart` | Isolation Forest scoring |
| `hibp_service.dart` | k-Anonymity password / email lookups |
| `offline_breach_db.dart` | Deterministic 10-breach fallback |
| `platform_channel_service.dart` | Bridge to Kotlin (Wi-Fi, apps, SMS) |
| `hive_service.dart` | Persistent storage (alerts, scans, settings) |
| `notification_service.dart` | `flutter_local_notifications` wrapper |
| `permission_service.dart` | Runtime permission prompts with rationale |
| `report_export_service.dart` | PDF / CSV report generation |
| `sms_stream_service.dart` | Toggle for native SMS foreground service |
| `wordpiece_tokenizer.dart` | DistilBERT tokenizer (planned on-device path) |

## State management

Why Riverpod over Bloc / Provider / Cubit:

| Concern | Riverpod's answer |
|---|---|
| Cross-screen access | `ref.read(provider)` from anywhere, no `BuildContext` needed |
| Disposal | Auto-dispose on widget tree teardown |
| Testing | Override providers in `ProviderScope` — no mocking framework |
| Code-gen friction | Optional; we use plain `StateNotifierProvider` |
| Refresh storms | `select()` lets widgets watch one field of a big state |

The codebase is consistent: every notifier is a `StateNotifier`, every
state is immutable, every action is a method on the notifier. No
`ChangeNotifier`, no `setState` outside of animation widgets.

## On-device ML pipeline

The most architecturally interesting part of the app. Six models, four
of them shipped on device, all running in pure Dart.

### Training (Python, offline)

```
ml_training/scripts/
  01_collect_data.py          # Pulls URL + permission datasets
  02_prepare_phishing_data.py # Feature engineering
  03_train_distilbert.py      # GPU, ~5 min — server-only artefact
  04_prepare_malware_data.py  # 25-feature vectors
  05_train_random_forest.py   # 60 trees, ~30 s
  06_train_lightgbm.py        # 176 trees, ~10 s
  07_train_gnn.py             # 3-layer GCN, GPU, ~4 min
  08_train_isolation_forest.py
  12_export_json.py           # ← THE KEY STEP
```

### The export-to-JSON trick

`12_export_json.py` traverses the sklearn / LightGBM / GNN model and
emits a JSON tree representation:

```json
{
  "schema_version": 1,
  "n_features": 25,
  "trees": [
    {
      "feature": 4,
      "threshold": 0.5,
      "left": { "feature": 12, "threshold": 0.5, ... },
      "right": { "leaf_value": 0.83 }
    },
    ...
  ]
}
```

This is bit-identical to the trained model's decision logic but uses
zero TF / PyTorch runtime. Total weight: ~2.5 MB across all four models.

### Inference (Dart, on device)

Each `*_ml_service.dart` ships a tree-walker:

```dart
double predict(List<double> features) {
  double sum = 0;
  for (final tree in _trees) {
    sum += _walkTree(tree, features);
  }
  return sum / _trees.length;
}

double _walkTree(Map<String, dynamic> node, List<double> features) {
  if (node.containsKey('leaf_value')) return node['leaf_value'];
  final f = features[node['feature']];
  return f < node['threshold']
      ? _walkTree(node['left'], features)
      : _walkTree(node['right'], features);
}
```

Average latency on a mid-range Android (Snapdragon 695): **~6 ms per
scan**. Inference runs on the UI thread without jank.

### Why not TFLite?

Five different conversion paths blocked on Python 3.12 + Windows.
Documented in [`ml_training/README.md`](ml_training/README.md#why-json-tree-walk-not-tflite-on-the-device).
JSON tree-walk delivers the same decisions for a smaller binary and
zero native dependencies — net win.

## Native Android integration

Three pieces of Kotlin in `android/app/src/main/kotlin/com/cyberguard/ai/`:

### `MainActivity.kt` — method-channel bridge

Exposes Android system APIs to Dart over a `MethodChannel` named
`com.cyberguard.ai/platform`:

| Method | Purpose |
|---|---|
| `getWifiDetails()` | SSID, BSSID, RSSI, encryption, frequency from `WifiManager` |
| `getInstalledApps()` | Package name, version, permissions, install source from `PackageManager` |
| `getAppIcon(packageName)` | PNG bytes of an installed app's icon |
| `getRecentSms(limit)` | Reads last N SMS from `content://sms/inbox` |
| `openAppSettings()` | Deep-links into per-app settings |

### `PhishingGuardService.kt` — foreground SMS scanner

When the user toggles "Live SMS Phishing Guard" in Settings:

1. Request `RECEIVE_SMS` + `POST_NOTIFICATIONS` runtime permissions
2. Start a foreground service with `dataSync` type
3. Register a `SmsReceiver` BroadcastReceiver
4. On every incoming SMS, run the same regex / keyword checks the Dart
   side uses (deliberately re-implemented in Kotlin to avoid spinning up
   a Dart isolate)
5. If suspicious, post a `NotificationCompat` alert

This is the only part of the app that runs without the user opening it.
It's also the only place where Kotlin re-implements logic that exists
in Dart — the trade-off is worth it because spinning up a Flutter engine
per SMS would burn battery.

### `SmsReceiver.kt` + `BootReceiver.kt`

Lifecycle management — restart the guard after device boot if the user
had it enabled.

## Data persistence

All persistent state lives in **Hive boxes** in the app's private
storage:

| Box | Contents |
|---|---|
| `settings` | API keys, toggle states, autoScanFrequency, theme |
| `alerts` | Threat alerts shown on the Alerts screen |
| `phishing_history` | Past URL scans with verdicts |
| `malware_apps` | Scanned app risk scores (cached for fast resume) |
| `wifi_scans` | Wi-Fi scan history |
| `breach_history` | Past breach lookups (just the input + verdict) |
| `score_history` | 7 most recent unified security scores for the chart |

The AES key for Hive is stored in `flutter_secure_storage` (Android
Keystore-backed). Even root access to the app's data directory wouldn't
yield plaintext settings.

## Localisation

`lib/l10n/app_*.arb` files plus `l10n.yaml` configure `flutter gen-l10n`
to emit `AppLocalizations` classes for English, Hindi, Tamil, Telugu.

Every user-visible string in the codebase is wired through
`AppLocalizations.of(context)!.<key>` — there are no hardcoded copy
strings in any screen file. Adding a new locale is a copy-paste of
`app_en.arb` and translating the values.

Plural forms use ICU MessageFormat (`{count, plural, =1{...} other{...}}`).
Long Tamil labels are auto-shrunk by `Flexible` + `FittedBox(scaleDown)`
in the button and section-header widgets to avoid overflow.

## Threat alert flow

```
[Module Scan]
     │
     │ produces ScanResult with risk='high'
     ▼
[Repository creates AlertModel]
     │
     ▼
[HiveService.saveAlert]
     │
     ├──→ [AlertsNotifier.loadAlerts]  (badge count +1)
     │
     └──→ [DashboardNotifier.loadDashboard]  (Recent Alerts card refresh)
     │
     ▼
[NotificationService.showUnsafe*]  ← if real-time alerts enabled
     │
     ▼
[System notification tray]
```

Alerts deletes / mark-all-read in the Alerts screen invalidate
`dashboardProvider` so the dashboard's badge and "Recent Alerts" list
refresh on the next frame (see
[`features/alerts/provider/alerts_provider.dart`](lib/features/alerts/provider/alerts_provider.dart)).

## Build pipeline

| Step | Tool | When |
|---|---|---|
| Pull deps | `flutter pub get` | On clone |
| Generate localisations | `flutter gen-l10n` (auto-runs via `pub get`) | After ARB edit |
| Native Android build | Gradle 8.11.1 + JDK 21 (pinned via `android/gradle.properties`) | Every `flutter run` |
| Hive type adapters | Manual (no codegen) — adapter classes live alongside models | When models change |
| ML weights | `python ml_training/scripts/12_export_json.py` writes to `assets/models/` | Re-train + re-export |

## Design decisions and trade-offs

| Decision | Alternative | Why we chose this |
|---|---|---|
| Riverpod | Bloc / Provider | No `BuildContext` coupling, easier cross-provider syncing |
| Hive | sqflite / Drift | Faster reads for our access pattern, no SQL |
| JSON tree-walk | TFLite | Smaller binary, no native deps, identical accuracy |
| Kotlin native bridge | Pure Flutter plugins | Existing plugins for SMS / packages were either dead or read-only |
| Light theme only | Auto dark mode | Dark mode had contrast bugs across 30+ files; removed cleanly until a full rewrite |
| HIBP + offline fallback | HIBP-only | Lets users without an API key still see real breach data |
| Foreground SMS service | Receiver-only | Receiver gets throttled on Android 12+; foreground service keeps it alive |
| Single APK | Modular feature delivery | Project scope; can split later via `--split-per-abi` |

---

For the security reasoning behind these choices — what threats they
defend against and which they explicitly punt — see
[`THREAT_MODEL.md`](THREAT_MODEL.md).
