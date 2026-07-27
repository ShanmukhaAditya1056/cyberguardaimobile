'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/**
 * Arbitration log: records every case where two threat-intel sources disagreed
 * and a higher-trust source overrode a lower-trust one. Empty on a fresh
 * install, which is the expected state for most runs.
 */
class ArbitrationPage extends BasePage {
  constructor() {
    super('ArbitrationPage', AutoId.arbitrationRoot);
  }

  async waitUntilLoaded() {
    await this.driver.waitUntil(
      async () =>
        (await this.existsId(AutoId.arbitrationList, { timeout: 500 })) ||
        (await this.existsId(AutoId.arbitrationEmptyState, { timeout: 500 })) ||
        (await this.isDisplayed(this.byText('Arbitration', { exact: false }), { timeout: 500 })),
      { timeout: 15000, timeoutMsg: 'Arbitration log never rendered' }
    );
    return this;
  }

  async isEmpty() {
    return this.existsId(AutoId.arbitrationEmptyState, { timeout: 2500 });
  }
}

module.exports = new ArbitrationPage();
module.exports.ArbitrationPage = ArbitrationPage;
