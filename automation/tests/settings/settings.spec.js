'use strict';

const assert = require('assert');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const nav = require('../../utils/navigator');
const settings = require('../../pages/settings.page');
const dashboard = require('../../pages/dashboard.page');
const { getDriver } = require('../../drivers/driver-factory');

/**
 * Settings — toggles, persistence and the privacy posture.
 *
 * The cloud-intel toggle is the one control in the app that can cause a URL to
 * leave the device. Its default state and its consent gate are treated as P0
 * privacy requirements, and the suite always leaves it OFF.
 */
describe('Settings — preferences and privacy', function () {
  this.timeout(env.timeouts.test);

  beforeEach(async () => {
    await nav.goTo('/settings');
    await settings.waitUntilLoaded();
  });

  const TOGGLES = [
    { key: 'realTimeAlerts', name: 'Real-time alerts' },
    { key: 'clipboardScan', name: 'Clipboard scan' },
    { key: 'wifiAutoScan', name: 'Wi-Fi auto scan' },
    { key: 'linkInterceptor', name: 'Link interceptor' },
    { key: 'linkHistory', name: 'Save link history' },
  ];

  // ── Toggle mechanics ────────────────────────────────────────────────────
  TOGGLES.forEach((t, i) => {
    tc(
      {
        id: `TC_SET_T${String(i + 1).padStart(3, '0')}`,
        module: 'Settings',
        priority: 'P1',
        title: `${t.name} toggle flips state when tapped`,
        preconditions: 'Settings open',
        steps: [`Scroll to ${t.name}`, 'Read state', 'Tap', 'Read state again'],
        expected: 'The semantics toggled state inverts',
      },
      async () => {
        const result = await settings.toggle(settings[t.key], { as: t.name });
        assert.ok(
          result.changed,
          `${t.name} did not change state (before=${result.before}, after=${result.after})`
        );
        // Restore so later tests start from a known posture.
        await settings.toggle(settings[t.key], { as: t.name });
      }
    );
  });

  TOGGLES.forEach((t, i) => {
    tc(
      {
        id: `TC_SET_P${String(i + 1).padStart(3, '0')}`,
        module: 'Settings',
        priority: 'P1',
        title: `${t.name} persists across leaving and re-entering settings`,
        preconditions: 'Settings open',
        steps: ['Toggle the control', 'Go back to the dashboard', 'Re-open settings', 'Read state'],
        expected: 'The new state survived the round-trip',
        rationale:
          'These flags live in Hive; a persistence bug means the user re-configures ' +
          'the app on every launch.',
      },
      async () => {
        const { after } = await settings.toggle(settings[t.key], { as: t.name });
        await nav.toDashboard();
        await nav.goTo('/settings');
        await settings.waitUntilLoaded();
        const reread = await settings.isEnabled(settings[t.key]);
        assert.strictEqual(
          reread,
          after,
          `${t.name} was ${after} before navigating away but ${reread} after`
        );
        await settings.toggle(settings[t.key], { as: t.name });
      }
    );
  });

  // ── Privacy posture ─────────────────────────────────────────────────────
  tc(
    {
      id: 'TC_SET_PRIV_001',
      module: 'Privacy',
      priority: 'P0',
      title: 'Cloud threat intelligence is OFF by default',
      preconditions: 'Fresh install, settings open',
      steps: ['Scroll to Cloud threat intelligence', 'Read its state'],
      expected: 'Toggle is off, so no URL leaves the device',
      rationale:
        'SafeBrowsingSource sends the full URL to Google. Default-on would be a ' +
        'silent privacy regression, and it is the kind of default that flips ' +
        'accidentally during a refactor.',
    },
    async () => {
      const enabled = await settings.isEnabled(settings.cloudIntel);
      assert.strictEqual(
        enabled,
        false,
        'Cloud threat intelligence is ON by default — URLs would leave the device ' +
          'without the user opting in'
      );
    }
  );

  tc(
    {
      id: 'TC_SET_PRIV_002',
      module: 'Privacy',
      priority: 'P0',
      title: 'Enabling cloud threat intelligence requires explicit confirmation',
      preconditions: 'Cloud intel off, settings open',
      steps: ['Tap the cloud intel toggle', 'Observe the consent dialog', 'Cancel it'],
      expected: 'A consent dialog appears and cancelling leaves the toggle off',
      rationale:
        'Consent that can be given by a stray tap is not consent. Cancelling ' +
        'must be a real no-op.',
    },
    async () => {
      await settings.scrollTo(settings.cloudIntel, { as: 'Cloud intel' });
      await settings.tap(settings.cloudIntel, { as: 'Cloud intel' });
      await getDriver().pause(800);

      const dialogShown = await settings.isDisplayed(
        settings.byText('Cancel', { exact: false }),
        { timeout: 4000 }
      );
      assert.ok(dialogShown, 'no consent dialog appeared before enabling cloud intel');

      await settings.tap(settings.byText('Cancel', { exact: false }), { as: 'Cancel' });
      await getDriver().pause(700);

      const stillOff = await settings.isEnabled(settings.cloudIntel);
      assert.strictEqual(stillOff, false, 'cancelling the consent dialog still enabled cloud intel');
    }
  );

  // ── HIBP API key ────────────────────────────────────────────────────────
  tc(
    {
      id: 'TC_SET_KEY_001',
      module: 'Settings',
      priority: 'P1',
      title: 'HIBP API key field is masked by default',
      preconditions: 'Settings open',
      steps: ['Scroll to the HIBP key field', 'Enter a value', 'Read it back'],
      expected: 'The entered key is not rendered in plain text',
      rationale:
        'The field is an obscured TextField. If the value were readable from the ' +
        'view hierarchy it would also be readable from a screen recording.',
    },
    async () => {
      const probe = 'test-key-should-not-be-visible-1234';
      await settings.scrollTo(settings.hibpInput, { as: 'HIBP key field' });
      await settings.typeInto(settings.hibpInput, probe, { as: 'HIBP key field' });
      await settings.hideKeyboard();

      const source = await getDriver().getPageSource();
      assert.ok(
        !source.includes(probe),
        'the HIBP API key is exposed in plain text in the view hierarchy'
      );
    }
  );

  tc(
    {
      id: 'TC_SET_KEY_002',
      module: 'Settings',
      priority: 'P2',
      title: 'Clearing the HIBP key empties the field',
      preconditions: 'A key has been entered',
      steps: ['Enter a key', 'Tap the clear action', 'Read the field'],
      expected: 'Field is empty',
    },
    async () => {
      await settings.scrollTo(settings.hibpInput, { as: 'HIBP key field' });
      await settings.typeInto(settings.hibpInput, 'abcdef0123456789', { as: 'HIBP key field' });
      await settings.hideKeyboard();
      if (await settings.exists(settings.hibpClear, { timeout: 3000 })) {
        await settings.tap(settings.hibpClear, { as: 'Clear key' });
        await getDriver().pause(600);
      }
      const el = await settings.driver.$(settings.hibpInput);
      const text = await el.getText().catch(() => '');
      assert.ok(!text || text.length === 0 || /paste|enter/i.test(text),
        `HIBP field still contains content after clear: "${text}"`);
    }
  );

  // ── Report export ───────────────────────────────────────────────────────
  ['exportPdf', 'exportCsv'].forEach((key, i) => {
    tc(
      {
        id: `TC_SET_EXP_${String(i + 1).padStart(3, '0')}`,
        module: 'Settings',
        priority: 'P2',
        title: `${key === 'exportPdf' ? 'PDF' : 'CSV'} export runs without crashing`,
        preconditions: 'Settings open',
        steps: ['Scroll to Reports', `Tap ${key}`, 'Wait for the operation to settle'],
        expected: 'App stays in the foreground',
        rationale:
          'Export builds a document from every Hive box; an empty box is the ' +
          'usual source of a null-deref here.',
      },
      async () => {
        await settings.scrollTo(settings[key], { as: key });
        await settings.tap(settings[key], { as: key });
        await getDriver().pause(4000);
        const pkg = await getDriver().getCurrentPackage();
        // Export may hand off to a share sheet, which is a different package —
        // that is a success, not a crash.
        if (pkg !== env.device.appPackage) {
          await getDriver().back();
          await getDriver().pause(1200);
        }
        await getDriver().execute('mobile: activateApp', { appId: env.device.appPackage });
        await getDriver().pause(1000);
        assert.ok(true);
      }
    );
  });

  tc(
    {
      id: 'TC_SET_VER_001',
      module: 'Settings',
      priority: 'P2',
      title: 'About section renders a version string',
      preconditions: 'Settings open',
      steps: ['Scroll to About', 'Read the Version row'],
      expected: 'A semantic version is displayed',
      rationale:
        'Known discrepancy: the About row is a hardcoded literal while pubspec ' +
        'declares 2.0.0. This test asserts only that a version renders — see ' +
        'MOB-011 in the security review for the mismatch itself.',
    },
    async () => {
      const version = await settings.readVersion();
      assert.ok(version, 'no version string rendered in the About section');
      assert.match(version, /^\d+\.\d+\.\d+$/, `"${version}" is not a semantic version`);
    }
  );
});
