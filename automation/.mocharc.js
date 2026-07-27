'use strict';

const env = require('./config/env');

/**
 * Mocha configuration.
 *
 * `bail: false` is deliberate — a full pass/fail matrix is the deliverable, so
 * one early failure must not hide the state of the other 200 cases.
 */
module.exports = {
  require: ['./tests/hooks.js'],
  spec: ['tests/**/*.spec.js'],
  timeout: env.timeouts.test,
  retries: env.run.retries,
  bail: false,
  reporter: 'spec',
  slow: 10000,
  // Suites share one Appium session, so they must not interleave.
  parallel: false,
  color: true,
};
