'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/** Alert history, backed by the Hive alerts box. */
class AlertsPage extends BasePage {
  constructor() {
    super('AlertsPage', AutoId.alertsRoot);
  }

  get clearButton() {
    return this.byId(AutoId.alertsClearBtn);
  }

  async waitUntilLoaded() {
    // The clear action only renders when alerts exist, so wait on either it or
    // the empty state — whichever the current data produces.
    await this.driver.waitUntil(
      async () =>
        (await this.exists(this.clearButton, { timeout: 500 })) ||
        (await this.existsId(AutoId.alertsEmptyState, { timeout: 500 })) ||
        (await this.isDisplayed(this.byText('Alerts', { exact: false }), { timeout: 500 })),
      { timeout: 15000, timeoutMsg: 'Alerts screen never rendered a list or empty state' }
    );
    return this;
  }

  async isEmpty() {
    return this.existsId(AutoId.alertsEmptyState, { timeout: 2500 });
  }

  async clearAll() {
    await this.tap(this.clearButton, { as: 'Clear all alerts' });
    const confirm = this.byText('Clear', { exact: false });
    if (await this.exists(confirm, { timeout: 2500 })) {
      await this.tap(confirm, { as: 'Confirm clear' });
    }
  }
}

module.exports = new AlertsPage();
module.exports.AlertsPage = AlertsPage;
