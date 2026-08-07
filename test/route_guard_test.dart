import 'package:cyberguard_ai/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sign-in is mandatory, and the gate that enforces it lives in exactly one
/// place — [resolveRoute]. It is the only thing standing between an
/// unauthenticated user and every screen in the app, so it gets pinned here
/// rather than trusted.
///
/// The awkward case is a build with no Firebase credentials: signing in is
/// then impossible, so enforcing the gate would brick the app permanently
/// (including CI). The guard must stand down there and nowhere else.

const _protected = [
  '/dashboard',
  '/phishing',
  '/malware',
  '/breach',
  '/wifi',
  '/alerts',
  '/settings',
  '/fusion',
  '/risk',
  '/screenshot',
  '/intercept',
  '/arbitration',
  '/malware/detail',
  '/phishing/qr',
];

void main() {
  group('onboarding comes first', () {
    test('an un-onboarded user is pushed to onboarding from anywhere', () {
      for (final path in [..._protected, '/login']) {
        expect(
          resolveRoute(
            path: path,
            onboardingComplete: false,
            authConfigured: true,
            signedIn: false,
          ),
          '/onboarding',
          reason: '$path should route to onboarding on first launch',
        );
      }
    });

    test('onboarding itself is not redirected in a loop', () {
      expect(
        resolveRoute(
          path: '/onboarding',
          onboardingComplete: false,
          authConfigured: true,
          signedIn: false,
        ),
        isNull,
      );
    });

    test('splash is never bounced', () {
      expect(
        resolveRoute(
          path: '/',
          onboardingComplete: false,
          authConfigured: true,
          signedIn: false,
        ),
        isNull,
      );
    });
  });

  group('sign-in is mandatory', () {
    test('every protected route redirects to /login when signed out', () {
      for (final path in _protected) {
        expect(
          resolveRoute(
            path: path,
            onboardingComplete: true,
            authConfigured: true,
            signedIn: false,
          ),
          '/login',
          reason: '$path must not be reachable without a session',
        );
      }
    });

    test('/login is reachable while signed out', () {
      expect(
        resolveRoute(
          path: '/login',
          onboardingComplete: true,
          authConfigured: true,
          signedIn: false,
        ),
        isNull,
      );
    });

    test('a signed-in user passes through to protected routes', () {
      for (final path in _protected) {
        expect(
          resolveRoute(
            path: path,
            onboardingComplete: true,
            authConfigured: true,
            signedIn: true,
          ),
          isNull,
          reason: '$path should be allowed once signed in',
        );
      }
    });

    test('a signed-in user is not stranded on /login', () {
      expect(
        resolveRoute(
          path: '/login',
          onboardingComplete: true,
          authConfigured: true,
          signedIn: true,
        ),
        '/dashboard',
      );
    });
  });

  group('unconfigured builds are not bricked', () {
    // Without google-services.json there is no way to sign in at all, so
    // enforcing the gate would lock the user out of the whole app forever.
    test('every route is allowed when auth cannot work', () {
      for (final path in [..._protected, '/login', '/onboarding']) {
        expect(
          resolveRoute(
            path: path,
            onboardingComplete: true,
            authConfigured: false,
            signedIn: false,
          ),
          isNull,
          reason: '$path must stay reachable when auth is unconfigured',
        );
      }
    });

    test('onboarding still runs first even when auth is unconfigured', () {
      expect(
        resolveRoute(
          path: '/dashboard',
          onboardingComplete: false,
          authConfigured: false,
          signedIn: false,
        ),
        '/onboarding',
      );
    });
  });

  group('the gate is closed by default', () {
    test('an unknown/deep-linked path is protected, not allowed through', () {
      // Anything not explicitly public requires a session — a new screen
      // added later is guarded automatically rather than by remembering to.
      expect(
        resolveRoute(
          path: '/some/future/screen',
          onboardingComplete: true,
          authConfigured: true,
          signedIn: false,
        ),
        '/login',
      );
    });
  });
}
