import { ZodError } from 'zod';

import { config } from '../config/env.js';

/** Wraps an async route so a rejected promise reaches the error handler. */
export const asyncRoute = (handler) => (req, res, next) =>
  Promise.resolve(handler(req, res, next)).catch(next);

export function notFound(_req, res) {
  res.status(404).json({ error: 'Not found' });
}

/**
 * Terminal error handler.
 *
 * Validation problems are echoed back in detail because the user needs to know
 * which field was wrong. Everything else is reduced to a generic message in
 * production: an unexpected stack trace or a Mongo error string can name
 * internal paths, collections and driver versions, and that is free
 * reconnaissance for anyone probing the API.
 */
export function errorHandler(err, _req, res, _next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: 'Invalid request',
      details: err.errors.map((e) => ({
        field: e.path.join('.'),
        message: e.message,
      })),
    });
  }

  // Duplicate key — the only Mongo error with a safe, useful message.
  if (err?.code === 11000) {
    return res.status(409).json({ error: 'That email is already registered' });
  }

  const status = err.status ?? 500;
  if (status >= 500) {
    console.error('[error]', err);
  }

  return res.status(status).json({
    error:
      status >= 500 && config.isProduction
        ? 'Something went wrong'
        : err.message ?? 'Something went wrong',
  });
}
