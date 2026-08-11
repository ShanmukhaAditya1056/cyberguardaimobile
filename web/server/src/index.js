import mongoose from 'mongoose';

import { createApp } from './app.js';
import { config } from './config/env.js';
import { loadModels } from './engines/modelStore.js';

/**
 * Boot order matters, and it is the opposite of the obvious one.
 *
 * Parsing 2.5 MB of models and connecting to Mongo takes several seconds.
 * Doing that *before* `listen()` leaves the port closed for the whole window,
 * and a closed port is indistinguishable from a crashed server: the dev proxy
 * reports ECONNREFUSED as a 500, and nothing in that response suggests waiting
 * would help. Under a file watcher, which restarts the process on every save,
 * that window is most of a working session.
 *
 * So the socket opens first and every /api route answers 503 with the stage it
 * is in until both steps finish. Same time to ready; the failure mode in
 * between becomes legible and retryable instead of looking like an outage.
 */

const boot = { models: false, db: false };

function readiness() {
  if (!boot.models) return { ready: false, reason: 'loading models' };
  if (!boot.db) return { ready: false, reason: 'connecting to database' };
  return { ready: true };
}

async function main() {
  const app = createApp(readiness);
  const server = app.listen(config.port, () => {
    console.log(`[api] listening on http://localhost:${config.port}`);
  });

  // Models before Mongo: a request that landed mid-load would otherwise get a
  // rules-only verdict for no reason other than timing, and the same URL would
  // score differently depending on how soon after boot it was scanned. The
  // readiness gate is what actually holds those requests off.
  const engines = await loadModels();
  const loaded = Object.entries(engines)
    .filter(([key, value]) => value === true && key !== 'ok')
    .map(([key]) => key);
  console.log(`[models] loaded: ${loaded.join(', ') || 'none'}`);
  for (const err of engines.errors) {
    console.warn(`[models] ${err}`);
  }
  if (engines.errors.length > 0) {
    console.warn(
      '[models] Affected scanners will fall back to their rules engines. ' +
        `Expected files in ${engines.modelsDir}`,
    );
  }
  boot.models = true;

  await mongoose.connect(config.mongoUri);
  console.log(`[db] connected to ${redact(config.mongoUri)}`);
  boot.db = true;

  console.log('[api] ready');

  // Finish in-flight requests before exiting, so a deploy does not drop a scan
  // halfway through writing its result.
  const shutdown = async (signal) => {
    console.log(`[api] ${signal} received, shutting down`);
    server.close(async () => {
      await mongoose.disconnect();
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10_000).unref();
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

/** Keeps credentials in a connection string out of the logs. */
function redact(uri) {
  return uri.replace(/\/\/[^@]*@/, '//***@');
}

main().catch((err) => {
  console.error('[api] failed to start:', err);
  process.exit(1);
});
