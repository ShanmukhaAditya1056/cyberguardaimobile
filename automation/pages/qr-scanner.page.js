'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/**
 * QR phishing scanner. A headless emulator has no usable camera feed, so the
 * suite verifies the screen opens, requests camera permission and can be
 * dismissed without leaking the camera session — not that a code is decoded.
 */
class QrScannerPage extends BasePage {
  constructor() {
    super('QrScannerPage', AutoId.qrRoot);
  }

  async waitUntilLoaded() {
    await this.driver.waitUntil(
      async () =>
        (await this.existsId(AutoId.qrCloseBtn, { timeout: 500 })) ||
        (await this.isDisplayed(this.byText('QR', { exact: false }), { timeout: 500 })),
      { timeout: 15000, timeoutMsg: 'QR scanner never rendered' }
    );
    return this;
  }

  async close() {
    if (await this.existsId(AutoId.qrCloseBtn, { timeout: 2000 })) {
      await this.tapId(AutoId.qrCloseBtn, 'Close QR scanner');
    } else {
      await this.back();
    }
  }
}

module.exports = new QrScannerPage();
module.exports.QrScannerPage = QrScannerPage;
