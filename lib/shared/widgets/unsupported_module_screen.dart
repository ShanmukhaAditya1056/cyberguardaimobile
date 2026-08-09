import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'smart_back_button.dart';

/// Shown in place of a module the current OS genuinely cannot run.
///
/// The route stays registered rather than being removed, because a
/// notification tap, a deep link or a stale `context.push` can all still aim at
/// it — and landing on "Page not found" would read as a bug in the app rather
/// than a limit of the platform. Saying which OS restriction is responsible,
/// and where the feature does work, is more useful than either.
class UnsupportedModuleScreen extends StatelessWidget {
  /// Module name as the user knows it, e.g. "App Scanner".
  final String moduleName;

  /// Why this host cannot run it, in one or two plain sentences.
  final String reason;

  /// Platforms where the module is fully available.
  final List<String> availableOn;

  final IconData icon;

  const UnsupportedModuleScreen({
    super.key,
    required this.moduleName,
    required this.reason,
    required this.availableOn,
    this.icon = Icons.block_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Text(moduleName, style: AppTextStyles.headline2),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 34, color: AppColors.warning),
              ),
              const SizedBox(height: 20),
              Text(
                'Not available on ${AppPlatform.displayName}',
                style: AppTextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                reason,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              if (availableOn.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Fully available on ${_joinNaturally(availableOn)}.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: Text(
                  'Back to Dashboard',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _joinNaturally(List<String> items) {
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }
}
