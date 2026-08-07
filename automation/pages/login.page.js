'use strict';

const { BasePage } = require('./base.page');
const { AutoId } = require('../config/auto-ids.generated');

/**
 * Sign-in screen.
 *
 * Sign-in is mandatory whenever the build has Firebase credentials, so this
 * screen sits between a cold start and every other screen in the app. Builds
 * without `android/app/google-services.json` — CI's default — cannot sign in
 * at all, so the router gate stands down there and this screen never appears.
 * `isShown()` therefore has to be treated as "maybe", not "always".
 *
 * Credentials come from the environment so no account details live in the
 * repository:
 *   CG_TEST_EMAIL, CG_TEST_PASSWORD
 */
class LoginPage extends BasePage {
  constructor() {
    super('LoginPage', AutoId.loginRoot);
  }

  get emailField() {
    return this.byId(AutoId.loginEmail);
  }

  get passwordField() {
    return this.byId(AutoId.loginPassword);
  }

  get submitButton() {
    return this.byId(AutoId.loginSubmit);
  }

  get googleButton() {
    return this.byId(AutoId.loginGoogle);
  }

  get registerTab() {
    return this.byId(AutoId.loginTabRegister);
  }

  get signInTab() {
    return this.byId(AutoId.loginTabSignIn);
  }

  get errorBanner() {
    return this.byId(AutoId.loginError);
  }

  /** True when the gate is up and this screen is in front of the user. */
  async isShown({ timeout = 8000 } = {}) {
    return this.exists(this.emailField, { timeout });
  }

  /**
   * True when the build has no Firebase config — the form is replaced by an
   * explanation and there is nothing to sign in to.
   */
  async isUnavailable({ timeout = 2000 } = {}) {
    return this.exists(this.byId(AutoId.loginUnavailable), { timeout });
  }

  async signIn(email, password) {
    await this.typeInto(this.emailField, email, { as: 'Email' });
    await this.typeInto(this.passwordField, password, { as: 'Password' });
    await this.tap(this.submitButton, { as: 'Sign In' });
  }

  /**
   * Polls until the selector is no longer present. BasePage has waitUntilOpen
   * but no inverse, and the sign-in handshake is defined by the login root
   * going away rather than by any element appearing.
   */
  async waitUntilGone(selector, { timeout = 20000, interval = 500 } = {}) {
    const deadline = Date.now() + timeout;
    while (Date.now() < deadline) {
      if (!(await this.exists(selector, { timeout: interval }))) return true;
    }
    throw new Error(
      `${this.name}: element still present after ${timeout}ms — sign-in did not complete. ` +
        'Check the credentials and that Email/Password is enabled in the Firebase console.',
    );
  }

  /**
   * Signs in with the credentials in the environment.
   *
   * Returns 'signed-in' | 'not-required' | 'no-credentials' rather than
   * throwing, so the caller decides whether a missing account is fatal. A
   * suite that silently skipped the gate would report green while testing a
   * configuration nobody ships.
   */
  async signInFromEnv({ timeout = 20000 } = {}) {
    if (!(await this.isShown({ timeout: 5000 }))) {
      if (await this.isUnavailable()) return 'not-required';
      return 'not-required';
    }

    const email = process.env.CG_TEST_EMAIL;
    const password = process.env.CG_TEST_PASSWORD;
    if (!email || !password) return 'no-credentials';

    await this.signIn(email, password);

    // The router releases the gate on the auth state change; the login root
    // disappearing is the signal that it happened.
    await this.waitUntilGone(this.emailField, { timeout });
    return 'signed-in';
  }
}

module.exports = new LoginPage();
module.exports.LoginPage = LoginPage;
