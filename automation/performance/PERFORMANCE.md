# Performance Testing — CyberGuard AI

Methodology, budgets and how to interpret the numbers.

**This document describes the harness. It does not contain measured results** —
those are produced by a run and written to
`reports/JSON/performance-results.json` and
`reports/JSON/load-test-results.json`. Publishing invented numbers here would
defeat the point of measuring.

---

## What is measured, and what cannot be

CyberGuard AI has **no backend**. There is no API of its own to load-test, no
server response time to profile, no database to saturate. Performance for this
application means two different things, and they need two different harnesses:

| Dimension | Harness | Runs where |
|---|---|---|
| **On-device latency** — cold start, scan time, memory | Appium (`tests/performance/perf.spec.js`) | Real emulator/device |
| **Client contract under load** — throughput, p95/p99 | k6 (`k6-load-test.js`) | Localhost mock only |

### Why the load test targets a mock

The app's only remote endpoints are:

- `safebrowsing.googleapis.com` — Google
- `api.pwnedpasswords.com` / `haveibeenpwned.com` — Have I Been Pwned

Both are **third-party production services**. Pointing 100–1000 concurrent
virtual users at either would be a denial-of-service attempt against
infrastructure this project does not own, would violate both providers'
acceptable-use terms, and would get the project's API keys revoked. HIBP in
particular rate-limits aggressively and bans on abuse.

`mock-threat-intel-server.js` implements the same request/response shapes —
Safe Browsing's `threatMatches:find` (including the empty-object response for a
clean URL) and HIBP's `range/{prefix}` k-anonymity format. The load profile
therefore exercises the same payload sizes, status codes and error branches
that the real client code handles.

**What this measures:** the client contract, the harness and the request
pipeline.
**What it does not measure:** Google's or HIBP's capacity — which was never a
meaningful thing for this project to measure, and never something it could act
on.

The script enforces this: `setup()` throws if `BASE_URL` resolves to anything
other than localhost.

---

## On-device metrics

Run as part of the normal suite (`npm test`) or standalone:

```bash
npx mocha --spec 'tests/performance/**/*.spec.js'
```

| Test | Metric | Budget | Why that budget |
|---|---|---|---|
| `TC_PERF_001` | Cold start → interactive | 15 s | `main()` initialises Hive, notifications and warms three ML models before the first frame |
| `TC_PERF_002` | URL scan latency (10 samples) | 8 s worst case | A rules engine plus a logistic regression, all in Dart — should be tens of ms |
| `TC_PERF_003` | Full installed-app scan | 60 s | Scales with package count; an emulator has few apps, so this is a floor check |
| `TC_PERF_004` | Memory growth over 20 scans | 150 MB | Detects retained tokenizer buffers and Hive write leaks |
| `TC_PERF_005` | Screen-to-screen navigation | 3 s | Route transition plus first paint |

**The budgets are deliberately generous.** CI emulators are slow, shared and
inconsistent — a tight threshold would produce a flaky suite that gets ignored
within a week. These catch order-of-magnitude regressions, not 10% drift.

For meaningful trend analysis, use `reports/JSON/performance-results.json`,
which records min / avg / p95 / max per metric across runs.

### A note on TC_PERF_004

Memory is read with `dumpsys meminfo`, which needs Appium's
`--relaxed-security`. Without it the test **skips** rather than asserting on a
number it could not read. A skip here means "not measured", not "passed".

---

## Load profiles

Start the mock first:

```bash
node performance/mock-threat-intel-server.js
```

Then, in another terminal:

```bash
# Baseline — the profile requested in the brief
k6 run -e SCENARIO=baseline performance/k6-load-test.js

# Stress — find the breaking point
k6 run -e SCENARIO=stress performance/k6-load-test.js

# Spike — recovery behaviour
k6 run -e SCENARIO=spike performance/k6-load-test.js

# Endurance — leak and degradation detection
k6 run -e SCENARIO=endurance performance/k6-load-test.js
```

| Scenario | Profile | Answers |
|---|---|---|
| `baseline` | 100 VUs, 60 s constant | What is normal throughput and latency? |
| `stress` | 200 → 500 → 1000 VUs | Where does it break, and how? |
| `spike` | 50 → 500 → 50, sharp | Does it recover, and how fast? |
| `endurance` | 100 VUs, 30 min | Does anything degrade over time? |

### Thresholds

```js
http_req_failed:   ['rate<0.01']                  // < 1% errors
http_req_duration: ['p(95)<500', 'p(99)<1500']    // ms
business_errors:   ['rate<0.01']                  // malformed responses
```

`business_errors` is separate from `http_req_failed` on purpose: a 200 response
carrying a malformed body is a failure the HTTP metric would not catch, and it
is exactly the kind of bug a client contract test should surface.

### Output

```
 Requests per second : 118.42 req/sec
 Total requests      : 7105
 Error rate          : 0.00%

 Response times
   Minimum : 11.83 ms
   Average : 41.27 ms
   Median  : 33.91 ms
   P95     : 96.44 ms
   P99     : 412.08 ms
   Maximum : 782.13 ms

 Thresholds: PASSED
```

*(Shape of the output only — the numbers above are illustrative, not measured.)*

Machine-readable results land in `reports/JSON/load-test-results.json`.

---

## Interpreting results

**Latency distribution matters more than the average.** The mock deliberately
injects a slow tail (3% of requests take 250–750 ms extra) to model real
upstream behaviour. If p99 is close to the average, the harness is not
producing realistic variance and the numbers are not telling you much.

**A rising error rate under `stress` is the useful signal.** Where the error
rate departs from zero is the practical capacity limit of the client pipeline.

**Under `endurance`, watch the trend, not the absolute values.** Latency that
climbs steadily over 30 minutes at constant load indicates a leak. Flat is
healthy, regardless of the number.

**On-device memory growth is the highest-value metric here.** The target market
for this app is low-end Android devices, where a slow leak becomes an OOM kill
long before it would on a developer's phone.

---

## What this harness does not cover

Stated so the coverage claim is not overread:

- **Real-network conditions.** No latency injection, packet loss or bandwidth
  shaping between the app and the network. `mobile: shell` could drive `tc`
  rules for this if needed.
- **Battery and thermal impact.** The SMS foreground service runs continuously
  when enabled; its power draw is not measured here and would need a physical
  device with a power monitor.
- **Real-device fragmentation.** Everything runs on one emulator profile.
  Low-end ARM hardware will behave differently, and that is the segment that
  matters most for this app.
- **ML inference profiling in isolation.** Scan latency is measured end-to-end
  through the UI; it does not separate model inference from rendering.
- **Sustained multi-hour app usage.** The endurance profile loads the client
  contract, not the app itself.
