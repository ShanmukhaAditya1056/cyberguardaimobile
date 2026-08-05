import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Why a sign-in attempt failed, in terms the UI can act on.
enum AuthFailure {
  /// Firebase was never configured for this build — see [AuthService.init].
  notConfigured,
  invalidEmail,
  wrongPassword,
  userNotFound,
  emailInUse,
  weakPassword,
  networkError,
  cancelled,
  unknown,
}

class AuthResult {
  final User? user;
  final AuthFailure? failure;

  const AuthResult.success(this.user) : failure = null;
  const AuthResult.failed(this.failure) : user = null;

  bool get ok => failure == null;
}

/// Email/password and Google sign-in on top of Firebase Auth.
///
/// Firebase is **optional at build time**. `google-services.json` is not in the
/// repository (it carries project-specific keys), and the google-services
/// Gradle plugin is only applied when that file is present — see
/// android/app/build.gradle. So on a clean checkout the app compiles and runs
/// with no Firebase project at all, `Firebase.initializeApp()` throws, and
/// [isConfigured] stays false. Every call below then fails fast with
/// [AuthFailure.notConfigured] instead of throwing, and the login screen
/// explains what is missing rather than showing a broken form.
///
/// To enable it: create a Firebase project, register an Android app with the
/// `com.cyberguard.ai` package name and your signing SHA-1 (Google sign-in
/// will not work without the fingerprint), enable the Email/Password and
/// Google providers in the console, then drop google-services.json into
/// android/app/.
class AuthService {
  AuthService._();

  static bool _configured = false;
  static bool _initCalled = false;

  /// True once Firebase has actually initialised. Callers should branch on
  /// this rather than assuming auth works.
  static bool get isConfigured => _configured;

  /// Safe to call unconditionally from main(); never throws.
  static Future<void> init() async {
    if (_initCalled) return;
    _initCalled = true;
    try {
      await Firebase.initializeApp();
      _configured = true;
    } catch (_) {
      // No google-services.json, or a malformed one. Not fatal: the rest of
      // the app is fully functional offline, so auth simply stays unavailable.
      _configured = false;
    }
  }

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Fires on sign-in/sign-out. Empty when auth is unconfigured, so the
  /// router can listen unconditionally.
  static Stream<User?> get authStateChanges =>
      _configured ? _auth.authStateChanges() : const Stream<User?>.empty();

  static User? get currentUser => _configured ? _auth.currentUser : null;

  static bool get isSignedIn => currentUser != null;

  static Future<AuthResult> signInWithEmail(
    String email,
    String password,
  ) async {
    if (!_configured) return const AuthResult.failed(AuthFailure.notConfigured);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failed(_mapCode(e.code));
    } catch (_) {
      return const AuthResult.failed(AuthFailure.unknown);
    }
  }

  static Future<AuthResult> registerWithEmail(
    String email,
    String password,
  ) async {
    if (!_configured) return const AuthResult.failed(AuthFailure.notConfigured);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failed(_mapCode(e.code));
    } catch (_) {
      return const AuthResult.failed(AuthFailure.unknown);
    }
  }

  static Future<AuthResult> signInWithGoogle() async {
    if (!_configured) return const AuthResult.failed(AuthFailure.notConfigured);
    try {
      final account = await GoogleSignIn().signIn();
      // Null means the user dismissed the account chooser — not an error, and
      // it must not surface as one.
      if (account == null) {
        return const AuthResult.failed(AuthFailure.cancelled);
      }

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return AuthResult.success(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failed(_mapCode(e.code));
    } catch (_) {
      // Almost always a missing/mismatched SHA-1 fingerprint in the Firebase
      // console, which surfaces as an opaque PlatformException.
      return const AuthResult.failed(AuthFailure.unknown);
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    if (!_configured) return;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (_) {
      // Deliberately silent: reporting whether an address exists would let
      // anyone enumerate registered accounts.
    }
  }

  static Future<void> signOut() async {
    if (!_configured) return;
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Not signed in via Google, or Play Services unavailable.
    }
    await _auth.signOut();
  }

  static AuthFailure _mapCode(String code) => switch (code) {
        'invalid-email' => AuthFailure.invalidEmail,
        'wrong-password' || 'invalid-credential' => AuthFailure.wrongPassword,
        'user-not-found' => AuthFailure.userNotFound,
        'email-already-in-use' => AuthFailure.emailInUse,
        'weak-password' => AuthFailure.weakPassword,
        'network-request-failed' => AuthFailure.networkError,
        _ => AuthFailure.unknown,
      };
}
