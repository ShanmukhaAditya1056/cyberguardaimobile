import 'package:cyberguard_ai/data/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// google-services.json is not in the repository, so this — no Firebase
/// project at all — is the configuration a clean checkout and CI actually
/// build and run. The contract that matters is that every entry point fails
/// *politely* instead of throwing: the app is a fully on-device security tool
/// and must stay completely usable with auth unavailable.
///
/// Firebase.initializeApp() has no platform binding under flutter_test, so it
/// throws and AuthService.init() swallows it, leaving isConfigured false. That
/// is exactly the unconfigured path, which makes it testable here.

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AuthService.init();
  });

  group('with no Firebase configuration', () {
    test('init() completes without throwing and reports unconfigured', () {
      expect(AuthService.isConfigured, isFalse);
    });

    test('init() is idempotent', () async {
      await AuthService.init();
      await AuthService.init();
      expect(AuthService.isConfigured, isFalse);
    });

    test('there is no signed-in user', () {
      expect(AuthService.currentUser, isNull);
      expect(AuthService.isSignedIn, isFalse);
    });

    test('authStateChanges is an empty stream, not an error', () {
      expect(AuthService.authStateChanges, emitsDone);
    });

    test('email sign-in fails as notConfigured', () async {
      final r = await AuthService.signInWithEmail('a@b.com', 'password');
      expect(r.ok, isFalse);
      expect(r.failure, AuthFailure.notConfigured);
      expect(r.user, isNull);
    });

    test('registration fails as notConfigured', () async {
      final r = await AuthService.registerWithEmail('a@b.com', 'password');
      expect(r.ok, isFalse);
      expect(r.failure, AuthFailure.notConfigured);
    });

    test('Google sign-in fails as notConfigured rather than throwing', () async {
      final r = await AuthService.signInWithGoogle();
      expect(r.ok, isFalse);
      expect(r.failure, AuthFailure.notConfigured);
    });

    test('password reset is a silent no-op', () async {
      await expectLater(
          AuthService.sendPasswordReset('a@b.com'), completes);
    });

    test('signOut is a silent no-op', () async {
      await expectLater(AuthService.signOut(), completes);
    });
  });

  group('AuthResult', () {
    test('success carries no failure', () {
      const r = AuthResult.success(null);
      expect(r.ok, isTrue);
      expect(r.failure, isNull);
    });

    test('failure is not ok', () {
      const r = AuthResult.failed(AuthFailure.wrongPassword);
      expect(r.ok, isFalse);
      expect(r.user, isNull);
      expect(r.failure, AuthFailure.wrongPassword);
    });

    test('cancelled is modelled as a failure the UI can silence', () {
      // The login screen maps this to an empty message: dismissing the Google
      // account chooser must not look like an error.
      const r = AuthResult.failed(AuthFailure.cancelled);
      expect(r.ok, isFalse);
      expect(r.failure, AuthFailure.cancelled);
    });
  });
}
