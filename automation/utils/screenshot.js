'use strict';

const fs = require('fs');
const path = require('path');
const env = require('../config/env');
const logger = require('../utils/logger');

const log = logger('screenshot');

fs.mkdirSync(env.screenshotsDir, { recursive: true });

function slug(text) {
  return String(text)
    .replace(/[^a-z0-9]+/gi, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 90)
    .toLowerCase();
}

/**
 * Captures the device screen.
 *
 * Returns a path **relative to the reports root** so the HTML report can embed
 * it with a portable `src` that survives being copied to GitHub Pages. Never
 * throws: a failed screenshot must not convert a genuine assertion failure
 * into a confusing capture error.
 */
async function capture(driver, name, { subdir = '' } = {}) {
  if (!driver) return null;
  const dir = subdir ? path.join(env.screenshotsDir, subdir) : env.screenshotsDir;
  fs.mkdirSync(dir, { recursive: true });

  const filename = `${Date.now()}-${slug(name)}.png`;
  const absolute = path.join(dir, filename);

  try {
    const base64 = await driver.takeScreenshot();
    fs.writeFileSync(absolute, Buffer.from(base64, 'base64'));
    return path.posix.join('screenshots', subdir, filename).replace(/\/+/g, '/');
  } catch (err) {
    log.warn('Screenshot capture failed', { name, error: err.message });
    return null;
  }
}

/**
 * Dumps the current accessibility/UI hierarchy next to a failure.
 *
 * For a Flutter app this is the single most useful failure artefact: it shows
 * exactly which `resource-id`s the semantics tree actually published, which is
 * how you tell "the widget moved" apart from "the identifier was never wired
 * up on this screen".
 */
async function captureHierarchy(driver, name) {
  if (!driver) return null;
  const dir = path.join(env.logsDir, 'hierarchy');
  fs.mkdirSync(dir, { recursive: true });
  const file = path.join(dir, `${Date.now()}-${slug(name)}.xml`);
  try {
    const xml = await driver.getPageSource();
    fs.writeFileSync(file, xml, 'utf8');
    return file;
  } catch (err) {
    log.warn('Hierarchy dump failed', { name, error: err.message });
    return null;
  }
}

/** Pulls recent logcat lines so a crash has native context attached. */
async function captureDeviceLogs(driver, name, { lines = 300 } = {}) {
  if (!driver) return null;
  const dir = path.join(env.logsDir, 'device');
  fs.mkdirSync(dir, { recursive: true });
  const file = path.join(dir, `${Date.now()}-${slug(name)}.log`);
  try {
    const entries = await driver.getLogs('logcat');
    const text = entries
      .slice(-lines)
      .map((e) => `${e.timestamp} ${e.level} ${e.message}`)
      .join('\n');
    fs.writeFileSync(file, logger.redact(text), 'utf8');
    return file;
  } catch (err) {
    log.warn('logcat capture failed', { name, error: err.message });
    return null;
  }
}

module.exports = { capture, captureHierarchy, captureDeviceLogs, slug };
