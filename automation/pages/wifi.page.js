'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');
const env = require('../config/env');

/**
 * Wi-Fi trust scanner. Needs ACCESS_FINE_LOCATION (and NEARBY_WIFI_DEVICES on
 * API 33+) to read the SSID at all — on an emulator with no real Wi-Fi the
 * screen legitimately renders an empty/unavailable state, so tests assert that
 * it degrades gracefully rather than requiring a trust score.
 */
class WifiPage extends BasePage {
  constructor() {
    super('WifiPage', AutoId.wifiRoot);
  }

  get scanButton() {
    return this.byId(AutoId.wifiScanBtn);
  }

  async waitUntilLoaded() {
    await this.waitFor(this.scanButton, { as: 'Scan this network button' });
    return this;
  }

  async runScan({ timeout = env.timeouts.scan } = {}) {
    await this.tap(this.scanButton, { as: 'Scan this network' });
    await this.driver.waitUntil(
      async () => {
        const el = await this.driver.$(this.scanButton);
        const enabled = await el.getAttribute('enabled').catch(() => 'true');
        return enabled === 'true' || enabled === true;
      },
      { timeout, interval: 1000, timeoutMsg: `Wi-Fi scan did not settle in ${timeout}ms` }
    );
  }

  /** Emulators have no real AP; both outcomes are valid, neither may crash. */
  async hasResultOrEmptyState() {
    const score = await this.existsId(AutoId.wifiTrustScore, { timeout: 2500 });
    const empty = await this.existsId(AutoId.wifiEmptyState, { timeout: 2500 });
    return score || empty;
  }
}

module.exports = new WifiPage();
module.exports.WifiPage = WifiPage;
