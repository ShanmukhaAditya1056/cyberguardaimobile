import fs from 'node:fs';

import { config } from '../config/env.js';

/**
 * Verifies Firebase ID tokens, so an account created on the phone signs in on
 * the web and vice versa.
 *
 * The app authenticates against Firebase directly and never talks to this
 * server. The browser does the same — it runs the Firebase JS SDK, gets an ID
 * token, and hands it here exactly once, in exchange for the httpOnly session
 * cookie the rest of the API already uses. That keeps the shared identity
 * without putting a bearer token anywhere page scripts can read it.
 *
 * Configuration is optional on purpose, mirroring `AuthService.isConfigured`
 * in the app: with no project ID, [isConfigured] stays false, the session route
 * answers 501 with an explanation, and the local email/password accounts carry
 * on working. CI runs in exactly that state.
 */

let app = null;
let auth = null;
let initError = '';
let initialised = false;

function credentialFrom(admin, raw) {
  if (!raw) return null;
  // Accept either a path to the JSON or the JSON itself — some hosts only
  // offer environment variables, and pasting the file in is the usual escape.
  const text = raw.trimStart().startsWith('{')
    ? raw
    : fs.readFileSync(raw, 'utf8');
  return admin.cert(JSON.parse(text));
}

async function init() {
  if (initialised) return;
  initialised = true;

  const { projectId, serviceAccount } = config.firebase;
  if (!projectId) {
    initError = 'FIREBASE_PROJECT_ID is not set';
    return;
  }

  try {
    // Imported lazily so a deployment that never enables Firebase does not pay
    // the module's load cost, and so a broken install cannot stop the API from
    // booting — every other route works without it.
    const admin = await import('firebase-admin/app');
    const { getAuth } = await import('firebase-admin/auth');

    const credential = credentialFrom(admin, serviceAccount);
    app = admin.initializeApp(
      credential ? { credential, projectId } : { projectId },
      'cyberguard-verify',
    );
    auth = getAuth(app);
  } catch (err) {
    app = null;
    auth = null;
    initError = err.message;
  }
}

export async function isConfigured() {
  await init();
  return auth !== null;
}

/** Why auth is unavailable, for `/api/health` and the sign-in screen. */
export async function configurationError() {
  await init();
  return auth === null ? initError : '';
}

/**
 * Returns the token's verified claims, or throws.
 *
 * `checkRevoked` is deliberately off: it costs a network round trip per
 * request, and this token is exchanged for a session cookie exactly once at
 * sign-in rather than presented on every call.
 */
export async function verifyIdToken(idToken) {
  await init();
  if (!auth) {
    const err = new Error(
      `Firebase sign-in is not configured on this server (${initError}).`,
    );
    err.status = 501;
    throw err;
  }

  try {
    return await auth.verifyIdToken(idToken);
  } catch (cause) {
    // The library's messages name internal token fields and clock skew in
    // detail. The client only needs to know the token was not acceptable.
    const err = new Error('That sign-in could not be verified. Try again.');
    err.status = 401;
    err.cause = cause;
    throw err;
  }
}
