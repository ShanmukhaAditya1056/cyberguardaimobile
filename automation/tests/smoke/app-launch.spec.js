'use strict';

const assert = require('assert');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const { getDriver } = require('../../drivers/driver-factory');
const dashboard = require('../../pages/dashboard.page');
const onboarding = require('../../pages/onboarding.page');

/**
 * Smoke: if any of these fail the rest of the suite is meaningless, so they run
 * first and are all P0.
 */
describe('Smoke — application launch', function () {
  this.timeout(env.timeouts.test);

  before(async () => {
    // First launch lands on onboarding; get to the dashboard once so the rest
    // of the suite starts from a known screen.
    await onboarding.dismiss();
    await dashboard.waitUntilLoaded();
  });

  tc(
    {
      id: 'TC_SMOKE_001',
      module: 'Smoke',
      priority: 'P0',
      title: 'Application package under test is installed and running',
      preconditions: 'APK installed on the device',
      steps: ['Query the foreground package from the driver'],
      expected: 'Foreground package is com.cyberguard.ai',
    },
    async () => {
      const pkg = await getDriver().getCurrentPackage();
      assert.strictEqual(pkg, env.device.appPackage);
    }
  );

  tc(
    {
      id: 'TC_SMOKE_002',
      module: 'Smoke',
      priority: 'P0',
      title: 'Dashboard renders after launch',
      preconditions: 'Onboarding already completed',
      steps: ['Wait for the dashboard root'],
      expected: 'Dashboard root and Scan Now button are present',
    },
    async () => {
      assert.ok(await dashboard.isOpen(), 'dashboard root not on screen');
    }
  );

  tc(
    {
      id: 'TC_SMOKE_003',
      module: 'Smoke',
      priority: 'P0',
      title: 'Flutter semantics tree is published to the accessibility layer',
      preconditions: 'App in the foreground',
      steps: ['Read the page source', 'Look for cg_ automation identifiers'],
      expected: 'At least one cg_* resource-id is present',
      rationale:
        'Flutter renders to one canvas. If the semantics tree is missing, every ' +
        'locator in the suite fails with an identical timeout — this test names ' +
        'the real cause instead.',
    },
    async () => {
      const source = await getDriver().getPageSource();
      assert.ok(
        source.includes('cg_'),
        'No cg_* resource-id found in the view hierarchy. The Flutter semantics ' +
          'tree is not reaching UiAutomator2 — check that Semantics(identifier:) ' +
          'wrappers survived the build.'
      );
    }
  );

  tc(
    {
      id: 'TC_SMOKE_004',
      module: 'Smoke',
      priority: 'P0',
      title: 'Application does not crash within 10s of idling on the dashboard',
      preconditions: 'Dashboard open',
      steps: ['Idle for 10 seconds', 'Re-check the foreground package'],
      expected: 'App is still in the foreground',
    },
    async () => {
      await getDriver().pause(10000);
      const pkg = await getDriver().getCurrentPackage();
      assert.strictEqual(pkg, env.device.appPackage, 'app left the foreground while idle');
    }
  );

  tc(
    {
      id: 'TC_SMOKE_005',
      module: 'Smoke',
      priority: 'P0',
      title: 'Scan Now control is present and enabled',
      preconditions: 'Dashboard open',
      steps: ['Locate the Scan Now button', 'Read its enabled attribute'],
      expected: 'Button exists and is enabled',
    },
    async () => {
      const el = await dashboard.waitFor(dashboard.scanButton, { as: 'Scan Now' });
      const enabled = await el.getAttribute('enabled');
      assert.notStrictEqual(enabled, 'false', 'Scan Now is disabled on a fresh dashboard');
    }
  );

  tc(
    {
      id: 'TC_SMOKE_006',
      module: 'Smoke',
      priority: 'P1',
      title: 'App version reported by the package manager is well formed',
      preconditions: 'App installed',
      steps: ['Read versionName via the package manager'],
      expected: 'versionName matches a semantic version',
      rationale:
        'Reports quote the app version; a malformed value silently corrupts ' +
        'every historical comparison.',
    },
    async () => {
      const { describeDevice } = require('../../drivers/driver-factory');
      const info = await describeDevice();
      if (info.appVersion === 'unknown') {
        // mobile: shell needs --relaxed-security; treat as inconclusive, not a
        // false failure, and say so rather than asserting something untrue.
        this.skip();
        return;
      }
      assert.match(
        info.appVersion,
        /^\d+\.\d+\.\d+/,
        `versionName "${info.appVersion}" is not a semantic version`
      );
    }
  );
});
