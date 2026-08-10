import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';

import { createApp } from '../src/app.js';
import { loadModels } from '../src/engines/modelStore.js';

/**
 * Route-level checks against a real HTTP server.
 *
 * Deliberately no MongoDB: everything below exercises the stateless half of
 * the API — the scanning routes, validation and the auth boundary — so the
 * suite runs on a clean checkout with nothing installed. The history and
 * session routes need a database and are covered by `historyService` usage in
 * the app rather than here.
 */

let server;
let base;

before(async () => {
  await loadModels();
  server = createApp().listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => {
  server?.close();
});

const post = (path, body) =>
  fetch(base + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

describe('health', () => {
  it('reports which engines loaded', async () => {
    const res = await fetch(`${base}/api/health`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.ok, true);
    assert.ok('phishing' in body.engines);
    assert.ok('wifi' in body.engines);
  });
});

describe('phishing routes', () => {
  it('flags a phishing URL and runs the model', async () => {
    const { result } = await (
      await post('/api/phishing/scan', {
        url: 'http://secure-hdfc-verify.tk/kyc-update',
      })
    ).json();
    assert.equal(result.isPhishing, true);
    assert.ok(result.shapReasons.length > 0);
  });

  it('clears a whitelisted bank at the fixed confidence', async () => {
    const { result } = await (
      await post('/api/phishing/scan', { url: 'https://onlinesbi.sbi' })
    ).json();
    assert.equal(result.isPhishing, false);
    assert.equal(result.confidence, 96);
  });

  it('extracts and scans every link in pasted text', async () => {
    const body = await (
      await post('/api/phishing/scan-text', {
        text: 'KYC pending. Verify at http://sbi-verify.tk/update or www.example.com',
      })
    ).json();
    assert.equal(body.urlsFound, 2);
    assert.ok(body.worst, 'expected the phishing link to be identified');
  });
});

describe('malware routes', () => {
  it('scores a submitted permission set', async () => {
    const { result } = await (
      await post('/api/malware/scan', {
        appName: 'Fast Loan',
        permissions: [
          'android.permission.READ_SMS',
          'android.permission.BIND_ACCESSIBILITY_SERVICE',
        ],
        isFromTrustedStore: false,
      })
    ).json();
    assert.equal(typeof result.riskScore, 'number');
    assert.ok(['low', 'medium', 'high', 'critical'].includes(result.riskLevel));
  });

  it('serves the permission catalogue for the client checklist', async () => {
    const { permissions } = await (
      await fetch(`${base}/api/malware/permissions`)
    ).json();
    assert.equal(permissions.length, 35);
    assert.ok(permissions.every((p) => p.permission && p.danger && p.shortName));
  });

  it('rejects an oversized batch rather than accepting the work', async () => {
    const res = await post('/api/malware/scan-batch', {
      apps: Array.from({ length: 501 }, () => ({ appName: 'x' })),
    });
    assert.equal(res.status, 400);
  });
});

describe('wifi routes', () => {
  it('scores an open network below an encrypted one', async () => {
    const open = await (
      await post('/api/wifi/analyze', { ssid: 'Free', security: 'Open', rssi: -55 })
    ).json();
    const wpa = await (
      await post('/api/wifi/analyze', { ssid: 'Home', security: 'WPA2', rssi: -55 })
    ).json();
    assert.ok(open.result.trustScore < wpa.result.trustScore);
  });

  it('rejects a malformed BSSID', async () => {
    const res = await post('/api/wifi/analyze', {
      ssid: 'Home',
      bssid: 'not-a-mac',
    });
    assert.equal(res.status, 400);
  });
});

describe('breach routes', () => {
  it('refuses anything that is not a hash prefix and suffix', async () => {
    // The schema is what enforces the privacy guarantee: a client that tried
    // to send the password itself must be rejected, never relayed onward.
    for (const body of [
      { prefix: 'hunter2', suffix: 'x' },
      { prefix: '5BAA6', suffix: 'too-short' },
      { password: 'hunter2' },
    ]) {
      const res = await post('/api/breach/password', body);
      assert.equal(res.status, 400, JSON.stringify(body));
    }
  });

  it('rejects a malformed email on the account route', async () => {
    const res = await post('/api/breach/account', { email: 'not-an-email' });
    assert.equal(res.status, 400);
  });
});

describe('auth boundary', () => {
  it('requires a session for every history route', async () => {
    for (const path of [
      '/api/dashboard',
      '/api/dashboard/alerts',
      '/api/phishing/history',
      '/api/malware/history',
      '/api/breach/history',
      '/api/wifi/history',
      '/api/wifi/known-networks',
      '/api/auth/me',
    ]) {
      const res = await fetch(base + path);
      assert.equal(res.status, 401, `${path} was not protected`);
    }
  });

  it('lets a signed-out visitor still scan', async () => {
    // Every engine works on the submitted input alone. Refusing to answer
    // without an account would gate a safety check behind a signup.
    const res = await post('/api/phishing/scan', { url: 'https://example.org' });
    assert.equal(res.status, 200);
    assert.equal((await res.json()).signedIn, false);
  });
});

describe('error handling', () => {
  it('returns a JSON 404 for an unknown route', async () => {
    const res = await fetch(`${base}/api/nope`);
    assert.equal(res.status, 404);
    assert.ok((await res.json()).error);
  });

  it('returns field-level detail for a validation failure', async () => {
    const res = await post('/api/phishing/scan', { url: '' });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.ok(Array.isArray(body.details) && body.details.length > 0);
  });
});
