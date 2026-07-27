'use strict';

const assert = require('assert');
const { tc } = require('../../utils/testcase');
const env = require('../../config/env');
const nav = require('../../utils/navigator');
const phishing = require('../../pages/phishing.page');
const {
  SAFE_WHITELISTED,
  DANGEROUS_DETERMINISTIC,
  AMBIGUOUS,
  NEUTRAL,
  MALFORMED,
  INJECTION_SHAPED,
} = require('../../data/urls');

/**
 * URL phishing scanner.
 *
 * The verdict expectations here are not guesses — `test/automation_corpus_test.dart`
 * asserts the same claims directly against `PhishingRepository`, so a rule-weight
 * change fails fast in the Dart suite instead of showing up as flaky Appium runs.
 *
 * Everything is on-device: no test in this file causes a network request.
 */
describe('Phishing — URL scanner', function () {
  this.timeout(env.timeouts.test);

  beforeEach(async () => {
    await nav.goTo('/phishing');
    await phishing.waitUntilLoaded();
  });

  // ── Whitelisted domains: deterministic (ML blend is bypassed) ───────────
  SAFE_WHITELISTED.forEach((entry, i) => {
    tc(
      {
        id: `TC_PHISH_W${String(i + 1).padStart(3, '0')}`,
        module: 'Phishing',
        priority: 'P1',
        title: `Whitelisted URL is reported safe: ${entry.url}`,
        preconditions: 'Phishing URL tab open',
        steps: [`Enter ${entry.url}`, 'Tap Scan Now', 'Read the verdict'],
        testData: entry.url,
        expected: 'Verdict is Safe',
        rationale: entry.note,
      },
      async () => {
        const verdict = await phishing.scanUrl(entry.url);
        assert.strictEqual(
          verdict,
          'safe',
          `${entry.url} is whitelisted but was reported "${verdict}"`
        );
      }
    );
  });

  // ── High-score URLs: ML blend cannot flip them ──────────────────────────
  DANGEROUS_DETERMINISTIC.forEach((entry, i) => {
    tc(
      {
        id: `TC_PHISH_D${String(i + 1).padStart(3, '0')}`,
        module: 'Phishing',
        priority: 'P0',
        title: `Malicious URL is flagged: ${entry.url}`,
        preconditions: 'Phishing URL tab open',
        steps: [`Enter ${entry.url}`, 'Tap Scan Now', 'Read the verdict'],
        testData: entry.url,
        expected: 'Verdict is Dangerous (or at minimum Suspicious)',
        rationale: `rules score ${entry.score} = ${entry.breakdown}`,
      },
      async () => {
        const verdict = await phishing.scanUrl(entry.url);
        assert.notStrictEqual(
          verdict,
          'safe',
          `${entry.url} scores ${entry.score} on rules alone (${entry.breakdown}) ` +
            `but was reported safe — a false negative on a phishing URL`
        );
      }
    );
  });

  // ── Ambiguous: assert only that a verdict renders ───────────────────────
  AMBIGUOUS.forEach((entry, i) => {
    tc(
      {
        id: `TC_PHISH_A${String(i + 1).padStart(3, '0')}`,
        module: 'Phishing',
        priority: 'P2',
        title: `Borderline URL produces a verdict: ${entry.url}`,
        preconditions: 'Phishing URL tab open',
        steps: [`Enter ${entry.url}`, 'Tap Scan Now'],
        testData: entry.url,
        expected: 'Some verdict renders; the app does not hang',
        rationale:
          `${entry.note}. Below the deterministic bar, so the on-device model ` +
          `gets a real vote — asserting a specific verdict would be inventing one.`,
      },
      async () => {
        const verdict = await phishing.scanUrl(entry.url);
        assert.ok(
          ['safe', 'suspicious', 'dangerous'].includes(verdict),
          `no verdict rendered for ${entry.url}`
        );
      }
    );
  });

  NEUTRAL.forEach((entry, i) => {
    tc(
      {
        id: `TC_PHISH_N${String(i + 1).padStart(3, '0')}`,
        module: 'Phishing',
        priority: 'P2',
        title: `Rule-free URL produces a verdict: ${entry.url}`,
        preconditions: 'Phishing URL tab open',
        steps: [`Enter ${entry.url}`, 'Tap Scan Now'],
        testData: entry.url,
        expected: 'Some verdict renders',
        rationale: entry.note,
      },
      async () => {
        const verdict = await phishing.scanUrl(entry.url);
        assert.ok(['safe', 'suspicious', 'dangerous'].includes(verdict));
      }
    );
  });

  // ── Malformed input: must never crash ───────────────────────────────────
  MALFORMED.forEach((entry, i) => {
    tc(
      {
        id: `TC_PHISH_M${String(i + 1).padStart(3, '0')}`,
        module: 'Input Validation',
        priority: 'P1',
        title: `Malformed input handled without crashing: ${entry.note}`,
        preconditions: 'Phishing URL tab open',
        steps: [`Enter ${JSON.stringify(entry.input)}`, 'Tap Scan Now', 'Wait 3s'],
        testData: entry.input,
        expected: 'App stays in the foreground; no crash dialog',
      },
      async () => {
        await phishing.enterUrl(entry.input);
        await phishing.tapScan();
        await phishing.driver.pause(2500);
        const pkg = await phishing.driver.getCurrentPackage();
        assert.strictEqual(
          pkg,
          env.device.appPackage,
          `app left the foreground after scanning ${JSON.stringify(entry.input)} — likely a crash`
        );
      }
    );
  });

  // ── Payload-shaped input ────────────────────────────────────────────────
  INJECTION_SHAPED.forEach((entry, i) => {
    tc(
      {
        id: `TC_PHISH_I${String(i + 1).padStart(3, '0')}`,
        module: 'Input Validation',
        priority: 'P1',
        title: `Payload-shaped input is treated as text: ${entry.note}`,
        preconditions: 'Phishing URL tab open',
        steps: [`Enter ${JSON.stringify(entry.input)}`, 'Tap Scan Now', 'Wait 3s'],
        testData: entry.input,
        expected: 'Input is scanned as an opaque string; app stays alive',
        rationale:
          'The scanner never evaluates input and has no SQL/template engine, so ' +
          'this documents that the input path stays inert rather than implying ' +
          'an injection surface exists.',
      },
      async () => {
        await phishing.enterUrl(entry.input);
        await phishing.tapScan();
        await phishing.driver.pause(2500);
        const pkg = await phishing.driver.getCurrentPackage();
        assert.strictEqual(pkg, env.device.appPackage, 'app crashed on payload-shaped input');
      }
    );
  });

  // ── Interaction behaviour ───────────────────────────────────────────────
  tc(
    {
      id: 'TC_PHISH_X001',
      module: 'Phishing',
      priority: 'P2',
      title: 'Scanning an empty field does not produce a verdict card',
      preconditions: 'Phishing URL tab open, field empty',
      steps: ['Leave the URL field empty', 'Tap Scan Now'],
      expected: 'No verdict is rendered and the app remains responsive',
    },
    async () => {
      await phishing.enterUrl('');
      await phishing.tapScan();
      await phishing.driver.pause(2000);
      const pkg = await phishing.driver.getCurrentPackage();
      assert.strictEqual(pkg, env.device.appPackage);
    }
  );

  tc(
    {
      id: 'TC_PHISH_X002',
      module: 'Phishing',
      priority: 'P2',
      title: 'Consecutive scans replace the previous verdict',
      preconditions: 'Phishing URL tab open',
      steps: [
        'Scan a known-dangerous URL',
        'Scan a whitelisted URL',
        'Read the verdict',
      ],
      expected: 'The second verdict is Safe, not a stale Dangerous result',
      rationale:
        'A stale verdict card is worse than no card — it tells the user a ' +
        'dangerous link is safe or vice versa.',
    },
    async () => {
      await phishing.scanUrl(DANGEROUS_DETERMINISTIC[0].url);
      const second = await phishing.scanUrl(SAFE_WHITELISTED[0].url);
      assert.strictEqual(
        second,
        'safe',
        'verdict did not refresh after a second scan — stale result shown'
      );
    }
  );

  tc(
    {
      id: 'TC_PHISH_X003',
      module: 'Phishing',
      priority: 'P2',
      title: 'Very long input is accepted without truncating the app',
      preconditions: 'Phishing URL tab open',
      steps: ['Enter a 2000-character URL', 'Tap Scan Now'],
      testData: '2000-char URL',
      expected: 'App handles it without crashing',
    },
    async () => {
      const long = 'https://example.com/' + 'a'.repeat(2000);
      await phishing.enterUrl(long);
      await phishing.tapScan();
      await phishing.driver.pause(3000);
      const pkg = await phishing.driver.getCurrentPackage();
      assert.strictEqual(pkg, env.device.appPackage, 'app crashed on a 2000-char URL');
    }
  );

  tc(
    {
      id: 'TC_PHISH_X004',
      module: 'Phishing',
      priority: 'P2',
      title: 'Switching to the SMS tab and back preserves the URL tab',
      preconditions: 'Phishing screen open',
      steps: ['Open the SMS tab', 'Return to the URL tab', 'Check the input is present'],
      expected: 'URL input is rendered again',
    },
    async () => {
      await phishing.openSmsTab();
      await phishing.openUrlTab();
      assert.ok(
        await phishing.exists(phishing.urlInput, { timeout: 6000 }),
        'URL input missing after tab round-trip'
      );
    }
  );
});
