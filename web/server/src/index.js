import mongoose from 'mongoose';

import { createApp } from './app.js';
import { config } from './config/env.js';
import { loadModels } from './engines/modelStore.js';

async function main() {
  // Models first: a request that arrived mid-load would otherwise get a
  // rules-only verdict for no reason other than timing, and the same URL would
  // score differently depending on how soon after boot it was scanned.
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

  await mongoose.connect(config.mongoUri);
  console.log(`[db] connected to ${redact(config.mongoUri)}`);

  const app = createApp();
  const server = app.listen(config.port, () => {
    console.log(`[api] listening on http://localhost:${config.port}`);
  });

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
