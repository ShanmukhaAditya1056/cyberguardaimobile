/**
 * End-to-end harness: the full API against a real MongoDB.
 *
 *   npm run test:e2e --workspace server
 *
 * Kept out of `npm test` on purpose — that suite has to run on a clean
 * checkout with nothing installed, so it covers the stateless half of the API
 * only. Everything that needs a database lives here: sessions, per-account
 * history, the Evil Twin comparison, and the isolation checks that prove one
 * account cannot read or delete another's data.
 *
 * Creates a uniquely-named throwaway database and drops it on the way out, so
 * it never touches a real one.
 */
import mongoose from 'mongoose';
import { createApp } from '../src/app.js';
import { loadModels } from '../src/engines/modelStore.js';

/**
 * Honours MONGO_URI so CI can point at a service container, but always
 * replaces the database name with a unique throwaway one. That is deliberate:
 * this script calls `dropDatabase()` on the way out, and inheriting a name
 * from the environment would mean a mistyped variable wipes a real database.
 */
function throwawayDatabaseUri() {
  const base = process.env.MONGO_URI ?? 'mongodb://127.0.0.1:27017';
  const name = `cyberguard_e2e_${Date.now()}`;
  try {
    const url = new URL(base);
    url.pathname = `/${name}`;
    return url.toString();
  } catch {
    return `mongodb://127.0.0.1:27017/${name}`;
  }
}

const DB = throwawayDatabaseUri();
await loadModels();
await mongoose.connect(DB);
console.log(`[e2e] using ${DB.replace(/\/\/[^@]*@/, '//***@')}`);

const server = createApp().listen(0);
await new Promise((r) => server.once('listening', r));
const base = `http://127.0.0.1:${server.address().port}`;

let failures = 0;
const check = async (name, fn) => {
  try {
    await fn();
    console.log(`  PASS  ${name}`);
  } catch (e) {
    failures++;
    console.log(`  FAIL  ${name}\n        ${e.message}`);
  }
};

// Minimal cookie jar — the session is httpOnly, so fetch will not carry it
// between calls on its own.
function jar() {
  let cookie = '';
  return {
    async call(path, { method = 'GET', body } = {}) {
      const res = await fetch(base + path, {
        method,
        headers: {
          ...(body ? { 'Content-Type': 'application/json' } : {}),
          ...(cookie ? { Cookie: cookie } : {}),
        },
        body: body ? JSON.stringify(body) : undefined,
      });
      const setCookie = res.headers.getSetCookie?.() ?? [];
      if (setCookie.length) {
        cookie = setCookie.map((c) => c.split(';')[0]).join('; ');
      }
      let json = null;
      try {
        json = await res.json();
      } catch {
        /* no body */
      }
      return { status: res.status, body: json };
    },
  };
}

const alice = jar();
const bob = jar();

await check('register issues a session', async () => {
  const r = await alice.call('/api/auth/register', {
    method: 'POST',
    body: {
      email: 'alice@example.com',
      password: 'correct-horse-battery',
      displayName: 'Alice',
    },
  });
  if (r.status !== 201) throw new Error(`status ${r.status}: ${JSON.stringify(r.body)}`);
  if (r.body.user.email !== 'alice@example.com') throw new Error('wrong user');
});

await check('the session survives to /auth/me', async () => {
  const r = await alice.call('/api/auth/me');
  if (r.status !== 200) throw new Error(`status ${r.status}`);
});

await check('the password hash is never returned', async () => {
  const r = await alice.call('/api/auth/me');
  if (JSON.stringify(r.body).includes('passwordHash')) throw new Error('hash leaked');
});

await check('duplicate registration is rejected with 409', async () => {
  const r = await jar().call('/api/auth/register', {
    method: 'POST',
    body: { email: 'alice@example.com', password: 'another-long-password' },
  });
  if (r.status !== 409) throw new Error(`status ${r.status}`);
});

await check('a wrong password looks identical to an unknown account', async () => {
  const known = await jar().call('/api/auth/login', {
    method: 'POST',
    body: { email: 'alice@example.com', password: 'wrong-but-long-enough' },
  });
  const unknown = await jar().call('/api/auth/login', {
    method: 'POST',
    body: { email: 'nobody@example.com', password: 'wrong-but-long-enough' },
  });
  if (known.status !== 401 || unknown.status !== 401) throw new Error('statuses differ');
  if (known.body.error !== unknown.body.error) {
    throw new Error(`messages differ: "${known.body.error}" vs "${unknown.body.error}"`);
  }
});

await check('a phishing scan is written to history', async () => {
  await alice.call('/api/phishing/scan', {
    method: 'POST',
    body: { url: 'http://sbi-verify.tk/kyc-update' },
  });
  const r = await alice.call('/api/phishing/history');
  if (r.body.scans.length !== 1) throw new Error(`scans: ${r.body.scans.length}`);
  if (r.body.scans[0].verdict !== 'phishing') throw new Error(`verdict ${r.body.scans[0].verdict}`);
});

await check('a phishing verdict raises an alert', async () => {
  const r = await alice.call('/api/dashboard/alerts');
  if (r.body.alerts.length < 1) throw new Error('no alerts');
  if (r.body.alerts[0].module !== 'phishing') throw new Error('wrong module');
});

await check('the dashboard reflects the scan', async () => {
  const r = await alice.call('/api/dashboard');
  if (typeof r.body.score !== 'number') throw new Error('no score');
  if (r.body.unreadAlerts < 1) throw new Error(`unread count is ${r.body.unreadAlerts}`);
  if (r.body.recentScans.length < 1) throw new Error('no recent scans');
});

await check('the Evil Twin check fires on a changed BSSID', async () => {
  await alice.call('/api/wifi/analyze', {
    method: 'POST',
    body: { ssid: 'CafeWiFi', bssid: 'aa:bb:cc:dd:ee:01', security: 'WPA2' },
  });
  const r = await alice.call('/api/wifi/analyze', {
    method: 'POST',
    body: { ssid: 'CafeWiFi', bssid: 'aa:bb:cc:dd:ee:99', security: 'WPA2' },
  });
  const consistency = r.body.result.checks.find((c) => c.name === 'BSSID Consistency');
  if (consistency.passed) throw new Error('Evil Twin not detected');
});

await check('breach history stores only the hash prefix', async () => {
  await alice.call('/api/breach/account', {
    method: 'POST',
    body: { email: 'someone@yahoo.com' },
  });
  const r = await alice.call('/api/breach/history');
  const scan = r.body.scans[0];
  if (scan.input.length !== 5) throw new Error(`stored input: ${scan.input}`);
  if (JSON.stringify(scan).includes('someone@yahoo.com')) {
    throw new Error('full address was stored');
  }
});

await check('one account cannot see another history', async () => {
  await bob.call('/api/auth/register', {
    method: 'POST',
    body: { email: 'bob@example.com', password: 'a-different-long-password' },
  });
  const r = await bob.call('/api/phishing/history');
  if (r.body.scans.length !== 0) throw new Error(`bob sees ${r.body.scans.length} scans`);
  const d = await bob.call('/api/dashboard');
  if (d.body.recentScans.length !== 0) throw new Error('bob sees alice on the dashboard');
});

await check('one account cannot delete another scan', async () => {
  const alices = (await alice.call('/api/phishing/history')).body.scans;
  const r = await bob.call(`/api/phishing/history/${alices[0]._id}`, { method: 'DELETE' });
  if (r.status !== 404) throw new Error(`status ${r.status}`);
  const after = (await alice.call('/api/phishing/history')).body.scans;
  if (after.length !== alices.length) throw new Error('the scan was deleted');
});

await check('saveScanHistory off stops writes but still scans', async () => {
  await alice.call('/api/auth/settings', {
    method: 'PATCH',
    body: { saveScanHistory: false },
  });
  const before = (await alice.call('/api/phishing/history')).body.scans.length;
  const scan = await alice.call('/api/phishing/scan', {
    method: 'POST',
    body: { url: 'http://evil-2.tk/login' },
  });
  if (!scan.body.result.isPhishing) throw new Error('scan did not run');
  const after = (await alice.call('/api/phishing/history')).body.scans.length;
  if (after !== before) throw new Error(`history grew ${before} -> ${after}`);
  await alice.call('/api/auth/settings', {
    method: 'PATCH',
    body: { saveScanHistory: true },
  });
});

await check('clear-history affects only the calling account', async () => {
  await bob.call('/api/phishing/scan', {
    method: 'POST',
    body: { url: 'http://bobs-link.tk/x' },
  });
  await alice.call('/api/dashboard/history', { method: 'DELETE' });
  const a = await alice.call('/api/phishing/history');
  if (a.body.scans.length !== 0) throw new Error('alice still has history');
  const b = await bob.call('/api/phishing/history');
  if (b.body.scans.length !== 1) throw new Error('bob history was destroyed too');
});

await check('a trusted feed overrules a clean local verdict', async () => {
  // account-services-portal.com looks innocuous to the rules engine but is on
  // the reputation blocklist — the exact case arbitration exists for.
  const r = await bob.call('/api/defense/scan', {
    method: 'POST',
    body: { url: 'https://account-services-portal.com/login', cloudIntel: true },
  });
  const result = r.body.result;
  if (!result.overrideApplied) throw new Error('no override was applied');
  if (!result.hasConflict) throw new Error('the disagreement was not recorded');
  if (result.action === 'allow') throw new Error('an overridden link was allowed');
});

await check('the override is written to the arbitration log', async () => {
  const log = await bob.call('/api/defense/arbitration');
  if (log.body.entries.length < 1) throw new Error('nothing was logged');
  if (log.body.summary.overrides < 1) throw new Error('override not counted');
});

await check('a unanimous verdict is not logged', async () => {
  const before = (await bob.call('/api/defense/arbitration')).body.entries.length;
  await bob.call('/api/defense/scan', {
    method: 'POST',
    body: { url: 'https://google.com', cloudIntel: false },
  });
  const after = (await bob.call('/api/defense/arbitration')).body.entries.length;
  if (after !== before) throw new Error('an undisputed run was logged');
});

await check('predictive risk reflects the account history', async () => {
  const r = await bob.call('/api/defense/risk');
  if (typeof r.body.assessment.riskScore !== 'number') throw new Error('no score');
  if (!Array.isArray(r.body.assessment.forecast)) throw new Error('no forecast');
  if (r.body.signals.suspiciousSms !== 0) {
    throw new Error('the web build has no SMS inbox; this must be 0');
  }
});

await check('the arbitration log is per-account', async () => {
  const r = await alice.call('/api/defense/arbitration');
  if (r.body.entries.length !== 0) throw new Error("alice sees bob's entries");
});

await check('scam text classifier scores a pasted message', async () => {
  const r = await bob.call('/api/defense/screenshot', {
    method: 'POST',
    body: { text: 'Congratulations! You have won a prize. Share OTP immediately.' },
  });
  if (!r.body.result.isScam) throw new Error('lottery scam not detected');
});

await check('logout invalidates the session', async () => {
  await alice.call('/api/auth/logout', { method: 'POST' });
  const r = await alice.call('/api/auth/me');
  if (r.status !== 401) throw new Error(`status ${r.status}`);
});

await mongoose.connection.dropDatabase();
await mongoose.disconnect();
server.close();
console.log(
  failures === 0 ? '\nAll end-to-end checks passed.' : `\n${failures} check(s) failed.`,
);
process.exit(failures === 0 ? 0 : 1);
