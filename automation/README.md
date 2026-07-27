# CyberGuard AI — Appium E2E Automation

End-to-end test automation for the CyberGuard AI Flutter Android app, with
Excel/HTML/JSON reporting, screenshot and log capture, and GitHub Actions
integration that publishes results to GitHub Pages.

---

## Read this first: how the suite sees a Flutter app

Flutter paints its entire UI into a single Android `FlutterView`. A driver
looking at the view hierarchy normally sees **one opaque node** — no buttons,
no text fields, nothing to tap.

This suite solves that without shipping a special test-only build. The app
publishes a semantics tree, and every widget the tests touch carries a
`Semantics(identifier: …)`. The Flutter engine maps that identifier onto
`AccessibilityNodeInfo.viewIdResourceName`, which UiAutomator2 exposes as an
ordinary **`resource-id`**.

The practical consequences:

- Tests run against **the same APK users install** — no
  `enableFlutterDriverExtension()`, no separate entrypoint.
- Locators are stable `resource-id` strings, not brittle text or coordinates.
- The identifiers double as real accessibility improvements.

The identifiers are declared once in Dart
(`lib/core/utils/automation_ids.dart`) and **generated** into JavaScript
(`config/auto-ids.generated.js`). Never edit the generated file — the runner
regenerates it and `npm run doctor` fails if it has drifted.

---

## Quick start

```bash
# 1. Build and install the app
cd ..
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 2. Install the suite
cd automation
npm install
npx appium driver install uiautomator2

# 3. Start Appium (leave running in its own terminal)
npm run appium

# 4. Check everything is wired up
npm run doctor

# 5. Run
npm test
```

Reports land in `reports/`. Open `reports/HTML/execution-report.html`.

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Node.js | ≥ 20 | `node --version` |
| Java JDK | 17 | Needed by the Appium UiAutomator2 driver |
| Android SDK | platform-tools + an emulator image | `adb` must be on `PATH` |
| Flutter | 3.41.8 | Only needed to build the APK |
| Emulator or device | API 30+ | API 34 is what CI uses |

`npm run doctor` verifies all of this and tells you exactly what is missing —
run it before opening an issue about a failing test.

---

## Commands

| Command | What it does |
|---|---|
| `npm test` | Full suite, then generates every report |
| `npm run test:smoke` | Smoke only — fastest signal that the setup works |
| `npm run test:navigation` | Route and back-navigation coverage |
| `npm run test:phishing` | URL scanner, including the malformed-input corpus |
| `npm run test:settings` | Preferences, persistence and privacy posture |
| `npm run report` | Regenerate reports from an existing results file — no device needed |
| `npm run doctor` | Preflight environment check |
| `npm run appium` | Start the Appium server |

Run a single test by name:

```bash
npx mocha --grep "TC_PHISH_D001"
npx mocha --grep "Privacy"
```

---

## Configuration

Everything is environment-driven — nothing is hardcoded, because a hardcoded
device name is the usual reason a suite that passes locally fails in CI.

| Variable | Default | Purpose |
|---|---|---|
| `CG_APP_PATH` | `build/app/outputs/flutter-apk/app-debug.apk` | APK to install |
| `CG_APP_PACKAGE` | `com.cyberguard.ai` | Package under test |
| `CG_DEVICE_NAME` | `Android Emulator` | Device name |
| `CG_UDID` | — | Target a specific device |
| `APPIUM_HOST` / `APPIUM_PORT` | `127.0.0.1` / `4723` | Appium server |
| `CG_ELEMENT_TIMEOUT` | `15000` | Element wait (ms) |
| `CG_SCAN_TIMEOUT` | `45000` | Scan-completion wait (ms) |
| `CG_TEST_TIMEOUT` | `120000` | Per-test timeout (ms) |
| `CG_RETRIES` | `1` | Retries per failing test |
| `CG_SCREENSHOT_ALL` | `false` | Screenshot passing tests too (slow) |
| `CG_FULL_RESET` | `false` | Wipe app data between sessions |
| `CG_PASS_THRESHOLD` | `95` | Pass-rate gate (%) |
| `CG_ALLOW_NETWORK_TESTS` | `false` | **Leave false.** See below. |
| `CG_LOG_LEVEL` | `info` | `debug` \| `info` \| `warn` \| `error` |

### `CG_ALLOW_NETWORK_TESTS` — why it defaults to false

The app's only remote dependencies are **Google Safe Browsing** and **Have I
Been Pwned** — third-party production services it does not own. Tests that would
issue real requests to either are gated behind this flag and are marked
`NOT_APPLICABLE` by default.

**CI must never set it.** A test matrix repeatedly hitting HIBP will get the
API key rate-limited and then banned. If you need to exercise the live path,
set it locally, with your own key, for a single run.

---

## Structure

```
automation/
├── config/
│   ├── env.js                    All environment-dependent values
│   ├── capabilities.js           W3C capabilities for UiAutomator2
│   ├── sync-ids.js               Generates the JS mirror from the Dart source
│   └── auto-ids.generated.js     GENERATED — do not edit
├── drivers/
│   └── driver-factory.js         One session per run; device metadata
├── pages/                        Page Object Model — one per screen
│   ├── base.page.js              Locators, explicit waits, failure messages
│   └── *.page.js                 14 screen objects
├── data/
│   └── urls.js                   URL corpus with documented expectations
├── tests/
│   ├── hooks.js                  Session lifecycle + failure evidence capture
│   ├── smoke/                    P0 — nothing else matters if these fail
│   ├── navigation/               All 16 routes + back-navigation integrity
│   ├── phishing/                 URL scanner + malformed/payload input
│   ├── dashboard/                Unified score, scan mechanics
│   ├── settings/                 Toggles, persistence, privacy posture
│   ├── modules/                  Malware, Wi-Fi, breach, alerts, fusion
│   ├── crosscutting/             i18n, accessibility, resilience
│   └── performance/              Cold start, scan latency, memory growth
├── reporting/
│   ├── collector.js              Canonical execution-results.json
│   ├── excel-reporter.js         Four workbooks, eight sheets
│   ├── html-reporter.js          Self-contained, theme-aware HTML
│   └── generate-all.js           Orchestrator + history + Actions summary
├── performance/
│   ├── mock-threat-intel-server.js   Local stand-in for the real APIs
│   └── k6-load-test.js               Load profiles (localhost only)
├── runners/
│   ├── run-suite.js              Entry point; reports always run
│   └── doctor.js                 Preflight checks
└── utils/
    ├── logger.js                 Namespaced, credential-redacting
    ├── screenshot.js             Screenshots, hierarchy dumps, logcat
    ├── navigator.js              Route map and navigation helpers
    └── testcase.js               tc() — test metadata for the reports
```

---

## Writing a test

Use `tc()` rather than a bare `it()`. It carries the metadata the Excel and
HTML reports need, and it enforces unique test IDs.

```js
const { tc } = require('../../utils/testcase');
const phishing = require('../../pages/phishing.page');

tc(
  {
    id: 'TC_PHISH_D009',              // unique; duplicates throw at load time
    module: 'Phishing',               // groups the reports
    priority: 'P0',                   // P0 failures become Critical defects
    title: 'IP-address URL is flagged as dangerous',
    preconditions: 'Phishing URL tab open',
    steps: ['Enter the URL', 'Tap Scan Now', 'Read the verdict'],
    testData: 'http://192.168.1.50/aadhaar-verify',
    expected: 'Verdict is Dangerous',
    rationale: 'IP-address URLs score 35 on rules alone.',
  },
  async () => {
    const verdict = await phishing.scanUrl('http://192.168.1.50/aadhaar-verify');
    assert.notStrictEqual(verdict, 'safe');
  }
);
```

For something the app genuinely cannot do, declare it rather than deleting it:

```js
tc.notApplicable(
  { id: 'TC_AUTH_001', module: 'Authentication', title: 'Valid login' },
  'The application has no login, accounts or sessions.'
);
```

These appear in the reports with their reason, so the coverage claim stays
auditable.

### Adding a new automation identifier

1. Add it to `lib/core/utils/automation_ids.dart`.
2. Attach it in the widget — `autoIdent: AutoId.myThing` on the shared widgets,
   or `Semantics(identifier: AutoId.myThing, container: true, child: …)`.
3. `flutter analyze` then rebuild the APK.
4. `node config/sync-ids.js` (or just run the suite — it regenerates).
5. Use it in a page object.

---

## Reports

Every run produces:

```
reports/
├── Excel/
│   ├── Automation_Test_Report.xlsx   8 sheets: executed, passed, failed,
│   │                                  skipped/NA, metrics, defects,
│   │                                  per-module pass rate, full steps
│   ├── Passed_Test_Cases.xlsx
│   ├── Failed_Test_Cases.xlsx
│   └── Execution_Summary.xlsx
├── HTML/
│   ├── execution-report.html         Failures with embedded screenshots
│   └── dashboard.html                Summary + historical trend
├── JSON/
│   ├── execution-results.json        Canonical source for everything else
│   ├── performance-results.json      min/avg/p95/max per metric
│   └── load-test-results.json        k6 output, when run
├── Summary/summary.md                Also posted to the Actions summary
└── history.json                      Rolling last 100 runs
```

`execution-results.json` is the single source of truth — every other format is
derived from it. That means you can regenerate the whole set from a downloaded
CI artifact with `npm run report`, without a device.

**Reports are generated whether tests pass or fail.** A run with twelve
failures is precisely the run whose report you need.

---

## Performance and load testing

On-device metrics (cold start, scan latency, memory growth) run as part of the
normal suite — see `tests/performance/perf.spec.js`.

For load testing, start the local mock first:

```bash
node performance/mock-threat-intel-server.js &

k6 run -e SCENARIO=baseline   performance/k6-load-test.js   # 100 VUs / 60s
k6 run -e SCENARIO=stress     performance/k6-load-test.js   # 200 → 500 → 1000
k6 run -e SCENARIO=spike      performance/k6-load-test.js   # 50 → 500 → 50
k6 run -e SCENARIO=endurance  performance/k6-load-test.js   # 100 VUs / 30m
```

**The script refuses to run against a non-localhost host.** This is deliberate.
The app has no backend; its real endpoints belong to Google and HIBP, and
driving 100–1000 concurrent users at third-party production infrastructure is
an attack, not a test. The mock implements the same request/response contracts,
so the load profile exercises the same client-side code paths.

---

## CI/CD

Three workflows:

| Workflow | Trigger | Does |
|---|---|---|
| `android-e2e.yml` | push, PR, dispatch, nightly | Analyze → Dart tests → build APK → boot emulator → Appium → E2E → reports → artifacts |
| `deploy-reports.yml` | after E2E completes | Publishes reports to GitHub Pages, archives history |
| `security-review.yml` | push, PR, dispatch, weekly | Gitleaks, Semgrep, Trivy, manifest audit |

### One-time repository setup

1. **Settings → Pages → Source:** *GitHub Actions*.
2. **Settings → Actions → General → Workflow permissions:** *Read and write*.
3. No secrets are required. CI builds with an empty API key, which disables
   the cloud threat-intel source — which is what we want, since CI must not
   call third-party APIs.

Published report URL:

```
https://<username>.github.io/<repository>/reports/latest/execution-report.html
```

### Pass/fail gate

The workflow fails when:

- the APK build fails, or
- the emulator or Appium never becomes healthy, or
- the pass rate falls below `CG_PASS_THRESHOLD` (default 95%).

Artifacts are uploaded **before** the gate is applied, so a failing run still
produces a complete report.

---

## Troubleshooting

### Every test fails with "not found after 15000ms"

The semantics tree is not reaching UiAutomator2. Confirm with:

```bash
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml -
grep -c 'cg_' ui.xml     # 0 means no identifiers are published
```

Usual causes:

1. **The installed APK predates the identifiers.** Rebuild and reinstall — this
   is the answer roughly nine times in ten.
2. `config/auto-ids.generated.js` is stale → `node config/sync-ids.js`.
3. Accessibility never activated. Restart the Appium session; UiAutomator2
   attaches the accessibility client on connect.

`TC_SMOKE_003` exists to catch exactly this and fail with a clear message
instead of 200 identical timeouts.

### "No active Appium session"

The server is not running, or is on a different port.

```bash
curl http://127.0.0.1:4723/status
npm run appium
```

### Emulator is extremely slow / tests time out

Hardware acceleration is off. On Linux confirm KVM:

```bash
ls -la /dev/kvm
```

Also raise the timeouts:

```bash
CG_ELEMENT_TIMEOUT=30000 CG_SCAN_TIMEOUT=90000 npm test
```

### `mobile: shell` fails and some tests skip

Appium needs `--relaxed-security` for shell access. Without it, the memory and
version tests skip rather than reporting a number they could not read.

```bash
npx appium --allow-cors --relaxed-security
```

### Tests interfere with each other

The suite shares one session for speed. If state leaks between suites:

```bash
CG_FULL_RESET=true npm test
```

### Report generation fails

Regenerate from the existing results without a device:

```bash
npm run report
```

If `execution-results.json` is missing, the suite never reached `afterAll` —
check `logs/execution.log`.

### A test fails only in CI

Compare the environments first:

```bash
CG_PLATFORM_VERSION=14 CG_DEVICE_NAME="Pixel 6" npm test
```

Then read the CI artifacts — `screenshots/failures/`,
`logs/hierarchy/` (what was actually on screen) and `logs/device/` (logcat)
are captured for every failure precisely for this.

---

## Design decisions

**One Appium session for the whole run.** Session creation costs 10–25s on an
emulator; 200 tests each paying it would take hours. Isolation comes from
`navigator.toDashboard()` in `beforeEach`.

**No implicit waits.** Implicit waits hide races and make timeouts
uninterpretable. Every wait is explicit and names what it was waiting for.

**`bail: false`.** The full pass/fail matrix is the deliverable; one early
failure must not hide the state of everything else.

**Reports before the gate.** Report generation is never conditional on tests
passing.

**Credentials are redacted in logs.** `utils/logger.js` strips API-key-shaped
strings before anything reaches a log file — logs get attached to CI artifacts
and published.

**Assertions match what the app can actually guarantee.** The URL corpus only
asserts hard verdicts where the outcome is deterministic (whitelisted domains
bypass the ML blend; rules scores ≥ 67 cannot be flipped by it). Borderline
URLs assert only that *a* verdict rendered. Those claims are independently
verified by `test/automation_corpus_test.dart`, so a rule-weight change fails
in a two-second Dart test rather than as a confusing emulator run.
