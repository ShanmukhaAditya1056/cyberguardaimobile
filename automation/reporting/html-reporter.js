'use strict';

const fs = require('fs');
const path = require('path');

/**
 * Self-contained HTML reports.
 *
 * No CDN links, no external fonts: the output is published to GitHub Pages and
 * also opened straight off a downloaded artifact, so every byte has to be in
 * the file. Screenshots are referenced by relative path because inlining a few
 * hundred PNGs as data URIs would produce a report too large to open.
 */

const esc = (s) =>
  String(s === null || s === undefined ? '' : s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

const ms = (n) => `${(n / 1000).toFixed(2)}s`;

const STATUS_LABEL = {
  passed: 'Passed',
  failed: 'Failed',
  skipped: 'Skipped',
  blocked: 'Blocked',
  not_applicable: 'N/A',
};

const CSS = `
:root{
  --bg:#f6f7f9; --surface:#fff; --text:#0f172a; --muted:#64748b; --border:#e2e8f0;
  --pass:#059669; --fail:#dc2626; --skip:#d97706; --na:#6366f1; --accent:#1a73e8;
  --pass-bg:#d4f5e2; --fail-bg:#ffd9de; --skip-bg:#fff3cd; --na-bg:#e7e7f5;
  --shadow:0 1px 3px rgba(15,23,42,.08),0 1px 2px rgba(15,23,42,.06);
}
@media (prefers-color-scheme:dark){
  :root{
    --bg:#0b1120; --surface:#131c31; --text:#e2e8f0; --muted:#94a3b8; --border:#1e293b;
    --pass-bg:#052e21; --fail-bg:#3f1218; --skip-bg:#3d2c06; --na-bg:#1e1b4b;
    --shadow:0 1px 3px rgba(0,0,0,.4);
  }
}
:root[data-theme="dark"]{
  --bg:#0b1120; --surface:#131c31; --text:#e2e8f0; --muted:#94a3b8; --border:#1e293b;
  --pass-bg:#052e21; --fail-bg:#3f1218; --skip-bg:#3d2c06; --na-bg:#1e1b4b;
}
:root[data-theme="light"]{
  --bg:#f6f7f9; --surface:#fff; --text:#0f172a; --muted:#64748b; --border:#e2e8f0;
  --pass-bg:#d4f5e2; --fail-bg:#ffd9de; --skip-bg:#fff3cd; --na-bg:#e7e7f5;
}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);
  font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  -webkit-font-smoothing:antialiased}
.wrap{max-width:1180px;margin:0 auto;padding:32px 20px 80px}
header{margin-bottom:28px}
h1{font-size:26px;font-weight:800;letter-spacing:-.4px;margin:0 0 6px}
.sub{color:var(--muted);font-size:14px}
.meta{display:flex;flex-wrap:wrap;gap:8px;margin-top:14px}
.chip{background:var(--surface);border:1px solid var(--border);border-radius:999px;
  padding:5px 12px;font-size:12.5px;color:var(--muted);box-shadow:var(--shadow)}
.chip b{color:var(--text);font-weight:600}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin:22px 0}
.tile{background:var(--surface);border:1px solid var(--border);border-radius:14px;
  padding:16px 18px;box-shadow:var(--shadow)}
.tile .k{font-size:12px;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);font-weight:600}
.tile .v{font-size:30px;font-weight:800;letter-spacing:-1px;margin-top:6px}
.v.pass{color:var(--pass)} .v.fail{color:var(--fail)} .v.skip{color:var(--skip)} .v.na{color:var(--na)}
.bar{height:10px;border-radius:99px;background:var(--border);overflow:hidden;display:flex;margin:6px 0 22px}
.bar i{display:block;height:100%}
.bar .p{background:var(--pass)} .bar .f{background:var(--fail)}
.bar .s{background:var(--skip)} .bar .n{background:var(--na)}
section{background:var(--surface);border:1px solid var(--border);border-radius:16px;
  padding:20px 22px;margin-bottom:20px;box-shadow:var(--shadow)}
h2{font-size:17px;font-weight:700;margin:0 0 14px}
.scroll{overflow-x:auto;-webkit-overflow-scrolling:touch}
table{width:100%;border-collapse:collapse;font-size:13.5px;min-width:640px}
th{text-align:left;font-weight:600;color:var(--muted);font-size:11.5px;text-transform:uppercase;
  letter-spacing:.5px;padding:8px 10px;border-bottom:2px solid var(--border);white-space:nowrap}
td{padding:9px 10px;border-bottom:1px solid var(--border);vertical-align:top}
tr:last-child td{border-bottom:none}
.badge{display:inline-block;padding:2px 9px;border-radius:99px;font-size:11.5px;font-weight:700}
.b-passed{background:var(--pass-bg);color:var(--pass)}
.b-failed{background:var(--fail-bg);color:var(--fail)}
.b-skipped{background:var(--skip-bg);color:var(--skip)}
.b-blocked{background:var(--border);color:var(--muted)}
.b-not_applicable{background:var(--na-bg);color:var(--na)}
code,pre{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:12.5px}
pre{background:var(--bg);border:1px solid var(--border);border-radius:10px;padding:12px;
  overflow-x:auto;white-space:pre-wrap;word-break:break-word;margin:8px 0 0}
.fail-card{border-left:3px solid var(--fail);padding-left:14px;margin-bottom:18px}
.fail-card h3{margin:0 0 4px;font-size:14.5px;font-weight:700}
.fail-card .who{color:var(--muted);font-size:12.5px;margin-bottom:6px}
.shot{max-width:260px;border-radius:10px;border:1px solid var(--border);margin-top:10px;display:block}
.note{background:var(--na-bg);border-radius:10px;padding:12px 14px;font-size:13.5px;color:var(--text)}
.mono{font-family:ui-monospace,Menlo,Consolas,monospace;font-size:12px;color:var(--muted)}
footer{color:var(--muted);font-size:12.5px;text-align:center;margin-top:36px}
.toggle{position:fixed;top:14px;right:14px;background:var(--surface);border:1px solid var(--border);
  color:var(--text);border-radius:99px;padding:7px 14px;font-size:12.5px;cursor:pointer;box-shadow:var(--shadow)}
@media(max-width:640px){.wrap{padding:20px 14px 60px}h1{font-size:21px}.tile .v{font-size:24px}}
`;

const THEME_JS = `
(function(){
  var btn=document.getElementById('themeToggle');
  if(!btn)return;
  btn.addEventListener('click',function(){
    var r=document.documentElement;
    var cur=r.getAttribute('data-theme');
    if(!cur){cur=window.matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light';}
    r.setAttribute('data-theme',cur==='dark'?'light':'dark');
  });
})();
`;

function shell(title, body) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)}</title>
<style>${CSS}</style>
</head>
<body>
<button class="toggle" id="themeToggle">Toggle theme</button>
<div class="wrap">
${body}
</div>
<script>${THEME_JS}</script>
</body>
</html>`;
}

function statusBar(s) {
  const total = s.total || 1;
  const pct = (n) => ((n / total) * 100).toFixed(2);
  return `<div class="bar">
    <i class="p" style="width:${pct(s.passed)}%"></i>
    <i class="f" style="width:${pct(s.failed)}%"></i>
    <i class="s" style="width:${pct(s.skipped + s.blocked)}%"></i>
    <i class="n" style="width:${pct(s.not_applicable)}%"></i>
  </div>`;
}

function tiles(s) {
  return `<div class="tiles">
    <div class="tile"><div class="k">Total</div><div class="v">${s.total}</div></div>
    <div class="tile"><div class="k">Executed</div><div class="v">${s.executed}</div></div>
    <div class="tile"><div class="k">Passed</div><div class="v pass">${s.passed}</div></div>
    <div class="tile"><div class="k">Failed</div><div class="v fail">${s.failed}</div></div>
    <div class="tile"><div class="k">Skipped</div><div class="v skip">${s.skipped + s.blocked}</div></div>
    <div class="tile"><div class="k">N/A</div><div class="v na">${s.not_applicable}</div></div>
    <div class="tile"><div class="k">Pass rate</div><div class="v ${s.passRate >= 95 ? 'pass' : 'fail'}">${s.passRate}%</div></div>
  </div>`;
}

function header(data, title, subtitle) {
  const e = data.environment || {};
  return `<header>
    <h1>${esc(title)}</h1>
    <div class="sub">${esc(subtitle)}</div>
    <div class="meta">
      <span class="chip">Build <b>${esc(data.run.buildNumber)}</b></span>
      <span class="chip">Branch <b>${esc(data.run.branch)}</b></span>
      <span class="chip">Commit <b>${esc(String(data.run.commit).slice(0, 8))}</b></span>
      <span class="chip">Device <b>${esc(e.device || 'unknown')}</b></span>
      <span class="chip">Android <b>${esc(e.androidVersion || '?')}</b> (API ${esc(e.apiLevel || '?')})</span>
      <span class="chip">App <b>${esc(e.appVersion || '?')}</b></span>
      <span class="chip">Duration <b>${ms(data.run.wallClockMs)}</b></span>
      <span class="chip">Generated <b>${esc(new Date(data.generatedAt).toUTCString())}</b></span>
    </div>
  </header>`;
}

function failuresSection(data) {
  const failed = data.results.filter((r) => r.status === 'failed');
  if (!failed.length) {
    return `<section><h2>Failures</h2><div class="note">No failures in this run.</div></section>`;
  }
  const cards = failed
    .map(
      (r) => `<div class="fail-card">
      <h3>${esc(r.id || '')} — ${esc(r.title)}</h3>
      <div class="who">${esc(r.module)} · ${esc(r.priority)} · ${ms(r.durationMs)}</div>
      <pre>${esc(r.error ? r.error.message : 'unknown failure')}</pre>
      ${r.screenshot ? `<img class="shot" src="${esc(r.screenshot)}" alt="Failure screenshot for ${esc(r.id || r.title)}" loading="lazy">` : ''}
      ${r.deviceLog ? `<div class="mono">device log: ${esc(r.deviceLog)}</div>` : ''}
    </div>`
    )
    .join('\n');
  return `<section><h2>Failures (${failed.length})</h2>${cards}</section>`;
}

function moduleTable(data) {
  const rows = data.modules
    .map(
      (m) => `<tr>
      <td><b>${esc(m.module)}</b></td>
      <td>${m.total}</td><td>${m.executed}</td>
      <td style="color:var(--pass)">${m.passed}</td>
      <td style="color:var(--fail)">${m.failed}</td>
      <td>${m.skipped}</td><td>${m.not_applicable}</td>
      <td><b>${m.passRate}%</b></td>
      <td>${ms(m.durationMs)}</td>
    </tr>`
    )
    .join('\n');
  return `<section><h2>Results by module</h2><div class="scroll"><table>
    <thead><tr><th>Module</th><th>Total</th><th>Executed</th><th>Passed</th><th>Failed</th>
    <th>Skipped</th><th>N/A</th><th>Pass rate</th><th>Duration</th></tr></thead>
    <tbody>${rows}</tbody></table></div></section>`;
}

function allTestsTable(data) {
  const rows = data.results
    .map(
      (r) => `<tr>
      <td class="mono">${esc(r.id || '—')}</td>
      <td>${esc(r.module)}</td>
      <td>${esc(r.title)}</td>
      <td>${esc(r.priority)}</td>
      <td><span class="badge b-${r.status}">${STATUS_LABEL[r.status]}</span></td>
      <td>${ms(r.durationMs)}</td>
    </tr>`
    )
    .join('\n');
  return `<section><h2>All test cases (${data.results.length})</h2><div class="scroll"><table>
    <thead><tr><th>Test ID</th><th>Module</th><th>Test name</th><th>Priority</th>
    <th>Status</th><th>Time</th></tr></thead><tbody>${rows}</tbody></table></div></section>`;
}

function notApplicableSection(data) {
  const na = data.results.filter((r) => r.status === 'not_applicable');
  if (!na.length) return '';
  const rows = na
    .map(
      (r) => `<tr><td class="mono">${esc(r.id)}</td><td>${esc(r.title)}</td>
      <td>${esc(r.rationale)}</td></tr>`
    )
    .join('\n');
  return `<section><h2>Not applicable (${na.length})</h2>
    <div class="note">These cases are declared rather than silently omitted. Each one states
    why it cannot run against this application.</div>
    <div class="scroll"><table><thead><tr><th>Test ID</th><th>Test name</th><th>Reason</th></tr></thead>
    <tbody>${rows}</tbody></table></div></section>`;
}

// ── Public API ──────────────────────────────────────────────────────────────

function executionReport(data) {
  const s = data.summary;
  return shell(
    'CyberGuard AI — E2E Execution Report',
    [
      header(
        data,
        'CyberGuard AI — Appium E2E Execution Report',
        'Android end-to-end automation run against the on-device build'
      ),
      tiles(s),
      statusBar(s),
      failuresSection(data),
      moduleTable(data),
      notApplicableSection(data),
      allTestsTable(data),
      `<footer>Generated by the CyberGuard AI Appium suite · build ${esc(data.run.buildNumber)}</footer>`,
    ].join('\n')
  );
}

function dashboard(data, history = []) {
  const s = data.summary;
  const trendRows = history
    .slice(-15)
    .map(
      (h) => `<tr><td class="mono">${esc(h.buildNumber)}</td><td>${esc(h.date)}</td>
      <td>${h.total}</td><td style="color:var(--pass)">${h.passed}</td>
      <td style="color:var(--fail)">${h.failed}</td><td><b>${h.passRate}%</b></td></tr>`
    )
    .join('\n');

  const trendSection = history.length
    ? `<section><h2>Execution history</h2><div class="scroll"><table>
       <thead><tr><th>Build</th><th>Date</th><th>Total</th><th>Passed</th><th>Failed</th><th>Pass rate</th></tr></thead>
       <tbody>${trendRows}</tbody></table></div></section>`
    : `<section><h2>Execution history</h2><div class="note">This is the first recorded run —
       history builds up from the next execution onwards.</div></section>`;

  return shell(
    'CyberGuard AI — QA Dashboard',
    [
      header(data, 'CyberGuard AI — QA Dashboard', 'Latest run at a glance, with historical trend'),
      tiles(s),
      statusBar(s),
      moduleTable(data),
      trendSection,
      `<footer>Generated by the CyberGuard AI Appium suite</footer>`,
    ].join('\n')
  );
}

function generate(data, outDir, history = []) {
  fs.mkdirSync(outDir, { recursive: true });
  const written = [];

  const reportPath = path.join(outDir, 'execution-report.html');
  fs.writeFileSync(reportPath, executionReport(data), 'utf8');
  written.push(reportPath);

  const dashPath = path.join(outDir, 'dashboard.html');
  fs.writeFileSync(dashPath, dashboard(data, history), 'utf8');
  written.push(dashPath);

  return written;
}

module.exports = { generate, executionReport, dashboard };
