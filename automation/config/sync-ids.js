'use strict';

/**
 * Parses `lib/core/utils/automation_ids.dart` and emits `auto-ids.generated.js`.
 *
 * The Dart class is the single source of truth. Hand-copying those strings into
 * JavaScript guarantees drift the first time somebody renames one, and the
 * failure mode is a page object silently waiting 15s for an element that no
 * longer exists. `npm run doctor` re-runs this and fails if the checked-in file
 * is stale, so CI catches the drift instead of a flaky test.
 */

const fs = require('fs');
const path = require('path');

const DART_SRC = path.resolve(
  __dirname,
  '..',
  '..',
  'lib',
  'core',
  'utils',
  'automation_ids.dart'
);
const OUT = path.join(__dirname, 'auto-ids.generated.js');

/** `static const foo = 'cg_foo';` */
const CONST_RE = /static\s+const\s+(\w+)\s*=\s*'([^']+)'\s*;/g;
/** `static String foo(int i) => 'cg_foo_$i';` */
const FN_RE = /static\s+String\s+(\w+)\(([^)]*)\)\s*=>\s*'([^']+)'\s*;/g;

function parseDart(source) {
  const constants = {};
  const builders = {};

  let m;
  while ((m = CONST_RE.exec(source)) !== null) {
    constants[m[1]] = m[2];
  }
  while ((m = FN_RE.exec(source)) !== null) {
    const [, name, params, template] = m;
    const argName = (params.split(/\s+/).pop() || 'value').trim();
    // 'cg_x_$slug' -> template literal 'cg_x_${slug}'
    builders[name] = {
      arg: argName,
      template: template.replace(/\$(\w+)/g, (_, v) => '${' + v + '}'),
    };
  }
  return { constants, builders };
}

function render({ constants, builders }) {
  const lines = [];
  lines.push("'use strict';");
  lines.push('');
  lines.push('/*');
  lines.push(' * GENERATED FILE — DO NOT EDIT.');
  lines.push(' * Source: lib/core/utils/automation_ids.dart');
  lines.push(' * Regenerate: node automation/config/sync-ids.js');
  lines.push(' */');
  lines.push('');
  lines.push('const AutoId = Object.freeze({');
  for (const [k, v] of Object.entries(constants)) {
    lines.push(`  ${k}: '${v}',`);
  }
  for (const [k, { arg, template }] of Object.entries(builders)) {
    lines.push(`  ${k}: (${arg}) => \`${template}\`,`);
  }
  lines.push('});');
  lines.push('');
  lines.push('module.exports = { AutoId };');
  lines.push('');
  return lines.join('\n');
}

function generate() {
  const source = fs.readFileSync(DART_SRC, 'utf8');
  const parsed = parseDart(source);
  const count =
    Object.keys(parsed.constants).length + Object.keys(parsed.builders).length;
  if (count === 0) {
    throw new Error(`Parsed 0 identifiers from ${DART_SRC} — parser is broken.`);
  }
  return { code: render(parsed), count };
}

function write() {
  const { code, count } = generate();
  fs.writeFileSync(OUT, code, 'utf8');
  return { count, out: OUT };
}

/** Returns true when the checked-in file matches what we would generate now. */
function isUpToDate() {
  if (!fs.existsSync(OUT)) return false;
  return fs.readFileSync(OUT, 'utf8') === generate().code;
}

if (require.main === module) {
  const { count, out } = write();
  console.log(`Wrote ${count} automation identifiers -> ${path.relative(process.cwd(), out)}`);
}

module.exports = { generate, write, isUpToDate, OUT, DART_SRC };
