'use strict';

const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');
const env = require('../config/env');

/**
 * Builds the Excel deliverables from `execution-results.json`.
 *
 * Four workbooks:
 *   Automation_Test_Report.xlsx  — 7 sheets, the full picture
 *   Passed_Test_Cases.xlsx       — passed only
 *   Failed_Test_Cases.xlsx       — failed only, with failure reasons
 *   Execution_Summary.xlsx       — one-page metrics for a reviewer
 */

const STATUS_FILL = {
  passed: 'FFD4F5E2',
  failed: 'FFFFD9DE',
  skipped: 'FFFFF3CD',
  blocked: 'FFE2E3E5',
  not_applicable: 'FFE7E7F5',
};

const HEADER_FILL = 'FF1A73E8';

function styleHeader(row) {
  row.eachCell((cell) => {
    cell.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: HEADER_FILL } };
    cell.alignment = { vertical: 'middle', horizontal: 'left', wrapText: true };
    cell.border = {
      top: { style: 'thin', color: { argb: 'FFCCCCCC' } },
      left: { style: 'thin', color: { argb: 'FFCCCCCC' } },
      bottom: { style: 'thin', color: { argb: 'FFCCCCCC' } },
      right: { style: 'thin', color: { argb: 'FFCCCCCC' } },
    };
  });
  row.height = 24;
}

function paintStatus(row, statusColumnKey) {
  const cell = row.getCell(statusColumnKey);
  const fill = STATUS_FILL[String(cell.value).toLowerCase().replace(/[^a-z_]/g, '')];
  if (fill) {
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: fill } };
    cell.font = { bold: true };
  }
}

function autoFit(sheet, { max = 60 } = {}) {
  sheet.columns.forEach((column) => {
    let width = column.header ? String(column.header).length : 10;
    column.eachCell({ includeEmpty: false }, (cell) => {
      const len = cell.value ? String(cell.value).length : 0;
      if (len > width) width = len;
    });
    column.width = Math.min(Math.max(width + 2, 10), max);
  });
}

const humanStatus = (s) =>
  ({
    passed: 'PASS',
    failed: 'FAIL',
    skipped: 'SKIPPED',
    blocked: 'BLOCKED',
    not_applicable: 'NOT APPLICABLE',
  }[s] || s.toUpperCase());

const ms = (n) => `${(n / 1000).toFixed(2)}s`;

// ── Sheet builders ──────────────────────────────────────────────────────────

function addExecutedSheet(wb, data, { filter = null, name = 'Executed Test Cases' } = {}) {
  const sheet = wb.addWorksheet(name, {
    views: [{ state: 'frozen', ySplit: 1 }],
  });
  sheet.columns = [
    { header: 'Test ID', key: 'id', width: 20 },
    { header: 'Module', key: 'module', width: 20 },
    { header: 'Test Name', key: 'title', width: 55 },
    { header: 'Priority', key: 'priority', width: 10 },
    { header: 'Status', key: 'status', width: 16 },
    { header: 'Execution Time', key: 'duration', width: 15 },
    { header: 'Preconditions', key: 'preconditions', width: 30 },
    { header: 'Test Data', key: 'testData', width: 30 },
    { header: 'Expected Result', key: 'expected', width: 40 },
    { header: 'Actual Result', key: 'actual', width: 45 },
  ];
  styleHeader(sheet.getRow(1));

  const rows = filter ? data.results.filter(filter) : data.results;
  rows.forEach((r) => {
    const row = sheet.addRow({
      id: r.id || '—',
      module: r.module,
      title: r.title,
      priority: r.priority,
      status: humanStatus(r.status),
      duration: ms(r.durationMs),
      preconditions: r.preconditions,
      testData: typeof r.testData === 'string' ? r.testData.slice(0, 200) : '—',
      expected: r.expected,
      actual:
        r.status === 'passed'
          ? 'As expected'
          : r.error
          ? r.error.message.split('\n')[0].slice(0, 300)
          : r.rationale || '—',
    });
    row.alignment = { vertical: 'top', wrapText: true };
    paintStatus(row, 'status');
  });

  sheet.autoFilter = { from: 'A1', to: { row: 1, column: sheet.columns.length } };
  return sheet;
}

function addFailedSheet(wb, data) {
  const sheet = wb.addWorksheet('Failed Tests', { views: [{ state: 'frozen', ySplit: 1 }] });
  sheet.columns = [
    { header: 'Test ID', key: 'id', width: 20 },
    { header: 'Module', key: 'module', width: 20 },
    { header: 'Test Name', key: 'title', width: 50 },
    { header: 'Priority', key: 'priority', width: 10 },
    { header: 'Failure Reason', key: 'reason', width: 70 },
    { header: 'Screenshot', key: 'screenshot', width: 45 },
    { header: 'Device Log', key: 'deviceLog', width: 40 },
    { header: 'Retries', key: 'retries', width: 9 },
  ];
  styleHeader(sheet.getRow(1));

  const failed = data.results.filter((r) => r.status === 'failed');
  if (failed.length === 0) {
    const row = sheet.addRow({ id: '—', module: '—', title: 'No failures in this run', reason: '—' });
    row.font = { italic: true, color: { argb: 'FF059669' } };
  }
  failed.forEach((r) => {
    const row = sheet.addRow({
      id: r.id || '—',
      module: r.module,
      title: r.title,
      priority: r.priority,
      reason: r.error ? r.error.message.slice(0, 1000) : 'unknown',
      screenshot: r.screenshot || '—',
      deviceLog: r.deviceLog || '—',
      retries: r.retries,
    });
    row.alignment = { vertical: 'top', wrapText: true };
  });
  return sheet;
}

function addSkippedSheet(wb, data) {
  // Excel forbids * ? : \ / [ ] in sheet names, so "N/A" cannot appear here.
  const sheet = wb.addWorksheet('Skipped and Not Applicable', {
    views: [{ state: 'frozen', ySplit: 1 }],
  });
  sheet.columns = [
    { header: 'Test ID', key: 'id', width: 22 },
    { header: 'Module', key: 'module', width: 20 },
    { header: 'Test Name', key: 'title', width: 50 },
    { header: 'Status', key: 'status', width: 18 },
    { header: 'Reason', key: 'reason', width: 80 },
  ];
  styleHeader(sheet.getRow(1));

  const rows = data.results.filter((r) => r.status === 'skipped' || r.status === 'not_applicable');
  rows.forEach((r) => {
    const row = sheet.addRow({
      id: r.id || '—',
      module: r.module,
      title: r.title,
      status: humanStatus(r.status),
      reason: r.rationale || 'Skipped at runtime — see the execution log',
    });
    row.alignment = { vertical: 'top', wrapText: true };
    paintStatus(row, 'status');
  });
  return sheet;
}

function addMetricsSheet(wb, data) {
  const sheet = wb.addWorksheet('Execution Metrics');
  const s = data.summary;
  const e = data.environment || {};

  sheet.columns = [
    { header: 'Metric', key: 'metric', width: 34 },
    { header: 'Value', key: 'value', width: 55 },
  ];
  styleHeader(sheet.getRow(1));

  const rows = [
    ['Build number', data.run.buildNumber],
    ['Branch', data.run.branch],
    ['Commit', data.run.commit],
    ['Started at', data.run.startedAt],
    ['Finished at', data.run.finishedAt],
    ['Wall-clock duration', ms(data.run.wallClockMs)],
    ['', ''],
    ['Total test cases', s.total],
    ['Executed', s.executed],
    ['Passed', s.passed],
    ['Failed', s.failed],
    ['Skipped', s.skipped],
    ['Blocked', s.blocked],
    ['Not applicable', s.not_applicable],
    ['Pass percentage', `${s.passRate}%`],
    ['Fail percentage', `${s.failRate}%`],
    ['', ''],
    ['Device', e.device || 'unknown'],
    ['Manufacturer', e.manufacturer || 'unknown'],
    ['Android version', e.androidVersion || 'unknown'],
    ['API level', e.apiLevel || 'unknown'],
    ['Screen size', e.screenSize || 'unknown'],
    ['App package', e.appPackage || 'unknown'],
    ['App version', e.appVersion || 'unknown'],
  ];

  rows.forEach(([metric, value]) => {
    const row = sheet.addRow({ metric, value });
    if (metric && !value && value !== 0) row.font = { bold: true };
    if (metric === 'Pass percentage') {
      row.getCell('value').font = {
        bold: true,
        color: { argb: s.passRate >= 95 ? 'FF059669' : 'FFDC2626' },
      };
    }
  });
  return sheet;
}

function addModuleSheet(wb, data) {
  const sheet = wb.addWorksheet('Pass Rate by Module', { views: [{ state: 'frozen', ySplit: 1 }] });
  sheet.columns = [
    { header: 'Module', key: 'module', width: 26 },
    { header: 'Total', key: 'total', width: 10 },
    { header: 'Executed', key: 'executed', width: 11 },
    { header: 'Passed', key: 'passed', width: 10 },
    { header: 'Failed', key: 'failed', width: 10 },
    { header: 'Skipped', key: 'skipped', width: 10 },
    { header: 'N/A', key: 'not_applicable', width: 8 },
    { header: 'Pass Rate', key: 'passRate', width: 12 },
    { header: 'Duration', key: 'duration', width: 12 },
  ];
  styleHeader(sheet.getRow(1));

  data.modules.forEach((m) => {
    const row = sheet.addRow({
      module: m.module,
      total: m.total,
      executed: m.executed,
      passed: m.passed,
      failed: m.failed,
      skipped: m.skipped,
      not_applicable: m.not_applicable,
      passRate: `${m.passRate}%`,
      duration: ms(m.durationMs),
    });
    row.getCell('passRate').font = {
      bold: true,
      color: { argb: m.passRate >= 95 ? 'FF059669' : m.passRate >= 80 ? 'FFD97706' : 'FFDC2626' },
    };
  });
  return sheet;
}

function addDefectSheet(wb, data) {
  const sheet = wb.addWorksheet('Defect Summary', { views: [{ state: 'frozen', ySplit: 1 }] });
  sheet.columns = [
    { header: 'Defect ID', key: 'defect', width: 14 },
    { header: 'Test ID', key: 'id', width: 20 },
    { header: 'Module', key: 'module', width: 20 },
    { header: 'Severity', key: 'severity', width: 12 },
    { header: 'Summary', key: 'summary', width: 60 },
    { header: 'Evidence', key: 'evidence', width: 45 },
  ];
  styleHeader(sheet.getRow(1));

  // Priority maps to severity: a P0 failure is a blocker by definition.
  const SEVERITY = { P0: 'Critical', P1: 'High', P2: 'Medium', P3: 'Low' };

  const failed = data.results.filter((r) => r.status === 'failed');
  if (failed.length === 0) {
    const row = sheet.addRow({ defect: '—', summary: 'No defects raised in this run' });
    row.font = { italic: true, color: { argb: 'FF059669' } };
  }
  failed.forEach((r, i) => {
    sheet.addRow({
      defect: `DEF-${String(i + 1).padStart(3, '0')}`,
      id: r.id || '—',
      module: r.module,
      severity: SEVERITY[r.priority] || 'Medium',
      summary: r.error ? r.error.message.split('\n')[0].slice(0, 400) : r.title,
      evidence: r.screenshot || '—',
    }).alignment = { vertical: 'top', wrapText: true };
  });
  return sheet;
}

function addStepsSheet(wb, data) {
  const sheet = wb.addWorksheet('Test Case Steps', { views: [{ state: 'frozen', ySplit: 1 }] });
  sheet.columns = [
    { header: 'Test ID', key: 'id', width: 22 },
    { header: 'Module', key: 'module', width: 20 },
    { header: 'Test Name', key: 'title', width: 50 },
    { header: 'Preconditions', key: 'preconditions', width: 32 },
    { header: 'Test Steps', key: 'steps', width: 65 },
    { header: 'Expected Result', key: 'expected', width: 42 },
    { header: 'Rationale', key: 'rationale', width: 60 },
  ];
  styleHeader(sheet.getRow(1));

  data.results.forEach((r) => {
    const row = sheet.addRow({
      id: r.id || '—',
      module: r.module,
      title: r.title,
      preconditions: r.preconditions,
      steps: (r.steps || []).map((s, i) => `${i + 1}. ${s}`).join('\n') || '—',
      expected: r.expected,
      rationale: r.rationale || '—',
    });
    row.alignment = { vertical: 'top', wrapText: true };
  });
  return sheet;
}

// ── Workbook builders ───────────────────────────────────────────────────────

function withMeta(wb) {
  wb.creator = 'CyberGuard AI — Appium E2E Suite';
  wb.created = new Date();
  return wb;
}

async function generate(data, outDir) {
  fs.mkdirSync(outDir, { recursive: true });
  const written = [];

  // 1. Full report
  const main = withMeta(new ExcelJS.Workbook());
  addExecutedSheet(main, data);
  addExecutedSheet(main, data, { filter: (r) => r.status === 'passed', name: 'Passed Tests' });
  addFailedSheet(main, data);
  addSkippedSheet(main, data);
  addMetricsSheet(main, data);
  addDefectSheet(main, data);
  addModuleSheet(main, data);
  addStepsSheet(main, data);
  for (const sheet of main.worksheets) autoFit(sheet);
  const mainPath = path.join(outDir, 'Automation_Test_Report.xlsx');
  await main.xlsx.writeFile(mainPath);
  written.push(mainPath);

  // 2. Passed only
  const passed = withMeta(new ExcelJS.Workbook());
  addExecutedSheet(passed, data, { filter: (r) => r.status === 'passed', name: 'Passed Test Cases' });
  autoFit(passed.worksheets[0]);
  const passedPath = path.join(outDir, 'Passed_Test_Cases.xlsx');
  await passed.xlsx.writeFile(passedPath);
  written.push(passedPath);

  // 3. Failed only
  const failed = withMeta(new ExcelJS.Workbook());
  addFailedSheet(failed, data);
  addDefectSheet(failed, data);
  for (const sheet of failed.worksheets) autoFit(sheet);
  const failedPath = path.join(outDir, 'Failed_Test_Cases.xlsx');
  await failed.xlsx.writeFile(failedPath);
  written.push(failedPath);

  // 4. Summary
  const summary = withMeta(new ExcelJS.Workbook());
  addMetricsSheet(summary, data);
  addModuleSheet(summary, data);
  for (const sheet of summary.worksheets) autoFit(sheet);
  const summaryPath = path.join(outDir, 'Execution_Summary.xlsx');
  await summary.xlsx.writeFile(summaryPath);
  written.push(summaryPath);

  return written;
}

module.exports = { generate };
