import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/gradient_button.dart';

/// Runtime permission prompts, and the rationale sheet shown before each one.
///
/// Only Android and iOS have runtime permissions in this sense. On the desktops
/// a process is granted network and filesystem access when it launches — there
/// is nothing to ask for, and `permission_handler` has no Linux implementation
/// at all, so touching `Permission.x` there throws `MissingPluginException`.
/// Every entry point below therefore short-circuits to "granted" on a host
/// without a permission model, which is the truthful answer: the capability is
/// already available.
///
/// This says nothing about whether a *feature* exists on the host — that is
/// [AppPlatform]'s job. SMS scanning is unavailable on Windows because Windows
/// has no inbox, not because a permission was refused.
class PermissionService {
  /// Request SMS permission with rationale bottom sheet
  static Future<bool> requestSmsPermission(BuildContext context) async {
    if (!AppPlatform.hasRuntimePermissions) return false;
    final status = await Permission.sms.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      final shouldRequest = await _showRationaleSheet(
        context,
        icon: Icons.sms_outlined,
        title: l.permSmsTitle,
        rationale: l.permSmsRationale,
        iconColor: AppColors.blue,
      );
      if (!shouldRequest) return false;
    }

    final result = await Permission.sms.request();
    return result.isGranted;
  }

  /// Request the permissions needed to read the connected Wi-Fi's SSID:
  ///  - ACCESS_FINE_LOCATION (Android 9–12 path)
  ///  - NEARBY_WIFI_DEVICES (Android 13+ path; permission_handler maps this
  ///    to `Permission.nearbyWifiDevices` and silently no-ops on API < 33)
  ///
  /// Returns true if either path is satisfied. Without one of these the
  /// system returns "<unknown ssid>" and SSID surfaces as "Unknown" in the
  /// UI, regardless of the user's actual network.
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // Reading the SSID is gated on location only on Android. The desktops hand
    // it over freely, and on iOS no permission unlocks it at all — it needs a
    // build-time entitlement, so prompting would be theatre.
    if (!AppPlatform.isAndroid) return AppPlatform.canReadWifiIdentity;
    final locStatus = await Permission.location.status;
    final nearbyStatus = await Permission.nearbyWifiDevices.status;
    if (locStatus.isGranted || nearbyStatus.isGranted) return true;

    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      final shouldRequest = await _showRationaleSheet(
        context,
        icon: Icons.wifi_outlined,
        title: l.permLocationTitle,
        rationale: l.permLocationRationale,
        iconColor: AppColors.safe,
      );
      if (!shouldRequest) return false;
    }

    // Ask for both. The platform will silently skip whichever doesn't apply.
    final results = await [
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();
    return results[Permission.location]?.isGranted == true ||
        results[Permission.nearbyWifiDevices]?.isGranted == true;
  }

  /// Request notification permission (Android 13+)
  static Future<bool> requestNotificationPermission(
      BuildContext context) async {
    // On the desktops NotificationService.init() already asked the OS through
    // the notification plugin itself, so there is nothing further to request.
    if (!AppPlatform.hasRuntimePermissions) {
      return AppPlatform.canPostNotifications;
    }
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      final shouldRequest = await _showRationaleSheet(
        context,
        icon: Icons.notifications_outlined,
        title: l.permNotifTitle,
        rationale: l.permNotifRationale,
        iconColor: AppColors.warning,
      );
      if (!shouldRequest) return false;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Check if package query permission is available (Android 11+)
  static Future<bool> hasPackageQueryPermission() async {
    // This is a normal permission declared in manifest, not runtime
    return true;
  }

  static Future<bool> _showRationaleSheet(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String rationale,
    required Color iconColor,
  }) async {
    if (!context.mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppGradients.blue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headline2),
            const SizedBox(height: 12),
            Text(
              rationale,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: AppLocalizations.of(ctx)!.permAllowButton,
              gradient: AppGradients.blue,
              onTap: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                AppLocalizations.of(ctx)!.permNotNow,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.white50),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Check all permissions and return status map
  static Future<Map<String, bool>> checkAllPermissions() async {
    if (!AppPlatform.hasRuntimePermissions) {
      return {
        'sms': AppPlatform.canReadSms,
        'location': AppPlatform.canReadWifiIdentity,
        'notification': AppPlatform.canPostNotifications,
      };
    }
    return {
      'sms': await Permission.sms.isGranted,
      'location': await Permission.location.isGranted,
      'notification': await Permission.notification.isGranted,
    };
  }
}
