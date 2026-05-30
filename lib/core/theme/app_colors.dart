import 'package:flutter/material.dart';

/// Zomato-inspired clean light palette.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bg = Color(0xFFF7F7F7); // light page bg
  static const Color bgSafe = Color(0xFFF7F7F7);
  static const Color bgWarn = Color(0xFFF7F7F7);
  static const Color bgDanger = Color(0xFFF7F7F7);
  static const Color surface = Color(0xFFFFFFFF); // cards

  // Brand
  static const Color blue = Color(0xFF1A73E8); // CyberGuard blue (Zomato red analog)
  static const Color blueDark = Color(0xFF1557B0);
  static const Color blueGlow = Color(0x1A1A73E8); // 10% blue

  // Text — pure-ish black for titles, true grays for body / hints.
  static const Color textDark = Color(0xFF111111);
  static const Color textMedium = Color(0xFF555555);
  static const Color textLight = Color(0xFF8A8A8A);

  // Dividers + borders
  static const Color divider = Color(0xFFF0F0F0);
  static const Color border = Color(0xFFE8E8E8);

  // Status colors
  static const Color safe = Color(0xFF1EA672);
  static const Color safeDark = Color(0xFF158F5C);
  static const Color safeGlow = Color(0x1A1EA672);
  static const Color safeLightBg = Color(0xFFE8F5EE);

  static const Color warning = Color(0xFFF4831F);
  static const Color warningDark = Color(0xFFD96D0F);
  static const Color warningGlow = Color(0x1AF4831F);
  static const Color warningLightBg = Color(0xFFFFF3E6);

  static const Color danger = Color(0xFFE23744); // Zomato red
  static const Color dangerDark = Color(0xFFC72632);
  static const Color dangerGlow = Color(0x1AE23744);
  static const Color dangerLightBg = Color(0xFFFFEAEA);

  static const Color critical = Color(0xFFD4003E);
  static const Color criticalDark = Color(0xFFB00033);
  static const Color criticalGlow = Color(0x1AD4003E);
  static const Color criticalLightBg = Color(0xFFFFE0EB);

  // Info / blue surface tint (light tint for chips / icon backgrounds)
  static const Color infoBlueBg = Color(0xFFE8F0FE);

  // Risk badge pairs (bg + text use same family)
  static const Color lowBadge = Color(0xFF1EA672);
  static const Color medBadge = Color(0xFFF4831F);
  static const Color highBadge = Color(0xFFE23744);
  static const Color critBadge = Color(0xFFD4003E);

  // Legacy whites kept as compatibility aliases — now point at the new
  // light palette so screens that still reference them render correctly.
  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xFF3D3D3D); // textDark
  static const Color white50 = Color(0xFF696969); // textMedium
  static const Color white30 = Color(0xFF999999); // textLight
  static const Color white15 = Color(0xFFE8E8E8); // border
  static const Color white08 = Color(0xFFF0F0F0); // divider

  // Legacy glass tokens → now flat light surfaces
  static const Color glass = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFE8E8E8);
  static const Color glassDeep = Color(0xFFFAFAFA);

  // Card overlays & shimmer
  static const Color cardOverlay = Color(0xFFFAFAFA);
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  /// Theme-aware primary text colour: pure white in dark mode, near-black
  /// otherwise. Use for headings / body text that needs to flip between
  /// the two themes.
  static Color textOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF111111);

  /// Theme-aware secondary text colour for subtitles / captions.
  static Color subtextOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFB0B0B0)
          : const Color(0xFF555555);

  static Color forRiskLevel(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return critBadge;
      case 'high':
        return highBadge;
      case 'medium':
        return medBadge;
      case 'low':
        return lowBadge;
      default:
        return safe;
    }
  }
}
