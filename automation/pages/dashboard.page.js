'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');
const env = require('../config/env');

/**
 * The app shell. Every other screen is reached from here, so this page object
 * doubles as the navigation hub for the whole suite.
 */
class DashboardPage extends BasePage {
  constructor() {
    super('DashboardPage', AutoId.dashboardRoot);
  }

  get scanButton() {
    return this.byId(AutoId.dashboardScanFab);
  }

  get alertsButton() {
    return this.byId(AutoId.dashboardAlertsBtn);
  }

  get settingsButton() {
    return this.byId(AutoId.dashboardSettingsBtn);
  }

  get scoreValue() {
    return this.byId(AutoId.dashboardScoreValue);
  }

  /** Cyber-defense tiles are keyed by their route slug: fusion, risk, … */
  defenseTile(slug) {
    return this.byId(AutoId.defenseTile(slug));
  }

  async waitUntilLoaded() {
    await this.waitFor(this.scanButton, {
      as: 'Scan Now button',
      timeout: env.timeouts.appLaunch,
    });
    return this;
  }

  /**
   * Reads the unified security score.
   * Returns `null` before the first scan, when the ring renders an em-dash
   * placeholder rather than a number.
   */
  async readScore() {
    const raw = await this.textOf(this.scoreValue, { as: 'score value' });
    if (!raw || raw === '—') return null;
    const n = parseInt(raw, 10);
    return Number.isFinite(n) ? n : null;
  }

  async hasNeverScanned() {
    return (await this.readScore()) === null;
  }

  /**
   * Runs a quick scan and waits for the confirmation snackbar.
   *
   * The scan opportunistically probes Wi-Fi (only when location permission is
   * already granted) and always recomputes the unified score, so the snackbar
   * text varies. Both variants start with the same localized stem, so we wait
   * on the score becoming numeric instead of matching snackbar copy.
   */
  async runQuickScan({ timeout = env.timeouts.scan } = {}) {
    await this.tap(this.scanButton, { as: 'Scan Now' });
    await this.driver.waitUntil(
      async () => (await this.readScore()) !== null,
      {
        timeout,
        interval: 750,
        timeoutMsg: `Score never resolved to a number within ${timeout}ms after Scan Now`,
      }
    );
    return this.readScore();
  }

  async openAlerts() {
    await this.tap(this.alertsButton, { as: 'Alerts' });
  }

  async openSettings() {
    await this.tap(this.settingsButton, { as: 'Settings' });
  }

  async openDefenseTile(slug) {
    await this.tap(this.defenseTile(slug), { as: `${slug} tile` });
  }

  /** Module cards (Phishing/Malware/Breach/Wi-Fi) are matched by their label. */
  async openModuleByLabel(label) {
    const selector = this.byText(label, { exact: false });
    await this.scrollTo(selector, { as: `${label} module card` });
    await this.tap(selector, { as: `${label} module card` });
  }
}

module.exports = new DashboardPage();
module.exports.DashboardPage = DashboardPage;
