# Application Inventory — CyberGuard AI

Equivalent of the requested "backend inventory", re-scoped to what this
application actually is: a fully on-device Android client with no server
component.

**Generated:** 2026-07-27

---

## 1. Technology stack

| Layer | Technology |
|---|---|
| Language | Dart 3.x, Kotlin (native layer) |
| Framework | Flutter 3.41.8 (stable) |
| Target platform | Android only — no `ios/`, `web/`, `windows/`, `macos/` or `linux/` directory exists |
| Package manager | Dart pub (`pubspec.yaml`) + Gradle (Android) |
| Application ID | `com.cyberguard.ai` |
| Declared version | 2.0.0+1 (`pubspec.yaml`) — displayed as 1.0.0 in-app, see MOB-011 |
| Min / target SDK | Inherited from `flutter.minSdkVersion` / `flutter.targetSdkVersion` |
| Java / Kotlin target | 17 |

**Source size:** 116 Dart files, 4 Kotlin files, 4 localisation bundles.

---

## 2. Architecture

**Pattern:** Feature-first layered architecture with unidirectional data flow.

```
lib/
├── core/         Cross-cutting: theme, router, i18n, config, utils
├── data/
│   ├── models/         Hive-annotated persistence models
│   ├── repositories/   Business logic; the only layer that writes to storage
│   └── services/       Device APIs, ML inference, threat intelligence
├── features/     13 features, each: provider/ + view/ + widgets/
└── shared/       Reusable widgets and global providers
```

- **State management:** Riverpod (`flutter_riverpod` 2.6.1) — providers per
  feature, no global mutable singletons except `wifiMlService`.
- **Navigation:** `go_router` with a declarative route table and a redirect
  guard on `onboardingComplete`.
- **Persistence:** Hive (local NoSQL key-value), 7 boxes.
- **No dependency injection container** — dependencies are constructor-injected,
  which is why `SafeBrowsingSource` and `HibpService` are testable with a mock
  `Dio`.

**Not present:** monolith/microservice split, service layer over HTTP, message
queue, scheduled server jobs, ORM. None of these concepts apply to this app.

---

## 3. Routes (client-side navigation, not HTTP endpoints)

The requested "endpoint inventory" has no counterpart. The closest analogue is
the GoRouter table — 16 in-app destinations, all local:

| Route | Screen | Entry point | Auth required |
|---|---|---|---|
| `/` | Splash | Cold start | None (no auth exists) |
| `/onboarding` | Onboarding | First run only | None |
| `/dashboard` | Dashboard | Home | None |
| `/phishing` | Phishing scanner | Module card | None |
| `/phishing/qr` | QR scanner | From phishing | Camera permission |
| `/malware` | Malware scanner | Module card | `QUERY_ALL_PACKAGES` |
| `/malware/detail` | App detail | From scan results | None |
| `/breach` | Breach monitor | Module card | Optional HIBP key |
| `/wifi` | Wi-Fi scanner | Module card | Location permission |
| `/alerts` | Alert history | App bar | None |
| `/intercept` | Link warning | Reactive (VIEW intent) | None |
| `/fusion` | Threat fusion | Defense tile | None |
| `/arbitration` | Arbitration log | Defense tile | None |
| `/risk` | Predictive risk | Defense tile | None |
| `/screenshot` | Screenshot scanner | Defense tile | Photo access |
| `/settings` | Settings | App bar | None |

**There is no authentication anywhere in this application.** No login, no
accounts, no sessions, no tokens, no roles. Every route is reachable by the
single local user.

---

## 4. Outbound network calls

The complete external attack surface — two third-party services, both optional:

| # | Service | Endpoint | Trigger | Default | Data transmitted |
|---|---|---|---|---|---|
| 1 | Google Safe Browsing v4 | `POST safebrowsing.googleapis.com/v4/threatMatches:find` | URL scan | **OFF** | Full URL + API key |
| 2 | HIBP Passwords | `GET api.pwnedpasswords.com/range/{prefix}` | Password check | On | **5-char SHA-1 prefix only** (k-anonymity, `Add-Padding: true`) |
| 3 | HIBP Breaches | `GET haveibeenpwned.com/api/v3/breachedaccount/{email}` | Breach check | Requires user key | Email address + user's API key |

**In the shipping default configuration, endpoint 1 never fires** — it is gated
on both a configured key and the user-enabled cloud-intel preference, which
defaults to off behind an explicit consent dialog.

Endpoint 2 is the privacy-preserving design: the full password never leaves the
device, and padding defeats response-size correlation.

---

## 5. Data storage inventory

All storage is local. No remote database exists.

| Box | Model | Contents | Encrypted | Sensitivity |
|---|---|---|---|---|
| `scanResultsBox` | `ScanResultModel` | Scanned URLs, verdicts, confidence | ❌ | Browsing history |
| `alertsBox` | `AlertModel` | Threat alerts, truncated URLs | ❌ | Browsing history |
| `wifiScansBox` | `WifiScanModel` | SSID, BSSID, trust score | ❌ | **Location trail** |
| `scoreHistoryBox` | `ScoreEntryModel` | Daily security scores | ❌ | Behavioural profile |
| `settingsBox` | `SettingsModel` | Preferences + **HIBP API key** | ❌ | **Credential** |
| `appScanCacheBox` | `AppScanModel` | Installed-app inventory + risk | ❌ | **Device fingerprint** |
| `prefsBox` | `String` | Interceptor flags | ❌ | Low |

See MOB-003, MOB-004, MOB-005.

---

## 6. Android permissions

| Permission | Purpose | Play-restricted | Finding |
|---|---|---|---|
| `INTERNET` | Optional threat-intel lookups | No | — |
| `ACCESS_NETWORK_STATE` | Connectivity checks | No | — |
| `ACCESS_WIFI_STATE` / `CHANGE_WIFI_STATE` | Wi-Fi analysis | No | — |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Required to read SSID | No | — |
| `NEARBY_WIFI_DEVICES` | SSID on API 33+ | No | Correctly declared **without** `neverForLocation` |
| `READ_SMS` / `RECEIVE_SMS` | SMS phishing scan | **Yes** | MOB-010 |
| `QUERY_ALL_PACKAGES` | Malware scanner inventory | **Yes** | MOB-008 |
| `RECEIVE_BOOT_COMPLETED` | Restart SMS guard | No | Guarded by user opt-in |
| `FOREGROUND_SERVICE` + `_DATA_SYNC` | Background SMS guard | No | — |
| `POST_NOTIFICATIONS` | Threat alerts | No | — |
| `VIBRATE`, `WAKE_LOCK` | Alert feedback | No | — |
| `READ_EXTERNAL_STORAGE` | Screenshot scan (`maxSdkVersion=32`) | No | Correctly version-capped |

---

## 7. Exported components

| Component | Exported | Justification |
|---|---|---|
| `MainActivity` | ✅ true | LAUNCHER + link interceptor (`VIEW` http/https, `SEND` text/plain) — MOB-009 |
| `PhishingGuardService` | ❌ false | Correct — internal foreground service |
| `BootReceiver` | ✅ true | Required for `BOOT_COMPLETED`; action-checked and gated on user opt-in |
| `SmsReceiver` | n/a | **Registered dynamically in code, not in the manifest** — good practice |

---

## 8. On-device ML inventory

| Model | Asset | Format | Size | Used by |
|---|---|---|---|---|
| Phishing classifier | `phishing_weights.json` | Logistic regression (8000 training samples) | 1.5 KB | URL scanning |
| Malware RF | `malware_rf_weights.json` | Random forest | 780 KB | App scoring |
| Malware LightGBM | `malware_lgbm_weights.json` | GBM | 873 KB | App scoring |
| Malware GNN | `malware_gnn_weights.json` | Graph NN | 347 KB | App scoring |
| Wi-Fi anomaly | `wifi_isoforest_weights.json` | Isolation forest | 864 KB | Network trust |
| DistilBERT vocab | `distilbert_vocab.txt` | WordPiece vocabulary | 1.1 MB | Tokenizer (forward-looking) |

Models execute directly in Dart — there is no TFLite runtime dependency. See
MOB-013 regarding asset integrity.

---

## 9. Third-party integrations

| Category | Present |
|---|---|
| Payment gateway | ❌ None |
| Cloud storage | ❌ None |
| Email service | ❌ None |
| Analytics / crash reporting | ❌ None |
| Push notification service | ❌ None — notifications are local only |
| Ad networks | ❌ None |
| Social login | ❌ None |

The absence of analytics and crash reporting is consistent with the app's
privacy posture. It also means there is no telemetry to correlate a production
incident against — a trade-off worth making consciously.
