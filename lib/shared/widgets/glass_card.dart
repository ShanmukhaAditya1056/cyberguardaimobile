import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Flat white Zomato-style card. Same API as the old GlassCard so existing
/// screens continue to compile, but it now renders a clean white surface
/// with a very subtle shadow — no blur, no glass effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderWidth;
  // ignore: unused_element_parameter
  final double blurSigma; // accepted for API compat; unused.
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  // ignore: unused_element_parameter
  final bool animate;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 12,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth = 1,
    this.blurSigma = 0,
    this.backgroundColor,
    this.shadows,
    this.onTap,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg =
        isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    final defaultBorder =
        isDark ? const Color(0xFF2A2A2A) : AppColors.border;
    final defaultShadow = isDark
        ? const BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        : const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          );

    Widget card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : Border.all(color: defaultBorder, width: 1),
        boxShadow: shadows ?? [defaultShadow],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.blueGlow,
          highlightColor: AppColors.divider,
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
