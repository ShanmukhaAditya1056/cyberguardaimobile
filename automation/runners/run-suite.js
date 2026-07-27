'use strict';

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const env = require('../config/env');

/**
 * Entry point: runs Mocha, then generates reports **whether or not tests
 * passed**.
 *
 * This ordering is the whole point. A run where 12 tests fail is exactly the
 * run whose Excel and HTML reports matter most, so report generation must not
 * be conditional on a zero exit code. The process finally exits on the pass-rate
 * gate, after everything is written.
 */

function parseArgs(argv) {
  const args = { suite: null, grep: null, bail: false };
  for (const arg of argv.slice(2)) {
    if (arg.startsWith('--suite=')) args.suite = arg.split('=')[1];
    else if (arg.startsWith('--grep=')) args.grep = arg.split('=')[1];
    else if (arg === '--bail') args.bail = true;
  }
  return args;
}

/** Maps a friendly suite name to its spec glob. */
function specFor(suite) {
  if (!suite) return 'tests/**/*.spec.js';
  const known = {
    smoke: 'tests/smoke/**/*.spec.js',
    navigation: 'tests/navigation/**/*.spec.js',
    phishing: 'tests/phishing/**/*.spec.js',
    dashboard: 'tests/dashboard/**/*.spec.js',
    settings: 'tests/settings/**/*.spec.js',
    modules: 'tests/modules/**/*.spec.js',
    crosscutting: 'tests/crosscutting/**/*.spec.js',
    performance: 'tests/performance/**/*.spec.js',
  };
  return known[suite] || `tests/${suite}/**/*.spec.js`;
}

function run(command, args, options = {}) {
  return new Promise((resolve) => {
    const child = spawn(command, args, {
      cwd: env.root,
      stdio: 'inherit',
      shell: process.platform === 'win32',
      ...options,
    });
    child.on('close', (code) => resolve(code === null ? 1 : code));
  });
}

async function main() {
  const args = parseArgs(process.argv);

  // Keep the JS identifiers in step with the Dart source before anything runs.
  const { write, isUpToDate } = require('../config/sync-ids');
  if (!isUpToDate()) {
    const { count } = write();
    console.log(`[run-suite] Regenerated ${count} automation identifiers from the Dart source.`);
  }

  const mochaArgs = ['mocha', '--spec', specFor(args.suite)];
  if (args.grep) mochaArgs.push('--grep', args.grep);
  if (args.bail) mochaArgs.push('--bail');

  console.log(`[run-suite] Executing: npx ${mochaArgs.join(' ')}`);
  const testExit = await run('npx', mochaArgs);

  // ── Reports are generated unconditionally ──────────────────────────────
  console.log('\n[run-suite] Generating reports…');
  let data = null;
  try {
    data = await require('../reporting/generate-all').main();
  } catch (err) {
    console.error('[run-suite] Report generation failed:', err.message);
    // A reporting failure is itself a failure worth surfacing, but only after
    // we have reported the test outcome.
    process.exit(testExit || 1);
  }

  // ── Pass gate ──────────────────────────────────────────────────────────
  const s = data.summary;
  const threshold = parseFloat(process.env.CG_PASS_THRESHOLD || '95');

  console.log('');
  console.log('─'.repeat(60));
  console.log(` Total ${s.total} · executed ${s.executed} · passed ${s.passed} · failed ${s.failed}`);
  console.log(` Skipped ${s.skipped} · not applicable ${s.not_applicable}`);
  console.log(` Pass rate: ${s.passRate}% (threshold ${threshold}%)`);
  console.log('─'.repeat(60));

  if (s.executed === 0) {
    console.error('[run-suite] No tests executed — treating as a failure.');
    process.exit(1);
  }

  if (s.passRate < threshold) {
    console.error(`[run-suite] FAIL — pass rate ${s.passRate}% is below the ${threshold}% gate.`);
    process.exit(1);
  }

  console.log('[run-suite] PASS');
  process.exit(0);
}

main().catch((err) => {
  console.error('[run-suite] Fatal:', err);
  process.exit(1);
});
