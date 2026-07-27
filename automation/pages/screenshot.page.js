'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/**
 * Screenshot scam scanner (ML Kit on-device OCR + scam classifier).
 *
 * Driving the system gallery/camera picker from Appium means leaving the app
 * under test and automating vendor-specific system UI, which is the flakiest
 * thing you can put in a mobile suite. These tests therefore assert the screen
 * renders, the picker launches, and cancelling returns cleanly — the
 * classifier itself is covered by test/screenshot_classifier_test.dart.
 */
class ScreenshotPage extends BasePage {
  constructor() {
    super('ScreenshotPage', AutoId.screenshotRoot);
  }

  get pickButton() {
    return this.byId(AutoId.screenshotPickBtn);
  }

  async waitUntilLoaded() {
    await this.waitFor(this.pickButton, { as: 'Choose from gallery button' });
    return this;
  }

  async openGalleryPicker() {
    await this.tap(this.pickButton, { as: 'Choose from gallery' });
    await this.driver.pause(1500);
  }

  /** True when focus has left the app under test (system picker is up). */
  async isSystemPickerOpen() {
    const pkg = await this.driver.getCurrentPackage().catch(() => '');
    return Boolean(pkg) && pkg !== 'com.cyberguard.ai';
  }
}

module.exports = new ScreenshotPage();
module.exports.ScreenshotPage = ScreenshotPage;
