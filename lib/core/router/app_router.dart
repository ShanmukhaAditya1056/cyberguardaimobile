import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/malware_repository.dart';
import '../../data/services/auth_service.dart';
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
import '../../shared/widgets/unsupported_module_screen.dart';
import '../platform/app_platform.dart';

/// Routes reachable without a session. Everything else requires sign-in.
const _publicRoutes = <String>{'/', '/onboarding', '/login'};

/// Onboarding + sign-in gate. Returns a path to redirect to, or null to allow.
///
/// Sign-in is mandatory: every route outside [_publicRoutes] requires a
/// session, enforced here at the router rather than per screen so no deep
/// link, notification tap or `context.go` can slip past it.
///
/// The single bypass is deliberate. When the build carries no Firebase
/// credentials, signing in is *impossible*, so enforcing the gate would brick
/// the app permanently — on CI, and on any clean checkout without
/// google-services.json. There the gate stands down instead of locking
/// everyone out of a tool they cannot authenticate into. Whenever auth can
/// actually work, it is enforced with no way around it.
/// Pure form of the guard, split out so the gate can be tested without a
/// Hive box, a Firebase project or a live router.
@visibleForTesting
String? resolveRoute({
  required String path,
  required bool onboardingComplete,
  required bool authConfigured,
  required bool signedIn,
}) {
  // Splash decides where to go itself; never bounce it.
  if (path == '/') return null;

  // First launch still goes through onboarding before anything else.
  if (!onboardingComplete) {
    return path == '/onboarding' ? null : '/onboarding';
  }

  if (!authConfigured) return null;

  if (!signedIn && !_publicRoutes.contains(path)) return '/login';

  // Already authenticated — don't strand the user on the login screen.
  if (signedIn && path == '/login') return '/dashboard';

  return null;
}

String? _routeGuard(BuildContext context, GoRouterState state) {
  final path = state.matchedLocation;
  if (path == '/') return null; // avoid a Hive read on every splash frame
  return resolveRoute(
    path: path,
    onboardingComplete: HiveService.getSettings().onboardingComplete,
    authConfigured: AuthService.isConfigured,
    signedIn: AuthService.isSignedIn,
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  redirect: _routeGuard,
  // Re-evaluates the guard on sign-in and sign-out, so signing out drops
  // straight back to /login from wherever the user happened to be.
  refreshListenable: AuthStateNotifier(),
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

    // QR code phishing scanner. The scanner plugin has no Windows or Linux
    // implementation, for either the camera or the image decoder.
    GoRoute(
      path: '/phishing/qr',
      builder: (_, __) => AppPlatform.canDecodeQrFromImage
          ? const QrScannerScreen()
          : const UnsupportedModuleScreen(
              moduleName: 'QR Scanner',
              icon: Icons.qr_code_scanner_rounded,
              reason: 'The QR decoder this app uses has no Windows or Linux '
                  'build. Paste the link from the QR code into the Phishing '
                  'scanner instead — it runs the same detection engine.',
              availableOn: ['Android', 'iOS', 'macOS'],
            ),
    ),

    // Malware scanner. Needs an installed-software inventory, which iOS's
    // sandbox does not expose to any app.
    GoRoute(
      path: '/malware',
      builder: (_, __) => AppPlatform.canEnumerateInstalledApps
          ? const MalwareScreen()
          : const UnsupportedModuleScreen(
              moduleName: 'App Scanner',
              icon: Icons.bug_report_rounded,
              reason: 'iOS does not let one app see what else is installed, '
                  'so there is no inventory to scan. Apple reviews every app '
                  'on the App Store before it ships, which covers much of the '
                  'same ground.',
              availableOn: ['Android', 'Windows', 'macOS', 'Linux'],
            ),
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

    // Screenshot AI scanner (Feature 3). Depends on ML Kit, which Google
    // builds for Android and iOS only.
    GoRoute(
      path: '/screenshot',
      builder: (_, __) => AppPlatform.canRunOcr
          ? const ScreenshotScannerScreen()
          : const UnsupportedModuleScreen(
              moduleName: 'Screenshot Scanner',
              icon: Icons.image_search_rounded,
              reason: 'Reading text out of an image needs on-device OCR, and '
                  'the engine this uses ships for phones only. Sending your '
                  'screenshots to a cloud OCR service instead would defeat the '
                  'point of an offline scanner.',
              availableOn: ['Android', 'iOS'],
            ),
    ),

    // Settings
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],

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
