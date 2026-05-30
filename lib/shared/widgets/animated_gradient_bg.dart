import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Zomato-style scaffold: flat light bg, no glassmorphism, no orbs.
/// Kept under the existing `GradientScaffold` name so screens that already
/// use it switch to the light theme automatically.
class GradientScaffold extends StatelessWidget {
  final int score;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GradientScaffold({
    super.key,
    required this.score,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: body,
    );
  }
}

/// Backwards compat — used by a few screens directly.
class AnimatedGradientBg extends StatelessWidget {
  final int score;
  final Widget child;
  const AnimatedGradientBg({super.key, required this.score, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.bg, child: child);
  }
}
