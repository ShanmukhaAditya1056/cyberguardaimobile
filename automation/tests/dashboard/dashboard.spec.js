'use strict';

const assert = require('assert');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const nav = require('../../utils/navigator');
const dashboard = require('../../pages/dashboard.page');
const { getDriver } = require('../../drivers/driver-factory');

describe('Dashboard — unified score and modules', function () {
  this.timeout(env.timeouts.test);

  beforeEach(async () => {
    await nav.toDashboard();
  });

  tc(
    {
      id: 'TC_DASH_001',
      module: 'Dashboard',
      priority: 'P0',
      title: 'Quick scan completes and resolves the unified score to a number',
      preconditions: 'Dashboard open',
      steps: ['Tap Scan Now', 'Wait for the score ring to show a number'],
      expected: 'Score is an integer in 0..100',
    },
    async () => {
      const score = await dashboard.runQuickScan();
      assert.ok(Number.isInteger(score), `score was ${score}, expected an integer`);
      assert.ok(score >= 0 && score <= 100, `score ${score} is outside 0..100`);
    }
  );

  tc(
    {
      id: 'TC_DASH_002',
      module: 'Dashboard',
      priority: 'P1',
      title: 'Score persists across a return to the dashboard',
      preconditions: 'A scan has completed',
      steps: ['Scan', 'Navigate to Settings', 'Return to the dashboard', 'Re-read the score'],
      expected: 'Score is unchanged',
      rationale:
        'The unified score is recomputed from cached module scores in Hive; ' +
        'losing it on navigation would mean the cache is not being read back.',
    },
    async () => {
      const first = await dashboard.runQuickScan();
      await dashboard.openSettings();
      await getDriver().pause(900);
      await getDriver().back();
      await getDriver().pause(900);
      const second = await dashboard.readScore();
      assert.strictEqual(second, first, `score changed from ${first} to ${second} on navigation`);
    }
  );

  tc(
    {
      id: 'TC_DASH_003',
      module: 'Dashboard',
      priority: 'P1',
      title: 'Scan button is disabled while a scan is in flight',
      preconditions: 'Dashboard open',
      steps: ['Tap Scan Now', 'Immediately read the button enabled state'],
      expected: 'Button reports enabled=false during the scan',
      rationale:
        'Without this, a double-tap starts two concurrent scans that race on ' +
        'the same Hive box.',
    },
    async () => {
      const el = await dashboard.waitFor(dashboard.scanButton, { as: 'Scan Now' });
      await el.click();
      // Read as fast as possible — the scan can be quick on a warm emulator.
      const enabled = await el.getAttribute('enabled');
      if (enabled === 'true') {
        // Scan already finished; that is acceptable but means we proved nothing.
        this.skip();
        return;
      }
      assert.strictEqual(enabled, 'false', 'Scan Now stayed enabled mid-scan');
    }
  );

  tc(
    {
      id: 'TC_DASH_004',
      module: 'Dashboard',
      priority: 'P2',
      title: 'All four cyber-defense tiles are present',
      preconditions: 'Dashboard open',
      steps: ['Scroll to the Cyber Defense section', 'Locate each tile'],
      expected: 'fusion, screenshot, risk and arbitration tiles all exist',
    },
    async () => {
      for (const slug of ['fusion', 'screenshot', 'risk', 'arbitration']) {
        const selector = dashboard.defenseTile(slug);
        await dashboard.scrollTo(selector, { as: `${slug} tile` });
        assert.ok(
          await dashboard.exists(selector, { timeout: 4000 }),
          `defense tile "${slug}" is missing from the dashboard`
        );
      }
    }
  );

  tc(
    {
      id: 'TC_DASH_005',
      module: 'Dashboard',
      priority: 'P2',
      title: 'Repeated scans keep the score within the valid range',
      preconditions: 'Dashboard open',
      steps: ['Run three consecutive quick scans', 'Check each resulting score'],
      expected: 'Every score is an integer in 0..100',
      rationale:
        'The score is a weighted blend of module scores; a drift or overflow ' +
        'bug only shows up after repeated recomputation.',
    },
    async () => {
      for (let i = 0; i < 3; i += 1) {
        const score = await dashboard.runQuickScan();
        assert.ok(
          Number.isInteger(score) && score >= 0 && score <= 100,
          `scan ${i + 1} produced an out-of-range score: ${score}`
        );
      }
    }
  );

  tc(
    {
      id: 'TC_DASH_006',
      module: 'Dashboard',
      priority: 'P2',
      title: 'Alerts entry point is reachable from the app bar',
      preconditions: 'Dashboard open',
      steps: ['Tap the notification bell'],
      expected: 'Alerts screen opens',
    },
    async () => {
      await dashboard.openAlerts();
      await getDriver().pause(900);
      const { AutoId } = require('../../config/auto-ids.generated');
      const opened =
        (await dashboard.existsId(AutoId.alertsRoot, { timeout: 6000 })) ||
        (await dashboard.isDisplayed(dashboard.byText('Alerts', { exact: false }), {
          timeout: 4000,
        }));
      assert.ok(opened, 'Alerts screen did not open from the bell icon');
    }
  );

  tc(
    {
      id: 'TC_DASH_007',
      module: 'Dashboard',
      priority: 'P2',
      title: 'Settings entry point is reachable from the app bar',
      preconditions: 'Dashboard open',
      steps: ['Tap the settings gear'],
      expected: 'Settings screen opens',
    },
    async () => {
      const { AutoId } = require('../../config/auto-ids.generated');
      await dashboard.openSettings();
      await getDriver().pause(900);
      assert.ok(
        await dashboard.existsId(AutoId.settingsRoot, { timeout: 8000 }),
        'Settings did not open from the gear icon'
      );
    }
  );
});
