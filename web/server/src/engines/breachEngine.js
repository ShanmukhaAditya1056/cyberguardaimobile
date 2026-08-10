import crypto from 'node:crypto';

import { config } from '../config/env.js';
import { offlineBreaches } from './offlineBreaches.js';

/**
 * Port of `HibpService`, `HashUtils` and `OfflineBreachDb`.
 *
 * The privacy property that makes this module defensible is k-anonymity, and
 * it survives the move to a server — with one addition that matters.
 *
 * On the phone, the SHA-1 is computed on-device and only its first five
 * characters ever leave. Here the browser does the same thing *before* the
 * request: `POST /api/breach/password` accepts a `prefix` and `suffix`, never a
 * password, so the plaintext never reaches this process, never lands in an
 * access log, and cannot be read out of a heap dump. The server relays the
 * prefix to HIBP exactly as the app does. See `client/src/lib/kAnonymity.js`
 * for the browser half.
 */

const HIBP_RANGE = 'https://api.pwnedpasswords.com/range/';
const HIBP_ACCOUNT = 'https://haveibeenpwned.com/api/v3/breachedaccount/';
const TIMEOUT_MS = 15_000;

export function sha1Upper(input) {
  return crypto
    .createHash('sha1')
    .update(input.trim().toLowerCase(), 'utf8')
    .digest('hex')
    .toUpperCase();
}

export const hibpPrefix = (input) => sha1Upper(input).slice(0, 5);
export const hibpSuffix = (input) => sha1Upper(input).slice(5);

/** Finds `suffix` in a HIBP range response and returns its breach count. */
export function parseRangeResponse(body, suffix) {
  const target = suffix.toUpperCase();
  for (const line of body.split('\n')) {
    const parts = line.trim().split(':');
    if (parts.length !== 2) continue;
    if (parts[0].trim().toUpperCase() === target) {
      return Number.parseInt(parts[1].trim(), 10) || 0;
    }
  }
  return 0;
}

export function maskEmail(email) {
  const parts = email.split('@');
  if (parts.length !== 2) return '***@***.***';
  const [local, domain] = parts;
  if (local.length <= 2) return `${local[0]}***@${domain}`;
  return `${local[0]}${'*'.repeat(local.length - 2)}${local[local.length - 1]}@${domain}`;
}

export function isValidEmail(email) {
  return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email.trim());
}

/**
 * Queries the HIBP range API for a 5-character prefix.
 *
 * `Add-Padding` asks HIBP to pad every response to a uniform size, so an
 * observer who can see the response length cannot narrow down which prefix was
 * requested. It costs nothing and closes a side channel the plain protocol
 * leaves open.
 */
export async function checkPasswordByPrefix(prefix, suffix) {
  if (!/^[0-9A-F]{5}$/i.test(prefix)) {
    throw new Error('prefix must be 5 hex characters');
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(`${HIBP_RANGE}${prefix.toUpperCase()}`, {
      headers: {
        'User-Agent': config.hibpUserAgent,
        'Add-Padding': 'true',
      },
      signal: controller.signal,
    });
    if (!response.ok) return 0;
    return parseRangeResponse(await response.text(), suffix);
  } finally {
    clearTimeout(timer);
  }
}

/**
 * The paid `/breachedaccount` lookup. Returns null when no key is configured,
 * which is the signal to fall back to the offline dataset.
 */
export async function fetchAccountBreaches(email) {
  if (!config.hibpApiKey) return null;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(
      `${HIBP_ACCOUNT}${encodeURIComponent(email)}?truncateResponse=false`,
      {
        headers: {
          'User-Agent': config.hibpUserAgent,
          'hibp-api-key': config.hibpApiKey,
        },
        signal: controller.signal,
      },
    );

    if (response.status === 404) return [];
    if (response.status === 401) throw new Error('Invalid HIBP API key');
    if (response.status === 429) {
      throw new Error('HIBP rate limit reached — please wait and try again');
    }
    if (!response.ok) return null;

    const data = await response.json();
    return data.map((b) => ({
      name: b.Name,
      title: b.Title,
      domain: b.Domain,
      breachDate: b.BreachDate,
      pwnCount: b.PwnCount,
      description: stripHtml(b.Description ?? ''),
      dataClasses: b.DataClasses ?? [],
      isVerified: b.IsVerified ?? true,
      isSensitive: b.IsSensitive ?? false,
    }));
  } finally {
    clearTimeout(timer);
  }
}

/** HIBP descriptions contain anchor tags; the client renders plain text. */
function stripHtml(html) {
  return html.replace(/<[^>]*>/g, '').trim();
}

/**
 * Offline fallback — port of `OfflineBreachDb.lookup`.
 *
 * These are real breaches, but *which* of them a given address is matched to
 * is derived deterministically from a SHA-1 of the address, not from a lookup.
 * It exists so the module still demonstrates something without a paid API key,
 * and every response that uses it carries `source: 'offline'` so the UI can
 * label it — presenting these as a genuine HIBP result would be a lie about
 * someone's security posture.
 */
export function offlineLookup(email) {
  const clean = email.trim().toLowerCase();
  if (!clean || !clean.includes('@')) return [];

  const domain = clean.split('@').pop();
  const digest = crypto.createHash('sha1').update(clean, 'utf8').digest();

  const flaggedKeywords = [
    'scammer', 'phish', 'hack', 'leak', 'pwned', 'breach', 'admin@test', 'demo@',
  ];
  const looksFlagged = flaggedKeywords.some((k) => clean.includes(k));

  const picks = new Set();

  for (const breach of offlineBreaches) {
    if (breach.domain === domain) picks.add(breach);
  }

  const shouldPick = digest[0] % 2 === 0 || looksFlagged;
  if (shouldPick) {
    for (let i = 0; i < offlineBreaches.length; i++) {
      if (digest[i % digest.length] % 3 === 0) picks.add(offlineBreaches[i]);
    }
  }

  if (looksFlagged && picks.size < 3) {
    for (let i = 0; i < 3; i++) picks.add(offlineBreaches[i]);
  }

  return [...picks].map((b) => ({
    name: b.name,
    title: b.title,
    domain: b.domain,
    breachDate: b.breachDate,
    pwnCount: b.pwnCount,
    description: b.description,
    dataClasses: b.dataClasses,
    isVerified: true,
    isSensitive: false,
  }));
}

/** Full account check: HIBP when a key is configured, offline otherwise. */
export async function checkAccount(email) {
  if (!isValidEmail(email)) {
    const err = new Error('Enter a valid email address');
    err.status = 400;
    throw err;
  }

  let breaches = null;
  let source = 'offline';

  try {
    breaches = await fetchAccountBreaches(email);
    if (breaches !== null) source = 'hibp';
  } catch (err) {
    // A bad key or a rate limit should degrade to the offline dataset rather
    // than fail the request — the user still gets an answer, labelled.
    breaches = null;
  }

  if (breaches === null) {
    breaches = offlineLookup(email);
    source = 'offline';
  }

  return {
    // Only the masked form and the hash prefix are returned or stored. The
    // full address is never persisted.
    maskedEmail: maskEmail(email),
    hashPrefix: hibpPrefix(email),
    isBreached: breaches.length > 0,
    breachCount: breaches.length,
    breaches,
    source,
    checkedAt: new Date().toISOString(),
  };
}
