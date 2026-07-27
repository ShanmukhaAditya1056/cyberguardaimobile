# Executive Summary — CyberGuard AI Security Assessment

**Application:** CyberGuard AI (`com.cyberguard.ai`) — Flutter Android security assistant
**Assessment date:** 2026-07-27
**Assessment type:** White-box static review (OWASP MASVS v2 / Mobile Top 10 2024)
**Codebase:** 116 Dart files, 4 Kotlin sources, ~40 direct dependencies

---

## Bottom line

CyberGuard AI is **well-designed and under-configured**.

The security *decisions* in the application logic are consistently sound —
several are the textbook-correct choice where a careless implementation would
have leaked user data. The security *configuration* of the build, by contrast,
is at Flutter's defaults, and those defaults are not release-safe.

Every High finding is a build-configuration issue fixable in under an hour.
None is an architectural flaw.

---

## Findings by severity

| Severity | Count |
|---|---:|
| **Critical** | **0** |
| **High** | **3** |
| **Medium** | **5** |
| **Low** | **4** |
| Informational | 3 |
| **Total** | **15** |

---

## Top risks

| # | ID | Risk | Severity |
|---|---|---|---|
| 1 | MOB-001 | Release builds are signed with the public **debug keystore**, so anyone can produce a tampered build that Android accepts as genuine | High |
| 2 | MOB-003 | The user's paid HIBP API key is stored in **plaintext**, even though `flutter_secure_storage` is already a dependency and simply never used | High |
| 3 | MOB-002 | The Google Safe Browsing key is a compile-time `const`, extractable from the APK with a single `strings` command | High |
| 4 | MOB-005 | Android backup is left enabled, so `adb backup` extracts all local data **from an unrooted device** | Medium |
| 5 | MOB-004 | All seven Hive databases are unencrypted — including Wi-Fi BSSID history (a location trail) and the full installed-app inventory | Medium |
| 6 | MOB-006 | R8 and Dart obfuscation are both disabled, which is what makes #3 trivial rather than merely possible | Medium |
| 7 | MOB-007 | No certificate pinning; a compromised public CA could intercept the HIBP key in transit | Medium |
| 8 | MOB-008 | `QUERY_ALL_PACKAGES` is a Play-restricted permission requiring an approved declaration before publication | Medium |
| 9 | MOB-010 | `READ_SMS` raises the consequence of any other compromise — SMS access defeats SMS-based 2FA | Low |
| 10 | MOB-012 | No root or tamper detection, so the app cannot warn users whose devices are already compromised | Low |

Risks #4, #5 and #10 compound: on a device with USB debugging enabled, #4 turns
#5 from "needs root" into "needs a USB cable."

---

## What the project got right

These are not participation points — each is a decision that is commonly
botched, and getting them wrong would have been a serious finding:

- **Have I Been Pwned k-anonymity is implemented correctly.** Only a
  5-character SHA-1 prefix leaves the device, and `Add-Padding: true` is set,
  which defeats the response-size correlation attack that most naïve
  implementations miss.
- **Cloud threat intelligence is off by default and gated behind an explicit
  consent dialog.** In the shipping default configuration, **no URL ever leaves
  the device**. Cancelling the dialog is a genuine no-op — verified by test
  `TC_SET_PRIV_002`.
- **Cleartext traffic is disabled** at both the manifest and network-security-
  config level, and user-added CAs are not trusted — which already defeats
  casual traffic interception on non-rooted devices.
- **The SMS receiver is registered dynamically rather than in the manifest**, so
  it is live only while the app runs. This is the correct pattern under Android
  14's implicit-broadcast restrictions.
- **The link interceptor deliberately omits `autoVerify`**, so the app never
  silently hijacks link handling — the user must choose it.
- **The API key file is correctly gitignored and was never committed.** Verified
  against the full reachable history; this is not a public credential leak.

---

## Scope correction the reader should know about

The assessment brief requested a **backend** security audit — endpoint
inventory, SQL injection, JWT handling, RBAC/IDOR, session management, CORS
headers, and a 100-virtual-user load test.

**This application has no backend.** There is no server, no API of its own, no
database server, no ORM, no authentication and no sessions. Detection runs
entirely on-device. Roughly half the requested test categories have no
counterpart in this codebase.

Rather than fabricate results for components that do not exist, those items are
listed explicitly in the "Not applicable" section of `security-review.md` with
the reason for each. Where a client-side analogue exists it **was** tested: 22
malformed- and payload-shaped-input cases confirm the URL scanner treats all
input as opaque text.

Separately, **no load test was run against the live endpoints.** The only
remote endpoints belong to Google and Have I Been Pwned. Pointing 100+
concurrent users at third-party production infrastructure would be abuse, would
violate both providers' terms, and would get the project's credentials revoked.
The equivalent load profile runs against a local mock that implements the same
request/response contracts, and the script refuses to execute against any
non-localhost target.

---

## Overall security score

# 68 / 100

**Risk rating: MEDIUM**

| Category | Score | Assessment |
|---|---:|---|
| Data storage | 11 / 25 | Weakest area — unencrypted databases, plaintext credential, backup enabled |
| Cryptography | 16 / 20 | Correct k-anonymity; no storage encryption |
| Network security | 15 / 20 | Cleartext blocked and system-CA-only trust; pinning absent |
| Platform interaction | 13 / 15 | Well-reasoned component exports; permissions broad but justified |
| Code quality & build | 8 / 20 | Debug signing and absent obfuscation dominate the deduction |

---

## Recommended remediation order

| Priority | Finding | Effort | Why first |
|---|---|---|---|
| 1 | MOB-001 — release signing key | ~30 min | Blocks any legitimate release and undermines all tamper resistance |
| 2 | MOB-002 — restrict the API key in Cloud Console | ~15 min | Console-only change; makes an extracted key useless |
| 3 | MOB-005 — disable/scope Android backup | ~15 min | One manifest attribute; removes the unrooted extraction path |
| 4 | MOB-006 — enable R8 + Dart obfuscation | ~1 hour | Raises the cost of every extraction attack |
| 5 | MOB-003 — move the HIBP key to secure storage | ~2 hours | Dependency is already installed and unused |
| 6 | MOB-004 — encrypt Hive boxes | ~4 hours | Needs a migration so existing users keep their history |

**Items 1–4 total roughly two hours and eliminate all three High findings.**

---

## Assurance statement

This assessment is a white-box static review of the source tree, Android
manifest and Gradle configuration. Findings cite exact file and line
references, and every line reference in `security-review.md` was verified
against the working tree at the time of writing.

**Not covered by this assessment:**

- Runtime instrumentation of a release binary (Frida, objection)
- Live traffic interception against the real third-party endpoints
- Penetration testing of Google's or HIBP's infrastructure (out of scope and
  not authorised)
- ML model adversarial robustness — how reliably the classifier can be evaded
  by a crafted URL is a model-quality question, not a security-control question,
  and warrants separate evaluation

---

## Supporting documents

| Document | Contents |
|---|---|
| `security-review.md` | All 15 findings with evidence, exploitation scenarios, remediation and verification steps |
| `mobile-inventory.md` | Technology stack, architecture, permissions, data-flow inventory |
| `dependency-report.md` | Dependency posture and supply-chain notes |
| `remediation-guide.md` | Copy-paste fixes in priority order |
| `findings.xlsx` | All findings as a filterable spreadsheet |
| `../automation/` | 171 Appium E2E test cases (169 executable + 2 declared not-applicable), including the privacy-posture tests referenced above |
