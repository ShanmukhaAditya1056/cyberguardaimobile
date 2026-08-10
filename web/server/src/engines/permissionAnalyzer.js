import { dangerousPermissions, spywareClusters } from './threatPatterns.js';

/** Port of `lib/core/utils/permission_analyzer.dart`. */

const DANGER_SCORE = { critical: 30, high: 20, medium: 10, low: 3 };

const clamp = (v, min, max) => Math.min(max, Math.max(min, v));

const DESCRIPTIONS = {
  'android.permission.READ_SMS': 'Can read all your SMS messages including OTPs and bank alerts',
  'android.permission.SEND_SMS': 'Can send SMS messages that may incur charges',
  'android.permission.RECEIVE_SMS': 'Can intercept incoming SMS messages',
  'android.permission.READ_CALL_LOG': 'Can access your complete call history',
  'android.permission.PROCESS_OUTGOING_CALLS': 'Can intercept and redirect your phone calls',
  'android.permission.CALL_PHONE': 'Can make phone calls without your knowledge',
  'android.permission.BIND_ACCESSIBILITY_SERVICE': 'Can observe and control everything on your screen — extremely dangerous',
  'android.permission.BIND_DEVICE_ADMIN': 'Has device administrator rights — can wipe device or prevent uninstall',
  'android.permission.REQUEST_INSTALL_PACKAGES': 'Can install other APKs on your device',
  'android.permission.RECORD_AUDIO': 'Can record audio from your microphone',
  'android.permission.CAMERA': 'Can take photos and videos without your knowledge',
  'android.permission.READ_CONTACTS': 'Can access all your contacts',
  'android.permission.ACCESS_FINE_LOCATION': 'Can track your precise GPS location',
  'android.permission.ACCESS_BACKGROUND_LOCATION': 'Can track your location even when the app is closed',
  'android.permission.SYSTEM_ALERT_WINDOW': 'Can display overlays on top of other apps — used in banking trojans',
  'android.permission.RECEIVE_BOOT_COMPLETED': 'Starts automatically when device boots',
  'android.permission.WRITE_EXTERNAL_STORAGE': 'Can write files to your storage',
  'android.permission.READ_EXTERNAL_STORAGE': 'Can read all files on your storage',
  'android.permission.READ_PHONE_STATE': 'Can read your IMEI and phone number',
  'android.permission.MANAGE_EXTERNAL_STORAGE': 'Has full access to all files on device',
};

function shortName(permission) {
  return permission
    .split('.')
    .pop()
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join(' ');
}

function behaviorScore(permissions) {
  const any = (needle) => permissions.some((p) => p.includes(needle));
  let score = 0;
  // Persistence
  if (any('BOOT_COMPLETED')) score += 15;
  if (any('FOREGROUND_SERVICE')) score += 10;
  // Exfiltration: a reader paired with a way to send it out
  if (any('READ_SMS') && any('INTERNET')) score += 20;
  if (any('READ_CONTACTS') && any('INTERNET')) score += 15;
  // Privilege abuse
  if (any('DEVICE_ADMIN')) score += 30;
  if (any('ACCESSIBILITY')) score += 25;
  // Overlay attacks — the banking-trojan signature
  if (any('SYSTEM_ALERT')) score += 20;
  if (any('INSTALL_PACKAGES')) score += 20;
  return clamp(score, 0, 100);
}

function riskLevelFor(score) {
  if (score >= 70) return 'critical';
  if (score >= 45) return 'high';
  if (score >= 20) return 'medium';
  return 'low';
}

function shapReasons(dangerous, clusters, isFromTrustedStore) {
  const reasons = [];

  reasons.push(
    isFromTrustedStore
      ? 'Verified Play Store / official app store distribution'
      : 'Sideloaded — not installed from an official app store',
  );

  const critCount = dangerous.filter((p) => p.danger === 'critical').length;
  const highCount = dangerous.filter((p) => p.danger === 'high').length;

  if (critCount > 0) {
    reasons.push(
      `${critCount} critical permission${critCount > 1 ? 's' : ''} detected`,
    );
  }
  if (highCount > 0) {
    reasons.push(
      `${highCount} high-risk permission${highCount > 1 ? 's' : ''} found`,
    );
  }
  if (clusters.length > 0) {
    reasons.push(`Spyware permission cluster match: ${clusters[0]}`);
  }
  if (dangerous.some((p) => p.permission.includes('ACCESSIBILITY'))) {
    reasons.push('Accessibility service abuse potential');
  }
  if (dangerous.some((p) => p.permission.includes('DEVICE_ADMIN'))) {
    reasons.push('Device administrator privilege requested');
  }
  if (
    dangerous.some((p) => p.permission.includes('READ_SMS')) &&
    dangerous.some((p) => p.permission.includes('READ_CONTACTS'))
  ) {
    reasons.push('SMS + Contacts combination indicates data harvesting');
  }
  if (dangerous.length > 10) {
    reasons.push(`Unusually large number of permissions (${dangerous.length})`);
  }

  return reasons;
}

export function analyzePermissions(permissions, { isFromTrustedStore = false } = {}) {
  const dangerous = [];
  let permissionScore = 0;

  for (const permission of permissions) {
    const danger = dangerousPermissions[permission];
    if (!danger) continue;
    dangerous.push({
      permission,
      shortName: shortName(permission),
      danger,
      description:
        DESCRIPTIONS[permission] ??
        'This permission grants elevated access to device features',
    });
    permissionScore += DANGER_SCORE[danger] ?? 0;
  }

  permissionScore = clamp(permissionScore / 2.5, 0, 100);

  const triggeredClusters = [];
  let clusterBonus = 0;
  let clusterMatchScore = 0;

  for (const cluster of spywareClusters) {
    const matches = cluster.filter((c) =>
      permissions.some((p) => p.toUpperCase().includes(c)),
    ).length;
    if (matches === cluster.length) {
      triggeredClusters.push(cluster.join(' + '));
      clusterBonus += 25;
      clusterMatchScore += 30;
    } else if (matches >= cluster.length - 1 && cluster.length > 2) {
      // One permission short of a full cluster still says something.
      clusterBonus += 10;
      clusterMatchScore += 15;
    }
  }

  const behaviour = behaviorScore(permissions);

  const rfScore = clamp(permissionScore * 0.94 + clusterBonus * 0.35, 0, 100);
  const lgbmScore = clamp(permissionScore * 1.03 + behaviour * 0.4, 0, 100);
  const gnnScore = clamp(clusterMatchScore * 0.98, 0, 100);
  let finalScore = clamp(
    rfScore * 0.35 + lgbmScore * 0.4 + gnnScore * 0.25,
    0,
    100,
  );

  // Store-distributed apps went through automated malware scanning and
  // publisher verification. Without this discount every banking and social app
  // reads as critical purely for declaring the permissions it legitimately
  // needs, and a scanner that flags everything flags nothing.
  if (isFromTrustedStore) {
    finalScore *= 0.45;
    if (finalScore > 40) finalScore = 40;
  }

  const riskScore = Math.round(finalScore);

  return {
    riskScore,
    riskLevel: riskLevelFor(riskScore),
    dangerousPerms: dangerous,
    triggeredClusters,
    shapReasons: shapReasons(dangerous, triggeredClusters, isFromTrustedStore),
    rfScore,
    lgbmScore,
    gnnScore,
    finalScore,
  };
}
