# Threat Model

> A structured analysis of what CyberGuard AI is designed to defend
> against, what it explicitly does not protect against, and what
> residual risks remain.
>
> Framework: **STRIDE** (Spoofing, Tampering, Repudiation, Information
> disclosure, Denial of service, Elevation of privilege), applied
> per-asset.

## Table of contents

- [Scope](#scope)
- [Assets being protected](#assets-being-protected)
- [Adversaries](#adversaries)
- [Trust boundaries](#trust-boundaries)
- [STRIDE analysis per module](#stride-analysis-per-module)
- [Cross-cutting controls](#cross-cutting-controls)
- [Out of scope](#out-of-scope)
- [Residual risks](#residual-risks)
- [Future hardening](#future-hardening)

---

## Scope

CyberGuard AI is a **client-side security advisory** running on the
user's Android phone. It does not:

- Run a VPN or intercept network traffic
- Replace the OS-level Android security model
- Provide tamper-proof guarantees against root / compromised firmware
- Defend against physical attackers with the unlocked device

It **does**:

- Warn the user about phishing URLs / SMS / QR codes before they tap
- Identify installed apps with high-risk permission patterns
- Tell the user if their email appeared in a public breach
- Score the trustworthiness of the connected Wi-Fi network

Everything below is framed against that scope.

## Assets being protected

| # | Asset | Why an attacker wants it |
|---|---|---|
| A1 | **User credentials** (passwords, OTPs) | Bank fraud, account takeover |
| A2 | **SMS messages** (especially OTPs and banking SMS) | Account takeover, transaction approval |
| A3 | **Email address** (in HIBP context) | Targeted phishing, credential stuffing |
| A4 | **Wi-Fi network metadata** (SSID, BSSID, IP) | Surveillance, evil-twin re-targeting |
| A5 | **Installed app list + permissions** | Stalkerware profiling, attack-surface mapping |
| A6 | **Scan history + alerts** (stored locally) | Behavioural profile of the user |
| A7 | **App integrity** (the CyberGuard binary itself) | Backdoor injection if rebuilt with malicious code |

## Adversaries

| Code | Adversary | Capabilities | Motivation |
|---|---|---|---|
| **T1** | **Phishing scammer** | Send SMS / WhatsApp links, host fake login pages, register lookalike domains | Steal banking / UPI / OTP credentials |
| **T2** | **Sideloaded malware author** | Distribute APKs via WhatsApp / Telegram / shady app stores; permissions like `BIND_ACCESSIBILITY_SERVICE`, `RECEIVE_SMS`, `REQUEST_INSTALL_PACKAGES` | Intercept OTPs, screen-record banking, install more droppers |
| **T3** | **Evil-twin Wi-Fi operator** | Set up open AP with same SSID as a trusted network (café, airport); MITM all traffic | Credential harvesting, session hijacking |
| **T4** | **Credential-stuffing botnet** | Use leaked username:password pairs against random sites | Account takeover at scale |
| **T5** | **Stalker / abusive partner** | Has occasional physical access to the device; can install commercial spyware (mSpy, Cocospy) | Surveillance, location tracking |
| **T6** | **Curious observer** (school IT, employer, ISP) | Network-level traffic analysis | Profile what the user does online |
| **T7** | **Malicious dependency** (supply chain) | Compromise an npm / pub.dev package the app depends on | Inject backdoor into the released APK |

Each STRIDE entry below is mapped back to the adversaries it addresses.

## Trust boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                     UNTRUSTED ZONE                          │
│                                                             │
│   Incoming SMS │ Pasted URL │ Scanned QR │ Open Wi-Fi APs   │
│   Installed apps (.apk files) │ User email input            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            │
                  (validated at entry)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      TRUSTED ZONE                           │
│              (the CyberGuard AI process)                    │
│                                                             │
│   On-device ML │ Hive (encrypted) │ Native Kotlin services  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            │
                  (k-Anonymity only)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     EXTERNAL ZONE                           │
│         haveibeenpwned.com/api/v3/range/{prefix}            │
│         (only first 5 chars of SHA-1 leave the device)      │
└─────────────────────────────────────────────────────────────┘
```

Every input from the untrusted zone is sanitised before reaching the
trusted zone. The trusted zone never sends raw user data to the
external zone — only HIBP-prefix hashes.

## STRIDE analysis per module

### Phishing scanner (URL / SMS / QR)

| STRIDE | Threat | Adversary | Control |
|---|---|---|---|
| **S** | Lookalike domain (`paytm.support` vs `paytm.com`) | T1 | Brand impersonation rule + suspicious TLD check |
| **S** | URL shortener hiding final destination | T1 | Flagged as low confidence; warned but not auto-blocked |
| **T** | User edits a flagged URL and retries | T1 | Re-runs the classifier; no state preserved |
| **R** | None — no shared log | — | — |
| **I** | URL leaks to a server | T6 | **All inference is local**. Verified by absence of network calls in `phishing_ml_service.dart`. |
| **D** | Long URL crashes the regex engine | T1 | URL truncated to 2048 chars before feature extraction |
| **E** | None — module has no privileged actions | — | — |

**Coverage:** The 12-feature LR + 60-tree RF achieves 95%+ on test set
including Indian-context URLs (HDFC, ICICI, UPI handles). False
negatives: AI-generated phishing with native English copy, zero-day
domains less than 24h old.

### Malware analyser

| STRIDE | Threat | Adversary | Control |
|---|---|---|---|
| **S** | Malicious app pretends to be legit ("CamScanner Pro") | T2 | `is_sideloaded` feature heavily weighted; Play Store-installed apps get lower base risk |
| **S** | Malware uses Accessibility Service legitimately (banks do too) | T2 | Combined with `bind_accessibility_service` + `request_install_packages` to disambiguate |
| **T** | User grants the malware permissions after our warning | T2 | We can warn but not block — out of scope (OS responsibility) |
| **I** | App list leaked | T6 | Read-only via `PackageManager`; never transmitted |
| **I** | Permission graph leaked | T6 | Computed entirely in Dart; not persisted |
| **D** | 500+ installed apps overwhelm the UI | — | Scan is incremental, progress bar, async batching |
| **E** | Our app gains privileged access to others' data | — | We only call `PackageManager.queryInstalledApplications()` — same access any launcher has |

**Coverage:** RF + LightGBM + GNN ensemble achieves 98.15% test
accuracy. False positives: legitimate but permission-heavy apps
(WhatsApp, Truecaller). False negatives: malware that lies in its
manifest (e.g. declares few permissions, requests more at runtime).

### Breach monitor

| STRIDE | Threat | Adversary | Control |
|---|---|---|---|
| **S** | Phishing site tells user "you've been breached, click here" | T1 | We never link out; results stay in-app |
| **T** | None | — | — |
| **R** | User denies they checked a breach | — | History stored locally only; user can delete |
| **I** | Email transmitted to HIBP | T6 | **k-Anonymity**: SHA-1 hashed locally, only first 5 chars sent |
| **I** | Password transmitted to HIBP | T6 | Same — SHA-1 prefix only |
| **D** | HIBP rate-limits the user | T1 indirectly | Offline DB fallback keeps the feature usable |
| **E** | None | — | — |

**The k-Anonymity proof.** When a user enters `user@example.com`:

1. SHA-1 hash computed locally: `9e7c97801cb4cce87b6c02f9e9aab1d3e6c5d6f9`
2. Only `9E7C9` (first 5 hex chars) sent to HIBP
3. HIBP returns ~800 hashes starting with `9E7C9`
4. Local code matches the remaining 35 chars against that list

At no point does the full email or full hash leave the device. This is
the same protocol Google's Password Checkup uses.

### Wi-Fi analyser

| STRIDE | Threat | Adversary | Control |
|---|---|---|---|
| **S** | Evil twin: same SSID, different BSSID | T3 | `BSSID Consistency` check — compares against stored BSSID for that SSID |
| **S** | Captive portal pretends to be a router login page | T3 | Out of scope (handled by Android's own captive portal flow) |
| **T** | Attacker forces user to disconnect and reconnect to capture handshake | T3 | Out of scope (KRACK / WPA2 cryptographic attacks) |
| **R** | None | — | — |
| **I** | DNS lookups leak to attacker's DNS | T3 | DNS health check flags non-Google/Cloudflare resolvers |
| **D** | Open networks have no encryption — anyone can monitor | T6 | `Encryption` check flagged red; ML model gives critical risk |
| **E** | Wi-Fi info leaks app's identity | — | We use Android's standard `WifiManager` — no extra fingerprinting |

**Coverage:** Six checks (encryption, signal, DNS, internet, BSSID,
latency) + Isolation Forest anomaly score. False positives common on
guest networks with deliberately weak settings. False negatives:
sophisticated evil twins that match BSSID *and* MAC.

### Live SMS phishing guard (native foreground service)

| STRIDE | Threat | Adversary | Control |
|---|---|---|---|
| **S** | Carrier-spoofed SMS ("HDFCBK" sender ID) | T1 | We classify the *content*, not the sender — sender ID is unreliable on Indian carriers anyway |
| **T** | User dismisses our notification and clicks the link | T1 | We warn, we can't block. OS responsibility. |
| **R** | None | — | — |
| **I** | SMS body leaks | T6 | **100% native Kotlin classification**. No Dart isolate, no network. SMS body never leaves `PhishingGuardService.kt`. |
| **D** | High-volume SMS spam triggers many notifications | T1 | Dedupe by hash; rate-limit one alert per minute |
| **E** | Service runs in background forever | — | User-toggleable in Settings; foreground type is `dataSync` (least-privileged of the persistent types) |

## Cross-cutting controls

### App integrity (A7)

- **Release builds** are signed with the developer's release key. If the
  user installs a modified APK, the signature mismatch is detected by
  the OS and a re-install prompt is shown.
- **Source is open** — any researcher can audit the lack of telemetry
  / analytics / hidden network calls.
- The `pubspec.yaml` contains **no Firebase, Sentry, Crashlytics, or
  Mixpanel** dependencies; a CI grep on those names would fail.

### Data at rest

- Hive boxes are stored in the app's private data dir (sandboxed by
  Android).
- The AES key for Hive is managed via `flutter_secure_storage`, which
  is backed by the Android Keystore — hardware-backed on devices with
  TEE / StrongBox.
- Even with root on the device, retrieving plaintext requires breaking
  Android Keystore, not just reading files.

### Network egress

The only external network call in the entire app is HIBP's k-Anonymity
endpoint. This can be verified by grepping for `http`:

```bash
grep -rE 'https?://' lib/ | grep -v 'github\|haveibeenpwned\|comment'
# expected: only the HIBP URL constant
```

### Permissions requested

Every dangerous permission is requested **only when its feature is
used**, with a rationale bottom sheet first:

| Permission | When asked | Why |
|---|---|---|
| `RECEIVE_SMS` / `READ_SMS` | When user enables Live SMS Guard or opens SMS tab | Classify phishing locally |
| `ACCESS_FINE_LOCATION` | When user taps "Scan Wi-Fi" | Required by Android to read SSID |
| `NEARBY_WIFI_DEVICES` | When user taps "Scan Wi-Fi" (Android 13+) | Modern equivalent of location for Wi-Fi |
| `POST_NOTIFICATIONS` | When user enables real-time alerts | Push threat warnings |
| `CAMERA` | When user taps QR scanner | Decode QR codes |
| `READ_EXTERNAL_STORAGE` | When user uploads QR from gallery | Pick image |

We do **not** request: contacts, microphone, call log, body sensors, or
the Accessibility Service. Any of those in a "security" app would be a
red flag — we abstain to set an example.

## Out of scope

These threats are explicitly **not** addressed and the user must rely
on the OS / other tools:

- **Root / jailbreak / firmware compromise.** A compromised OS bypasses
  every userspace control. We don't claim to defend against this.
- **Physical access with biometrics or PIN bypass.** This is the OS's
  problem.
- **Side-channel attacks** (Spectre, RowHammer, etc.) on the user's
  hardware.
- **Cryptographic attacks on WPA2 / TLS** themselves (KRACK, Logjam,
  POODLE). We trust the underlying crypto stack.
- **Government-grade spyware** (Pegasus, Predator). Out of scope for any
  consumer app.
- **Zero-day phishing domains** less than 24 hours old that haven't hit
  any threat-intel feed yet. Our model uses URL structure heuristics,
  not real-time blocklists, so a brand-new domain that follows safe
  conventions can pass.
- **Voice phishing (vishing).** Audio analysis is out of scope.

## Residual risks

Even within our scope, these are honest acknowledgements:

1. **The classifier is not perfect.** False positives waste user time,
   false negatives cause harm. We mitigate by showing confidence
   percentages and SHAP-style reasoning so the user can override.

2. **Offline breach DB is small** (10 historical breaches). Users
   without an HIBP API key get partial coverage. We warn explicitly via
   the orange "Offline database" banner.

3. **GNN model has only 94.63% accuracy** vs RF/LGBM's 99%. We weight
   it 25% in the ensemble for diversity, not because it's the best
   single model.

4. **Live SMS Guard requires `READ_SMS`** which is a Google-restricted
   permission. The Play Store may reject the app at submission; an APK
   sideload is the current distribution path.

5. **The app doesn't auto-update** detection rules. Once shipped, the
   ML models are frozen until the next APK release. Real cloud
   competitors update daily.

6. **Supply chain.** We pin direct dependencies in `pubspec.lock` but
   transitive deps can still be compromised. No SBOM is generated.

## Future hardening

The following would close the residual gaps if the project continues:

| Area | Improvement |
|---|---|
| **Detection** | Add a real-time abuse-feed (PhishTank, OpenPhish) updater — once a day, opt-in |
| **Model freshness** | Ship a remote-config endpoint to push rule updates without an APK release |
| **Supply chain** | Generate an SBOM (`cyclonedx-flutter`) per release; pin transitive deps |
| **Integrity** | Root / debugger detection with warning (not enforcement) |
| **Cert pinning** | Pin `api.pwnedpasswords.com`'s certificate to defeat hostile MITM proxies |
| **Tamper** | Verify APK signature at runtime and warn if mismatched |
| **A11y** | Full TalkBack pass on every screen |
| **Tests** | Unit-test the ML services with golden inputs/outputs |

---

For the engineering implementation behind these controls, see
[`ARCHITECTURE.md`](ARCHITECTURE.md). For the model metrics referenced
above, see [`ML_EVALUATION.md`](ML_EVALUATION.md).
