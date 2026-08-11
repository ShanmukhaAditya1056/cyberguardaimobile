# CyberGuard AI — Web (MERN)

The browser build of CyberGuard AI: **M**ongoDB, **E**xpress, **R**eact,
**N**ode.

This is not Flutter web. The detection engines are re-implemented in JavaScript
and run server-side, reading the very same JSON model exports the mobile app
bundles at `assets/models/` — not a copy, the same files. A copy would drift
the first time someone retrains a model and updates only one of them, and then
the phone and the browser would disagree about whether a URL is phishing.

```
web/
├── server/          Express + Mongoose API, and the ported engines
│   ├── src/engines/     phishing, malware, wifi, breach, scoring
│   ├── src/models/      Mongoose schemas
│   ├── src/routes/      REST endpoints
│   └── test/            53 tests, no database required
└── client/          React 18 + Vite
    └── src/pages/       dashboard, scanners, alerts, settings
```

---

## Quick start

Requires **Node 20+** and a MongoDB instance (local or Atlas).

```bash
cd web
npm install

cp server/.env.example server/.env
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
# paste that into JWT_SECRET in server/.env

npm run dev
```

- API → <http://localhost:4000>
- Client → <http://localhost:5173>

### One login for the app and the browser

Set `FIREBASE_PROJECT_ID` in `server/.env` to the project the Android app
authenticates against — the `project_id` in `android/app/google-services.json` —
and copy `client/.env.example` to `client/.env.local` with the config from
**Firebase console → that project → Add app → Web**.

The browser then signs in through Firebase and trades the resulting ID token
for this API's session cookie exactly once, at `POST /api/auth/session`. An
account created on the phone signs in here, and one created here signs in on
the phone. The token is never stored — the cookie remains the only credential
the page holds, and it is httpOnly.

Leave both unset and nothing breaks: the local email/password accounts below
remain the way in, and the sign-in screen says plainly that they are not shared
with the app. That is also the state CI runs in, which is why the test suites
need no Firebase credentials.

Vite proxies `/api` to the server, so the browser stays on one origin in
development and the session cookie behaves exactly as it will in production.
Pointing the client straight at `:4000` would make every request cross-origin
and hide cookie problems until deploy.

Check `GET /api/health` — it reports which models loaded.

### Production

```bash
npm run build          # client → web/client/dist
NODE_ENV=production npm start
```

Serve `client/dist` from any static host and set `CORS_ORIGINS` to its origin.
`JWT_SECRET` is **required** in production — the server refuses to start
without it rather than falling back to a default published in this repository.

---

## Testing

```bash
npm test --workspace server      # 53 tests, no database needed
npm run test:e2e --workspace server   # full round-trip, needs MongoDB
```

The main suite covers the engines, the routes, validation and the auth
boundary, and deliberately needs no database so it runs on a clean checkout.
The e2e harness creates a throwaway database and drops it afterwards; it covers
sessions, per-account history, the Evil Twin comparison, and the isolation
checks proving one account cannot read or delete another's data.

### Engine parity

The engines exist twice — Dart for the app, JavaScript here — and nothing can
assert equivalence across two languages in one process. Instead both sides pin
the same numbers for the same inputs:

- `test/engine_parity_test.dart` (Dart)
- `web/server/test/engines.test.js` (Node)

The list sizes in `threatPatterns.js` are asserted too, so adding a bank to one
whitelist and not the other fails a test rather than silently making the phone
and the browser disagree.

---

## Visual parity with the app

The web build is not a separate design that happens to share a palette. Every
colour, radius, font size and shadow in `client/src/index.css` is lifted from a
named Dart source, and the comment above each block says which one — the tinted
tile/accent pairs from `module_card.dart` and `stats_row.dart`, the hero tile
from `_ScoreHeader`, the badge's 20%→10% gradient from `risk_badge.dart`. Where
a number looks oddly precise (11.5px, 10.5px, −0.3px tracking) it is because
the Flutter widget uses exactly that.

Three things follow from taking that literally:

**Inter is loaded from `assets/fonts/`, not copied.** The CSS used to name
Inter without ever loading it, so the browser quietly fell back to Segoe UI on
Windows while every other value matched. The `@fonts` alias in `vite.config.js`
points at the Flutter asset directory — the same reasoning that has the server
read `assets/models/` in place.

**The content column is a phone's width**, not the browser's. A two-column
module grid stretched across 900px would share every colour with the app and
match none of its proportions.

**There is no nav bar.** `CyberGuardBottomNav` exists in `lib/shared/widgets/`
but nothing mounts it and it is still painted in the retired dark-glass style,
so copying it would have made the web build look *less* like the shipped app.
Navigation is the app's: the dashboard's module grid is the hub, every module
screen carries a back arrow, and the app bar holds only the alerts bell and the
settings gear. Sign-out is on Settings, where the app puts it.

The Material icons are redrawn as inline SVG in `client/src/components/
icons.jsx`, on the same 24px grid, each named after the `Icons.*` constant it
stands in for. They are not the Material font: shipping a second copy of it
would be waste, and pulling it from Google's CDN would break the "one outbound
dependency" promise below, which is a privacy claim rather than a performance
note.

---

## What the browser cannot do

Three modules work differently here, for reasons no amount of code can fix.

**App scanner.** No web API exposes an installed-app list — by design. So the
permission set is entered by hand (Play Store listings show it under "App
permissions"), and the same rules engine and RF/LightGBM/GNN ensemble score it.

**Wi-Fi.** A browser cannot read the SSID, BSSID, signal or cipher of the
network it is on. Details are entered from the network's sign or the user's
phone, and the same rules and Isolation Forest run over them. The DNS-health
and latency checks the app measures directly are omitted rather than assumed —
scoring an unmeasured check as failed would dock 20 points from every scan for
something the platform simply cannot see.

**SMS guard.** A web page can never be handed incoming messages. The
"paste a message" tab is the stand-in: it runs the same URL extraction and
scoring the live guard runs.

**Screenshot scanner.** ML Kit is mobile-only, and uploading a screenshot — the
input most likely to contain a bank balance or an OTP — to a cloud OCR service
would contradict the whole module. So the Defence page asks for the text and
runs the identical classifier over it.

The Smart Link Interceptor has no web equivalent at all: it needs the system
default-browser role.

### Proactive defence

The four features on the Defence page are full ports, not stand-ins:

- **Threat Fusion** reconciles several detection sources into one explainable
  verdict, weighted by trust × confidence.
- **Arbitration** is the rule that makes it worth doing: a sufficiently trusted
  feed that flags a URL floors the score into the dangerous band even when the
  local model called it clean. A trusted override is never silently allowed —
  at minimum it becomes a warning.
- **The arbitration log** records only the disputed runs — conflicts and
  overrides. Unanimous verdicts are not logged, because burying five
  disagreements in ten thousand agreements defeats the point of an audit trail.
- **Predictive Risk** scores how likely you are to be *targeted*, from your own
  last 7 days. Note it runs opposite to the security score: higher is worse.

External reputation feeds are off by default, mirroring the app's cloud-intel
opt-in. With them off only CyberGuard's own engine votes, and nothing leaves
the server.

---

## Privacy

The mobile app's guarantee is "no data leaves the phone". A server-backed web
app cannot claim that, so here is what is actually true.

**Passwords never reach the server.** The browser hashes with WebCrypto and
splits before the request: `POST /api/breach/password` accepts a 5-character
hash `prefix` and a 35-character `suffix`, and the schema *rejects* anything
else — a client that tried to send a password would be turned away, not quietly
relayed onward. Only the prefix goes to Have I Been Pwned; the suffix is
matched locally against the ~500 hashes sharing that prefix. Same k-anonymity
protocol as the app, same one Google's Password Checkup uses. See
`client/src/lib/kAnonymity.js`.

**Email addresses are not stored.** Account lookups need the address (HIBP's
account endpoint has no k-anonymity equivalent), but only the masked form and
the SHA-1 prefix are returned, and only the prefix is written to history — the
same substitution the app makes before writing to Hive.

**Firebase never hands the page a stored token.** When shared login is on, the
ID token exists for one request — the exchange at `/api/auth/session` — and is
then dropped. What persists is the same httpOnly cookie the local accounts use,
so enabling shared login does not widen what an XSS could reach.

**Sessions are httpOnly cookies, not localStorage.** A tool whose job is
judging hostile input must assume an XSS will eventually land somewhere in its
UI, and a token in localStorage is readable by any script on the page.

**History is scoped and expiring.** Every document is scoped by account and
every query filters on it. A 90-day TTL index matches the app's
`retentionDays`. Settings → Clear all history deletes everything in one action
without closing the account.

**One outbound dependency.** `api.pwnedpasswords.com` and, when a key is
configured, `haveibeenpwned.com`. Nothing else — no analytics, no CDN, no
error reporting.

---

## Configuration

See `server/.env.example`. Two notes:

- **`HIBP_API_KEY` is optional.** Without it, password checks still use the
  free range API, and account lookups fall back to the offline dataset — ten
  real historical breaches, matched to an address deterministically by hash
  rather than by lookup. Every such response carries `source: 'offline'` and
  the UI labels it, because presenting it as a genuine HIBP result would be a
  lie about someone's security posture.
- **`CORS_ORIGINS` cannot be a wildcard.** `credentials: true` makes that
  illegal, which is why the allowed origins are an explicit list.

---

## API

| Method | Path | Auth |
|---|---|---|
| `GET` | `/api/health` | — |
| `POST` | `/api/auth/register` · `/login` · `/logout` | — |
| `POST` | `/api/auth/session` (Firebase ID token → cookie) | — |
| `GET` | `/api/auth/me` | required |
| `PATCH` | `/api/auth/settings` | required |
| `POST` | `/api/phishing/scan` · `/scan-text` | optional |
| `GET`/`DELETE` | `/api/phishing/history[/:id]` | required |
| `POST` | `/api/malware/scan` · `/scan-batch` | optional |
| `GET` | `/api/malware/permissions` | — |
| `POST` | `/api/breach/password` · `/account` | optional |
| `POST` | `/api/wifi/analyze` | optional |
| `GET`/`DELETE` | `/api/wifi/known-networks[/:id]` | required |
| `POST` | `/api/defense/scan` (threat fusion) | optional |
| `GET`/`DELETE` | `/api/defense/arbitration[/:id]` | required |
| `GET` | `/api/defense/risk` | required |
| `POST` | `/api/defense/screenshot` (scam text) | optional |
| `GET` | `/api/dashboard` | required |
| `GET`/`PATCH`/`DELETE` | `/api/dashboard/alerts[...]` | required |
| `DELETE` | `/api/dashboard/history` | required |

"Optional" means a signed-out visitor gets the same verdict — every engine runs
on the submitted input alone. There is simply nowhere to file the result.
Gating a safety check behind a signup would be the wrong default for this app.
