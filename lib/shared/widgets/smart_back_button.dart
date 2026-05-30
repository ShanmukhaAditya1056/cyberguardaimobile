import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class SmartBackButton extends StatelessWidget {
  final Color? color;
  final String fallbackRoute;

  const SmartBackButton({
    super.key,
    this.color,
    this.fallbackRoute = '/dashboard',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color ?? AppColors.white70),
      tooltip: 'Back',
      onPressed: () {
        HapticFeedback.selectionClick();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackRoute);
        }
      },
    );
  }
}
