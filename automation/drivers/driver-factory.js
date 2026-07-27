'use strict';

const { remote } = require('webdriverio');
const env = require('../config/env');
const { buildCapabilities } = require('../config/capabilities');
const logger = require('../utils/logger');

const log = logger('driver');

/**
 * Owns the single WebDriver session shared by a Mocha run.
 *
 * One session per run rather than per test: an Appium session costs 10-25s to
 * establish on an emulator, and 200+ tests each paying that would put the suite
 * well past any sane CI budget. Isolation is instead provided by
 * `resetToDashboard()`, which is what the page objects call in `beforeEach`.
 */

let driver = null;

async function createDriver(overrides = {}) {
  if (driver) return driver;

  const capabilities = buildCapabilities(overrides);
  log.info('Starting Appium session', {
    host: `${env.appium.hostname}:${env.appium.port}`,
    app: capabilities['appium:app'] ? 'apk supplied' : 'using installed package',
    pkg: capabilities['appium:appPackage'],
  });

  driver = await remote({
    protocol: env.appium.protocol,
    hostname: env.appium.hostname,
    port: env.appium.port,
    path: env.appium.path,
    capabilities,
    logLevel: process.env.CG_WDIO_LOG_LEVEL || 'error',
    connectionRetryCount: 2,
    connectionRetryTimeout: 180000,
    waitforTimeout: env.timeouts.element,
  });

  if (env.timeouts.implicit > 0) {
    await driver.setTimeout({ implicit: env.timeouts.implicit });
  }

  const caps = driver.capabilities || {};
  log.info('Session ready', {
    sessionId: driver.sessionId,
    device: caps.deviceModel || caps.deviceName,
    androidVersion: caps.platformVersion,
    apiLevel: caps.deviceApiLevel,
  });

  return driver;
}

function getDriver() {
  if (!driver) {
    throw new Error(
      'No active Appium session. createDriver() must run in a root-level before() hook.'
    );
  }
  return driver;
}

async function deleteDriver() {
  if (!driver) return;
  try {
    await driver.deleteSession();
    log.info('Session closed');
  } catch (err) {
    log.warn('deleteSession failed (device may already be gone)', {
      error: err.message,
    });
  } finally {
    driver = null;
  }
}

/**
 * Device/session facts recorded in every report so a result can be traced back
 * to the hardware that produced it.
 */
async function describeDevice() {
  if (!driver) return {};
  const caps = driver.capabilities || {};
  let appVersion = 'unknown';
  try {
    // `dumpsys package` is the only reliable way to read versionName without
    // adding a dependency on the build system.
    const out = await driver.execute('mobile: shell', {
      command: 'dumpsys',
      args: ['package', env.device.appPackage, '|', 'grep', 'versionName'],
    });
    const m = String(out).match(/versionName=([^\s]+)/);
    if (m) appVersion = m[1];
  } catch {
    // `mobile: shell` needs --relaxed-security; not fatal for reporting.
  }

  return {
    device: caps.deviceModel || env.device.deviceName,
    manufacturer: caps.deviceManufacturer || 'unknown',
    androidVersion: caps.platformVersion || 'unknown',
    apiLevel: caps.deviceApiLevel || 'unknown',
    screenSize: caps.deviceScreenSize || 'unknown',
    appPackage: env.device.appPackage,
    appVersion,
    udid: caps.udid || env.device.udid || 'unknown',
  };
}

module.exports = { createDriver, getDriver, deleteDriver, describeDevice };
