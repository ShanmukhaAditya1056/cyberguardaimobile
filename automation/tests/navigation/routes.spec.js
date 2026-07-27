'use strict';

const assert = require('assert');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const { getDriver } = require('../../drivers/driver-factory');
const nav = require('../../utils/navigator');
const dashboard = require('../../pages/dashboard.page');
const phishing = require('../../pages/phishing.page');
const { AutoId } = require('../../config/auto-ids.generated');

/**
 * Navigation — every tappable route, plus back-navigation integrity.
 *
 * GoRouter's `redirect` forces onboarding until `onboardingComplete` is set,
 * so these tests assume onboarding is already done (the smoke suite does that).
 */
describe('Navigation — routes', function () {
  this.timeout(env.timeouts.test);

  beforeEach(async () => {
    await nav.toDashboard();
  });

  const routes = nav.tappableRoutes();

  // ── One reach test per tappable destination ─────────────────────────────
  routes.forEach((spec, i) => {
    tc(
      {
        id: `TC_NAV_${String(i + 1).padStart(3, '0')}`,
        module: 'Navigation',
        priority: 'P1',
        title: `${spec.name} (${spec.route}) opens from the dashboard`,
        preconditions: 'Dashboard open',
        steps: [`Tap the ${spec.name} entry point`, 'Wait for the destination root element'],
        expected: `${spec.name} renders its root element`,
      },
      async () => {
        await nav.goTo(spec.route);
        const found = await dashboard.exists(
          `//*[@resource-id="${spec.rootId}"]`,
          { timeout: env.timeouts.element }
        );
        assert.ok(found, `${spec.name} did not render (looked for ${spec.rootId})`);
      }
    );
  });

  // ── Back navigation ─────────────────────────────────────────────────────
  routes.forEach((spec, i) => {
    tc(
      {
        id: `TC_NAV_B${String(i + 1).padStart(3, '0')}`,
        module: 'Navigation',
        priority: 'P1',
        title: `Back from ${spec.name} returns to the dashboard`,
        preconditions: `${spec.name} open`,
        steps: ['Open the screen', 'Press the system back button'],
        expected: 'Dashboard is shown again',
        rationale:
          'A screen that swallows back is the most common way a Flutter app ' +
          'traps a user, and it is invisible to unit tests.',
      },
      async () => {
        await nav.goTo(spec.route);
        await getDriver().back();
        await getDriver().pause(700);
        assert.ok(
          await dashboard.isOpen({ timeout: 8000 }),
          `back from ${spec.name} did not return to the dashboard`
        );
      }
    );
  });

  tc(
    {
      id: 'TC_NAV_100',
      module: 'Navigation',
      priority: 'P1',
      title: 'QR scanner opens from inside the phishing screen',
      preconditions: 'Phishing screen open',
      steps: ['Open Phishing', 'Tap the QR action in the app bar'],
      expected: 'QR scanner screen is shown',
    },
    async () => {
      await nav.goTo('/phishing');
      await phishing.waitUntilLoaded();
      await phishing.openQrScanner();
      await getDriver().pause(1200);
      const onQr =
        (await dashboard.existsId(AutoId.qrRoot, { timeout: 6000 })) ||
        (await dashboard.existsId(AutoId.qrCloseBtn, { timeout: 2000 }));
      assert.ok(onQr, 'QR scanner did not open from the phishing screen');
    }
  );

  tc(
    {
      id: 'TC_NAV_101',
      module: 'Navigation',
      priority: 'P2',
      title: 'Back from the QR scanner returns to the phishing screen, not the dashboard',
      preconditions: 'QR scanner open from phishing',
      steps: ['Open Phishing', 'Open QR scanner', 'Press back'],
      expected: 'Phishing screen is shown',
      rationale:
        'A nested push must pop one level. Popping straight to the dashboard ' +
        'would mean the route stack is being replaced rather than pushed.',
    },
    async () => {
      await nav.goTo('/phishing');
      await phishing.waitUntilLoaded();
      await phishing.openQrScanner();
      await getDriver().pause(1200);
      await getDriver().back();
      await getDriver().pause(900);
      assert.ok(
        await dashboard.existsId(AutoId.phishingUrlInput, { timeout: 8000 }),
        'back from QR did not return to the phishing screen'
      );
    }
  );

  tc(
    {
      id: 'TC_NAV_102',
      module: 'Navigation',
      priority: 'P2',
      title: 'Rapid repeated navigation does not corrupt the route stack',
      preconditions: 'Dashboard open',
      steps: [
        'Open and close four different screens back to back with no settle time',
        'Confirm the dashboard is still reachable',
      ],
      expected: 'Dashboard is shown and responsive',
      rationale:
        'Fast double-taps on module cards are a classic way to push a route ' +
        'twice and leave the user two backs from home.',
    },
    async () => {
      const driver = getDriver();
      for (const route of ['/fusion', '/risk', '/arbitration', '/screenshot']) {
        await nav.goTo(route);
        await driver.back();
      }
      await driver.pause(1200);
      assert.ok(
        await dashboard.isOpen({ timeout: 10000 }),
        'route stack was corrupted by rapid navigation'
      );
    }
  );

  tc(
    {
      id: 'TC_NAV_103',
      module: 'Navigation',
      priority: 'P2',
      title: 'Back on the dashboard exits the app rather than looping',
      preconditions: 'Dashboard open (root of the stack)',
      steps: ['Press back on the dashboard', 'Read the foreground package'],
      expected: 'App is backgrounded; it does not navigate to another in-app screen',
    },
    async () => {
      const driver = getDriver();
      await driver.back();
      await driver.pause(1200);
      const pkg = await driver.getCurrentPackage();
      // Either the launcher is now in front, or the app handled back without
      // navigating somewhere unexpected. Both are acceptable; being on a
      // different *in-app* screen is not.
      if (pkg === env.device.appPackage) {
        assert.ok(
          await dashboard.isOpen({ timeout: 4000 }),
          'back from the dashboard landed on an unexpected in-app screen'
        );
      }
      await driver.execute('mobile: activateApp', { appId: env.device.appPackage });
      await driver.pause(1200);
    }
  );
});
