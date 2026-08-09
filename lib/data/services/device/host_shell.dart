import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Result of one host command.
class ShellResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const ShellResult(this.exitCode, this.stdout, this.stderr);

  bool get ok => exitCode == 0;

  /// stdout split into non-empty trimmed lines.
  List<String> get lines => stdout
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

/// Runs the read-only OS tools the desktop probes depend on.
///
/// Every desktop capability in this app is implemented by asking a tool the OS
/// already ships rather than by writing a native plugin per platform, so this
/// wrapper is the single place where that trust boundary lives. Three rules
/// hold everywhere it is used:
///
///  * arguments are passed as a list and `runInShell` stays false, so nothing
///    the user types can ever be re-parsed as shell syntax;
///  * every call is bounded by a timeout, because a hung `netsh` or a
///    `system_profiler` waiting on a stalled service must not freeze a scan;
///  * a missing binary is a normal outcome (no `nmcli` on a headless box), not
///    an error to propagate — it comes back as a non-zero [ShellResult].
class HostShell {
  HostShell._();

  static const defaultTimeout = Duration(seconds: 8);

  static Future<ShellResult> run(
    String executable,
    List<String> arguments, {
    Duration timeout = defaultTimeout,
  }) async {
    try {
      final process = await Process.start(
        executable,
        arguments,
        runInShell: false,
      );

      // Drain both pipes concurrently. Reading them in sequence deadlocks as
      // soon as a command writes more than the OS pipe buffer to the stream we
      // are not currently reading — `Get-AppxPackage` on a busy machine does.
      final stdoutFuture =
          process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();
      final stderrFuture =
          process.stderr.transform(const Utf8Decoder(allowMalformed: true)).join();

      final code = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      return ShellResult(code, await stdoutFuture, await stderrFuture);
    } on ProcessException catch (e) {
      // Binary not installed or not on PATH.
      return ShellResult(-1, '', e.message);
    } catch (e) {
      return ShellResult(-1, '', '$e');
    }
  }

  /// Runs a PowerShell script and decodes its JSON output.
  ///
  /// `-NoProfile` keeps a user's profile from injecting output ahead of the
  /// JSON, and `ConvertTo-Json` is always given `-Compress` plus an explicit
  /// depth because its default depth of 2 silently truncates nested objects.
  ///
  /// Returns an empty list when the command fails or emits nothing parseable.
  static Future<List<Map<String, dynamic>>> powershellJson(
    String script, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final result = await run(
      'powershell',
      ['-NoProfile', '-NonInteractive', '-Command', script],
      timeout: timeout,
    );
    if (result.stdout.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(result.stdout.trim());
      if (decoded is List) {
        return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
      // ConvertTo-Json emits a bare object, not a one-element array, when the
      // pipeline produced exactly one item.
      if (decoded is Map) return [Map<String, dynamic>.from(decoded)];
      return const [];
    } on FormatException {
      return const [];
    }
  }

  /// True if [executable] resolves on PATH.
  static Future<bool> exists(String executable) async {
    final probe = Platform.isWindows ? 'where' : 'which';
    final result = await run(probe, [executable],
        timeout: const Duration(seconds: 3));
    return result.ok && result.stdout.trim().isNotEmpty;
  }
}
