'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/**
 * Five-page pager. The final page's primary button requests SMS, location and
 * notification permissions before completing onboarding; `autoGrantPermissions`
 * in the capabilities means the system dialogs are auto-accepted in CI.
 */
class OnboardingPage extends BasePage {
  constructor() {
    super('OnboardingPage', AutoId.onboardingRoot);
    this.PAGE_COUNT = 5;
  }

  get skipButton() {
    return this.byId(AutoId.onboardingSkip);
  }

  get nextButton() {
    return this.byId(AutoId.onboardingNext);
  }

  async isShown({ timeout = 8000 } = {}) {
    return this.exists(this.nextButton, { timeout });
  }

  async skip() {
    await this.tap(this.skipButton, { as: 'Skip' });
  }

  async next() {
    await this.tap(this.nextButton, { as: 'Continue' });
  }

  /** Walks every page, then grants permissions on the last one. */
  async completeFully() {
    for (let i = 0; i < this.PAGE_COUNT; i += 1) {
      await this.next();
      await this.driver.pause(450); // page transition is 400ms
    }
  }

  /** Fast path used by most suites: bypass the tour without touching perms. */
  async dismiss() {
    if (await this.isShown({ timeout: 6000 })) {
      await this.skip();
      return true;
    }
    return false;
  }
}

module.exports = new OnboardingPage();
module.exports.OnboardingPage = OnboardingPage;
