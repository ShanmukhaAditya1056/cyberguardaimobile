'use strict';

/**
 * Local stand-in for the app's remote threat-intel dependencies.
 *
 * WHY THIS EXISTS
 * CyberGuard ships no backend. The only HTTP endpoints it talks to are
 * Google Safe Browsing (`threatMatches:find`) and Have I Been Pwned
 * (`range/{prefix}`), both third-party production services. A 100-VU load test
 * aimed at either would be a denial-of-service attempt against someone else's
 * infrastructure, would violate their acceptable-use terms, and would get the
 * project's API keys revoked.
 *
 * This server implements the same two request/response shapes the app's
 * `SafeBrowsingSource` and `HibpService` consume, so the load profile exercises
 * the same payload sizes, status codes and error paths — against localhost.
 * What it measures is the client contract and the harness, not Google's
 * capacity, which was never a meaningful thing for this project to measure.
 *
 * Run:  node automation/performance/mock-threat-intel-server.js
 *       PORT=8787 node automation/performance/mock-threat-intel-server.js
 */

const http = require('http');
const crypto = require('crypto');

const PORT = parseInt(process.env.PORT || '8787', 10);

/** Deterministic "malicious" set so load results are reproducible. */
const MALICIOUS_HOSTS = new Set([
  'sbi-alert-verify-now-secure.xyz',
  'paytm-verify-kyc-update-now.tk',
  'claim-prize-winner-now.click',
  'secure-hdfc-netbanking-login-verify.ml',
]);

/** Simulates realistic upstream latency without a real network. */
function simulatedLatencyMs() {
  // Log-normal-ish: mostly fast, occasional slow response.
  const base = 12 + Math.random() * 28;
  return Math.random() < 0.03 ? base + 250 + Math.random() * 500 : base;
}

function readBody(req) {
  return new Promise((resolve) => {
    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
      if (data.length > 1e6) req.destroy(); // basic guard
    });
    req.on('end', () => resolve(data));
  });
}

/** Google Safe Browsing v4 `threatMatches:find` response shape. */
function safeBrowsingResponse(body) {
  let parsed;
  try {
    parsed = JSON.parse(body || '{}');
  } catch {
    return { status: 400, payload: { error: { code: 400, message: 'Malformed JSON' } } };
  }

  const entries =
    (parsed.threatInfo && parsed.threatInfo.threatEntries) || [];
  const matches = [];

  for (const entry of entries) {
    let host = '';
    try {
      host = new URL(entry.url).hostname;
    } catch {
      continue;
    }
    if (MALICIOUS_HOSTS.has(host)) {
      matches.push({
        threatType: 'SOCIAL_ENGINEERING',
        platformType: 'ANY_PLATFORM',
        threatEntryType: 'URL',
        threat: { url: entry.url },
        cacheDuration: '300s',
      });
    }
  }

  // Safe Browsing returns `{}` when nothing matches — the app relies on that.
  return { status: 200, payload: matches.length ? { matches } : {} };
}

/** HIBP k-anonymity `range/{prefix}` response: newline-separated SUFFIX:COUNT. */
function hibpRangeResponse(prefix) {
  if (!/^[0-9A-F]{5}$/i.test(prefix)) {
    return { status: 400, payload: 'The hash prefix was not in a valid format' };
  }
  // Deterministic pseudo-random set derived from the prefix so a given prefix
  // always returns the same body — required for stable load-test assertions.
  const seed = crypto.createHash('sha1').update(prefix).digest('hex').toUpperCase();
  const lines = [];
  for (let i = 0; i < 400; i += 1) {
    const suffix = crypto
      .createHash('sha1')
      .update(seed + i)
      .digest('hex')
      .toUpperCase()
      .slice(0, 35);
    lines.push(`${suffix}:${(i * 7) % 5000}`);
  }
  return { status: 200, payload: lines.join('\r\n') };
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const started = process.hrtime.bigint();

  await new Promise((r) => setTimeout(r, simulatedLatencyMs()));

  let result;
  if (url.pathname === '/v4/threatMatches:find' && req.method === 'POST') {
    if (!url.searchParams.get('key')) {
      result = { status: 400, payload: { error: { code: 400, message: 'API key not valid' } } };
    } else {
      result = safeBrowsingResponse(await readBody(req));
    }
  } else if (url.pathname.startsWith('/range/') && req.method === 'GET') {
    result = hibpRangeResponse(url.pathname.slice('/range/'.length));
  } else if (url.pathname === '/health') {
    result = { status: 200, payload: { ok: true, uptime: process.uptime() } };
  } else {
    result = { status: 404, payload: { error: 'Not found' } };
  }

  const isJson = typeof result.payload === 'object';
  const body = isJson ? JSON.stringify(result.payload) : String(result.payload);
  const elapsedMs = Number(process.hrtime.bigint() - started) / 1e6;

  res.writeHead(result.status, {
    'Content-Type': isJson ? 'application/json' : 'text/plain',
    'Content-Length': Buffer.byteLength(body),
    'X-Mock-Latency-Ms': elapsedMs.toFixed(2),
  });
  res.end(body);
});

if (require.main === module) {
  server.listen(PORT, '127.0.0.1', () => {
    console.log(`Mock threat-intel server listening on http://127.0.0.1:${PORT}`);
    console.log('  POST /v4/threatMatches:find?key=...   (Safe Browsing shape)');
    console.log('  GET  /range/{5-hex-prefix}            (HIBP k-anonymity shape)');
    console.log('  GET  /health');
  });
}

module.exports = { server, PORT };
