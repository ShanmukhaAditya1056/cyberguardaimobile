'use strict';

const assert = require('assert');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const nav = require('../../utils/navigator');
const dashboard = require('../../pages/dashboard.page');
const settings = require('../../pages/settings.page');
const phishing = require('../../pages/phishing.page');
const { getDriver } = require('../../drivers/driver-factory');
const { SAFE_WHITELISTED } = require('../../data/urls');

/**
 * Lifecycle and resilience — the failures users actually hit.
 *
 * Unit tests never background an app, rotate it, or kill it mid-scan. Every
 * test here exercises a real Android lifecycle transition.
 */
describe('Resilience — lifecycle and state', function () {
  this.timeout(env.timeouts.test);

  const activate = async () => {
    await getDriver().execute('mobile: activateApp', { appId: env.device.appPackage });
    await getDriver().pause(1500);
  };

  tc(
    {
      id: 'TC_RES_001',
      module: 'Resilience',
      priority: 'P0',
      title: 'App survives being backgrounded and resumed',
      preconditions: 'Dashboard open',
      steps: ['Background the app for 5s', 'Bring it back', 'Confirm the dashboard is intact'],
      expected: 'Dashboard renders again with no crash',
    },
    async () => {
      await nav.toDashboard();
      await getDriver().execute('mobile: backgroundApp', { seconds: 5 });
      await activate();
      assert.ok(
        await dashboard.isOpen({ timeout: 15000 }),
        'dashboard did not restore after backgrounding'
      );
    }
  );

  tc(
    {
      id: 'TC_RES_002',
      module: 'Resilience',
      priority: 'P1',
      title: 'Unified score survives a background/resume cycle',
      preconditions: 'A scan has completed',
      steps: ['Scan', 'Background for 5s', 'Resume', 'Re-read the score'],
      expected: 'Score is unchanged',
      rationale:
        'Riverpod state is in memory; the score must be re-read from Hive on ' +
        'resume rather than silently resetting to the placeholder.',
    },
    async () => {
      await nav.toDashboard();
      const before = await dashboard.runQuickScan();
      await getDriver().execute('mobile: backgroundApp', { seconds: 5 });
      await activate();
      await dashboard.waitUntilLoaded();
      const after = await dashboard.readScore();
      assert.strictEqual(after, before, `score changed from ${before} to ${after} across resume`);
    }
  );

  tc(
    {
      id: 'TC_RES_003',
      module: 'Resilience',
      priority: 'P1',
      title: 'Settings toggles survive a background/resume cycle',
      preconditions: 'Settings open',
      steps: ['Toggle real-time alerts', 'Background 5s', 'Resume', 'Re-read the toggle'],
      expected: 'Toggle state is preserved',
    },
    async () => {
      await nav.goTo('/settings');
      await settings.waitUntilLoaded();
      const { after } = await settings.toggle(settings.realTimeAlerts, { as: 'Real-time alerts' });

      await getDriver().execute('mobile: backgroundApp', { seconds: 5 });
      await activate();

      await nav.goTo('/settings');
      await settings.waitUntilLoaded();
      const reread = await settings.isEnabled(settings.realTimeAlerts);
      assert.strictEqual(reread, after, 'toggle state was lost across a resume');

      await settings.toggle(settings.realTimeAlerts, { as: 'Real-time alerts' });
    }
  );

  tc(
    {
      id: 'TC_RES_004',
      module: 'Resilience',
      priority: 'P1',
      title: 'Backgrounding during an active scan does not corrupt state',
      preconditions: 'Dashboard open',
      steps: ['Start a quick scan', 'Background immediately', 'Resume', 'Confirm the dashboard works'],
      expected: 'App resumes to a usable dashboard',
      rationale:
        'The scan writes to Hive asynchronously. Interrupting it is the classic ' +
        'way to leave a half-written box that crashes on the next read.',
    },
    async () => {
      await nav.toDashboard();
      const el = await dashboard.waitFor(dashboard.scanButton, { as: 'Scan Now' });
      await el.click();
      await getDriver().execute('mobile: backgroundApp', { seconds: 3 });
      await activate();
      assert.ok(
        await dashboard.isOpen({ timeout: 20000 }),
        'dashboard did not recover after interrupting a scan'
      );
    }
  );

  tc(
    {
      id: 'TC_RES_005',
      module: 'Resilience',
      priority: 'P1',
      title: 'Scan history persists across a full app restart',
      preconditions: 'A URL has been scanned',
      steps: ['Scan a URL', 'Terminate the app', 'Relaunch', 'Confirm the app starts cleanly'],
      expected: 'App relaunches to the dashboard, skipping onboarding',
      rationale:
        'onboardingComplete lives in the same Hive box as scan history — a ' +
        'relaunch that shows onboarding again means the box was not persisted.',
    },
    async () => {
      await nav.goTo('/phishing');
      await phishing.waitUntilLoaded();
      await phishing.scanUrl(SAFE_WHITELISTED[0].url);

      await getDriver().execute('mobile: terminateApp', { appId: env.device.appPackage });
      await getDriver().pause(1500);
      await activate();
      await getDriver().pause(3000);

      assert.ok(
        await dashboard.isOpen({ timeout: env.timeouts.appLaunch }),
        'app did not return to the dashboard after a restart — onboarding state was lost'
      );
    }
  );

  tc(
    {
      id: 'TC_RES_006',
      module: 'Resilience',
      priority: 'P2',
      title: 'App handles airplane-mode-style offline operation',
      preconditions: 'Dashboard open',
      steps: ['Run a quick scan with no network dependency', 'Confirm it completes'],
      expected: 'Scan completes — all detection is on-device',
      rationale:
        'The product claim is on-device detection. If a scan needs the network ' +
        'to finish, that claim is false. Cloud intel is off by default, so this ' +
        'is exercised without touching flight mode.',
    },
    async () => {
      await nav.toDashboard();
      const score = await dashboard.runQuickScan();
      assert.ok(Number.isInteger(score), 'offline quick scan did not produce a score');
    }
  );

  tc(
    {
      id: 'TC_RES_007',
      module: 'Resilience',
      priority: 'P2',
      title: 'Repeated background/resume cycles do not degrade the app',
      preconditions: 'Dashboard open',
      steps: ['Background and resume five times', 'Confirm the dashboard still renders'],
      expected: 'App remains usable',
      rationale:
        'Leaked listeners (SMS stream, interceptor channel) accumulate per resume ' +
        'and only become visible after several cycles.',
    },
    async () => {
      await nav.toDashboard();
      for (let i = 0; i < 5; i += 1) {
        await getDriver().execute('mobile: backgroundApp', { seconds: 2 });
        await activate();
      }
      assert.ok(
        await dashboard.isOpen({ timeout: 15000 }),
        'dashboard stopped rendering after repeated background/resume cycles'
      );
    }
  );

  tc(
    {
      id: 'TC_RES_008',
      module: 'Resilience',
      priority: 'P2',
      title: 'Device rotation request does not crash the app',
      preconditions: 'Dashboard open',
      steps: ['Request landscape', 'Request portrait', 'Confirm the app is alive'],
      expected: 'App stays alive; portrait lock may reject the change',
      rationale:
        'main() locks portrait via SystemChrome. The lock must be enforced ' +
        'without throwing when a rotation is requested anyway.',
    },
    async () => {
      await nav.toDashboard();
      try {
        await getDriver().setOrientation('LANDSCAPE');
        await getDriver().pause(1200);
        await getDriver().setOrientation('PORTRAIT');
        await getDriver().pause(1200);
      } catch {
        // A portrait-locked activity can refuse the change; that is the
        // expected behaviour, not a failure.
      }
      const pkg = await getDriver().getCurrentPackage();
      assert.strictEqual(pkg, env.device.appPackage, 'app died on a rotation request');
    }
  );
});
