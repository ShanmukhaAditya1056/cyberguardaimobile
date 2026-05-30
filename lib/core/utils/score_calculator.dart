import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class ScoreCalculator {
  ScoreCalculator._();

  static int calculate({
    required int phishingScore,
    required int malwareScore,
    required int breachScore,
    required int wifiScore,
    required bool breachActive,
  }) {
    final weighted = (phishingScore * 0.30) +
        (malwareScore * 0.35) +
        (breachScore * 0.25) +
        (wifiScore * 0.10);

    final score = weighted.round().clamp(0, 100);
    return breachActive ? score.clamp(0, 45) : score;
  }

  static String label(int score) {
    if (score >= 70) return 'PROTECTED';
    if (score >= 40) return 'AT RISK';
    return 'CRITICAL';
  }

  static String labelVerbose(int score) {
    if (score >= 90) return 'Excellent Protection';
    if (score >= 70) return 'Well Protected';
    if (score >= 50) return 'Some Issues Found';
    if (score >= 40) return 'At Risk';
    if (score >= 20) return 'Serious Threats';
    return 'Critical Danger';
  }

  static LinearGradient gradient(int score) {
    if (score >= 70) return AppGradients.safe;
    if (score >= 40) return AppGradients.warning;
    return AppGradients.danger;
  }

  static Color glowColor(int score) {
    if (score >= 70) return AppColors.safeGlow;
    if (score >= 40) return AppColors.warningGlow;
    return AppColors.dangerGlow;
  }

  static Color primaryColor(int score) {
    if (score >= 70) return AppColors.safe;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  static LinearGradient bgGradient(int score) {
    return AppGradients.bgForScore(score);
  }

  /// Convert module-level threat count to a 0-100 security score
  static int fromThreatCount({
    required int totalApps,
    required int threatCount,
  }) {
    if (totalApps == 0) return 85;
    final ratio = threatCount / totalApps;
    if (ratio == 0) return 100;
    if (ratio < 0.01) return 90;
    if (ratio < 0.05) return 75;
    if (ratio < 0.10) return 55;
    if (ratio < 0.20) return 35;
    return 15;
  }

  /// Wi-Fi trust score from checks
  static int wifiTrustScore({
    required bool isEncrypted,
    required bool dnsHealthy,
    required bool bssidConsistent,
    required int rssi,
    required bool isPublic,
  }) {
    int score = 100;
    if (!isEncrypted) score -= 40;
    if (!dnsHealthy) score -= 20;
    if (!bssidConsistent) score -= 25;
    if (rssi < -80) score -= 10;
    if (isPublic) score -= 15;
    return score.clamp(0, 100);
  }
}
