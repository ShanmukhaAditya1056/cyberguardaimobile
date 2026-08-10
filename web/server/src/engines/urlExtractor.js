import { urlPattern } from './threatPatterns.js';

/** Port of `lib/core/utils/url_extractor.dart`. */

const urlRegex = new RegExp(urlPattern, 'gim');

export function extractUrls(text) {
  if (!text) return [];
  // A /g regex carries lastIndex between calls, so it is rebuilt per call
  // rather than shared — otherwise the second scan of the same text silently
  // starts partway through and misses the first link.
  return [...text.matchAll(new RegExp(urlRegex.source, 'gim'))]
    .map((m) => m[0].trim())
    .filter((url) => url.length > 4);
}

export function getDomain(url) {
  try {
    // The scheme test is case-insensitive here where the Dart original is not.
    // In the scan pipeline it makes no difference — `analyzeUrl` runs
    // `normalize`, which lowercases, before this is ever called — but
    // `getDomain` is also exported on its own, and given `HTTPS://example.com`
    // the case-sensitive form prepends a second scheme and returns "https" as
    // the domain. Defensive, not divergent.
    const cleaned = /^https?:\/\//i.test(url) ? url : `https://${url}`;
    const parsed = new URL(cleaned);
    let host = parsed.hostname.toLowerCase();
    if (host.startsWith('www.')) host = host.slice(4);
    return host;
  } catch {
    return null;
  }
}

export function getTld(domain) {
  const parts = domain.split('.');
  if (parts.length < 2) return null;
  return `.${parts[parts.length - 1]}`;
}

export function normalize(url) {
  const u = url.trim().toLowerCase();
  return u.startsWith('http') ? u : `https://${u}`;
}

/**
 * Whether the URL hides structure behind encoding or a second scheme.
 *
 * Percent-encoding is matched case-insensitively — see the Dart original for
 * why the fixed-case form never fired. RFC 3986 permits either case in an
 * escape sequence.
 */
export function hasEncodedTricks(url) {
  const lower = url.toLowerCase();
  return (
    lower.includes('%2f') ||
    lower.includes('%3a') ||
    url.includes('@') ||
    (url.includes('//') && url.indexOf('//') !== url.lastIndexOf('//'))
  );
}

export function isIpAddress(url) {
  return /https?:\/\/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/.test(url);
}

export function subdomainCount(domain) {
  return domain.split('.').length - 2;
}

export function isExcessivelyLong(url) {
  return url.length > 100;
}
