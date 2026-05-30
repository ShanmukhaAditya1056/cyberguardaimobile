import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtils {
  HashUtils._();

  /// Compute SHA-1 hash of input string, returns uppercase hex string
  static String sha1Hash(String input) {
    final bytes = utf8.encode(input.trim().toLowerCase());
    final digest = sha1.convert(bytes);
    return digest.toString().toUpperCase();
  }

  /// Get first 5 chars of SHA-1 hash (k-Anonymity prefix)
  static String hibpPrefix(String input) {
    return sha1Hash(input).substring(0, 5);
  }

  /// Get remainder after prefix (k-Anonymity suffix for local comparison)
  static String hibpSuffix(String input) {
    return sha1Hash(input).substring(5);
  }

  /// Parse HIBP range API response
  /// Response format: "SUFFIX:COUNT\r\n..."
  static int parseHibpResponse(String response, String suffix) {
    final lines = response.split('\n');
    for (final line in lines) {
      final parts = line.trim().split(':');
      if (parts.length == 2) {
        final responseSuffix = parts[0].trim().toUpperCase();
        if (responseSuffix == suffix.toUpperCase()) {
          return int.tryParse(parts[1].trim()) ?? 0;
        }
      }
    }
    return 0;
  }

  /// Mask email for display privacy (e.g. t***@gmail.com)
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***.***';
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}***@$domain';
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}@$domain';
  }

  /// Mask phone for display privacy
  static String maskPhone(String phone) {
    if (phone.length < 6) return '***';
    return '${phone.substring(0, 2)}****${phone.substring(phone.length - 2)}';
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  /// Validate phone format (Indian +91 or 10 digit)
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final regex = RegExp(r'^(?:\+91|91)?[6-9]\d{9}$');
    return regex.hasMatch(cleaned);
  }
}
