import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/utils/hash_utils.dart';
import '../models/breach_model.dart';
import 'dart:convert';

class HibpService {
  static const _timeout = Duration(seconds: 15);

  /// k-Anonymity password breach check using HIBP Range API
  /// Returns count of times password appears in breaches (0 = not breached)
  Future<int> checkPassword(String password) async {
    final prefix = HashUtils.hibpPrefix(password);
    final suffix = HashUtils.hibpSuffix(password);

    final url = Uri.parse('${AppConstants.hibpPasswordBase}$prefix');
    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': AppConstants.hibpUserAgent,
          'Add-Padding': 'true',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return HashUtils.parseHibpResponse(response.body, suffix);
      }
      return 0;
    } catch (e) {
      throw Exception('HIBP API error: $e');
    }
  }

  /// Get breach details for an account email using HIBP v3 API
  /// Requires HIBP API key
  Future<List<BreachModel>> getBreachesForAccount(
      String email, String apiKey) async {
    if (apiKey.isEmpty) return [];

    final encodedEmail = Uri.encodeComponent(email);
    final url = Uri.parse(
        '${AppConstants.hibpBreachBase}$encodedEmail?truncateResponse=false');

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': AppConstants.hibpUserAgent,
          'hibp-api-key': apiKey,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((b) => BreachModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      } else if (response.statusCode == 404) {
        return []; // No breaches found
      } else if (response.statusCode == 401) {
        throw Exception('Invalid HIBP API key');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limited — please wait and try again');
      }
      return [];
    } catch (e) {
      if (e.toString().contains('HIBP') || e.toString().contains('API')) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  /// Get all breaches in HIBP database (for reference)
  Future<List<BreachModel>> getAllBreaches() async {
    const url = 'https://haveibeenpwned.com/api/v3/breaches';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': AppConstants.hibpUserAgent},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((b) => BreachModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
