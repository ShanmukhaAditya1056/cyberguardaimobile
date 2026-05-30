import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/shap_explainer.dart';

class ShapBar extends StatefulWidget {
  final ShapReason reason;
  final int index;

  const ShapBar({super.key, required this.reason, required this.index});

  @override
  State<ShapBar> createState() => _ShapBarState();
}

class _ShapBarState extends State<ShapBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800 + widget.index * 100),
    );
    _fill = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.reason.positive ? AppColors.danger : AppColors.safe;
    final barColor =
        widget.reason.positive ? AppColors.dangerGlow : AppColors.safeGlow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.reason.positive ? Icons.warning_amber : Icons.check_circle_outline,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.reason.feature,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.white70),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(widget.reason.contribution * 100).round()}%',
                style: AppTextStyles.captionMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 4,
              color: AppColors.white08,
              child: AnimatedBuilder(
                animation: _fill,
                builder: (_, __) => FractionallySizedBox(
                  widthFactor: _fill.value * widget.reason.contribution,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(color: barColor, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
