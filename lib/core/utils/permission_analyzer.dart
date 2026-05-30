import '../constants/threat_patterns.dart';

enum PermissionDanger { low, medium, high, critical }

class PermissionRisk {
  final String permission;
  final String shortName;
  final PermissionDanger danger;
  final String description;

  const PermissionRisk({
    required this.permission,
    required this.shortName,
    required this.danger,
    required this.description,
  });
}

class AppRiskResult {
  final int riskScore;
  final String riskLevel; // 'low', 'medium', 'high', 'critical'
  final List<PermissionRisk> dangerousPerms;
  final List<String> triggeredClusters;
  final List<String> shapReasons;
  final double rfScore;
  final double lgbmScore;
  final double gnnScore;
  final double finalScore;

  const AppRiskResult({
    required this.riskScore,
    required this.riskLevel,
    required this.dangerousPerms,
    required this.triggeredClusters,
    required this.shapReasons,
    required this.rfScore,
    required this.lgbmScore,
    required this.gnnScore,
    required this.finalScore,
  });
}

class PermissionAnalyzer {
  PermissionAnalyzer._();

  static AppRiskResult analyze(
    List<String> permissions, {
    bool isFromTrustedStore = false,
  }) {
    final dangerous = <PermissionRisk>[];
    double permissionScore = 0;

    for (final perm in permissions) {
      final dangerStr = ThreatPatterns.dangerousPermissions[perm];
      if (dangerStr != null) {
        final danger = _parseDanger(dangerStr);
        final shortName = _shortName(perm);
        dangerous.add(PermissionRisk(
          permission: perm,
          shortName: shortName,
          danger: danger,
          description: _description(perm),
        ));
        permissionScore += _dangerScore(danger);
      }
    }

    // Normalize permission score to 0-100
    permissionScore = (permissionScore / 2.5).clamp(0, 100);

    // Check spyware clusters
    final triggeredClusters = <String>[];
    double clusterBonus = 0;
    int clusterMatchScore = 0;

    for (final cluster in ThreatPatterns.spywareClusters) {
      final matches = cluster.where((c) =>
          permissions.any((p) => p.toUpperCase().contains(c))).length;
      if (matches == cluster.length) {
        triggeredClusters.add(cluster.join(' + '));
        clusterBonus += 25;
        clusterMatchScore += 30;
      } else if (matches >= cluster.length - 1 && cluster.length > 2) {
        clusterBonus += 10;
        clusterMatchScore += 15;
      }
    }

    // Behavior score (derived from permission patterns)
    final behaviorScore = _calcBehaviorScore(permissions);

    // Ensemble scoring
    final rfScore = (permissionScore * 0.94 + clusterBonus * 0.35).clamp(0.0, 100.0);
    final lgbmScore = (permissionScore * 1.03 + behaviorScore * 0.40).clamp(0.0, 100.0);
    final gnnScore = (clusterMatchScore * 0.98).clamp(0.0, 100.0);
    var finalScore =
        (rfScore * 0.35 + lgbmScore * 0.40 + gnnScore * 0.25).clamp(0.0, 100.0);

    // Trust adjustment: apps shipped via Play Store / Galaxy Store have gone
    // through automated malware scanning + publisher verification. Heavily
    // discount their score so legit banking/social apps don't get flagged as
    // critical just for declaring sensitive permissions they legitimately use.
    if (isFromTrustedStore) {
      finalScore *= 0.45;
      // Even with risky perms, a trusted store app should not exceed "medium".
      if (finalScore > 40) finalScore = 40;
    }

    final riskScore = finalScore.round();
    final riskLevel = _riskLevel(riskScore);
    final shapReasons = _shapReasons(
      dangerous,
      triggeredClusters,
      isFromTrustedStore: isFromTrustedStore,
    );

    return AppRiskResult(
      riskScore: riskScore,
      riskLevel: riskLevel,
      dangerousPerms: dangerous,
      triggeredClusters: triggeredClusters,
      shapReasons: shapReasons,
      rfScore: rfScore,
      lgbmScore: lgbmScore,
      gnnScore: gnnScore,
      finalScore: finalScore,
    );
  }

  static double _calcBehaviorScore(List<String> permissions) {
    double score = 0;
    // Persistence patterns
    if (permissions.any((p) => p.contains('BOOT_COMPLETED'))) score += 15;
    if (permissions.any((p) => p.contains('FOREGROUND_SERVICE'))) score += 10;
    // Data exfiltration patterns
    if (permissions.any((p) => p.contains('READ_SMS')) &&
        permissions.any((p) => p.contains('INTERNET'))) score += 20;
    if (permissions.any((p) => p.contains('READ_CONTACTS')) &&
        permissions.any((p) => p.contains('INTERNET'))) score += 15;
    // Admin abuse
    if (permissions.any((p) => p.contains('DEVICE_ADMIN'))) score += 30;
    if (permissions.any((p) => p.contains('ACCESSIBILITY'))) score += 25;
    // Overlay attacks
    if (permissions.any((p) => p.contains('SYSTEM_ALERT'))) score += 20;
    // Install APKs
    if (permissions.any((p) => p.contains('INSTALL_PACKAGES'))) score += 20;
    return score.clamp(0.0, 100.0);
  }

  static double _dangerScore(PermissionDanger d) {
    switch (d) {
      case PermissionDanger.critical: return 30;
      case PermissionDanger.high: return 20;
      case PermissionDanger.medium: return 10;
      case PermissionDanger.low: return 3;
    }
  }

  static PermissionDanger _parseDanger(String s) {
    switch (s) {
      case 'critical': return PermissionDanger.critical;
      case 'high': return PermissionDanger.high;
      case 'medium': return PermissionDanger.medium;
      default: return PermissionDanger.low;
    }
  }

  static String _shortName(String perm) {
    return perm.split('.').last
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  static String _description(String perm) {
    const descriptions = {
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
    return descriptions[perm] ?? 'This permission grants elevated access to device features';
  }

  static String _riskLevel(int score) {
    if (score >= 70) return 'critical';
    if (score >= 45) return 'high';
    if (score >= 20) return 'medium';
    return 'low';
  }

  static List<String> _shapReasons(
    List<PermissionRisk> dangerous,
    List<String> clusters, {
    bool isFromTrustedStore = false,
  }) {
    final reasons = <String>[];

    if (isFromTrustedStore) {
      reasons.add('Verified Play Store / official app store distribution');
    } else {
      reasons.add('Sideloaded — not installed from an official app store');
    }

    final critCount = dangerous.where((p) => p.danger == PermissionDanger.critical).length;
    final highCount = dangerous.where((p) => p.danger == PermissionDanger.high).length;

    if (critCount > 0) {
      reasons.add('$critCount critical permission${critCount > 1 ? 's' : ''} detected');
    }
    if (highCount > 0) {
      reasons.add('$highCount high-risk permission${highCount > 1 ? 's' : ''} found');
    }
    if (clusters.isNotEmpty) {
      reasons.add('Spyware permission cluster match: ${clusters.first}');
    }
    if (dangerous.any((p) => p.permission.contains('ACCESSIBILITY'))) {
      reasons.add('Accessibility service abuse potential');
    }
    if (dangerous.any((p) => p.permission.contains('DEVICE_ADMIN'))) {
      reasons.add('Device administrator privilege requested');
    }
    if (dangerous.any((p) => p.permission.contains('READ_SMS')) &&
        dangerous.any((p) => p.permission.contains('READ_CONTACTS'))) {
      reasons.add('SMS + Contacts combination indicates data harvesting');
    }
    if (dangerous.length > 10) {
      reasons.add('Unusually large number of permissions (${dangerous.length})');
    }

    return reasons;
  }
}
