'use strict';

const fs = require('fs');
const http = require('http');
const { execSync } = require('child_process');
const env = require('../config/env');

/**
 * Preflight check.
 *
 * Every item here corresponds to a real way this suite fails with a confusing
 * error. Diagnosing "element not found" when the actual problem is "no emulator
 * is attached" wastes far more time than running this first.
 */

const results = [];

function check(name, fn, { fatal = true, hint = '' } = {}) {
  try {
    const detail = fn();
    results.push({ name, ok: true, detail: detail || 'ok', fatal });
  } catch (err) {
    results.push({ name, ok: false, detail: err.message, fatal, hint });
  }
}

function sh(cmd) {
  return execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
}

function httpGet(url, timeout = 2500) {
  return new Promise((resolve, reject) => {
    const req = http.get(url, (res) => {
      res.resume();
      resolve(res.statusCode);
    });
    req.setTimeout(timeout, () => {
      req.destroy();
      reject(new Error('timed out'));
    });
    req.on('error', reject);
  });
}

async function main() {
  check('Node version', () => {
    const major = parseInt(process.versions.node.split('.')[0], 10);
    if (major < 20) throw new Error(`Node ${process.versions.node} — need >= 20`);
    return `v${process.versions.node}`;
  });

  check(
    'adb on PATH',
    () => sh('adb version').split('\n')[0],
    { hint: 'Add $ANDROID_HOME/platform-tools to PATH.' }
  );

  check(
    'A device or emulator is attached',
    () => {
      const out = sh('adb devices');
      const devices = out
        .split('\n')
        .slice(1)
        .map((l) => l.trim())
        .filter((l) => l && l.endsWith('device'));
      if (devices.length === 0) throw new Error('no attached devices (adb devices is empty)');
      return `${devices.length} device(s): ${devices.map((d) => d.split('\t')[0]).join(', ')}`;
    },
    { hint: 'Start an emulator: emulator -avd <name>, or plug in a device with USB debugging on.' }
  );

  check(
    'App package is installed',
    () => {
      const out = sh(`adb shell pm list packages ${env.device.appPackage}`);
      if (!out.includes(env.device.appPackage)) {
        throw new Error(`${env.device.appPackage} is not installed`);
      }
      return env.device.appPackage;
    },
    {
      fatal: false,
      hint:
        'Build and install it: flutter build apk --debug && adb install -r ' +
        'build/app/outputs/flutter-apk/app-debug.apk',
    }
  );

  check(
    'APK artifact exists',
    () => {
      if (!fs.existsSync(env.appPath)) throw new Error(`not found at ${env.appPath}`);
      const mb = (fs.statSync(env.appPath).size / 1024 / 1024).toFixed(1);
      return `${env.appPath} (${mb} MB)`;
    },
    { fatal: false, hint: 'Run: flutter build apk --debug' }
  );

  check('Automation identifiers are in sync with the Dart source', () => {
    const { isUpToDate, write } = require('../config/sync-ids');
    if (!isUpToDate()) {
      const { count } = write();
      return `regenerated (${count} identifiers)`;
    }
    return 'up to date';
  });

  check('Node dependencies installed', () => {
    require.resolve('webdriverio');
    require.resolve('exceljs');
    require.resolve('mocha');
    return 'webdriverio, exceljs, mocha resolved';
  }, { hint: 'Run: npm install' });

  // Appium server reachability is async.
  const appiumUrl = `http://${env.appium.hostname}:${env.appium.port}/status`;
  try {
    const status = await httpGet(appiumUrl);
    results.push({
      name: 'Appium server reachable',
      ok: status === 200,
      detail: `${appiumUrl} -> HTTP ${status}`,
      fatal: true,
      hint: status === 200 ? '' : 'Start it: npx appium --allow-cors --relaxed-security',
    });
  } catch (err) {
    results.push({
      name: 'Appium server reachable',
      ok: false,
      detail: `${appiumUrl} — ${err.message}`,
      fatal: true,
      hint: 'Start it: npx appium --allow-cors --relaxed-security',
    });
  }

  // ── Report ────────────────────────────────────────────────────────────
  console.log('');
  console.log('CyberGuard Appium suite — preflight');
  console.log('─'.repeat(66));
  let fatalFailures = 0;
  for (const r of results) {
    const icon = r.ok ? '✓' : r.fatal ? '✗' : '!';
    console.log(`${icon} ${r.name}`);
    console.log(`    ${r.detail}`);
    if (!r.ok && r.hint) console.log(`    → ${r.hint}`);
    if (!r.ok && r.fatal) fatalFailures += 1;
  }
  console.log('─'.repeat(66));

  if (fatalFailures > 0) {
    console.log(`${fatalFailures} blocking problem(s). Fix these before running the suite.`);
    process.exit(1);
  }
  console.log('Ready to run: npm test');
  process.exit(0);
}

main().catch((err) => {
  console.error('doctor failed:', err);
  process.exit(1);
});
