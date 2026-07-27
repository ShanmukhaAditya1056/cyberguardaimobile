'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/**
 * Breach monitor (Have I Been Pwned, k-anonymity).
 *
 * IMPORTANT: a live lookup calls haveibeenpwned.com. The suite therefore only
 * exercises input handling, validation and the offline breach database by
 * default. Tests that would issue a real HIBP request are gated behind
 * `env.allowNetworkDependentTests` and are never enabled in CI — hammering a
 * third-party API from a test matrix is abuse, and HIBP rate-limits hard.
 */
class BreachPage extends BasePage {
  constructor() {
    super('BreachPage', AutoId.breachRoot);
  }

  get input() {
    return this.byId(AutoId.breachEmailInput);
  }

  get checkButton() {
    return this.byId(AutoId.breachCheckBtn);
  }

  async waitUntilLoaded() {
    await this.waitFor(this.input, { as: 'email/phone input' });
    return this;
  }

  async enterEmail(email) {
    await this.typeInto(this.input, email, { as: 'email input' });
    await this.hideKeyboard();
  }

  async tapCheck() {
    await this.tap(this.checkButton, { as: 'Check breach' });
  }

  async switchToPhoneMode() {
    await this.tap(this.byText('Phone', { exact: false }), { as: 'Phone tab' });
    await this.driver.pause(300);
  }

  async switchToEmailMode() {
    await this.tap(this.byText('Email', { exact: false }), { as: 'Email tab' });
    await this.driver.pause(300);
  }

  /** True when the check action is rendered but not actionable. */
  async isCheckDisabled() {
    const el = await this.waitFor(this.checkButton, { as: 'Check breach' });
    const enabled = await el.getAttribute('enabled');
    return enabled === 'false' || enabled === false;
  }
}

module.exports = new BreachPage();
module.exports.BreachPage = BreachPage;
