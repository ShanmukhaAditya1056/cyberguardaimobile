import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

class CyberGuardApp extends ConsumerWidget {
  const CyberGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
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
