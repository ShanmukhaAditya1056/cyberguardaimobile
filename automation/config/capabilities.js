'use strict';

const fs = require('fs');
const env = require('./env');

/**
 * Builds W3C capabilities for the UiAutomator2 driver.
 *
 * Why UiAutomator2 and not appium-flutter-driver: Flutter paints into a single
 * `FlutterView`, so a driver normally sees one opaque node. Rather than ship a
 * special `enableFlutterDriverExtension()` build (which then is not the APK
 * users install), the app publishes a semantics tree and every widget of
 * interest carries a `Semantics(identifier:)`. The engine maps that onto
 * `AccessibilityNodeInfo.viewIdResourceName`, so UiAutomator2 sees ordinary
 * **resource-id**s and we test the same APK that ships.
 */
function buildCapabilities(overrides = {}) {
  const d = env.device;

  const caps = {
    platformName: d.platformName,
    'appium:automationName': d.automationName,
    'appium:deviceName': d.deviceName,
    'appium:appPackage': d.appPackage,
    'appium:appActivity': d.appActivity,

    // Flutter's semantics tree is only built when an accessibility client is
    // attached. UiAutomator2 attaches one, but the tree is produced lazily on
    // the next frame — the generous element timeout below absorbs that.
    'appium:newCommandTimeout': env.timeouts.newCommand,
    'appium:androidInstallTimeout': 120000,
    'appium:adbExecTimeout': 120000,
    'appium:uiautomator2ServerLaunchTimeout': 120000,
    'appium:uiautomator2ServerInstallTimeout': 120000,

    // Do not let the driver spend 10s per lookup guessing; the page objects
    // do their own explicit waiting, which produces far better failure text.
    'appium:waitForIdleTimeout': 200,

    // Emulators are slow to settle after an animation. Disabling window
    // animations makes element bounds stable and cuts flake substantially.
    'appium:disableWindowAnimation': true,
    'appium:ignoreHiddenApiPolicyError': true,

    // Keep the app's own data between tests inside a suite; suites that need
    // a clean slate call `resetAppState()` explicitly.
    'appium:noReset': !env.run.fullReset,
    'appium:fullReset': env.run.fullReset,

    'appium:autoGrantPermissions': true,
  };

  if (d.udid) caps['appium:udid'] = d.udid;
  if (d.platformVersion) caps['appium:platformVersion'] = d.platformVersion;

  // Only hand Appium an `app` when the APK actually exists. If the package is
  // already installed on the device, omitting `app` makes session start much
  // faster and avoids a reinstall on every suite.
  if (env.appPath && fs.existsSync(env.appPath)) {
    caps['appium:app'] = env.appPath;
  }

  return { ...caps, ...overrides };
}

module.exports = { buildCapabilities };
