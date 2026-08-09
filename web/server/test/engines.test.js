import assert from 'node:assert/strict';
import { describe, it, before } from 'node:test';

import { loadModels, status } from '../src/engines/modelStore.js';
import { analyzeUrl, buildFeatures } from '../src/engines/phishingEngine.js';
import { analyzePermissions } from '../src/engines/permissionAnalyzer.js';
import {
  analyzeApp,
  extractFeatures,
} from '../src/engines/malwareEngine.js';
import { analyzeNetwork, classifySecurity } from '../src/engines/wifiEngine.js';
import {
  maskEmail,
  offlineLookup,
  parseRangeResponse,
  sha1Upper,
} from '../src/engines/breachEngine.js';
import { unifiedScore, label } from '../src/engines/scoreCalculator.js';
import * as patterns from '../src/engines/threatPatterns.js';
import { extractUrls, getDomain } from '../src/engines/urlExtractor.js';

before(async () => {
  await loadModels();
  const s = status();
  // Not an assertion — the engines are meant to degrade when a model is
  // absent, and the tests below cover both paths. This just makes it obvious
  // in the output which path a given run exercised.
  console.log('  models:', JSON.stringify({
    phishing: s.phishing,
    malwareRf: s.malwareRf,
    malwareLgbm: s.malwareLgbm,
    malwareGnn: s.malwareGnn,
    wifi: s.wifi,
  }));
});

describe('threat pattern parity with the Dart source', () => {
  // These lists are duplicated across two languages. If someone adds a bank to
  // the whitelist on one side only, the phone and the browser start
  // disagreeing about whether that bank's site is safe — so the sizes are
  // pinned, and a mismatch here is the reminder to update both.
  it('carries the expected number of entries in each list', () => {
    assert.equal(patterns.indianPhishingKeywords.length, 46);
    assert.equal(patterns.smsPhishingKeywords.length, 28);
    assert.equal(patterns.suspiciousTlds.length, 39);
    assert.equal(patterns.safeDomains.length, 89);
    assert.equal(Object.keys(patterns.dangerousPermissions).length, 35);
    assert.equal(patterns.spywareClusters.length, 8);
    assert.equal(patterns.suspiciousUrlPatterns.length, 4);
  });
});

describe('URL extraction', () => {
  it('keeps a multi-label government host intact', () => {
    // The regression this guards: truncating to `myaadhaar.uidai` missed the
    // whitelist and reported the real Aadhaar portal as phishing.
    const urls = extractUrls('Visit myaadhaar.uidai.gov.in to update');
    assert.ok(urls.includes('myaadhaar.uidai.gov.in'));
  });

  it('finds several links in one message', () => {
    const urls = extractUrls(
      'Click https://bit.ly/abc or www.example.com or paytm-verify.tk now',
    );
    assert.equal(urls.length, 3);
  });

  it('does not carry regex state between calls', () => {
    // A shared /g regex keeps lastIndex, so the second scan of identical text
    // would silently start partway through and miss the first link.
    const text = 'go to https://evil.tk/login now';
    assert.deepEqual(extractUrls(text), extractUrls(text));
  });

  it('strips www and lowercases the host', () => {
    assert.equal(getDomain('HTTPS://WWW.Example.COM/path'), 'example.com');
  });
});

describe('phishing engine', () => {
  it('clears whitelisted banking domains', () => {
    for (const url of [
      'https://onlinesbi.sbi',
      'https://www.hdfcbank.com/personal',
      'https://myaadhaar.uidai.gov.in',
      'https://amazon.in/orders',
    ]) {
      const r = analyzeUrl(url);
      assert.equal(r.isPhishing, false, `${url} was flagged`);
      assert.ok(r.triggeredRules.includes('Trusted domain whitelist'));
    }
  });

  it('does not let the model overturn a whitelist hit', () => {
    // The whitelist is a decision, not a score to be revised. A blended model
    // probability must never be able to flip "this is sbi.co.in".
    const r = analyzeUrl('https://onlinesbi.sbi');
    assert.equal(r.mlAvailable, false);
    assert.equal(r.confidence, 96);
  });

  it('flags an IP-address URL', () => {
    const r = analyzeUrl('http://192.168.4.1/login.php');
    assert.equal(r.isPhishing, true);
    assert.ok(r.triggeredRules.some((x) => x.includes('IP address')));
  });

  it('flags brand impersonation on a throwaway TLD', () => {
    const r = analyzeUrl('http://secure-hdfc-verify.tk/kyc-update');
    assert.equal(r.isPhishing, true);
    assert.ok(r.confidence >= 50);
  });

  it('flags the @ redirect trick', () => {
    // A browser loads evil.tk here, not sbi.co.in. Worth 30 points on its own.
    const r = analyzeUrl('https://sbi.co.in@evil.tk/login');
    assert.equal(r.isPhishing, true);
    assert.ok(r.triggeredRules.some((x) => x.includes('@')));
  });

  it('detects percent-encoding obfuscation', () => {
    // Regression: the check tested for `%2F`/`%3A` while the caller lowercases
    // first, so it scored nothing. Mirrors the Dart anchor.
    const r = analyzeUrl('https://redirect.tk/go?u=https%3A%2F%2Fevil.tk/login');
    assert.ok(r.triggeredRules.some((x) => x.includes('encoding')));
  });

  it('does not call first-party brand infrastructure impersonation', () => {
    // brand (20) + encoding (15) lands exactly on the 35-point threshold, so
    // an OAuth redirect_uri on these hosts flipped to phishing once the
    // encoding rule started firing. They are real Microsoft/Amazon/Google
    // endpoints and belong on the whitelist.
    for (const url of [
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize' +
        '?redirect_uri=https%3A%2F%2Fcontoso.com%2Fauth',
      'https://s3.amazonaws.com/bucket/file.pdf',
      'https://storage.googleapis.com/bucket/asset.png',
      'https://lh3.googleusercontent.com/a/photo.jpg',
    ]) {
      const r = analyzeUrl(url);
      assert.equal(r.isPhishing, false, url);
      assert.ok(r.triggeredRules.includes('Trusted domain whitelist'), url);
    }
  });

  it('still catches a lookalike that merely contains the brand', () => {
    for (const url of [
      'http://microsoftonline-verify.tk/login',
      'http://secure-amazonaws.top/signin',
    ]) {
      assert.equal(analyzeUrl(url).isPhishing, true, url);
    }
  });

  it('flags hyphen-stuffed domains', () => {
    const r = analyzeUrl('http://secure-login-hdfc-india-verify.com');
    assert.ok(r.triggeredRules.some((x) => x.includes('hyphens')));
  });

  it('always returns at least one explanation', () => {
    for (const url of ['https://example.org', 'http://a.tk/x', 'https://sbi.co.in']) {
      assert.ok(analyzeUrl(url).shapReasons.length > 0);
    }
  });

  it('produces confidences inside the documented bands', () => {
    for (const url of [
      'https://google.com',
      'http://1.2.3.4/verify-now',
      'https://ordinary-site.org/page',
    ]) {
      const r = analyzeUrl(url);
      assert.ok(r.confidence >= 50 && r.confidence <= 99, `${url}: ${r.confidence}`);
    }
  });
});

describe('phishing feature vector', () => {
  it('has exactly 12 features, all in [0,1]', () => {
    // The weights were fitted against this ordering and scaling. A feature
    // outside the range means the vector no longer matches the training data,
    // and the model output stops meaning anything.
    for (const url of [
      'https://google.com',
      'http://192.168.1.1/a?b=' + 'x'.repeat(300),
      '',
      'https://a-b-c-d-e.f.g.h.i.xyz/login?otp=1',
    ]) {
      const f = buildFeatures(url);
      assert.equal(f.length, 12);
      for (const [i, v] of f.entries()) {
        assert.ok(v >= 0 && v <= 1, `feature ${i} of "${url}" = ${v}`);
        assert.ok(Number.isFinite(v), `feature ${i} is not finite`);
      }
    }
  });

  it('sets the brand-spoof flag only for a mismatched host', () => {
    assert.equal(buildFeatures('https://paytm.com/pay')[10], 0);
    assert.equal(buildFeatures('https://paytm-verify.tk/pay')[10], 1);
  });
});

describe('permission analyzer', () => {
  it('scores a clean app at zero', () => {
    const r = analyzePermissions(['android.permission.INTERNET']);
    assert.equal(r.riskScore, 0);
    assert.equal(r.riskLevel, 'low');
  });

  it('flags a stalkerware permission cluster', () => {
    const r = analyzePermissions([
      'android.permission.RECORD_AUDIO',
      'android.permission.CAMERA',
      'android.permission.READ_CONTACTS',
    ]);
    assert.ok(r.triggeredClusters.length > 0);
    assert.ok(r.riskScore > 0);
  });

  it('discounts trusted-store distribution', () => {
    const perms = [
      'android.permission.READ_SMS',
      'android.permission.READ_CONTACTS',
      'android.permission.BIND_ACCESSIBILITY_SERVICE',
      'android.permission.SYSTEM_ALERT_WINDOW',
    ];
    const sideloaded = analyzePermissions(perms, { isFromTrustedStore: false });
    const store = analyzePermissions(perms, { isFromTrustedStore: true });
    assert.ok(store.riskScore < sideloaded.riskScore);
    // A store app must not exceed "medium" on declared permissions alone,
    // otherwise every banking app on the device reads as critical.
    assert.ok(store.riskScore <= 40);
  });

  it('names the reason it flagged something', () => {
    const r = analyzePermissions([
      'android.permission.BIND_DEVICE_ADMIN',
      'android.permission.RECEIVE_BOOT_COMPLETED',
    ]);
    assert.ok(r.shapReasons.some((x) => x.includes('Device administrator')));
  });
});

describe('malware engine', () => {
  it('builds a 25-feature vector in the trained column order', () => {
    const f = extractFeatures({
      permissions: ['android.permission.READ_SMS', 'android.permission.CAMERA'],
      totalPermissions: 2,
      isSideloaded: true,
    });
    assert.equal(f.length, 25);
    assert.equal(f[0], 1, 'read_sms is column 0');
    assert.equal(f[4], 1, 'camera is column 4');
    assert.equal(f[1], 0, 'send_sms not declared');
    assert.equal(f[20], 2, 'total permission count');
    assert.equal(f[24], 1, 'sideloaded flag');
  });

  /**
   * The banking-trojan permission set, and the anchor for cross-language
   * parity. `test/engine_parity_test.dart` pins the Dart rules engine at
   * exactly 66/high for the same input; this pins the JavaScript side to the
   * same number, so a drift in either implementation fails one of the two.
   */
  const BANKING_TROJAN_PERMISSIONS = [
    'android.permission.READ_SMS',
    'android.permission.RECEIVE_SMS',
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.BIND_ACCESSIBILITY_SERVICE',
    'android.permission.RECEIVE_BOOT_COMPLETED',
  ];

  it('matches the Dart rules engine exactly on the anchor input', () => {
    const rules = analyzePermissions(BANKING_TROJAN_PERMISSIONS, {
      isFromTrustedStore: false,
    });
    assert.equal(rules.riskScore, 66);
    assert.equal(rules.riskLevel, 'high');
  });

  it('scores a sideloaded app above the same app from a store', () => {
    const trojan = analyzeApp({
      appName: 'Fast Loan',
      permissions: BANKING_TROJAN_PERMISSIONS,
      isFromTrustedStore: false,
    });
    const legit = analyzeApp({
      appName: 'Bank App',
      permissions: BANKING_TROJAN_PERMISSIONS,
      isFromTrustedStore: true,
    });
    assert.ok(trojan.riskScore > legit.riskScore);
  });

  it('lets the trained ensemble move the rules verdict', () => {
    // Worth being explicit about, because it is surprising: on this permission
    // set the RF/LGBM/GNN ensemble disagrees with the rules engine and scores
    // it as largely benign, and the 50/50 blend drops a "high" rules verdict
    // to "medium". That is the behaviour of the shipped models, not a porting
    // artefact — the Dart app produces the same blend from the same weights.
    // Pinned so that retraining a model surfaces here rather than silently
    // changing what users are told.
    const result = analyzeApp({
      appName: 'Fast Loan',
      permissions: BANKING_TROJAN_PERMISSIONS,
      isFromTrustedStore: false,
    });
    if (!result.mlAvailable) {
      // Models absent: the rules verdict stands unmodified.
      assert.equal(result.riskScore, 66);
      assert.equal(result.riskLevel, 'high');
      return;
    }
    assert.ok(result.mlProbability < 0.5, 'ensemble reads this set as benign');
    assert.equal(result.riskScore, 38);
    assert.equal(result.riskLevel, 'medium');
  });

  it('never claims total certainty', () => {
    const r = analyzeApp({
      appName: 'Everything',
      permissions: Object.keys(patterns.dangerousPermissions),
      isFromTrustedStore: false,
    });
    assert.ok(r.riskScore <= 99, `riskScore was ${r.riskScore}`);
  });

  it('still answers when no model is loaded', () => {
    const r = analyzeApp({ appName: 'X', permissions: [] });
    assert.ok(typeof r.riskScore === 'number');
    assert.ok(Array.isArray(r.shapReasons));
  });
});

describe('wifi engine', () => {
  it('treats WEP as unencrypted', () => {
    const sec = classifySecurity('WEP');
    assert.equal(sec.isEncrypted, false);
    assert.equal(sec.code, 1);
  });

  it('assumes encrypted when the mode is unrecognised', () => {
    // Failing the other way would tell a WPA3 user their network is open.
    assert.equal(classifySecurity('').isEncrypted, true);
    assert.equal(classifySecurity('Unknown').isEncrypted, true);
  });

  it('scores an open network below an encrypted one', () => {
    const open = analyzeNetwork({ ssid: 'Free WiFi', security: 'Open', rssi: -55 });
    const wpa = analyzeNetwork({ ssid: 'Home', security: 'WPA2', rssi: -55 });
    assert.ok(open.trustScore < wpa.trustScore);
  });

  it('raises the Evil Twin check when the BSSID changed', () => {
    const r = analyzeNetwork({
      ssid: 'Home',
      bssid: 'aa:bb:cc:dd:ee:ff',
      security: 'WPA2',
      bssidChanged: true,
    });
    const check = r.checks.find((c) => c.name === 'BSSID Consistency');
    assert.equal(check.passed, false);
    assert.ok(check.detail.includes('Evil Twin'));
  });

  it('omits the DNS check rather than failing it when unmeasured', () => {
    // A browser cannot time the user's resolver. Scoring an unmeasured check
    // as failed would dock 20 points from every scan for nothing.
    const r = analyzeNetwork({ ssid: 'Home', security: 'WPA2' });
    assert.equal(r.dnsMeasured, false);
    assert.ok(!r.checks.some((c) => c.name === 'DNS Health'));
  });
});

describe('breach engine', () => {
  it('hashes to the published SHA-1 for a known input', () => {
    // "password" — the canonical HIBP example.
    assert.equal(sha1Upper('password'), '5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8');
  });

  it('finds a suffix in a range response', () => {
    const body = [
      '003D68EB55068C33ACE09247EE4C639306B:3',
      '012C192B2FAB3C0C8B0B4A6DF9E1C9DFC6E:5',
    ].join('\r\n');
    assert.equal(parseRangeResponse(body, '012C192B2FAB3C0C8B0B4A6DF9E1C9DFC6E'), 5);
    assert.equal(parseRangeResponse(body, 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'), 0);
  });

  it('masks an address without losing its domain', () => {
    assert.equal(maskEmail('alexander@gmail.com'), 'a*******r@gmail.com');
    assert.equal(maskEmail('ab@x.com'), 'a***@x.com');
    assert.equal(maskEmail('not-an-email'), '***@***.***');
  });

  it('is deterministic for the same address', () => {
    const a = offlineLookup('someone@yahoo.com');
    const b = offlineLookup('someone@yahoo.com');
    assert.deepEqual(a.map((x) => x.name).sort(), b.map((x) => x.name).sort());
  });

  it('matches a domain-relevant breach', () => {
    assert.ok(offlineLookup('someone@yahoo.com').some((b) => b.name === 'Yahoo'));
  });

  it('rejects a non-address', () => {
    assert.deepEqual(offlineLookup('not-an-email'), []);
  });
});

describe('unified score', () => {
  it('weights malware highest', () => {
    const base = { phishingScore: 100, malwareScore: 100, breachScore: 100, wifiScore: 100, breachActive: false };
    const badMalware = unifiedScore({ ...base, malwareScore: 0 });
    const badWifi = unifiedScore({ ...base, wifiScore: 0 });
    assert.ok(badMalware < badWifi);
  });

  it('caps the score while credentials are exposed', () => {
    // No amount of clean scanning should read as "protected" while the user's
    // credentials are known to be in a breach dump.
    const score = unifiedScore({
      phishingScore: 100,
      malwareScore: 100,
      breachScore: 100,
      wifiScore: 100,
      breachActive: true,
    });
    assert.ok(score <= 45);
    assert.notEqual(label(score), 'PROTECTED');
  });
});
