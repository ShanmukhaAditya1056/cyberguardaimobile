'use strict';

/**
 * Root-level Mocha hooks: one Appium session for the whole run, plus the
 * per-test failure-evidence capture that the reports depend on.
 *
 * Loaded via `--require` in .mocharc.js so it applies to every spec file.
 */

const fs = require('fs');
const path = require('path');
const env = require('../config/env');
const { createDriver, deleteDriver, describeDevice } = require('../drivers/driver-factory');
const { capture, captureHierarchy, captureDeviceLogs } = require('../utils/screenshot');
const logger = require('../utils/logger');
const results = require('../reporting/collector');

const log = logger('hooks');

exports.mochaHooks = {
  async beforeAll() {
    this.timeout(300000);
    log.info('Run starting', {
      build: env.run.buildNumber,
      branch: env.run.branch,
      commit: env.run.commit.slice(0, 8),
    });

    for (const dir of [env.reportsDir, env.screenshotsDir, env.logsDir]) {
      fs.mkdirSync(dir, { recursive: true });
    }

    await createDriver();
    const device = await describeDevice();
    results.setEnvironment({
      ...device,
      buildNumber: env.run.buildNumber,
      commit: env.run.commit,
      branch: env.run.branch,
      startedAt: new Date().toISOString(),
      ci: env.run.ci,
    });
    log.info('Device under test', device);
  },

  async afterEach() {
    const test = this.currentTest;
    if (!test) return;

    const meta = test.testCaseMeta || (test.fn && test.fn.testCaseMeta) || null;
    const failed = test.state === 'failed';

    let screenshot = null;
    let hierarchy = null;
    let deviceLog = null;

    if (failed) {
      // Evidence is only useful if it is captured before anything else touches
      // the device, so this runs first and swallows its own errors.
      const label = meta ? meta.id : test.title;
      screenshot = await capture(this.driver, `FAIL-${label}`, { subdir: 'failures' });
      hierarchy = await captureHierarchy(this.driver, `FAIL-${label}`);
      deviceLog = await captureDeviceLogs(this.driver, `FAIL-${label}`);
      log.error(`FAILED ${label}`, { error: test.err && test.err.message });
    } else if (env.run.screenshotAll && test.state === 'passed') {
      screenshot = await capture(this.driver, meta ? meta.id : test.title, { subdir: 'passed' });
    }

    results.record({
      meta,
      title: test.title,
      fullTitle: test.fullTitle(),
      suite: test.parent ? test.parent.title : '',
      state: test.state || (test.pending ? 'pending' : 'unknown'),
      duration: test.duration || 0,
      error: test.err
        ? {
            message: logger.redact(test.err.message || ''),
            stack: logger.redact(test.err.stack || ''),
          }
        : null,
      screenshot,
      hierarchy: hierarchy ? path.relative(env.root, hierarchy) : null,
      deviceLog: deviceLog ? path.relative(env.root, deviceLog) : null,
      retries: test.currentRetry ? test.currentRetry() : 0,
    });
  },

  async afterAll() {
    this.timeout(120000);
    results.finalise();
    await deleteDriver();
    log.info('Run complete', results.summary());
  },
};

// Expose the driver on the Mocha context so hooks above can reach it.
Object.defineProperty(exports.mochaHooks, 'driver', {
  get() {
    try {
      return require('../drivers/driver-factory').getDriver();
    } catch {
      return null;
    }
  },
});
