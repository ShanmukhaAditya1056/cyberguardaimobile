'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const nav = require('../../utils/navigator');
const dashboard = require('../../pages/dashboard.page');
const phishing = require('../../pages/phishing.page');
const malware = require('../../pages/malware.page');
const { getDriver } = require('../../drivers/driver-factory');
const { SAFE_WHITELISTED, DANGEROUS_DETERMINISTIC } = require('../../data/urls');

/**
 * Performance — on-device latency and memory.
 *
 * ── Why there is no 100-VU load test here ──────────────────────────────────
 * CyberGuard has no backend. Its only outbound calls go to Google Safe Browsing
 * and Have I Been Pwned, both third-party production services. Pointing a
 * sustained load test at either would be abuse, would breach their terms, and
 * would get the project's API keys revoked — so the suite does not do it, and
 * `automation/performance/` instead load-tests a local mock that implements the
 * same `ThreatIntelSource` contract.
 *
 * What is genuinely measurable on-device is measured here: cold start, scan
 * latency and memory growth. Thresholds are deliberately generous because CI
 * emulators are slow and shared — these catch regressions of an order of
 * magnitude, not 10% drift.
 */
describe('Performance — on-device latency', function () {
  this.timeout(env.timeouts.test * 2);

  const samples = [];

  const record = (metric, ms, threshold) => {
    samples.push({ metric, ms, threshold, at: new Date().toISOString() });
  };

  after(() => {
    // Persisted next to the reports so the perf numbers land in the artifacts
    // and can be trended across builds.
    const dir = path.join(env.reportsDir, 'JSON');
    fs.mkdirSync(dir, { recursive: true });
    const stats = {};
    for (const s of samples) {
      if (!stats[s.metric]) stats[s.metric] = { samples: [], threshold: s.threshold };
      stats[s.metric].samples.push(s.ms);
    }
    for (const [metric, data] of Object.entries(stats)) {
      const sorted = [...data.samples].sort((a, b) => a - b);
      data.min = sorted[0];
      data.max = sorted[sorted.length - 1];
      data.avg = Math.round(sorted.reduce((a, b) => a + b, 0) / sorted.length);
      data.p95 = sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * 0.95))];
    }
    fs.writeFileSync(
      path.join(dir, 'performance-results.json'),
      JSON.stringify({ generatedAt: new Date().toISOString(), metrics: stats, raw: samples }, null, 2),
      'utf8'
    );
  });

  tc(
    {
      id: 'TC_PERF_001',
      module: 'Performance',
      priority: 'P1',
      title: 'Cold start reaches an interactive dashboard within 15s',
      preconditions: 'App installed',
      steps: ['Terminate the app', 'Relaunch', 'Measure time until Scan Now is present'],
      expected: 'Under 15000ms on a CI emulator',
      rationale:
        'main() initialises Hive, notifications and warms three ML models before ' +
        'the first frame. A regression there is invisible until start-up crawls.',
    },
    async () => {
      const driver = getDriver();
      await driver.execute('mobile: terminateApp', { appId: env.device.appPackage });
      await driver.pause(1500);

      const t0 = Date.now();
      await driver.execute('mobile: activateApp', { appId: env.device.appPackage });
      await dashboard.waitUntilLoaded();
      const elapsed = Date.now() - t0;

      record('cold_start_ms', elapsed, 15000);
      assert.ok(elapsed < 15000, `cold start took ${elapsed}ms (budget 15000ms)`);
    }
  );

  tc(
    {
      id: 'TC_PERF_002',
      module: 'Performance',
      priority: 'P1',
      title: 'URL scan latency stays under 8s across 10 samples',
      preconditions: 'Phishing screen open',
      steps: ['Scan 10 URLs', 'Record each latency', 'Report min/avg/max/p95'],
      expected: 'Every sample under 8000ms',
      rationale:
        'This is the core interaction. It runs a rules engine plus a logistic ' +
        'regression entirely in Dart, so it should be tens of milliseconds — ' +
        'an 8s ceiling only catches catastrophic regressions.',
    },
    async () => {
      await nav.goTo('/phishing');
      await phishing.waitUntilLoaded();

      const corpus = [...SAFE_WHITELISTED, ...DANGEROUS_DETERMINISTIC].slice(0, 10);
      const timings = [];

      for (const entry of corpus) {
        const t0 = Date.now();
        await phishing.scanUrl(entry.url);
        const elapsed = Date.now() - t0;
        timings.push(elapsed);
        record('url_scan_ms', elapsed, 8000);
      }

      const worst = Math.max(...timings);
      const avg = Math.round(timings.reduce((a, b) => a + b, 0) / timings.length);
      assert.ok(
        worst < 8000,
        `slowest URL scan was ${worst}ms (avg ${avg}ms) against an 8000ms budget`
      );
    }
  );

  tc(
    {
      id: 'TC_PERF_003',
      module: 'Performance',
      priority: 'P1',
      title: 'Full app scan completes within 60s',
      preconditions: 'Malware screen open',
      steps: ['Run the installed-app scan', 'Measure wall clock'],
      expected: 'Under 60000ms',
      rationale:
        'Scales with installed package count. An emulator has few apps, so this ' +
        'is a floor check — a real device with 150 apps needs its own budget.',
    },
    async () => {
      await nav.goTo('/malware');
      await malware.waitUntilLoaded();

      const t0 = Date.now();
      await malware.runScan({ timeout: 60000 });
      const elapsed = Date.now() - t0;

      record('app_scan_ms', elapsed, 60000);
      assert.ok(elapsed < 60000, `app scan took ${elapsed}ms (budget 60000ms)`);
    }
  );

  tc(
    {
      id: 'TC_PERF_004',
      module: 'Performance',
      priority: 'P1',
      title: 'Memory does not grow unboundedly across 20 scans',
      preconditions: 'Phishing screen open',
      steps: [
        'Record baseline PSS',
        'Run 20 consecutive URL scans',
        'Record PSS again',
        'Compare growth',
      ],
      expected: 'Growth under 150MB',
      rationale:
        'Each scan allocates a tokenizer buffer and writes a Hive record. A ' +
        'retained reference here leaks steadily and eventually OOMs on a low-end ' +
        'device, which is the target market for this app.',
    },
    async () => {
      const driver = getDriver();

      const readPssKb = async () => {
        try {
          const out = await driver.execute('mobile: shell', {
            command: 'dumpsys',
            args: ['meminfo', env.device.appPackage],
          });
          const m = String(out).match(/TOTAL(?:\s+PSS)?:?\s+(\d+)/i);
          return m ? parseInt(m[1], 10) : null;
        } catch {
          return null;
        }
      };

      await nav.goTo('/phishing');
      await phishing.waitUntilLoaded();

      const before = await readPssKb();
      if (before === null) {
        // `mobile: shell` requires --relaxed-security. Skipping is honest;
        // asserting on a number we could not read would not be.
        this.skip();
        return;
      }

      for (let i = 0; i < 20; i += 1) {
        const entry = SAFE_WHITELISTED[i % SAFE_WHITELISTED.length];
        await phishing.scanUrl(entry.url);
      }

      const after = await readPssKb();
      const growthMb = Math.round(((after - before) / 1024) * 10) / 10;
      record('memory_growth_mb', growthMb, 150);

      assert.ok(
        growthMb < 150,
        `memory grew ${growthMb}MB across 20 scans (${before}KB -> ${after}KB), budget 150MB`
      );
    }
  );

  tc(
    {
      id: 'TC_PERF_005',
      module: 'Performance',
      priority: 'P2',
      title: 'Navigation between screens stays under 3s',
      preconditions: 'Dashboard open',
      steps: ['Navigate to six screens in turn', 'Measure each transition'],
      expected: 'Every transition under 3000ms',
    },
    async () => {
      const routes = ['/phishing', '/malware', '/breach', '/wifi', '/fusion', '/settings'];
      const slow = [];

      for (const route of routes) {
        await nav.toDashboard();
        const t0 = Date.now();
        await nav.goTo(route);
        const elapsed = Date.now() - t0;
        record(`nav_${route.replace(/\//g, '_')}_ms`, elapsed, 3000);
        if (elapsed >= 3000) slow.push(`${route} ${elapsed}ms`);
      }

      assert.deepStrictEqual(slow, [], `slow navigation transitions: ${slow.join(', ')}`);
    }
  );

  tc.notApplicable(
    {
      id: 'TC_PERF_LOAD_001',
      module: 'Performance',
      priority: 'P1',
      title: 'Baseline load test — 100 concurrent virtual users for 60s',
    },
    'The app has no backend of its own. Its only remote dependencies are Google ' +
      'Safe Browsing and Have I Been Pwned — third-party production services that ' +
      'must not be load-tested. The equivalent coverage runs against a local mock ' +
      'of the ThreatIntelSource contract: see automation/performance/k6-load-test.js.'
  );
});
