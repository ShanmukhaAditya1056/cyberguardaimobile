/**
 * The browser half of the k-anonymity password check.
 *
 * This is the module that makes the web build's privacy claim true. The
 * password is hashed here, in the page, and split; only the first five hex
 * characters of the SHA-1 are sent to the CyberGuard API, which relays them to
 * HIBP. The remaining 35 characters are compared locally against the ~500
 * hashes that share that prefix.
 *
 * So the password never crosses the network, never reaches the CyberGuard
 * server, and cannot appear in an access log, an APM trace or a database. It is
 * the same protocol the mobile app runs on-device and the same one Google's
 * Password Checkup uses.
 *
 * SHA-1 is not a security choice here — it is the hash HIBP's corpus is built
 * on, and the property being relied on is the prefix partition, not collision
 * resistance.
 */

export async function sha1Hex(input) {
  if (!globalThis.crypto?.subtle) {
    // WebCrypto is unavailable on insecure origins. Falling back to a JS SHA-1
    // would work, but sending the password to the server would not — so the
    // check refuses rather than quietly downgrading the privacy guarantee.
    throw new Error(
      'Secure hashing is unavailable. Open this page over HTTPS (or on ' +
        'localhost) so your password can be hashed before it is checked.',
    );
  }
  const bytes = new TextEncoder().encode(input);
  const digest = await globalThis.crypto.subtle.digest('SHA-1', bytes);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
    .toUpperCase();
}

/**
 * Splits a password into the prefix that may leave the browser and the suffix
 * that must not.
 */
export async function splitForRangeQuery(password) {
  const hash = await sha1Hex(password);
  return { prefix: hash.slice(0, 5), suffix: hash.slice(5) };
}
