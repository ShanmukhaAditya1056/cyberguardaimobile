'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/** Predictive risk forecast, derived from the stored score history. */
class RiskPage extends BasePage {
  constructor() {
    super('RiskPage', AutoId.riskRoot);
  }

  async waitUntilLoaded() {
    await this.driver.waitUntil(
      async () =>
        (await this.existsId(AutoId.riskForecastCard, { timeout: 500 })) ||
        (await this.isDisplayed(this.byText('Risk', { exact: false }), { timeout: 500 })),
      { timeout: 15000, timeoutMsg: 'Predictive risk screen never rendered' }
    );
    return this;
  }
}

module.exports = new RiskPage();
module.exports.RiskPage = RiskPage;
