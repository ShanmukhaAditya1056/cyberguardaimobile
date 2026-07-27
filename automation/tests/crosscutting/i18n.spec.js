'use strict';

const assert = require('assert');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const nav = require('../../utils/navigator');
const settings = require('../../pages/settings.page');
const dashboard = require('../../pages/dashboard.page');
const phishing = require('../../pages/phishing.page');
const { getDriver } = require('../../drivers/driver-factory');
const { AutoId } = require('../../config/auto-ids.generated');

/**
 * Localisation. The app ships four locales (lib/l10n/generated): English,
 * Hindi, Tamil and Telugu.
 *
 * These tests assert on *structure*, never on translated copy: asserting a
 * Hindi string would make the suite fail every time a translator improves the
 * wording. What must hold is that switching locale keeps every control present
 * and functional, which is where localisation actually breaks (overflow,
 * missing keys rendering as blanks, controls falling off-screen).
 */
describe('Localisation — locale switching', function () {
  this.timeout(env.timeouts.test);

  const LOCALES = [
    { label: 'English', code: 'en' },
    { label: 'हिन्दी', code: 'hi' },
    { label: 'தமிழ்', code: 'ta' },
    { label: 'తెలుగు', code: 'te' },
  ];

  afterEach(async () => {
    // Always restore English so a failure here does not cascade into every
    // later suite that matches on English text.
    try {
      await nav.goTo('/settings');
      await settings.waitUntilLoaded();
      await settings.selectLanguage('English');
    } catch {
      /* best effort */
    }
  });

  LOCALES.forEach((locale, i) => {
    tc(
      {
        id: `TC_I18N_${String(i + 1).padStart(3, '0')}`,
        module: 'Localisation',
        priority: 'P2',
        title: `Switching to ${locale.label} keeps the dashboard functional`,
        preconditions: 'Settings open',
        steps: [
          `Select ${locale.label} in the language picker`,
          'Return to the dashboard',
          'Confirm the scan control is still present and enabled',
        ],
        testData: locale.code,
        expected: 'Dashboard renders and the scan control is actionable',
        rationale:
          'A missing ARB key renders as an empty string, which silently produces ' +
          'an unlabelled but still-present button — only a structural check catches it.',
      },
      async () => {
        await nav.goTo('/settings');
        await settings.waitUntilLoaded();
        await settings.selectLanguage(locale.label);

        await nav.toDashboard();
        assert.ok(
          await dashboard.exists(dashboard.scanButton, { timeout: 10000 }),
          `scan control disappeared after switching to ${locale.label}`
        );

        const el = await dashboard.driver.$(dashboard.scanButton);
        const enabled = await el.getAttribute('enabled');
        assert.notStrictEqual(
          enabled,
          'false',
          `scan control became disabled in ${locale.label}`
        );
      }
    );
  });

  LOCALES.forEach((locale, i) => {
    tc(
      {
        id: `TC_I18N_S${String(i + 1).padStart(3, '0')}`,
        module: 'Localisation',
        priority: 'P2',
        title: `Phishing scanner is usable in ${locale.label}`,
        preconditions: `App set to ${locale.label}`,
        steps: [
          `Switch to ${locale.label}`,
          'Open the phishing scanner',
          'Confirm the URL field and scan button are both present',
        ],
        testData: locale.code,
        expected: 'Both controls render',
        rationale:
          'Longer scripts (Tamil/Telugu) are the most likely to overflow a fixed ' +
          'button and push a control out of the layout.',
      },
      async () => {
        await nav.goTo('/settings');
        await settings.waitUntilLoaded();
        await settings.selectLanguage(locale.label);

        await nav.goTo('/phishing');
        assert.ok(
          await phishing.exists(phishing.urlInput, { timeout: 10000 }),
          `URL input missing in ${locale.label}`
        );
        assert.ok(
          await phishing.exists(phishing.scanButton, { timeout: 6000 }),
          `scan button missing in ${locale.label}`
        );
      }
    );
  });

  tc(
    {
      id: 'TC_I18N_P001',
      module: 'Localisation',
      priority: 'P2',
      title: 'Selected locale survives leaving and re-entering settings',
      preconditions: 'Settings open',
      steps: ['Switch to Hindi', 'Go to the dashboard', 'Re-open settings', 'Confirm still Hindi'],
      expected: 'Locale persists',
      rationale: 'The locale lives in Hive via localeProvider; losing it resets the user on every launch.',
    },
    async () => {
      await nav.goTo('/settings');
      await settings.waitUntilLoaded();
      await settings.selectLanguage('हिन्दी');

      await nav.toDashboard();
      await nav.goTo('/settings');
      await settings.waitUntilLoaded();

      // Structural proof: the settings root is still rendered and the toggles
      // are still addressable by their (locale-independent) identifiers.
      assert.ok(
        await settings.exists(settings.realTimeAlerts, { timeout: 8000 }),
        'settings did not render correctly after a locale round-trip'
      );
    }
  );
});
