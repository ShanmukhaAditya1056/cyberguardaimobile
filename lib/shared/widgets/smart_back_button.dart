import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/automation_ids.dart';

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
    return Semantics(
      identifier: AutoId.backBtn,
      container: true,
      child: IconButton(
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
      ),
    );
  }
}
