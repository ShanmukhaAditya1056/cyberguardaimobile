import cookieParser from 'cookie-parser';
import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';

import { config } from './config/env.js';
import { status as modelStatus } from './engines/modelStore.js';
import { errorHandler, notFound } from './middleware/errors.js';
import authRoutes from './routes/auth.js';
import breachRoutes from './routes/breach.js';
import dashboardRoutes from './routes/dashboard.js';
import fusionRoutes from './routes/fusion.js';
import malwareRoutes from './routes/malware.js';
import phishingRoutes from './routes/phishing.js';
import wifiRoutes from './routes/wifi.js';

export function createApp() {
  const app = express();

  // Behind a reverse proxy the client IP arrives in X-Forwarded-For. Without
  // this, every rate limiter sees the proxy's address and throttles all users
  // as one. Set to 1 rather than `true`: trusting every hop lets a client
  // forge the header and evade the limits entirely.
  app.set('trust proxy', 1);

  app.use(
    helmet({
      // The client is served from its own origin by Vite in development and by
      // a static host in production, so this API never returns HTML and needs
      // no script-src policy of its own. Cross-origin resource policy is
      // relaxed to same-site so the separate client origin can read responses.
      contentSecurityPolicy: false,
      crossOriginResourcePolicy: { policy: 'same-site' },
    }),
  );

  app.use(
    cors({
      origin: config.corsOrigins,
      // Required for the session cookie to travel cross-origin. A wildcard
      // origin is illegal in combination with this, which is why the allowed
      // origins are an explicit list.
      credentials: true,
    }),
  );

  // 256 KB covers a 500-app batch scan comfortably and stops an unbounded body
  // from being buffered into memory before any route has looked at it.
  app.use(express.json({ limit: '256kb' }));
  app.use(cookieParser());

  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      limit: 120,
      standardHeaders: 'draft-7',
      legacyHeaders: false,
      message: { error: 'Too many requests — slow down.' },
    }),
  );

  app.get('/api/health', (_req, res) => {
    const engines = modelStatus();
    res.json({
      ok: true,
      // Every scanner degrades to its rules engine when a model is missing, so
      // an engine that failed to load is reported rather than hidden — a
      // deployment silently running rules-only would look identical otherwise.
      engines: {
        phishing: engines.phishing,
        malwareRf: engines.malwareRf,
        malwareLgbm: engines.malwareLgbm,
        malwareGnn: engines.malwareGnn,
        wifi: engines.wifi,
      },
      modelErrors: engines.errors,
      hibpKeyConfigured: Boolean(config.hibpApiKey),
    });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/phishing', phishingRoutes);
  app.use('/api/malware', malwareRoutes);
  app.use('/api/breach', breachRoutes);
  app.use('/api/wifi', wifiRoutes);
  app.use('/api/dashboard', dashboardRoutes);
  // Threat fusion, the arbitration log, predictive risk and the scam-text
  // classifier — the four proactive-defence features ported from the app.
  app.use('/api/defense', fusionRoutes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
