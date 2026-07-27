'use strict';

const fs = require('fs');
const path = require('path');
const env = require('../config/env');
const collector = require('./collector');
const excel = require('./excel-reporter');
const html = require('./html-reporter');

/**
 * Turns `execution-results.json` into every published artifact.
 *
 * Runs as a separate step from the suite so reports can be regenerated from a
 * downloaded artifact without an emulator, and so a reporting bug never fails
 * an otherwise-good test run.
 */

const ms = (n) => `${(n / 1000).toFixed(2)}s`;

function historyFile() {
  return path.join(env.reportsDir, 'history.json');
}

/** Appends this run to the rolling history used by the dashboard trend table. */
function updateHistory(data) {
  const file = historyFile();
  let history = [];
  if (fs.existsSync(file)) {
    try {
      history = JSON.parse(fs.readFileSync(file, 'utf8'));
    } catch {
      history = [];
    }
  }
  history.push({
    buildNumber: data.run.buildNumber,
    commit: String(data.run.commit).slice(0, 8),
    branch: data.run.branch,
    date: new Date(data.generatedAt).toISOString().slice(0, 16).replace('T', ' '),
    total: data.summary.total,
    executed: data.summary.executed,
    passed: data.summary.passed,
    failed: data.summary.failed,
    skipped: data.summary.skipped,
    passRate: data.summary.passRate,
    durationMs: data.run.wallClockMs,
  });
  // Keep the file bounded; the dashboard only renders the last 15 anyway.
  history = history.slice(-100);
  fs.writeFileSync(file, JSON.stringify(history, null, 2), 'utf8');
  return history;
}

function markdownSummary(data) {
  const s = data.summary;
  const e = data.environment || {};
  const failed = data.results.filter((r) => r.status === 'failed');
  const na = data.results.filter((r) => r.status === 'not_applicable');
  const passIcon = s.passRate >= 95 ? '✅' : '❌';

  const lines = [];
  lines.push('# Android Appium E2E Execution Summary');
  lines.push('');
  lines.push(`| | |`);
  lines.push(`|---|---|`);
  lines.push(`| **Build** | ${data.run.buildNumber} |`);
  lines.push(`| **Branch** | ${data.run.branch} |`);
  lines.push(`| **Commit** | \`${String(data.run.commit).slice(0, 8)}\` |`);
  lines.push(`| **Executed** | ${data.run.startedAt} |`);
  lines.push(`| **Duration** | ${ms(data.run.wallClockMs)} |`);
  lines.push(`| **Device** | ${e.device || 'unknown'} |`);
  lines.push(`| **Android** | ${e.androidVersion || '?'} (API ${e.apiLevel || '?'}) |`);
  lines.push(`| **App version** | ${e.appVersion || '?'} |`);
  lines.push('');
  lines.push('## Execution metrics');
  lines.push('');
  lines.push('| Metric | Value |');
  lines.push('|---|---:|');
  lines.push(`| Total test cases | ${s.total} |`);
  lines.push(`| Executed | ${s.executed} |`);
  lines.push(`| Passed | ${s.passed} |`);
  lines.push(`| Failed | ${s.failed} |`);
  lines.push(`| Skipped | ${s.skipped} |`);
  lines.push(`| Blocked | ${s.blocked} |`);
  lines.push(`| Not applicable | ${s.not_applicable} |`);
  lines.push(`| **Pass percentage** | **${s.passRate}%** ${passIcon} |`);
  lines.push(`| Fail percentage | ${s.failRate}% |`);
  lines.push('');

  lines.push('## Results by module');
  lines.push('');
  lines.push('| Module | Total | Passed | Failed | Pass rate |');
  lines.push('|---|---:|---:|---:|---:|');
  for (const m of data.modules) {
    lines.push(`| ${m.module} | ${m.total} | ${m.passed} | ${m.failed} | ${m.passRate}% |`);
  }
  lines.push('');

  if (failed.length) {
    lines.push(`## Failed tests (${failed.length})`);
    lines.push('');
    for (const r of failed) {
      const reason = r.error ? r.error.message.split('\n')[0].slice(0, 220) : 'unknown';
      lines.push(`- ✗ **${r.id || r.title}** — ${r.title}`);
      lines.push(`  - Module: ${r.module} · Priority: ${r.priority}`);
      lines.push(`  - Reason: ${reason}`);
    }
    lines.push('');
  } else {
    lines.push('## Failed tests');
    lines.push('');
    lines.push('None. 🎉');
    lines.push('');
  }

  if (na.length) {
    lines.push(`## Not applicable (${na.length})`);
    lines.push('');
    lines.push(
      'Declared explicitly rather than omitted, so the count is auditable:'
    );
    lines.push('');
    for (const r of na) {
      lines.push(`- **${r.id}** — ${r.title}`);
      lines.push(`  - ${r.rationale}`);
    }
    lines.push('');
  }

  const topPassing = [...data.modules]
    .filter((m) => m.executed > 0)
    .sort((a, b) => b.passRate - a.passRate || b.total - a.total)
    .slice(0, 5);
  if (topPassing.length) {
    lines.push('## Strongest modules');
    lines.push('');
    for (const m of topPassing) {
      lines.push(`- ${m.module}: ${m.passRate}% (${m.passed}/${m.executed})`);
    }
    lines.push('');
  }

  lines.push('## Artifacts');
  lines.push('');
  lines.push('- Automation_Test_Report.xlsx');
  lines.push('- Passed_Test_Cases.xlsx');
  lines.push('- Failed_Test_Cases.xlsx');
  lines.push('- Execution_Summary.xlsx');
  lines.push('- execution-report.html / dashboard.html');
  lines.push('- execution-results.json');
  lines.push('- screenshots/ and logs/');
  lines.push('');

  return lines.join('\n');
}

async function main() {
  const data = collector.load();

  const excelDir = path.join(env.reportsDir, 'Excel');
  const htmlDir = path.join(env.reportsDir, 'HTML');
  const summaryDir = path.join(env.reportsDir, 'Summary');
  fs.mkdirSync(summaryDir, { recursive: true });

  const history = updateHistory(data);

  const written = [];
  written.push(...(await excel.generate(data, excelDir)));
  written.push(...html.generate(data, htmlDir, history));

  const summaryPath = path.join(summaryDir, 'summary.md');
  const summary = markdownSummary(data);
  fs.writeFileSync(summaryPath, summary, 'utf8');
  written.push(summaryPath);

  // GitHub Actions step summary, when running in CI.
  if (process.env.GITHUB_STEP_SUMMARY) {
    fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, summary + '\n', 'utf8');
  }

  console.log('Reports written:');
  for (const f of written) console.log(`  ${path.relative(env.root, f)}`);
  console.log('');
  console.log(
    `Summary: ${data.summary.passed}/${data.summary.executed} passed ` +
      `(${data.summary.passRate}%), ${data.summary.failed} failed, ` +
      `${data.summary.not_applicable} not applicable.`
  );

  return data;
}

if (require.main === module) {
  main().catch((err) => {
    console.error('Report generation failed:', err.message);
    process.exit(1);
  });
}

module.exports = { main, markdownSummary, updateHistory };
