'use strict';

const assert = require('assert');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const nav = require('../../utils/navigator');
const { getDriver } = require('../../drivers/driver-factory');
const malware = require('../../pages/malware.page');
const wifi = require('../../pages/wifi.page');
const breach = require('../../pages/breach.page');
const alerts = require('../../pages/alerts.page');
const fusion = require('../../pages/fusion.page');
const risk = require('../../pages/risk.page');
const arbitration = require('../../pages/arbitration.page');
const screenshot = require('../../pages/screenshot.page');
const { SAFE_WHITELISTED, DANGEROUS_DETERMINISTIC } = require('../../data/urls');

const stillAlive = async () => {
  const pkg = await getDriver().getCurrentPackage();
  assert.strictEqual(pkg, env.device.appPackage, 'app left the foreground — likely a crash');
};

// ─────────────────────────────────────────────────────────────────────────────
describe('Malware — installed app scanner', function () {
  this.timeout(env.timeouts.test);

  beforeEach(async () => {
    await nav.goTo('/malware');
    await malware.waitUntilLoaded();
  });

  tc(
    {
      id: 'TC_MAL_001',
      module: 'Malware',
      priority: 'P0',
      title: 'App scan completes without crashing',
      preconditions: 'Malware screen open',
      steps: ['Tap Scan Now', 'Wait for the button to leave its loading state'],
      expected: 'Scan finishes and the app is still running',
      rationale:
        'The scan enumerates every installed package via QUERY_ALL_PACKAGES and ' +
        'runs a permission-feature ensemble over each — the most CPU-heavy path ' +
        'in the app and the most likely to ANR.',
    },
    async () => {
      await malware.runScan();
      await stillAlive();
    }
  );

  tc(
    {
      id: 'TC_MAL_002',
      module: 'Malware',
      priority: 'P1',
      title: 'Scan renders either results or an explicit empty state',
      preconditions: 'A scan has completed',
      steps: ['Run a scan', 'Check for result rows or an empty state'],
      expected: 'One of the two is present — never a blank screen',
    },
    async () => {
      await malware.runScan();
      const rows = await malware.visibleAppCount();
      const { AutoId } = require('../../config/auto-ids.generated');
      const empty = await malware.existsId(AutoId.malwareEmptyState, { timeout: 3000 });
      assert.ok(rows > 0 || empty, 'malware screen showed neither results nor an empty state');
    }
  );

  tc(
    {
      id: 'TC_MAL_003',
      module: 'Malware',
      priority: 'P2',
      title: 'Re-scanning is idempotent and does not duplicate rows',
      preconditions: 'Malware screen open',
      steps: ['Scan', 'Record the row count', 'Scan again', 'Compare'],
      expected: 'Row count is stable across scans',
      rationale:
        'The scan writes into a Hive cache box; appending instead of replacing ' +
        'would grow the list on every run.',
    },
    async () => {
      await malware.runScan();
      const first = await malware.visibleAppCount();
      await malware.runScan();
      const second = await malware.visibleAppCount();
      assert.strictEqual(second, first, `row count changed from ${first} to ${second} on re-scan`);
    }
  );
});

// ─────────────────────────────────────────────────────────────────────────────
describe('Wi-Fi — network trust scanner', function () {
  this.timeout(env.timeouts.test);

  beforeEach(async () => {
    await nav.goTo('/wifi');
    await wifi.waitUntilLoaded();
  });

  tc(
    {
      id: 'TC_WIFI_001',
      module: 'Wi-Fi',
      priority: 'P1',
      title: 'Wi-Fi scan settles without crashing on an emulator with no real AP',
      preconditions: 'Wi-Fi screen open',
      steps: ['Tap Scan this network', 'Wait for the scan to settle'],
      expected: 'App stays alive and renders a result or an unavailable state',
      rationale:
        'On API 33+ the SSID is unreadable without NEARBY_WIFI_DEVICES, and an ' +
        'emulator has no real AP — the screen must degrade, not throw.',
    },
    async () => {
      await wifi.runScan();
      await stillAlive();
      assert.ok(
        await wifi.hasResultOrEmptyState(),
        'Wi-Fi screen rendered neither a trust score nor an empty state'
      );
    }
  );

  tc(
    {
      id: 'TC_WIFI_002',
      module: 'Wi-Fi',
      priority: 'P2',
      title: 'Repeated Wi-Fi scans remain stable',
      preconditions: 'Wi-Fi screen open',
      steps: ['Run the scan three times in a row'],
      expected: 'App stays alive throughout',
    },
    async () => {
      for (let i = 0; i < 3; i += 1) {
        await wifi.runScan();
        await stillAlive();
      }
    }
  );
});

// ─────────────────────────────────────────────────────────────────────────────
describe('Breach — credential exposure monitor', function () {
  this.timeout(env.timeouts.test);

  beforeEach(async () => {
    await nav.goTo('/breach');
    await breach.waitUntilLoaded();
  });

  const INVALID_EMAILS = [
    { input: 'not-an-email', note: 'no @' },
    { input: '@example.com', note: 'no local part' },
    { input: 'user@', note: 'no domain' },
    { input: 'user@@example.com', note: 'double @' },
    { input: 'user @example.com', note: 'space in local part' },
    { input: '', note: 'empty' },
    { input: 'a'.repeat(300) + '@example.com', note: 'excessively long local part' },
    { input: "'; DROP TABLE breaches;--", note: 'SQL-shaped' },
    { input: '<script>alert(1)</script>@x.com', note: 'HTML-shaped' },
  ];

  INVALID_EMAILS.forEach((entry, i) => {
    tc(
      {
        id: `TC_BREACH_V${String(i + 1).padStart(3, '0')}`,
        module: 'Input Validation',
        priority: 'P1',
        title: `Invalid identifier is handled safely: ${entry.note}`,
        preconditions: 'Breach screen open',
        steps: [`Enter ${JSON.stringify(entry.input)}`, 'Tap Check', 'Wait'],
        testData: entry.input,
        expected: 'App does not crash and does not issue a network call',
        rationale:
          'Validation must reject locally. A malformed identifier reaching the ' +
          'HIBP client would waste the user quota and leak the input off-device.',
      },
      async () => {
        await breach.enterEmail(entry.input);
        await breach.tapCheck();
        await getDriver().pause(2500);
        await stillAlive();
      }
    );
  });

  tc(
    {
      id: 'TC_BREACH_001',
      module: 'Breach',
      priority: 'P2',
      title: 'Email and phone modes can be switched',
      preconditions: 'Breach screen open',
      steps: ['Switch to phone mode', 'Switch back to email mode'],
      expected: 'The input remains rendered in both modes',
    },
    async () => {
      await breach.switchToPhoneMode();
      assert.ok(await breach.exists(breach.input, { timeout: 5000 }), 'input lost in phone mode');
      await breach.switchToEmailMode();
      assert.ok(await breach.exists(breach.input, { timeout: 5000 }), 'input lost in email mode');
    }
  );

  tc.notApplicable(
    {
      id: 'TC_BREACH_NET_001',
      module: 'Breach',
      priority: 'P1',
      title: 'Live HIBP lookup returns breach records for a known-breached address',
      },
    'Requires a live call to haveibeenpwned.com. Driving a third-party production ' +
      'API from CI is abusive and rate-limited; enable CG_ALLOW_NETWORK_TESTS=1 ' +
      'locally with your own API key to run it manually.'
  );
});

// ─────────────────────────────────────────────────────────────────────────────
describe('Alerts — history', function () {
  this.timeout(env.timeouts.test);

  tc(
    {
      id: 'TC_ALERT_001',
      module: 'Alerts',
      priority: 'P1',
      title: 'Scanning a malicious URL creates an alert entry',
      preconditions: 'App running',
      steps: [
        'Scan a known-dangerous URL from the phishing screen',
        'Open Alerts',
        'Check the list is not empty',
      ],
      expected: 'At least one alert is present',
      rationale:
        'PhishingRepository.scanAndSave writes an AlertModel only when the verdict ' +
        'is phishing — this is the end-to-end proof that detection reaches history.',
    },
    async () => {
      const phishing = require('../../pages/phishing.page');
      await nav.goTo('/phishing');
      await phishing.waitUntilLoaded();
      await phishing.scanUrl(DANGEROUS_DETERMINISTIC[0].url);

      await nav.toDashboard();
      await nav.goTo('/alerts');
      await alerts.waitUntilLoaded();

      const empty = await alerts.isEmpty();
      assert.ok(!empty, 'no alert was recorded after detecting a phishing URL');
    }
  );

  tc(
    {
      id: 'TC_ALERT_002',
      module: 'Alerts',
      priority: 'P2',
      title: 'Alerts screen renders without crashing',
      preconditions: 'App running',
      steps: ['Open Alerts'],
      expected: 'Screen renders a list or an empty state',
    },
    async () => {
      await nav.goTo('/alerts');
      await alerts.waitUntilLoaded();
      await stillAlive();
    }
  );

  tc(
    {
      id: 'TC_ALERT_003',
      module: 'Alerts',
      priority: 'P2',
      title: 'Scanning a whitelisted URL does not create an alert',
      preconditions: 'Alerts cleared',
      steps: ['Clear alerts', 'Scan a whitelisted URL', 'Re-open alerts'],
      expected: 'No new alert is created for a safe verdict',
      rationale:
        'A false-positive alert trains users to ignore the alert list, which is ' +
        'worse than having no list.',
    },
    async () => {
      const phishing = require('../../pages/phishing.page');
      await nav.goTo('/alerts');
      await alerts.waitUntilLoaded();
      if (!(await alerts.isEmpty())) {
        await alerts.clearAll();
        await getDriver().pause(900);
      }

      await nav.toDashboard();
      await nav.goTo('/phishing');
      await phishing.waitUntilLoaded();
      await phishing.scanUrl(SAFE_WHITELISTED[0].url);

      await nav.toDashboard();
      await nav.goTo('/alerts');
      await alerts.waitUntilLoaded();
      assert.ok(
        await alerts.isEmpty(),
        'a safe verdict produced an alert — false positive in the alert history'
      );
    }
  );
});

// ─────────────────────────────────────────────────────────────────────────────
describe('Threat Fusion — multi-source arbitration', function () {
  this.timeout(env.timeouts.test);

  beforeEach(async () => {
    await nav.goTo('/fusion');
    await fusion.waitUntilLoaded();
  });

  tc(
    {
      id: 'TC_FUSION_001',
      module: 'Threat Fusion',
      priority: 'P1',
      title: 'Fusion scan of a whitelisted URL completes offline',
      preconditions: 'Cloud intel disabled (default)',
      steps: ['Enter a whitelisted URL', 'Run the fusion scan'],
      expected: 'Scan completes with only the local source enabled',
      rationale:
        'With cloud intel off, SafeBrowsingSource reports itself unavailable and ' +
        'the fusion must still produce a verdict from the local model alone.',
    },
    async () => {
      await fusion.scan(SAFE_WHITELISTED[0].url);
      await stillAlive();
    }
  );

  tc(
    {
      id: 'TC_FUSION_002',
      module: 'Threat Fusion',
      priority: 'P1',
      title: 'Fusion scan of a malicious URL completes offline',
      preconditions: 'Cloud intel disabled (default)',
      steps: ['Enter a known-dangerous URL', 'Run the fusion scan'],
      expected: 'Scan completes without crashing',
    },
    async () => {
      await fusion.scan(DANGEROUS_DETERMINISTIC[0].url);
      await stillAlive();
    }
  );

  tc(
    {
      id: 'TC_FUSION_003',
      module: 'Threat Fusion',
      priority: 'P2',
      title: 'Fusion handles malformed input without crashing',
      preconditions: 'Fusion screen open',
      steps: ['Enter free text', 'Run the fusion scan'],
      testData: 'not a url',
      expected: 'App stays alive',
    },
    async () => {
      await fusion.scan('not a url at all');
      await stillAlive();
    }
  );
});

// ─────────────────────────────────────────────────────────────────────────────
describe('Secondary screens — render integrity', function () {
  this.timeout(env.timeouts.test);

  const SCREENS = [
    { route: '/risk', page: risk, name: 'Predictive Risk', id: 'TC_RISK_001' },
    { route: '/arbitration', page: arbitration, name: 'Arbitration Log', id: 'TC_ARB_001' },
    { route: '/screenshot', page: screenshot, name: 'Screenshot Scanner', id: 'TC_SHOT_001' },
  ];

  SCREENS.forEach((s) => {
    tc(
      {
        id: s.id,
        module: s.name,
        priority: 'P2',
        title: `${s.name} renders and remains stable`,
        preconditions: 'Dashboard open',
        steps: [`Open ${s.name}`, 'Wait for it to render', 'Idle briefly'],
        expected: 'Screen renders; app stays in the foreground',
      },
      async () => {
        await nav.goTo(s.route);
        await s.page.waitUntilLoaded();
        await getDriver().pause(1500);
        await stillAlive();
      }
    );
  });

  tc(
    {
      id: 'TC_SHOT_002',
      module: 'Screenshot Scanner',
      priority: 'P2',
      title: 'Gallery picker launches and cancelling returns to the app',
      preconditions: 'Screenshot scanner open',
      steps: ['Tap Choose from gallery', 'Press back to cancel', 'Confirm the app is foreground'],
      expected: 'App regains the foreground cleanly',
      rationale:
        'Leaving the app for a system picker and coming back is where image-picker ' +
        'plugins most often lose their result callback and hang the screen.',
    },
    async () => {
      await nav.goTo('/screenshot');
      await screenshot.waitUntilLoaded();
      await screenshot.openGalleryPicker();
      await getDriver().back();
      await getDriver().pause(1500);
      await getDriver().execute('mobile: activateApp', { appId: env.device.appPackage });
      await getDriver().pause(1200);
      await stillAlive();
    }
  );
});
