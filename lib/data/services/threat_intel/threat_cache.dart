import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../hive_service.dart';
import 'threat_fusion_service.dart';

/// A small TTL cache of fused verdicts, keyed by a SHA-1 of the URL.
///
/// Purpose (Feature 4): avoid re-querying external sources for a URL that was
/// just analyzed — saves rate-limited API calls and gives an instant offline
/// answer for recently-seen links. Stored in the lightweight `prefsBox` as
/// JSON (no Hive schema migration), capped and self-pruning.
class ThreatCache {
  static const _key = 'threat_fusion_cache';
  static const Duration _ttl = Duration(hours: 6);
  static const int _maxEntries = 100;

  const ThreatCache();

  String _hash(String url) => sha1.convert(utf8.encode(url.trim())).toString();

  Map<String, dynamic> _readAll() {
    final raw = HiveService.getPref(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// Fresh cached fusion for [url], or null on miss/expiry.
  FusionResult? get(String url) {
    final all = _readAll();
    final entry = all[_hash(url)];
    if (entry is! Map) return null;
    final ts = (entry['ts'] as num?)?.toInt() ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > _ttl.inMilliseconds) return null;
    try {
      return FusionResult.fromJson(
          Map<String, dynamic>.from(entry['f'] as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> put(String url, FusionResult result) async {
    final all = _readAll();
    all[_hash(url)] = {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'f': result.toJson(),
    };

    // Prune expired + cap to the newest [_maxEntries].
    final now = DateTime.now().millisecondsSinceEpoch;
    final entries = all.entries
        .where((e) =>
            e.value is Map &&
            now - ((e.value as Map)['ts'] as num? ?? 0).toInt() <=
                _ttl.inMilliseconds)
        .toList()
      ..sort((a, b) => ((b.value as Map)['ts'] as num)
          .compareTo((a.value as Map)['ts'] as num));
    final capped = entries.take(_maxEntries);

    await HiveService.setPref(
      _key,
      jsonEncode({for (final e in capped) e.key: e.value}),
    );
  }

  Future<void> clear() => HiveService.setPref(_key, '');
}
