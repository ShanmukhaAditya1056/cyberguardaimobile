import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  // Background gradients
  static const LinearGradient bgSafe = LinearGradient(
    colors: [Color(0xFFF7F7F7), Color(0xFFF7F7F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient bgWarn = LinearGradient(
    colors: [Color(0xFFF7F7F7), Color(0xFFF7F7F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient bgDanger = LinearGradient(
    colors: [Color(0xFFF7F7F7), Color(0xFFF7F7F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient bgDefault = LinearGradient(
    colors: [Color(0xFFF7F7F7), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Status gradients
  static const LinearGradient blue = LinearGradient(
    colors: [Color(0xFF1A6BFF), Color(0xFF4A9EFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient safe = LinearGradient(
    colors: [Color(0xFF0FD97A), Color(0xFF4AE88A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFFF8C00), Color(0xFFFFB84D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFFF2929), Color(0xFFFF5757)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient critical = LinearGradient(
    colors: [Color(0xFFCC0044), Color(0xFFFF2D6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Radial glow
  static const RadialGradient scoreGlow = RadialGradient(
    colors: [Color(0x664A9EFF), Color(0x00000000)],
    radius: 0.8,
  );

  static const RadialGradient safeGlow = RadialGradient(
    colors: [Color(0x554AE88A), Color(0x00000000)],
    radius: 0.8,
  );

  static const RadialGradient dangerGlow = RadialGradient(
    colors: [Color(0x55FF5757), Color(0x00000000)],
    radius: 0.8,
  );

  // Header gradient overlay
  static const LinearGradient headerOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0x880A1628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Glass shimmer
  static const LinearGradient glassShimmer = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x0AFFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient forScore(int score) {
    if (score >= 70) return safe;
    if (score >= 40) return warning;
    return danger;
  }

  static LinearGradient bgForScore(int score) {
    if (score >= 70) return bgSafe;
    if (score >= 40) return bgWarn;
    return bgDanger;
  }

  static LinearGradient forRiskLevel(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return critical;
      case 'high':
        return danger;
      case 'medium':
        return warning;
      case 'low':
        return safe;
      default:
        return blue;
    }
  }

  // Module card gradients
  static const LinearGradient phishingModule = LinearGradient(
    colors: [Color(0xFF1A3A6B), Color(0xFF0D2040)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient malwareModule = LinearGradient(
    colors: [Color(0xFF3A1A6B), Color(0xFF200D40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient breachModule = LinearGradient(
    colors: [Color(0xFF6B1A2A), Color(0xFF400D14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient wifiModule = LinearGradient(
    colors: [Color(0xFF1A5A6B), Color(0xFF0D3040)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
