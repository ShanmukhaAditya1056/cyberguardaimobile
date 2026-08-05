import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/malware_repository.dart';
import '../../data/services/hive_service.dart';
import '../../features/alerts/view/alerts_screen.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/breach/view/breach_screen.dart';
import '../../features/dashboard/view/dashboard_screen.dart';
import '../../features/fusion/view/arbitration_log_screen.dart';
import '../../features/fusion/view/threat_scan_screen.dart';
import '../../features/interceptor/view/link_warning_screen.dart';
import '../../features/malware/view/app_detail_screen.dart';
import '../../features/risk/view/predictive_risk_screen.dart';
import '../../features/screenshot/view/screenshot_scanner_screen.dart';
import '../../features/malware/view/malware_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/phishing/view/phishing_screen.dart';
import '../../features/phishing/view/qr_scanner_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/wifi/view/wifi_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    // Splash
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),

    // Onboarding
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),

    // Sign in. Not a gate: every scanner works on-device without an account,
    // so nothing redirects here. Onboarding offers it, Settings links to it,
    // and the screen itself always offers a way straight to the dashboard.
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),

    // Dashboard — main shell
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const DashboardScreen(),
    ),

    // Phishing scanner
    GoRoute(
      path: '/phishing',
      builder: (_, __) => const PhishingScreen(),
    ),

    // QR code phishing scanner
    GoRoute(
      path: '/phishing/qr',
      builder: (_, __) => const QrScannerScreen(),
    ),

    // Malware scanner
    GoRoute(
      path: '/malware',
      builder: (_, __) => const MalwareScreen(),
    ),

    // App detail (extra = ScannedApp)
    GoRoute(
      path: '/malware/detail',
      builder: (context, state) {
        final app = state.extra as ScannedApp;
        return AppDetailScreen(app: app);
      },
    ),

    // Breach monitor
    GoRoute(
      path: '/breach',
      builder: (_, __) => const BreachScreen(),
    ),

    // Wi-Fi scanner
    GoRoute(
      path: '/wifi',
      builder: (_, __) => const WifiScreen(),
    ),

    // Alerts
    GoRoute(
      path: '/alerts',
      builder: (_, __) => const AlertsScreen(),
    ),

    // Smart Link Interceptor warning (Feature 1) — shown reactively when a
    // risky link is intercepted. Reads the pending verdict from the provider.
    GoRoute(
      path: '/intercept',
      builder: (_, __) => const LinkWarningScreen(),
    ),

    // Threat Fusion scan (Feature 4)
    GoRoute(
      path: '/fusion',
      builder: (_, __) => const ThreatScanScreen(),
    ),

    // Arbitration / detection-conflict log (Feature 2)
    GoRoute(
      path: '/arbitration',
      builder: (_, __) => const ArbitrationLogScreen(),
    ),

    // Predictive Risk dashboard (Feature 5)
    GoRoute(
      path: '/risk',
      builder: (_, __) => const PredictiveRiskScreen(),
    ),

    // Screenshot AI scanner (Feature 3)
    GoRoute(
      path: '/screenshot',
      builder: (_, __) => const ScreenshotScannerScreen(),
    ),

    // Settings
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],

  // Redirect to onboarding if not completed
  redirect: (context, state) {
    final settings = HiveService.getSettings();
    final onboarded = settings.onboardingComplete;
    final location = state.matchedLocation;

    // Always allow splash + onboarding
    if (location == '/' || location == '/onboarding') return null;

    // Force onboarding on first launch
    if (!onboarded) return '/onboarding';

    return null;
  },

  // Error page
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE23744), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Page not found',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF3D3D3D),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.error?.message ?? 'Unknown route',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF696969),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text(
              'Go to Dashboard',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF1A73E8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
