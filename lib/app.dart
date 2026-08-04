import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'features/interceptor/provider/interceptor_provider.dart';
import 'l10n/generated/app_localizations.dart';

/// Maps a notification payload to the screen that shows its details.
const _notifRoutes = <String, String>{
  NotifTarget.alerts: '/alerts',
  NotifTarget.phishing: '/phishing',
  NotifTarget.malware: '/malware',
  NotifTarget.breach: '/breach',
  NotifTarget.wifi: '/wifi',
  NotifTarget.report: '/alerts',
};

class CyberGuardApp extends ConsumerStatefulWidget {
  const CyberGuardApp({super.key});

  @override
  ConsumerState<CyberGuardApp> createState() => _CyberGuardAppState();
}

class _CyberGuardAppState extends ConsumerState<CyberGuardApp> {
  @override
  void initState() {
    super.initState();
    // A notification tap can land before the router is usable (cold start) or
    // while splash/onboarding still owns navigation, so drain on both a fresh
    // tap and every route change until it can actually be applied.
    NotificationService.navToken.addListener(_drainNotificationTarget);
    appRouter.routerDelegate.addListener(_drainNotificationTarget);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _drainNotificationTarget());
  }

  @override
  void dispose() {
    NotificationService.navToken.removeListener(_drainNotificationTarget);
    appRouter.routerDelegate.removeListener(_drainNotificationTarget);
    super.dispose();
  }

  void _drainNotificationTarget() {
    if (NotificationService.peekPendingTarget() == null) return;

    // Splash and onboarding both `context.go` when they finish, which would
    // wipe anything pushed underneath them. Wait for a real screen.
    final location = appRouter.routerDelegate.currentConfiguration.uri.path;
    if (location == '/' || location == '/onboarding') return;

    final route = _notifRoutes[NotificationService.consumePendingTarget()];
    if (route == null || route == location) return;

    // Never push from inside a router notification — let the frame settle.
    WidgetsBinding.instance.addPostFrameCallback((_) => appRouter.push(route));
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    // Smart Link Interceptor: instantiating the provider here starts its
    // listener (cold-start + stream). When a risky link is intercepted the
    // navToken bumps and we surface the warning screen over the current route.
    ref.listen<int>(interceptorProvider.select((s) => s.navToken), (prev, next) {
      if (next > 0 && next != (prev ?? 0)) {
        appRouter.push('/intercept');
      }
    });
    // Dark mode was retired: the legacy widget colour map proved too risky
    // to refactor cleanly before defence. The Zomato-style light theme is
    // now the only theme shipped — see assets/models/README.md for the
    // full rationale.
    return MaterialApp.router(
      title: 'CyberGuard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: appRouter,
    );
  }
}
