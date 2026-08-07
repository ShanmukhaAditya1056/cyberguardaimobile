'use strict';

const dashboard = require('../pages/dashboard.page');
const onboarding = require('../pages/onboarding.page');
const login = require('../pages/login.page');
const { getDriver } = require('../drivers/driver-factory');
const { AutoId } = require('../config/auto-ids.generated');
const logger = require('./logger');

const log = logger('navigator');

/**
 * Route map for the app's 16 GoRouter destinations.
 *
 * `reachable` marks how a route is entered. Three of them are deliberately not
 * reachable by tapping:
 *   /            splash, only on cold start
 *   /onboarding  only before onboardingComplete is set
 *   /intercept   pushed reactively when a risky link is intercepted, so it is
 *                driven by an ADB intent rather than a tap
 *   /malware/detail requires a completed scan with at least one result row
 */
const ROUTES = {
  '/': { name: 'Splash', reachable: 'cold-start', rootId: AutoId.splashRoot },
  '/onboarding': { name: 'Onboarding', reachable: 'first-run', rootId: AutoId.onboardingRoot },
  '/login': { name: 'Login', reachable: 'gate', rootId: AutoId.loginRoot },
  '/dashboard': { name: 'Dashboard', reachable: 'home', rootId: AutoId.dashboardRoot },
  '/phishing': { name: 'Phishing', reachable: 'module-card', label: 'Phishing', rootId: AutoId.phishingUrlInput },
  '/phishing/qr': { name: 'QR Scanner', reachable: 'from-phishing', rootId: AutoId.qrRoot },
  '/malware': { name: 'Malware', reachable: 'module-card', label: 'Malware', rootId: AutoId.malwareScanBtn },
  '/malware/detail': { name: 'App Detail', reachable: 'from-malware-list', rootId: AutoId.appDetailRoot },
  '/breach': { name: 'Breach', reachable: 'module-card', label: 'Breach', rootId: AutoId.breachEmailInput },
  '/wifi': { name: 'Wi-Fi', reachable: 'module-card', label: 'Wi-Fi', rootId: AutoId.wifiScanBtn },
  '/alerts': { name: 'Alerts', reachable: 'app-bar', rootId: AutoId.alertsRoot },
  '/intercept': { name: 'Link Warning', reachable: 'intent', rootId: AutoId.interceptRoot },
  '/fusion': { name: 'Threat Fusion', reachable: 'defense-tile', slug: 'fusion', rootId: AutoId.fusionUrlInput },
  '/arbitration': { name: 'Arbitration Log', reachable: 'defense-tile', slug: 'arbitration', rootId: AutoId.arbitrationRoot },
  '/risk': { name: 'Predictive Risk', reachable: 'defense-tile', slug: 'risk', rootId: AutoId.riskRoot },
  '/screenshot': { name: 'Screenshot Scanner', reachable: 'defense-tile', slug: 'screenshot', rootId: AutoId.screenshotPickBtn },
  '/settings': { name: 'Settings', reachable: 'app-bar', rootId: AutoId.settingsRoot },
};

/**
 * Returns to the dashboard from wherever the app currently is.
 *
 * Pressing back repeatedly is more robust than `driver.startActivity`, which
 * would restart the Flutter engine and wipe in-memory provider state that some
 * tests deliberately rely on.
 */
async function toDashboard({ maxBacks = 6 } = {}) {
  const driver = getDriver();

  if (await onboarding.isShown({ timeout: 1500 })) {
    await onboarding.skip();
  }

  // Sign-in gate. Present only when the build carries Firebase
  // credentials; CI has none, so the gate stands down there and this is a
  // no-op. When it IS present it must be cleared, or every route below
  // times out against a login form.
  const auth = await login.signInFromEnv();
  if (auth === 'no-credentials') {
    throw new Error(
      'The sign-in gate is up but CG_TEST_EMAIL / CG_TEST_PASSWORD are not set. ' +
      'This build has Firebase configured, so the suite cannot reach any screen ' +
      'without an account. Set both variables, or run against a build without ' +
      'android/app/google-services.json.',
    );
  }
  if (auth === 'signed-in') log.info('Signed in through the auth gate');

  for (let i = 0; i < maxBacks; i += 1) {
    if (await dashboard.isOpen({ timeout: 1200 })) {
      return dashboard;
    }
    await driver.back();
    await driver.pause(500);
  }

  if (await dashboard.isOpen({ timeout: 3000 })) return dashboard;

  // Last resort: relaunch. Records a warning because needing this usually
  // means a screen swallowed the back gesture.
  log.warn('Could not reach dashboard by backing out; relaunching the activity');
  await driver.execute('mobile: activateApp', { appId: 'com.cyberguard.ai' });
  await driver.pause(1500);
  await onboarding.dismiss();
  return dashboard.waitUntilLoaded();
}

/** Navigates to a route by its tap path. Throws for non-tappable routes. */
async function goTo(route) {
  const spec = ROUTES[route];
  if (!spec) throw new Error(`Unknown route: ${route}`);

  await toDashboard();

  switch (spec.reachable) {
    case 'home':
      return dashboard;
    case 'module-card':
      await dashboard.openModuleByLabel(spec.label);
      break;
    case 'defense-tile':
      await dashboard.openDefenseTile(spec.slug);
      break;
    case 'app-bar':
      if (route === '/alerts') await dashboard.openAlerts();
      else await dashboard.openSettings();
      break;
    default:
      throw new Error(
        `Route ${route} is not reachable by tapping (${spec.reachable}). ` +
          `Drive it explicitly from its own spec.`
      );
  }

  await getDriver().pause(700); // route transition
  return spec;
}

/** Tappable routes only — the set the navigation suite iterates. */
function tappableRoutes() {
  return Object.entries(ROUTES)
    .filter(([, s]) => ['module-card', 'defense-tile', 'app-bar'].includes(s.reachable))
    .map(([route, spec]) => ({ route, ...spec }));
}

module.exports = { ROUTES, toDashboard, goTo, tappableRoutes };
