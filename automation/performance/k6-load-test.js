import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

/**
 * Load profile for the threat-intel client contract.
 *
 * TARGET IS ALWAYS LOCALHOST. `BASE_URL` defaults to the mock server in
 * `mock-threat-intel-server.js` and the script refuses to run against a
 * non-local host — see the guard in `setup()`. CyberGuard has no backend of its
 * own; its real endpoints belong to Google and Have I Been Pwned, and directing
 * 100 concurrent users at either would be an attack on a third party rather
 * than a test of this project.
 *
 * Scenarios (select with -e SCENARIO=...):
 *   baseline   100 VUs / 60s      — the requested baseline profile
 *   stress     200 -> 500 -> 1000 — find the breaking point
 *   spike      50 -> 500 -> 50    — recovery behaviour
 *   endurance  100 VUs / 30m      — leak and degradation detection
 *
 * Run:
 *   node automation/performance/mock-threat-intel-server.js &
 *   k6 run -e SCENARIO=baseline automation/performance/k6-load-test.js
 */

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8787';
const SCENARIO = __ENV.SCENARIO || 'baseline';

const safeBrowsingLatency = new Trend('safebrowsing_latency', true);
const hibpLatency = new Trend('hibp_latency', true);
const businessErrors = new Rate('business_errors');

const PROFILES = {
  baseline: {
    executor: 'constant-vus',
    vus: 100,
    duration: '60s',
  },
  stress: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 200 },
      { duration: '60s', target: 200 },
      { duration: '30s', target: 500 },
      { duration: '60s', target: 500 },
      { duration: '30s', target: 1000 },
      { duration: '60s', target: 1000 },
      { duration: '30s', target: 0 },
    ],
  },
  spike: {
    executor: 'ramping-vus',
    startVUs: 50,
    stages: [
      { duration: '30s', target: 50 },
      { duration: '10s', target: 500 },
      { duration: '60s', target: 500 },
      { duration: '10s', target: 50 },
      { duration: '60s', target: 50 },
    ],
  },
  endurance: {
    executor: 'constant-vus',
    vus: 100,
    duration: '30m',
  },
};

export const options = {
  scenarios: { [SCENARIO]: PROFILES[SCENARIO] || PROFILES.baseline },
  thresholds: {
    // Fail the run on genuine regressions, not on noise.
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500', 'p(99)<1500'],
    business_errors: ['rate<0.01'],
    safebrowsing_latency: ['p(95)<500'],
    hibp_latency: ['p(95)<500'],
  },
  summaryTrendStats: ['min', 'avg', 'med', 'p(95)', 'p(99)', 'max'],
};

const URLS = [
  'https://www.google.com',
  'https://amazon.in',
  'https://sbi-alert-verify-now-secure.xyz/kyc-update',
  'https://paytm-verify-kyc-update-now.tk/login',
  'https://claim-prize-winner-now.click/reward-claim',
  'https://example.com',
];

const HASH_PREFIXES = ['5BAA6', '21BD1', 'A94A8', '0D107', 'B1B37', 'F7C3B'];

export function setup() {
  // Hard guard: this script must never be pointed at a third-party service.
  const allowedHosts = ['127.0.0.1', 'localhost', '::1', 'host.docker.internal'];
  const host = BASE_URL.replace(/^https?:\/\//, '').split(':')[0].split('/')[0];
  if (!allowedHosts.includes(host)) {
    throw new Error(
      `Refusing to run: BASE_URL host "${host}" is not local. This profile drives ` +
        `100-1000 concurrent users and must only ever target the bundled mock ` +
        `server. Never point it at safebrowsing.googleapis.com or ` +
        `api.pwnedpasswords.com.`
    );
  }

  const health = http.get(`${BASE_URL}/health`);
  if (health.status !== 200) {
    throw new Error(
      `Mock server is not running at ${BASE_URL}. Start it with:\n` +
        `  node automation/performance/mock-threat-intel-server.js`
    );
  }
  return { startedAt: new Date().toISOString() };
}

export default function loadTest() {
  // ── Safe Browsing lookup shape ────────────────────────────────────────
  const url = URLS[Math.floor(Math.random() * URLS.length)];
  const sbPayload = JSON.stringify({
    client: { clientId: 'cyberguard-ai', clientVersion: '2.0.0' },
    threatInfo: {
      threatTypes: [
        'MALWARE',
        'SOCIAL_ENGINEERING',
        'UNWANTED_SOFTWARE',
        'POTENTIALLY_HARMFUL_APPLICATION',
      ],
      platformTypes: ['ANY_PLATFORM'],
      threatEntryTypes: ['URL'],
      threatEntries: [{ url }],
    },
  });

  const sbRes = http.post(
    `${BASE_URL}/v4/threatMatches:find?key=load-test-key`,
    sbPayload,
    { headers: { 'Content-Type': 'application/json' }, tags: { endpoint: 'safebrowsing' } }
  );
  safeBrowsingLatency.add(sbRes.timings.duration);

  const sbOk = check(sbRes, {
    'safebrowsing: 200': (r) => r.status === 200,
    'safebrowsing: parseable JSON': (r) => {
      try {
        JSON.parse(r.body);
        return true;
      } catch {
        return false;
      }
    },
  });
  businessErrors.add(!sbOk);

  // ── HIBP k-anonymity range shape ──────────────────────────────────────
  const prefix = HASH_PREFIXES[Math.floor(Math.random() * HASH_PREFIXES.length)];
  const hibpRes = http.get(`${BASE_URL}/range/${prefix}`, {
    tags: { endpoint: 'hibp' },
  });
  hibpLatency.add(hibpRes.timings.duration);

  const hibpOk = check(hibpRes, {
    'hibp: 200': (r) => r.status === 200,
    'hibp: returns suffix:count lines': (r) => /^[0-9A-F]{35}:\d+/m.test(r.body),
  });
  businessErrors.add(!hibpOk);

  sleep(0.1 + Math.random() * 0.4);
}

export function handleSummary(data) {
  const m = data.metrics;
  const get = (name, stat) => (m[name] && m[name].values ? m[name].values[stat] : null);
  const round = (v) => (v === null || v === undefined ? null : Math.round(v * 100) / 100);

  const summary = {
    scenario: SCENARIO,
    target: BASE_URL,
    note:
      'Executed against the bundled local mock of the ThreatIntelSource contract. ' +
      'The app has no backend; its real endpoints are third-party production ' +
      'services and are never load-tested.',
    generatedAt: new Date().toISOString(),
    requests: {
      total: get('http_reqs', 'count'),
      perSecond: round(get('http_reqs', 'rate')),
      failedRate: round(get('http_req_failed', 'rate')),
    },
    responseTimeMs: {
      min: round(get('http_req_duration', 'min')),
      avg: round(get('http_req_duration', 'avg')),
      median: round(get('http_req_duration', 'med')),
      p95: round(get('http_req_duration', 'p(95)')),
      p99: round(get('http_req_duration', 'p(99)')),
      max: round(get('http_req_duration', 'max')),
    },
    thresholdsPassed: Object.values(data.metrics).every(
      (metric) =>
        !metric.thresholds ||
        Object.values(metric.thresholds).every((t) => t.ok !== false)
    ),
  };

  return {
    stdout: buildTextSummary(summary),
    'reports/JSON/load-test-results.json': JSON.stringify(summary, null, 2),
  };
}

function buildTextSummary(s) {
  return [
    '',
    '═══════════════════════════════════════════════════════════',
    ` Load test — ${s.scenario}`,
    ` Target: ${s.target}`,
    '═══════════════════════════════════════════════════════════',
    '',
    ` Requests per second : ${s.requests.perSecond} req/sec`,
    ` Total requests      : ${s.requests.total}`,
    ` Error rate          : ${(s.requests.failedRate * 100).toFixed(2)}%`,
    '',
    ' Response times',
    `   Minimum : ${s.responseTimeMs.min} ms`,
    `   Average : ${s.responseTimeMs.avg} ms`,
    `   Median  : ${s.responseTimeMs.median} ms`,
    `   P95     : ${s.responseTimeMs.p95} ms`,
    `   P99     : ${s.responseTimeMs.p99} ms`,
    `   Maximum : ${s.responseTimeMs.max} ms`,
    '',
    ` Thresholds: ${s.thresholdsPassed ? 'PASSED' : 'FAILED'}`,
    '',
    ` Note: ${s.note}`,
    '',
  ].join('\n');
}
