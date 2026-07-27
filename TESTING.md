# Testing & Security Assessment — CyberGuard AI

Index of the QA and security deliverables added to this repository.

---

## What was built

| Deliverable | Location |
|---|---|
| Appium E2E automation framework | [`automation/`](automation/) |
| 171 executable test cases | [`automation/tests/`](automation/tests/) |
| Excel / HTML / JSON reporting | [`automation/reporting/`](automation/reporting/) |
| Load & performance testing | [`automation/performance/`](automation/performance/) |
| Mobile security assessment | [`security/`](security/) |
| CI/CD workflows | [`.github/workflows/`](.github/workflows/) |
| Automation identifiers (app side) | [`lib/core/utils/automation_ids.dart`](lib/core/utils/automation_ids.dart) |

Full usage, configuration and troubleshooting: **[automation/README.md](automation/README.md)**

---

## Scope note

The original brief described a React web app with a backend API — Selenium
against GitHub Pages, endpoint inventory, SQL injection, JWT/RBAC/IDOR testing,
and a 100-VU load test against production.

This repository contains **a Flutter Android app with no backend**. There is no
web frontend, no server, no database server, no ORM, no authentication and no
sessions. Roughly half the requested test categories have no counterpart here.

Rather than fabricate results, the work was re-scoped and every omission is
recorded with its reason:

- Web/Selenium half — dropped; there is no web target.
- Backend audit — re-scoped to a mobile security assessment (OWASP MASVS).
- Non-applicable test categories — listed explicitly in
  [`security/security-review.md`](security/security-review.md#not-applicable-items)
  and in the "Not Applicable" sheet of `security/findings.xlsx`.

### Load testing against third-party services was not performed

The app's only remote endpoints belong to **Google Safe Browsing** and **Have I
Been Pwned**. Directing 100+ concurrent virtual users at third-party production
infrastructure is abuse, breaches both providers' terms, and would get the
project's API credentials revoked.

The equivalent load profile runs against
[`automation/performance/mock-threat-intel-server.js`](automation/performance/mock-threat-intel-server.js),
which implements the same request/response contracts. The k6 script **refuses
to execute against any non-localhost host**.

---

## Test coverage

**171 test cases** — 169 executable, 2 explicitly declared not-applicable.

| Suite | Cases | Covers |
|---|---:|---|
| Phishing | 51 | URL verdicts, 14 malformed inputs, 8 payload-shaped inputs |
| Navigation | 24 | All tappable routes + back-navigation integrity |
| Accessibility | 17 | Semantics tree per screen, 48dp touch targets, accessible names |
| Settings | 17 | Toggle mechanics, persistence, privacy posture |
| Breach | 11 | Identifier validation |
| Localisation | 9 | English, Hindi, Tamil, Telugu |
| Resilience | 8 | Background/resume, restart, interrupted scans, rotation |
| Dashboard | 7 | Unified score, scan mechanics, persistence |
| Performance | 6 | Cold start, scan latency, memory growth |
| Smoke | 6 | Launch, semantics tree availability |
| Secondary screens | 4 | Risk, arbitration, screenshot scanner |
| Malware / Alerts / Fusion / Wi-Fi | 11 | Scanning, alert lifecycle, offline fusion |

The count is honest. It is not padded to reach an arbitrary target — the app
has no login, accounts, CRUD or file upload, so test categories covering those
would be asserting against features that do not exist.

**Additionally:** `test/automation_corpus_test.dart` adds 36 Dart tests that
verify the E2E suite's URL expectations directly against `PhishingRepository`,
so a rule-weight change fails in two seconds rather than as a confusing
emulator run.

---

## Running

```bash
# Dart unit tests (69 total)
flutter test

# Appium E2E
cd automation
npm install
npx appium driver install uiautomator2
npm run appium &          # separate terminal
npm run doctor            # preflight
npm test
```

Reports appear in `automation/reports/`.

---

## Security assessment

Full white-box review against OWASP MASVS v2 / Mobile Top 10 (2024).

| Severity | Count |
|---|---:|
| Critical | 0 |
| High | 3 |
| Medium | 5 |
| Low | 4 |
| Informational | 3 |

**Score: 68/100 — MEDIUM risk.**

The three High findings are all build configuration, not application logic:

1. **MOB-001** — release builds are signed with the public debug keystore
2. **MOB-002** — the Safe Browsing API key is compiled into the APK
3. **MOB-003** — the HIBP key is stored in plaintext, though
   `flutter_secure_storage` is already a dependency and simply unused

[Steps 1–4 of the remediation guide](security/remediation-guide.md) clear all
three in about two hours.

The app also got several things genuinely right — correct HIBP k-anonymity with
padding, cloud lookups off by default behind a real consent gate, cleartext
traffic disabled, and a dynamically-registered SMS receiver. Those are detailed
in [security-review.md](security/security-review.md#positive-findings).

| Document | Contents |
|---|---|
| [executive-summary.md](security/executive-summary.md) | Findings, score, priorities |
| [security-review.md](security/security-review.md) | All 15 findings with evidence and fixes |
| [mobile-inventory.md](security/mobile-inventory.md) | Stack, architecture, permissions, data flows |
| [dependency-report.md](security/dependency-report.md) | Measured dependency posture |
| [remediation-guide.md](security/remediation-guide.md) | Copy-paste fixes in priority order |
| `findings.xlsx` | Findings, risk summary, MASVS coverage, not-applicable items |

---

## CI/CD

| Workflow | Trigger | Purpose |
|---|---|---|
| [`android-e2e.yml`](.github/workflows/android-e2e.yml) | push, PR, dispatch, nightly | Build APK → emulator → Appium → reports → artifacts |
| [`deploy-reports.yml`](.github/workflows/deploy-reports.yml) | after E2E | Publish to GitHub Pages, archive history |
| [`security-review.yml`](.github/workflows/security-review.yml) | push, PR, dispatch, weekly | Gitleaks, Semgrep, Trivy, manifest audit |

**One-time setup:** Settings → Pages → Source: *GitHub Actions*, and
Settings → Actions → Workflow permissions: *Read and write*. No secrets needed.

Published reports:
`https://<username>.github.io/<repository>/reports/latest/execution-report.html`

---

## Changes made to the app itself

Appium cannot see inside a Flutter app by default — Flutter renders to a single
canvas, so the accessibility tree is what makes automation possible.

Added `Semantics(identifier: …)` wrappers across the UI, declared centrally in
[`lib/core/utils/automation_ids.dart`](lib/core/utils/automation_ids.dart) (89
identifiers). The Flutter engine maps these to
`AccessibilityNodeInfo.viewIdResourceName`, which Appium reads as `resource-id`.

This means tests run against **the same APK users install** — no test-only
build variant — and the identifiers are genuine accessibility improvements,
not test scaffolding. Icon-only controls also gained accessible names.

No application behaviour was changed. `flutter analyze` is clean and all 69
Dart tests pass.
