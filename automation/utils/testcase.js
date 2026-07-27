'use strict';

/**
 * Declares a test case with the metadata the reports need.
 *
 * A plain Mocha title cannot carry a test-case ID, module, priority or the
 * documented steps, and the Excel/HTML reports are required to show all of
 * them. `tc()` attaches that metadata to the Mocha test object so the reporter
 * can read it back without a parallel spreadsheet drifting out of sync with
 * the code.
 *
 *   tc({
 *     id: 'TC_PHISH_004',
 *     module: 'Phishing',
 *     priority: 'P1',
 *     title: 'IP-address URL is flagged as dangerous',
 *     preconditions: 'Phishing screen open',
 *     steps: ['Enter http://192.168.1.50/...', 'Tap Scan Now'],
 *     expected: 'Verdict reads Dangerous',
 *   }, async () => { ... });
 */

const registry = new Map();

const VALID_PRIORITIES = new Set(['P0', 'P1', 'P2', 'P3']);

function tc(meta, fn) {
  const { id, module: moduleName, priority = 'P2', title } = meta;

  if (!id) throw new Error('tc() requires an id, e.g. TC_PHISH_001');
  if (!moduleName) throw new Error(`tc(${id}) requires a module`);
  if (!title) throw new Error(`tc(${id}) requires a title`);
  if (!VALID_PRIORITIES.has(priority)) {
    throw new Error(`tc(${id}) has invalid priority "${priority}"`);
  }
  if (registry.has(id)) {
    throw new Error(`Duplicate test case id: ${id} (already used by "${registry.get(id).title}")`);
  }

  const record = {
    id,
    module: moduleName,
    priority,
    title,
    preconditions: meta.preconditions || '—',
    steps: meta.steps || [],
    testData: meta.testData || '—',
    expected: meta.expected || '—',
    /** Documented reason this case exists; surfaces in the report. */
    rationale: meta.rationale || '',
  };
  registry.set(id, record);

  // `it` is injected by Mocha at runtime.
  const testFn = it(`${id} — ${title}`, async function runTestCase() {
    this.testCaseMeta = record;
    return fn.call(this);
  });

  // Mocha's `it()` returns the Test; stash metadata for the reporter.
  if (testFn) testFn.testCaseMeta = record;
  return testFn;
}

/** Marks a case as intentionally not applicable, with a visible reason. */
tc.notApplicable = function notApplicable(meta, reason) {
  const record = {
    id: meta.id,
    module: meta.module,
    priority: meta.priority || 'P3',
    title: meta.title,
    preconditions: '—',
    steps: [],
    testData: '—',
    expected: '—',
    rationale: reason,
    notApplicable: true,
  };
  registry.set(meta.id, record);
  const testFn = it.skip(`${meta.id} — ${meta.title} [N/A: ${reason}]`, () => {});
  if (testFn) testFn.testCaseMeta = record;
  return testFn;
};

tc.registry = registry;
tc.all = () => Array.from(registry.values());
tc.count = () => registry.size;

module.exports = { tc };
