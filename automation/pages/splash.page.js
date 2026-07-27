'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/**
 * Splash holds for a deliberate 1200ms, reads `onboardingComplete` from Hive,
 * then routes to /onboarding or /dashboard. It has no interactive elements —
 * the only thing worth asserting is that it does not hang.
 */
class SplashPage extends BasePage {
  constructor() {
    super('SplashPage', AutoId.splashRoot);
  }

  async isBranded() {
    return this.isDisplayed(this.byText('CyberGuard AI'), { timeout: 5000 });
  }

  async tagline() {
    return this.textOf(this.byText('Intelligent Security Assistant'));
  }
}

module.exports = new SplashPage();
module.exports.SplashPage = SplashPage;
