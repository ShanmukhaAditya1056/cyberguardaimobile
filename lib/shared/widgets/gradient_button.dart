import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/automation_ids.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  /// Stable resource-id for E2E automation. See [AutoId].
  final String? autoIdent;

  const GradientButton({
    super.key,
    required this.label,
    required this.gradient,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.borderRadius = 14,
    this.textStyle,
    this.padding,
    this.autoIdent,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null || widget.isLoading) return;
    _ctrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    if (widget.onTap != null && !widget.isLoading) {
      widget.onTap!();
    }
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.gradient.colors.first.withValues(alpha: 0.3);
    final isEnabled = widget.onTap != null && !widget.isLoading;

    // Publish the button to the semantics tree so both TalkBack and the
    // Appium driver see a real, tappable node carrying [autoIdent] as its
    // resource-id. `enabled` lets tests assert the disabled/loading state
    // instead of inferring it from pixels.
    return Semantics(
      identifier: widget.autoIdent ?? '',
      button: true,
      enabled: isEnabled,
      label: widget.label,
      container: true,
      child: _buildButton(glowColor),
    );
  }

  Widget _buildButton(Color glowColor) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: child,
          ),
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.onTap != null && !widget.isLoading
                ? widget.gradient
                : LinearGradient(colors: [
                    widget.gradient.colors.first.withValues(alpha: 0.5),
                    widget.gradient.colors.last.withValues(alpha: 0.5),
                  ]),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: AppColors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          style: widget.textStyle ?? AppTextStyles.button,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Small icon-only gradient button
class GradientIconButton extends StatefulWidget {
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  /// Stable resource-id for E2E automation. See [AutoId].
  final String? autoIdent;

  /// Accessible name. Icon-only buttons are invisible to both screen readers
  /// and automation without one.
  final String? semanticLabel;

  const GradientIconButton({
    super.key,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.autoIdent,
    this.semanticLabel,
  });

  @override
  State<GradientIconButton> createState() => _GradientIconButtonState();
}

class _GradientIconButtonState extends State<GradientIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: widget.autoIdent ?? '',
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      container: true,
      child: _buildIconButton(),
    );
  }

  Widget _buildIconButton() {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.size / 3),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(widget.icon, color: AppColors.white, size: widget.iconSize),
        ),
      ),
    );
  }
}
