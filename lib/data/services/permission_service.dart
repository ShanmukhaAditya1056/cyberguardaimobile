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
/// Every entry point below is guarded by [AppPlatform.hasRuntimePermissions],
/// because `permission_handler` needs a platform implementation and touching
/// `Permission.x` without one throws `MissingPluginException` rather than
/// returning "denied".
///
/// This says nothing about whether a *feature* exists on the host — that is
/// [AppPlatform]'s job. A refused permission and an absent capability are
/// different answers and the UI words them differently.
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

  /// Requests whatever this Android version needs to read the connected
  /// Wi-Fi's SSID — and nothing more.
  ///
  /// On Android 13+ that is NEARBY_WIFI_DEVICES alone, declared with
  /// `neverForLocation` in the manifest. The user is asked for "nearby
  /// devices", never for location, and the device-wide Location toggle does
  /// not have to be on.
  ///
  /// On Android 12 and below the platform offers no such route: the SSID is
  /// location-gated and ACCESS_FINE_LOCATION is the only way to read it.
  /// Nothing in this app reads a position either way.
  ///
  /// Without a grant the system returns "<unknown ssid>" and the network
  /// surfaces as "Unknown" whatever the user is actually connected to.
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // A host with no permission model has nothing to prompt for.
    if (!AppPlatform.isAndroid) return AppPlatform.canReadWifiIdentity;

    // `nearbyWifiDevices` reports denied rather than throwing below API 33,
    // so this is safe to check first on every version.
    final nearby = await Permission.nearbyWifiDevices.request();
    if (nearby.isGranted) return true;

    final locStatus = await Permission.location.status;
    if (locStatus.isGranted) return true;

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

    // Only reached on Android 12 and below, or if the nearby-devices prompt
    // above was declined. ACCESS_FINE_LOCATION is capped at API 32 in the
    // manifest, so on 13+ this request cannot succeed and correctly returns
    // false rather than showing a location prompt the OS would refuse.
    final location = await Permission.location.request();
    return location.isGranted;
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
