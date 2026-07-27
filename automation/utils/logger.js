'use strict';

const fs = require('fs');
const path = require('path');
const env = require('../config/env');

const LEVELS = { debug: 10, info: 20, warn: 30, error: 40 };
const threshold = LEVELS[process.env.CG_LOG_LEVEL] || LEVELS.info;

fs.mkdirSync(env.logsDir, { recursive: true });

const RUN_LOG = path.join(env.logsDir, 'execution.log');
const stream = fs.createWriteStream(RUN_LOG, { flags: 'a' });

/** Redacts anything that looks like a credential before it reaches a log file. */
const REDACTIONS = [
  [/AIza[0-9A-Za-z_-]{35}/g, 'AIza***REDACTED***'],
  [/\b[0-9a-f]{32}\b/gi, '***REDACTED_HEX32***'],
  [/(api[_-]?key["'\s:=]+)([^\s"',}]+)/gi, '$1***REDACTED***'],
  [/(bearer\s+)([A-Za-z0-9._-]+)/gi, '$1***REDACTED***'],
];

function redact(text) {
  let out = String(text);
  for (const [re, replacement] of REDACTIONS) out = out.replace(re, replacement);
  return out;
}

function write(level, scope, message, meta) {
  if (LEVELS[level] < threshold) return;
  const ts = new Date().toISOString();
  const metaStr = meta ? ` ${redact(JSON.stringify(meta))}` : '';
  const line = `${ts} [${level.toUpperCase()}] [${scope}] ${redact(message)}${metaStr}`;
  stream.write(line + '\n');
  if (level === 'error') console.error(line);
  else if (level === 'warn') console.warn(line);
  else if (LEVELS[level] >= LEVELS.info) console.log(line);
}

/** Creates a namespaced logger, e.g. `logger('DashboardPage')`. */
function logger(scope) {
  return {
    debug: (msg, meta) => write('debug', scope, msg, meta),
    info: (msg, meta) => write('info', scope, msg, meta),
    warn: (msg, meta) => write('warn', scope, msg, meta),
    error: (msg, meta) => write('error', scope, msg, meta),
  };
}

logger.redact = redact;
logger.logFile = RUN_LOG;

module.exports = logger;
