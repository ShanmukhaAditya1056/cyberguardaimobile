// Validates android/app/google-services.json before you find out the hard way.
//
// The three failure modes below all produce the same symptom at runtime — an
// opaque PlatformException from signInWithGoogle(), or a silent fallback to
// "auth unavailable" — with nothing in the build output pointing at the cause:
//
//   * the package name in the file does not match applicationId
//   * no OAuth client of type 1 (Android), i.e. no SHA-1 was registered
//   * the file is truncated or not valid JSON
//
// Run: dart run tool/check_firebase_config.dart

import 'dart:convert';
import 'dart:io';

const _expectedPackage = 'com.cyberguard.ai';
const _configPath = 'android/app/google-services.json';

/// google-services.json client entries use numeric OAuth client types.
/// 1 = Android (requires a registered SHA-1), 3 = web/server.
const _oauthAndroid = 1;

void main() {
  exitCode = _check();
}

/// Returns the process exit code: 0 usable (or deliberately absent), 1 broken.
int _check() {
  final file = File(_configPath);

  if (!file.existsSync()) {
    stdout.writeln('google-services.json not found at $_configPath');
    stdout.writeln();
    stdout.writeln('That is a supported state: the app builds and runs with');
    stdout.writeln('auth disabled. See docs/AUTH_SETUP.md to enable it.');
    return 0;
  }

  Map<String, dynamic> config;
  try {
    config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    return _fail('$_configPath is not valid JSON: $e');
  }

  final clients = (config['client'] as List?) ?? const [];
  if (clients.isEmpty) {
    return _fail('No "client" entries — this file registers no app at all.');
  }

  Map<String, dynamic>? match;
  final seen = <String>[];
  for (final raw in clients) {
    final client = raw as Map<String, dynamic>;
    final pkg = (((client['client_info'] as Map?)?['android_client_info']
        as Map?)?['package_name']) as String?;
    if (pkg != null) seen.add(pkg);
    if (pkg == _expectedPackage) match = client;
  }

  if (match == null) {
    return _fail(
      'No client for "$_expectedPackage".\n'
      '  Found: ${seen.isEmpty ? "(none)" : seen.join(", ")}\n'
      '  Re-register the Android app in Firebase with that exact package name.',
    );
  }

  final oauth = (match['oauth_client'] as List?) ?? const [];
  final hasAndroidClient = oauth.any(
      (c) => (c as Map<String, dynamic>)['client_type'] == _oauthAndroid);

  final projectId =
      ((config['project_info'] as Map?)?['project_id']) as String? ?? '?';

  stdout.writeln('google-services.json looks usable.');
  stdout.writeln('  project      $projectId');
  stdout.writeln('  package      $_expectedPackage');
  stdout.writeln('  oauth client ${oauth.length} entr'
      '${oauth.length == 1 ? "y" : "ies"}');

  if (!hasAndroidClient) {
    stdout.writeln();
    stdout.writeln('WARNING: no OAuth client of type $_oauthAndroid (Android).');
    stdout.writeln('Email/password sign-in will work, but "Continue with');
    stdout.writeln('Google" will fail with an opaque PlatformException.');
    stdout.writeln('Add your signing SHA-1 in the Firebase console, then');
    stdout.writeln('download google-services.json again.');
    return 1;
  }

  stdout.writeln();
  stdout.writeln('Email/password and Google sign-in are both configured.');
  return 0;
}

int _fail(String message) {
  stderr.writeln('google-services.json is not usable.');
  stderr.writeln('  $message');
  return 1;
}
