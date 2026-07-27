'use strict';

const fs = require('fs');
const path = require('path');
const env = require('../config/env');

/**
 * Accumulates one record per executed test, then writes the canonical
 * `execution-results.json`.
 *
 * Every other report (Excel, HTML, Markdown, the Actions summary) is generated
 * from that one file rather than from live Mocha state. That keeps report
 * generation reproducible — you can regenerate the whole set from a downloaded
 * artifact without re-running the suite — and stops four generators from
 * disagreeing about what "passed" means.
 */

const state = {
  environment: {},
  results: [],
  startedAt: Date.now(),
  finishedAt: null,
};

function setEnvironment(envInfo) {
  state.environment = { ...state.environment, ...envInfo };
}

/** Normalises Mocha's states into the five the reports use. */
function normaliseStatus(record) {
  if (record.meta && record.meta.notApplicable) return 'not_applicable';
  switch (record.state) {
    case 'passed':
      return 'passed';
    case 'failed':
      return 'failed';
    case 'pending':
      return 'skipped';
    default:
      return 'blocked';
  }
}

function record(entry) {
  const meta = entry.meta || {};
  state.results.push({
    id: meta.id || null,
    module: meta.module || inferModule(entry.suite),
    priority: meta.priority || 'P2',
    title: meta.title || entry.title,
    mochaTitle: entry.title,
    suite: entry.suite,
    fullTitle: entry.fullTitle,
    preconditions: meta.preconditions || '—',
    steps: meta.steps || [],
    testData: meta.testData || '—',
    expected: meta.expected || '—',
    rationale: meta.rationale || '',
    status: normaliseStatus(entry),
    durationMs: entry.duration || 0,
    error: entry.error,
    screenshot: entry.screenshot,
    hierarchy: entry.hierarchy,
    deviceLog: entry.deviceLog,
    retries: entry.retries || 0,
    recordedAt: new Date().toISOString(),
  });
}

function inferModule(suiteTitle) {
  return (suiteTitle || 'Uncategorised').split('—')[0].trim() || 'Uncategorised';
}

function summary() {
  const counts = {
    total: state.results.length,
    passed: 0,
    failed: 0,
    skipped: 0,
    blocked: 0,
    not_applicable: 0,
  };
  for (const r of state.results) counts[r.status] += 1;

  // Executed = everything we actually attempted on the device.
  counts.executed = counts.passed + counts.failed;
  counts.passRate =
    counts.executed > 0 ? Number(((counts.passed / counts.executed) * 100).toFixed(2)) : 0;
  counts.failRate =
    counts.executed > 0 ? Number(((counts.failed / counts.executed) * 100).toFixed(2)) : 0;
  counts.durationMs = state.results.reduce((acc, r) => acc + r.durationMs, 0);
  return counts;
}

/** Per-module rollup used by the HTML dashboard and the Actions summary. */
function byModule() {
  const map = new Map();
  for (const r of state.results) {
    if (!map.has(r.module)) {
      map.set(r.module, {
        module: r.module,
        total: 0,
        passed: 0,
        failed: 0,
        skipped: 0,
        blocked: 0,
        not_applicable: 0,
        durationMs: 0,
      });
    }
    const m = map.get(r.module);
    m.total += 1;
    m[r.status] += 1;
    m.durationMs += r.durationMs;
  }
  return Array.from(map.values())
    .map((m) => ({
      ...m,
      executed: m.passed + m.failed,
      passRate:
        m.passed + m.failed > 0
          ? Number(((m.passed / (m.passed + m.failed)) * 100).toFixed(2))
          : 0,
    }))
    .sort((a, b) => a.module.localeCompare(b.module));
}

function finalise() {
  state.finishedAt = Date.now();
  fs.mkdirSync(env.reportsDir, { recursive: true });

  const payload = {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    environment: state.environment,
    run: {
      startedAt: new Date(state.startedAt).toISOString(),
      finishedAt: new Date(state.finishedAt).toISOString(),
      wallClockMs: state.finishedAt - state.startedAt,
      buildNumber: env.run.buildNumber,
      commit: env.run.commit,
      branch: env.run.branch,
    },
    summary: summary(),
    modules: byModule(),
    results: state.results,
  };

  const jsonDir = path.join(env.reportsDir, 'JSON');
  fs.mkdirSync(jsonDir, { recursive: true });
  fs.writeFileSync(
    path.join(jsonDir, 'execution-results.json'),
    JSON.stringify(payload, null, 2),
    'utf8'
  );
  return payload;
}

function load() {
  const file = path.join(env.reportsDir, 'JSON', 'execution-results.json');
  if (!fs.existsSync(file)) {
    throw new Error(
      `No execution-results.json at ${file}. Run the suite before generating reports.`
    );
  }
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

module.exports = { setEnvironment, record, summary, byModule, finalise, load, state };
