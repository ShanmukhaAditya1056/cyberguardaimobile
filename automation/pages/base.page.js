'use strict';

const env = require('../config/env');
const { getDriver } = require('../drivers/driver-factory');
const logger = require('../utils/logger');

/**
 * Shared behaviour for every page object.
 *
 * All element access funnels through here so that:
 *  - locators are built one way (resource-id first, text as a fallback),
 *  - waits are always explicit — there is no implicit wait to hide races,
 *  - a failure message names the page, the logical element and the locator
 *    that was actually used, instead of webdriverio's default
 *    "element ("//*[...]") still not displayed after 15000ms".
 */
class BasePage {
  /**
   * @param {string} name Page name used in logs and failure messages.
   * @param {string} rootId Automation id that proves this page is on screen.
   */
  constructor(name, rootId) {
    this.name = name;
    this.rootId = rootId;
    this.log = logger(name);
  }

  get driver() {
    return getDriver();
  }

  // ── Locator builders ────────────────────────────────────────────────────

  /**
   * Flutter publishes `Semantics(identifier:)` as `viewIdResourceName`, which
   * UiAutomator2 exposes as `resource-id`. Matching on the raw attribute (not
   * the `id` strategy) avoids UiAutomator2's package-prefixing rules, which do
   * not apply to identifiers minted by the Flutter engine.
   */
  byId(id) {
    return `//*[@resource-id="${id}"]`;
  }

  byText(text, { exact = true } = {}) {
    return exact
      ? `//*[@text=${xpathLiteral(text)}]`
      : `//*[contains(@text, ${xpathLiteral(text)})]`;
  }

  byContentDesc(label) {
    return `//*[@content-desc=${xpathLiteral(label)}]`;
  }

  // ── Core interactions ───────────────────────────────────────────────────

  /**
   * Waits for an element and returns it.
   * @param {string} selector XPath.
   * @param {object} opts
   * @param {string} opts.as Human name used in the failure message.
   */
  async waitFor(selector, { as = selector, timeout = env.timeouts.element, visible = true } = {}) {
    const el = await this.driver.$(selector);
    try {
      await el.waitForExist({ timeout });
      if (visible) await el.waitForDisplayed({ timeout });
    } catch (err) {
      throw new Error(
        `[${this.name}] "${as}" not found after ${timeout}ms.\n` +
          `  locator: ${selector}\n` +
          `  hint: dump the hierarchy (logs/hierarchy/) to see which resource-ids the ` +
          `semantics tree actually published on this screen.`
      );
    }
    return el;
  }

  async tap(selector, opts = {}) {
    const el = await this.waitFor(selector, opts);
    // `click()` on UiAutomator2 resolves to a tap at the element's centre,
    // which is what we want for Flutter semantics nodes (they carry bounds but
    // not always a click action).
    await el.click();
    this.log.debug('tapped', { element: opts.as || selector });
    return el;
  }

  async tapId(id, as) {
    return this.tap(this.byId(id), { as: as || id });
  }

  async typeInto(selector, text, { as, clearFirst = true } = {}) {
    const el = await this.waitFor(selector, { as: as || selector });
    await el.click();
    if (clearFirst) {
      try {
        await el.clearValue();
      } catch {
        // Some Flutter text fields do not implement clear; fall back to a
        // select-all + delete via the keyboard.
        await this.driver.execute('mobile: performEditorAction', { action: 'selectAll' }).catch(() => {});
      }
    }
    await el.addValue(text);
    this.log.debug('typed', { element: as || selector, length: String(text).length });
    return el;
  }

  async typeIntoId(id, text, as) {
    return this.typeInto(this.byId(id), text, { as: as || id });
  }

  async textOf(selector, { as } = {}) {
    const el = await this.waitFor(selector, { as: as || selector });
    const text = await el.getText();
    return (text || '').trim();
  }

  async textOfId(id, as) {
    return this.textOf(this.byId(id), { as: as || id });
  }

  /** Non-throwing existence check. Use for "is the empty state showing?". */
  async exists(selector, { timeout = 3000 } = {}) {
    try {
      const el = await this.driver.$(selector);
      await el.waitForExist({ timeout });
      return true;
    } catch {
      return false;
    }
  }

  async existsId(id, opts) {
    return this.exists(this.byId(id), opts);
  }

  async isDisplayed(selector, { timeout = 3000 } = {}) {
    try {
      const el = await this.driver.$(selector);
      await el.waitForDisplayed({ timeout });
      return true;
    } catch {
      return false;
    }
  }

  /** Reads the semantics `toggled` state that `_ToggleTile` publishes. */
  async isToggledId(id) {
    const el = await this.waitFor(this.byId(id), { as: id });
    const checked = await el.getAttribute('checked');
    return checked === 'true' || checked === true;
  }

  // ── Navigation & state ──────────────────────────────────────────────────

  /** True when this page's root identifier is on screen. */
  async isOpen({ timeout = env.timeouts.element } = {}) {
    if (!this.rootId) {
      throw new Error(`[${this.name}] has no rootId; cannot assert isOpen().`);
    }
    return this.exists(this.byId(this.rootId), { timeout });
  }

  async waitUntilOpen({ timeout = env.timeouts.element } = {}) {
    await this.waitFor(this.byId(this.rootId), {
      as: `${this.name} root`,
      timeout,
      visible: false,
    });
    return this;
  }

  async back() {
    await this.driver.back();
  }

  async scrollDown({ times = 1 } = {}) {
    const { width, height } = await this.driver.getWindowSize();
    for (let i = 0; i < times; i += 1) {
      await this.driver.performActions([
        {
          type: 'pointer',
          id: 'finger1',
          parameters: { pointerType: 'touch' },
          actions: [
            { type: 'pointerMove', duration: 0, x: Math.round(width / 2), y: Math.round(height * 0.75) },
            { type: 'pointerDown', button: 0 },
            { type: 'pause', duration: 100 },
            { type: 'pointerMove', duration: 400, x: Math.round(width / 2), y: Math.round(height * 0.25) },
            { type: 'pointerUp', button: 0 },
          ],
        },
      ]);
      await this.driver.releaseActions();
    }
  }

  /**
   * Scrolls until `selector` appears, for long screens like Settings where the
   * target starts far below the fold.
   */
  async scrollTo(selector, { maxScrolls = 8, as = selector } = {}) {
    for (let i = 0; i < maxScrolls; i += 1) {
      if (await this.exists(selector, { timeout: 800 })) {
        return this.driver.$(selector);
      }
      await this.scrollDown();
    }
    throw new Error(
      `[${this.name}] "${as}" not reachable after ${maxScrolls} scrolls.\n  locator: ${selector}`
    );
  }

  async hideKeyboard() {
    try {
      if (await this.driver.isKeyboardShown()) {
        await this.driver.hideKeyboard();
      }
    } catch {
      // Not all Android builds implement hideKeyboard; harmless.
    }
  }
}

/**
 * Safely embeds arbitrary text in an XPath literal.
 * XPath 1.0 has no escape syntax, so a string containing both quote types must
 * be assembled with `concat()`.
 */
function xpathLiteral(value) {
  const s = String(value);
  if (!s.includes("'")) return `'${s}'`;
  if (!s.includes('"')) return `"${s}"`;
  const parts = s.split("'").map((part) => `'${part}'`);
  return `concat(${parts.join(`, "'", `)})`;
}

module.exports = { BasePage, xpathLiteral };
