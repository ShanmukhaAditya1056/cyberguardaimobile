import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Zomato-inspired clean light theme.
class AppTheme {
  AppTheme._();

  // Backwards-compatible alias used by older call sites.
  static ThemeData get dark => darkTheme;

  // Dark variant — true black scaffold + slightly off-black cards so
  // depth is still visible. Text is pure white.
  static ThemeData get darkTheme {
    const bgDark = Color(0xFF000000);
    const surfaceDark = Color(0xFF121212);
    const borderDark = Color(0xFF2A2A2A);
    const dividerDark = Color(0xFF1F1F1F);
    const textOnDark = Color(0xFFFFFFFF);
    const textMutedOnDark = Color(0xFFB0B0B0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      canvasColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.blue,
        onPrimary: Colors.white,
        secondary: AppColors.safe,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: textOnDark,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      // The DefaultTextStyle Flutter injects comes from `bodyMedium`.
      // We set every text-theme entry to pure white so headings, body,
      // captions etc. all read clearly on the true-black scaffold.
      // Widgets that intentionally want muted/secondary text use
      // `AppColors.subtextOn(context)` to opt back into the lighter grey.
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textOnDark),
        headlineMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textOnDark),
        titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textOnDark),
        titleMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textOnDark),
        bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textOnDark),
        bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textOnDark),
        bodySmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textOnDark),
        labelLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textOnDark),
      ).apply(fontFamilyFallback: AppTextStyles.fontFallback),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: bgDark,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: bgDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textOnDark),
        iconTheme: IconThemeData(color: textOnDark),
        actionsIconTheme: IconThemeData(color: textMutedOnDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderDark)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderDark)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.blue, width: 1.5)),
        hintStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, color: textMutedOnDark),
      ),
      dividerTheme: const DividerThemeData(
          color: dividerDark, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: textOnDark, size: 24),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        surfaceTintColor: surfaceDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: surfaceDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textOnDark),
        contentTextStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, color: textMutedOnDark),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.blue;
          return borderDark;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue,
        linearTrackColor: borderDark,
        circularTrackColor: borderDark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.blue,
        onPrimary: Colors.white,
        secondary: AppColors.safe,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textDark,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        // Default to textDark so widgets that inherit DefaultTextStyle —
        // including headings that use `AppTextStyles.titleMedium` etc. —
        // render in strong near-black instead of muted grey. Widgets
        // that intentionally want lighter / muted text use
        // `AppColors.subtextOn(context)` explicitly.
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMedium,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMedium,
          letterSpacing: 0.5,
        ),
      ).apply(fontFamilyFallback: AppTextStyles.fontFallback),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
        actionsIconTheme: IconThemeData(color: AppColors.textMedium),
        centerTitle: false,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.blue,
        unselectedLabelColor: AppColors.textLight,
        indicatorColor: AppColors.blue,
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.textLight,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.textMedium,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textMedium,
        size: 24,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bg,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.textMedium,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.blue;
          return AppColors.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue,
        linearTrackColor: AppColors.divider,
        circularTrackColor: AppColors.divider,
      ),
      splashColor: AppColors.blueGlow,
      highlightColor: AppColors.divider,
      splashFactory: InkRipple.splashFactory,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
