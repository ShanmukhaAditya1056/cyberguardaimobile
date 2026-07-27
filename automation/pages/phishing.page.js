'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');
const env = require('../config/env');

/**
 * URL + SMS phishing scanner.
 *
 * Scanning is fully on-device (DistilBERT TFLite + heuristics), so these tests
 * are deterministic and need no network. Cloud threat intel is a separate,
 * default-off feature and is never enabled by this page object.
 */
class PhishingPage extends BasePage {
  constructor() {
    super('PhishingPage', AutoId.phishingRoot);
  }

  get urlInput() {
    return this.byId(AutoId.phishingUrlInput);
  }

  get scanButton() {
    return this.byId(AutoId.phishingScanBtn);
  }

  get pasteButton() {
    return this.byId(AutoId.phishingPasteBtn);
  }

  get qrButton() {
    return this.byId(AutoId.phishingQrBtn);
  }

  get urlTab() {
    return this.byId(AutoId.phishingTabUrl);
  }

  get smsTab() {
    return this.byId(AutoId.phishingTabSms);
  }

  get smsLoadButton() {
    return this.byId(AutoId.phishingSmsLoadBtn);
  }

  get smsScanAllButton() {
    return this.byId(AutoId.phishingSmsScanAllBtn);
  }

  async waitUntilLoaded() {
    await this.waitFor(this.urlInput, { as: 'URL input' });
    return this;
  }

  async enterUrl(url) {
    await this.typeInto(this.urlInput, url, { as: 'URL input' });
    await this.hideKeyboard();
  }

  async tapScan() {
    await this.tap(this.scanButton, { as: 'Scan Now' });
  }

  /**
   * Enters a URL, scans it and waits for a verdict.
   *
   * Resolution is detected by the risk wording appearing on screen. The app
   * renders one of Safe / Suspicious / Dangerous (localized), so the caller
   * gets back the raw verdict text and asserts on it.
   */
  async scanUrl(url, { timeout = env.timeouts.scan } = {}) {
    await this.enterUrl(url);
    await this.tapScan();
    return this.waitForVerdict({ timeout });
  }

  /**
   * Waits until any known risk word is rendered, then returns it normalised.
   * @returns {Promise<'safe'|'suspicious'|'dangerous'>}
   */
  async waitForVerdict({ timeout = env.timeouts.scan } = {}) {
    const words = {
      dangerous: ['Dangerous', 'High Risk', 'Phishing'],
      suspicious: ['Suspicious', 'Medium Risk', 'Caution'],
      safe: ['Safe', 'Low Risk', 'Legitimate'],
    };

    let found = null;
    await this.driver.waitUntil(
      async () => {
        for (const [verdict, labels] of Object.entries(words)) {
          for (const label of labels) {
            if (await this.exists(this.byText(label, { exact: false }), { timeout: 300 })) {
              found = verdict;
              return true;
            }
          }
        }
        return false;
      },
      {
        timeout,
        interval: 600,
        timeoutMsg:
          `No phishing verdict rendered within ${timeout}ms. ` +
          `Expected one of Safe / Suspicious / Dangerous.`,
      }
    );
    return found;
  }

  async openSmsTab() {
    await this.tap(this.smsTab, { as: 'SMS tab' });
    await this.driver.pause(400);
  }

  async openUrlTab() {
    await this.tap(this.urlTab, { as: 'URL tab' });
    await this.driver.pause(400);
  }

  async openQrScanner() {
    await this.tap(this.qrButton, { as: 'QR scanner' });
  }

  /** True when the Scan button is rendered but not actionable. */
  async isScanDisabled() {
    const el = await this.waitFor(this.scanButton, { as: 'Scan Now' });
    const enabled = await el.getAttribute('enabled');
    return enabled === 'false' || enabled === false;
  }
}

module.exports = new PhishingPage();
module.exports.PhishingPage = PhishingPage;
