'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/**
 * Settings is the longest screen in the app — most controls start below the
 * fold, so nearly every accessor scrolls first.
 *
 * Privacy note: `cloudIntel` is the toggle that lets URLs leave the device.
 * The suite asserts it defaults to OFF and that enabling it demands explicit
 * consent, but it never leaves it enabled.
 */
class SettingsPage extends BasePage {
  constructor() {
    super('SettingsPage', AutoId.settingsRoot);
  }

  // ── Toggles ─────────────────────────────────────────────────────────────
  get realTimeAlerts() {
    return this.byId(AutoId.settingsRealTimeAlerts);
  }
  get clipboardScan() {
    return this.byId(AutoId.settingsClipboardScan);
  }
  get wifiAutoScan() {
    return this.byId(AutoId.settingsWifiAutoScan);
  }
  get liveSmsGuard() {
    return this.byId(AutoId.settingsLiveSmsGuard);
  }
  get linkInterceptor() {
    return this.byId(AutoId.settingsLinkInterceptor);
  }
  get cloudIntel() {
    return this.byId(AutoId.settingsCloudIntel);
  }
  get linkHistory() {
    return this.byId(AutoId.settingsLinkHistory);
  }

  // ── HIBP key ────────────────────────────────────────────────────────────
  get hibpInput() {
    return this.byId(AutoId.settingsHibpInput);
  }
  get hibpSave() {
    return this.byId(AutoId.settingsHibpSave);
  }
  get hibpClear() {
    return this.byId(AutoId.settingsHibpClear);
  }

  // ── Reports & danger zone ───────────────────────────────────────────────
  get exportPdf() {
    return this.byId(AutoId.settingsExportPdf);
  }
  get exportCsv() {
    return this.byId(AutoId.settingsExportCsv);
  }
  get resetButton() {
    return this.byId(AutoId.settingsReset);
  }

  async waitUntilLoaded() {
    await this.waitFor(this.realTimeAlerts, { as: 'Real-time alerts toggle' });
    return this;
  }

  /** Scrolls the control into view, then reports its semantics toggle state. */
  async isEnabled(selector) {
    await this.scrollTo(selector, { as: 'toggle' });
    const el = await this.driver.$(selector);
    const checked = await el.getAttribute('checked');
    return checked === 'true' || checked === true;
  }

  async toggle(selector, { as = 'toggle' } = {}) {
    await this.scrollTo(selector, { as });
    const before = await this.isEnabled(selector);
    await this.tap(selector, { as });
    await this.driver.pause(500);
    const after = await this.isEnabled(selector);
    return { before, after, changed: before !== after };
  }

  async setHibpKey(key) {
    await this.scrollTo(this.hibpInput, { as: 'HIBP API key field' });
    await this.typeInto(this.hibpInput, key, { as: 'HIBP API key field' });
    await this.hideKeyboard();
    await this.tap(this.hibpSave, { as: 'Save HIBP key' });
  }

  async clearHibpKey() {
    await this.scrollTo(this.hibpClear, { as: 'Clear HIBP key' });
    await this.tap(this.hibpClear, { as: 'Clear HIBP key' });
  }

  /** Reads the version string rendered in the About block. */
  async readVersion() {
    const selector = this.byText('Version', { exact: false });
    await this.scrollTo(selector, { as: 'Version row' });
    // The row renders "Version" and the value as sibling text nodes; grab the
    // whole row's text and pull the semver out of it.
    const row = await this.driver.$(`${selector}/..`);
    const text = await row.getText();
    const m = String(text).match(/\d+\.\d+\.\d+/);
    return m ? m[0] : null;
  }

  /** Language picker exposes one chip per supported locale. */
  async selectLanguage(label) {
    const selector = this.byText(label, { exact: false });
    await this.scrollTo(selector, { as: `${label} language chip` });
    await this.tap(selector, { as: `${label} language chip` });
    await this.driver.pause(600); // locale rebuild
  }

  async tapReset() {
    await this.scrollTo(this.resetButton, { as: 'Reset button' });
    await this.tap(this.resetButton, { as: 'Reset button' });
  }
}

module.exports = new SettingsPage();
module.exports.SettingsPage = SettingsPage;
