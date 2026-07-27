import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/automation_ids.dart';

/// Blinkit-style bright pastel tile with dark text. Light-on-dark accent.
class BlinkCard extends StatefulWidget {
  final Widget child;
  final Color tile;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;

  const BlinkCard({
    super.key,
    required this.child,
    this.tile = const Color(0xFFFFFFFF),
    this.accent = const Color(0xFF3B82F6),
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 20,
    this.onTap,
  });

  /// Convenience for the various module/category palettes used across the app.
  static const Color blueTile = Color(0xFFE0EBFF);
  static const Color blueAccent = Color(0xFF3B82F6);

  static const Color peachTile = Color(0xFFFFE7D6);
  static const Color peachAccent = Color(0xFFEA580C);

  static const Color roseTile = Color(0xFFFFD9DE);
  static const Color roseAccent = Color(0xFFE11D48);

  static const Color mintTile = Color(0xFFD4F5E2);
  static const Color mintAccent = Color(0xFF059669);

  static const Color amberTile = Color(0xFFFFF3D6);
  static const Color amberAccent = Color(0xFFCA8A04);

  static const Color lavenderTile = Color(0xFFE9E1FB);
  static const Color lavenderAccent = Color(0xFF7C3AED);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  @override
  State<BlinkCard> createState() => _BlinkCardState();
}

class _BlinkCardState extends State<BlinkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In dark mode mix the pastel tile with the dark surface so the
    // brand hue stays but the tile becomes legible on a dark scaffold.
    final tileColor = isDark
        ? Color.lerp(widget.tile, const Color(0xFF1E1E1E), 0.78)!
        : widget.tile;
    final shadowAlpha = isDark ? 0.35 : 0.18;

    Widget card = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: shadowAlpha),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: isDark ? const Color(0xFFEAEAEA) : BlinkCard.textPrimary,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) {
          _press.forward();
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) {
          _press.reverse();
          widget.onTap!();
        },
        onTapCancel: () => _press.reverse(),
        child: ScaleTransition(scale: _scale, child: card),
      );
    }

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    return card;
  }
}

/// Dark surface card — used inside Blinkit-style screens for secondary content
/// where lots of small white text is needed (long lists, tech details).
class BlinkSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const BlinkSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 18,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A4A),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? const Color(0xFF2C3E66),
          width: 0.8,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: card,
        ),
      );
    }

    if (margin != null) card = Padding(padding: margin!, child: card);
    return card;
  }
}

/// Solid-color rounded button — replaces the heavy GradientButton on most
/// Blinkit-style surfaces.
class BlinkButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final double height;
  final double radius;
  final bool fullWidth;

  /// Stable resource-id for E2E automation. See [AutoId].
  final String? autoIdent;

  const BlinkButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = const Color(0xFF0F172A),
    this.textColor = Colors.white,
    this.isLoading = false,
    this.height = 48,
    this.radius = 14,
    this.fullWidth = true,
    this.autoIdent,
  });

  @override
  State<BlinkButton> createState() => _BlinkButtonState();
}

class _BlinkButtonState extends State<BlinkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    final bg = enabled ? widget.color : widget.color.withValues(alpha: 0.5);

    return Semantics(
      identifier: widget.autoIdent ?? '',
      button: true,
      enabled: enabled,
      label: widget.label,
      container: true,
      child: _buildButton(enabled, bg),
    );
  }

  Widget _buildButton(bool enabled, Color bg) {
    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              _press.forward();
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: enabled
          ? (_) {
              _press.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(widget.textColor),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: widget.textColor, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: widget.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Light pill-shaped text field for use inside BlinkCards.
class BlinkInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Stable resource-id for E2E automation. See [AutoId].
  final String? autoIdent;

  const BlinkInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hint,
    this.icon,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.autoIdent,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: autoIdent ?? '',
      textField: true,
      container: true,
      child: _buildField(context),
    );
  }

  Widget _buildField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.done,
        style: TextStyle(
          fontFamily: 'Inter',
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            color: isDark
                ? const Color(0xFF777777)
                : const Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: const Color(0xFF64748B))
              : null,
          suffixIcon: suffix,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
