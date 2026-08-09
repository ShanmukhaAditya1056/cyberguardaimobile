import { models } from './modelStore.js';
import { isolationForestScore } from './trees.js';

/**
 * Port of `WifiMlService` and the scoring half of `WifiRepository`.
 *
 * What is deliberately *not* here: reading the network. A browser cannot see
 * the SSID, the BSSID, the signal strength or the cipher of the Wi-Fi it is
 * connected to — no web API exposes any of it, for good reason. So the web
 * version scores a network the user describes, which is what the module is
 * actually useful for in a browser: checking a café's network against the
 * details on the sign before trusting it, or getting a second opinion on a
 * network the phone already scanned.
 *
 * The DNS-health and latency checks the app measures directly have no browser
 * equivalent either, so they are optional inputs rather than assumed values.
 */

const clamp = (v, min, max) => Math.min(max, Math.max(min, v));

const FEATURE_COUNT = 8;

/**
 * Column order must match `08_train_isolation_forest.py`:
 * [rssi, encryption_code, is_public, dns_response_ms,
 *  beacon_interval, bssid_changes, rssi_variance, frequency_ghz]
 */
export function extractFeatures({
  rssi,
  encryptionCode,
  isPublic,
  dnsResponseMs,
  beaconInterval = 100,
  bssidChanges = 0,
  rssiVariance = 1.0,
  frequencyGhz,
}) {
  return [
    rssi,
    encryptionCode,
    isPublic ? 1 : 0,
    dnsResponseMs,
    beaconInterval,
    bssidChanges,
    rssiVariance,
    frequencyGhz,
  ];
}

/** Isolation Forest verdict, or null when the model did not load. */
export function detectAnomaly(features) {
  const model = models().wifi;
  if (!model || features.length !== FEATURE_COUNT) return null;

  const scaled = features.map((value, i) => {
    const scale = model.scalerScale[i];
    return scale === 0 ? 0 : (value - model.scalerMean[i]) / scale;
  });

  const raw = isolationForestScore(model.trees, scaled, model.maxSamples);
  const adjusted = raw - model.offset;

  return {
    anomalyScore: adjusted,
    isAnomaly: adjusted < 0,
    trustScore: Math.round(((clamp(adjusted, -0.5, 0.5) + 0.5) / 1.0) * 100),
  };
}

/** Port of `ScoreCalculator.wifiTrustScore`. */
export function rulesTrustScore({
  isEncrypted,
  dnsHealthy,
  bssidConsistent,
  rssi,
  isPublic,
}) {
  let score = 100;
  if (!isEncrypted) score -= 40;
  if (!dnsHealthy) score -= 20;
  if (!bssidConsistent) score -= 25;
  if (rssi < -80) score -= 10;
  if (isPublic) score -= 15;
  return clamp(score, 0, 100);
}

function riskLevelFor(trustScore) {
  if (trustScore >= 80) return 'low';
  if (trustScore >= 60) return 'medium';
  if (trustScore >= 40) return 'high';
  return 'critical';
}

/**
 * Maps a security label to the encryption code the model was trained on
 * (0 = open, 1 = WEP, 2 = WPA/WPA2/WPA3) and to whether it counts as
 * encrypted at all.
 *
 * WEP is reported as unencrypted for the same reason as everywhere else in
 * this codebase: it has been trivially breakable since 2001, and telling
 * someone a WEP network is "encrypted" is worse than telling them nothing.
 */
export function classifySecurity(security) {
  const value = (security ?? '').trim().toUpperCase();
  if (value === '' || value === 'UNKNOWN') {
    return { code: 2, isEncrypted: true, label: 'Unknown' };
  }
  if (value === 'OPEN' || value === 'NONE') {
    return { code: 0, isEncrypted: false, label: 'Open (no encryption)' };
  }
  if (value.startsWith('WEP')) {
    return { code: 1, isEncrypted: false, label: 'WEP (broken encryption)' };
  }
  if (value.startsWith('WPA3') || value.includes('SAE')) {
    return { code: 2, isEncrypted: true, label: 'WPA3' };
  }
  if (value.startsWith('WPA2')) {
    return { code: 2, isEncrypted: true, label: 'WPA2' };
  }
  if (value.startsWith('WPA')) {
    return { code: 2, isEncrypted: true, label: 'WPA' };
  }
  return { code: 2, isEncrypted: true, label: security };
}

/**
 * Full analysis of a user-described network.
 *
 * `bssidChanged` is supplied by the caller: the route looks up whether this
 * account has seen a different BSSID for the same SSID before, which is the
 * Evil Twin check the mobile app performs against its local history.
 */
export function analyzeNetwork({
  ssid = '',
  bssid = '',
  rssi = -60,
  security = '',
  frequency = 2437,
  dnsResponseMs = null,
  bssidChanged = false,
}) {
  const sec = classifySecurity(security);
  const isPublic = !sec.isEncrypted;

  // The browser cannot measure DNS latency against the user's resolver, so an
  // unsupplied value is treated as "not measured" rather than as a failure —
  // scoring an unmeasured check as failed would penalise every scan by 20
  // points for something the platform simply cannot see.
  const dnsMeasured = typeof dnsResponseMs === 'number';
  const dnsHealthy = dnsMeasured ? dnsResponseMs < 500 : true;

  const checks = [
    {
      name: 'Encryption',
      passed: sec.isEncrypted,
      detail: sec.isEncrypted
        ? `Network is encrypted (${sec.label})`
        : sec.label.startsWith('WEP')
          ? 'WEP encryption — broken since 2001, treat as open'
          : 'OPEN network — no encryption!',
    },
    {
      name: 'Signal Quality',
      passed: rssi >= -80,
      detail:
        rssi >= -50
          ? `Excellent signal (${rssi} dBm)`
          : rssi >= -70
            ? `Good signal (${rssi} dBm)`
            : rssi >= -80
              ? `Fair signal (${rssi} dBm)`
              : `Weak signal (${rssi} dBm) — possibly monitored`,
    },
    {
      name: 'BSSID Consistency',
      passed: !bssidChanged,
      detail: bssidChanged
        ? 'BSSID changed! Possible Evil Twin attack'
        : bssid
          ? 'Access point address recorded for this network'
          : 'No access point address given — Evil Twin check skipped',
    },
  ];

  if (dnsMeasured) {
    checks.push({
      name: 'DNS Health',
      passed: dnsHealthy,
      detail: dnsHealthy
        ? `DNS resolution healthy (${dnsResponseMs}ms)`
        : 'DNS lookup slow or failing — possible interception',
    });
  }

  const baseScore = rulesTrustScore({
    isEncrypted: sec.isEncrypted,
    dnsHealthy,
    bssidConsistent: !bssidChanged,
    rssi,
    isPublic,
  });

  let trustScore = baseScore;
  const anomaly = detectAnomaly(
    extractFeatures({
      rssi,
      encryptionCode: sec.code,
      isPublic,
      dnsResponseMs: dnsMeasured ? clamp(dnsResponseMs, 5, 200) : 50,
      bssidChanges: bssidChanged ? 1 : 0,
      frequencyGhz: frequency > 4000 ? 5.0 : 2.4,
    }),
  );

  if (anomaly?.isAnomaly) {
    trustScore = clamp(baseScore - 25, 0, 100);
    checks.push({
      name: 'ML anomaly',
      passed: false,
      detail:
        'Isolation Forest flagged this network as anomalous ' +
        `(score=${anomaly.anomalyScore.toFixed(3)})`,
    });
  } else if (anomaly) {
    trustScore = clamp(Math.round((baseScore + anomaly.trustScore) / 2), 0, 100);
  }

  return {
    ssid,
    bssid,
    rssi,
    frequency,
    isEncrypted: sec.isEncrypted,
    securityLabel: sec.label,
    trustScore,
    riskLevel: riskLevelFor(trustScore),
    checks,
    bssidChanged,
    dnsMeasured,
    mlAvailable: anomaly !== null,
  };
}
