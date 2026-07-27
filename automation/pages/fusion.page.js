'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');
const env = require('../config/env');

/**
 * Threat Fusion: combines every enabled ThreatIntelSource into one weighted
 * verdict. With cloud intel off (the default) the only live source is the
 * local ML model, so results are deterministic and fully offline.
 */
class FusionPage extends BasePage {
  constructor() {
    super('FusionPage', AutoId.fusionRoot);
  }

  get urlInput() {
    return this.byId(AutoId.fusionUrlInput);
  }

  get scanButton() {
    return this.byId(AutoId.fusionScanBtn);
  }

  async waitUntilLoaded() {
    await this.waitFor(this.urlInput, { as: 'fusion URL input' });
    return this;
  }

  async scan(url, { timeout = env.timeouts.scan } = {}) {
    await this.typeInto(this.urlInput, url, { as: 'fusion URL input' });
    await this.hideKeyboard();
    await this.tap(this.scanButton, { as: 'Run fusion scan' });
    await this.driver.waitUntil(
      async () => {
        const el = await this.driver.$(this.scanButton);
        const enabled = await el.getAttribute('enabled').catch(() => 'true');
        return enabled === 'true' || enabled === true;
      },
      { timeout, interval: 800, timeoutMsg: `Fusion scan did not finish in ${timeout}ms` }
    );
  }
}

module.exports = new FusionPage();
module.exports.FusionPage = FusionPage;
