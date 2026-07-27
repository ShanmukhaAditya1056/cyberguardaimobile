'use strict';

const path = require('path');

/**
 * Single source of truth for every environment-dependent value.
 *
 * Nothing in the suite may hardcode a device name, APK path or timeout — CI
 * and a local workstation differ on all three, and a hardcoded value is the
 * usual reason a suite that passes locally fails in Actions.
 */

const ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(ROOT, '..');

function bool(value, fallback) {
  if (value === undefined || value === '') return fallback;
  return /^(1|true|yes|on)$/i.test(String(value));
}

function int(value, fallback) {
  const n = parseInt(value, 10);
  return Number.isFinite(n) ? n : fallback;
}

const env = {
  // ── Paths ───────────────────────────────────────────────────────────────
  root: ROOT,
  repoRoot: REPO_ROOT,
  reportsDir: process.env.CG_REPORTS_DIR || path.join(ROOT, 'reports'),
  screenshotsDir: process.env.CG_SCREENSHOTS_DIR || path.join(ROOT, 'screenshots'),
  logsDir: process.env.CG_LOGS_DIR || path.join(ROOT, 'logs'),

  /**
   * APK under test. Defaults to the debug artifact `flutter build apk --debug`
   * drops, which is what CI builds.
   */
  appPath:
    process.env.CG_APP_PATH ||
    path.join(REPO_ROOT, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk'),

  // ── Appium server ───────────────────────────────────────────────────────
  appium: {
    protocol: process.env.APPIUM_PROTOCOL || 'http',
    hostname: process.env.APPIUM_HOST || '127.0.0.1',
    port: int(process.env.APPIUM_PORT, 4723),
    path: process.env.APPIUM_PATH || '/',
  },

  // ── Device under test ───────────────────────────────────────────────────
  device: {
    platformName: 'Android',
    automationName: 'UiAutomator2',
    deviceName: process.env.CG_DEVICE_NAME || 'Android Emulator',
    udid: process.env.CG_UDID || undefined,
    platformVersion: process.env.CG_PLATFORM_VERSION || undefined,
    appPackage: process.env.CG_APP_PACKAGE || 'com.cyberguard.ai',
    appActivity: process.env.CG_APP_ACTIVITY || 'com.cyberguard.ai.MainActivity',
  },

  // ── Timeouts (ms) ───────────────────────────────────────────────────────
  timeouts: {
    implicit: int(process.env.CG_IMPLICIT_TIMEOUT, 0),
    element: int(process.env.CG_ELEMENT_TIMEOUT, 15000),
    // The splash screen holds for a deliberate 1200ms, then Hive is read and
    // the router redirects. 30s gives a cold emulator room without masking a
    // genuine hang.
    appLaunch: int(process.env.CG_LAUNCH_TIMEOUT, 30000),
    scan: int(process.env.CG_SCAN_TIMEOUT, 45000),
    test: int(process.env.CG_TEST_TIMEOUT, 120000),
    newCommand: int(process.env.CG_NEW_COMMAND_TIMEOUT, 300),
  },

  // ── Execution behaviour ─────────────────────────────────────────────────
  run: {
    retries: int(process.env.CG_RETRIES, 1),
    /** Screenshot every test, not just failures. Off by default — it is slow. */
    screenshotAll: bool(process.env.CG_SCREENSHOT_ALL, false),
    /** Reset app state between suites so tests never inherit Hive data. */
    fullReset: bool(process.env.CG_FULL_RESET, false),
    /** Set by CI so reports can record provenance. */
    buildNumber: process.env.GITHUB_RUN_NUMBER || process.env.CG_BUILD_NUMBER || 'local',
    commit: process.env.GITHUB_SHA || process.env.CG_COMMIT || 'unknown',
    branch:
      process.env.GITHUB_REF_NAME || process.env.CG_BRANCH || 'unknown',
    ci: bool(process.env.CI, false),
  },

  /**
   * Hard safety switch. The suite must never drive load at a third-party
   * service (Google Safe Browsing, HIBP). Cloud threat intel is OFF by default
   * in the app and the suite keeps it that way unless a human opts in locally.
   * CI must never set this.
   */
  allowNetworkDependentTests: bool(process.env.CG_ALLOW_NETWORK_TESTS, false),
};

module.exports = env;
