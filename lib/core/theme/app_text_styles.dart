import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography tokens. **Most styles intentionally omit `color`** so that
/// `Text` widgets inherit colour from the surrounding `DefaultTextStyle`
/// (driven by `Theme.of(context).textTheme`). This is what makes the
/// app readable in both light and dark mode without per-widget overrides.
///
/// The exceptions are `button` / `buttonSmall`, which sit on coloured
/// gradient buttons where the foreground should stay pure white in
/// both themes.
class AppTextStyles {
  AppTextStyles._();

  /// Inter covers Latin, Greek and Cyrillic — it has no Devanagari, Tamil or
  /// Telugu glyphs. The app ships `hi`, `ta` and `te` localisations, so every
  /// style hands those scripts off to the matching Noto face instead of
  /// letting them fall through to whatever the device happens to have
  /// installed (which on a stripped Android build can be nothing at all, and
  /// renders as tofu boxes).
  ///
  /// Order is irrelevant here because the three scripts occupy disjoint
  /// Unicode blocks; only the face that actually owns the codepoint is used.
  ///
  /// `AppTheme` applies this to both `textTheme`s as well, which is what
  /// carries it to the inline `TextStyle(fontFamily: 'Inter', …)` call sites
  /// scattered through the feature screens — those inherit it via
  /// `TextStyle.merge` against the ambient `DefaultTextStyle`.
  static const List<String> fontFallback = <String>[
    'NotoSansDevanagari',
    'NotoSansTamil',
    'NotoSansTelugu',
  ];

  // Display — score numbers
  static const TextStyle display = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.0,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 64,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.0,
    height: 1.0,
  );

  // Headline
  static const TextStyle headline = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // Title
  static const TextStyle title = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.4,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  // Caption — slightly muted, but driven by ThemeData.textTheme.bodySmall
  // colour rather than a hard-coded one.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle captionMedium = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Badge — colour is set per-usage (risk badges, pills, etc.)
  static const TextStyle badge = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    height: 1.0,
  );

  // Button text — stays white in both themes because the background is
  // always a coloured gradient.
  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
    height: 1.2,
  );

  // Label
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );

  // Score label
  static const TextStyle scoreLabel = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );

  // Monospace for hashes etc
  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: fontFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.5,
  );

  // Tab label
  static const TextStyle tab = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  // Helper to obscure the unused-import warning. Returns the platform
  // default text colour; only ever called when an inherited colour
  // genuinely isn't available.
  static Color defaultColor(BuildContext context) =>
      AppColors.textOn(context);
}
