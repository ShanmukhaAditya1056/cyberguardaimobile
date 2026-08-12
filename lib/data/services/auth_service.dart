import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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

  /// Registers, then sends a verification link to the address given.
  ///
  /// The link is fire-and-forget: the account exists either way, and the app
  /// stays usable while it is unverified. Blocking every feature behind a
  /// click in an inbox would strand anyone whose mail is slow or filtered, on
  /// an app whose scanners work perfectly well without an account at all.
  /// [isEmailVerified] is what a caller checks when it wants the stronger
  /// guarantee.
  ///
  /// Google sign-in deliberately gets no equivalent. Google has already
  /// verified the address before it hands over a credential, so a second
  /// confirmation would ask someone to prove what the provider just proved.
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
      try {
        await cred.user?.sendEmailVerification();
      } catch (_) {
        // Quota exceeded, or offline. The account is already created, so
        // failing the whole registration here would be worse than letting
        // them ask for the link again from the banner.
      }
      return AuthResult.success(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failed(_mapCode(e.code));
    } catch (_) {
      return const AuthResult.failed(AuthFailure.unknown);
    }
  }

  /// Whether the signed-in account has confirmed its address.
  ///
  /// True for Google accounts without any extra step, since Google verifies
  /// before issuing the credential.
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// True only for an account that signed in with a password and has not yet
  /// clicked its link — the one case where the verification banner belongs.
  static bool get needsEmailVerification =>
      _configured && currentUser != null && !isEmailVerified;

  /// Re-sends the verification link. Returns false when the send failed, so
  /// the UI can say so rather than claiming an email is on its way.
  static Future<bool> resendEmailVerification() async {
    if (!_configured) return false;
    try {
      await currentUser?.sendEmailVerification();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Re-reads the account from Firebase and reports whether it is now
  /// verified.
  ///
  /// `emailVerified` is baked into the cached ID token, so it stays false
  /// locally after the user clicks the link until the token is refreshed.
  /// Without this reload the banner would never go away on its own.
  static Future<bool> refreshEmailVerified() async {
    if (!_configured) return false;
    try {
      await currentUser?.reload();
      return isEmailVerified;
    } catch (_) {
      return false;
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

/// Bridges [AuthService.authStateChanges] to GoRouter's `refreshListenable`,
/// so the route guard re-runs the moment a session starts or ends. Without it
/// signing out would leave the user sitting on a protected screen until they
/// happened to navigate.
class AuthStateNotifier extends ChangeNotifier {
  StreamSubscription<User?>? _sub;

  AuthStateNotifier() {
    _sub = AuthService.authStateChanges.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
