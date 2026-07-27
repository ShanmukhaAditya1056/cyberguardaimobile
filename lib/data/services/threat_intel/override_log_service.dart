import 'dart:convert';

import '../hive_service.dart';
import 'threat_fusion_service.dart';

/// One recorded arbitration decision where sources disagreed and/or a trusted
/// source overrode the local verdict (Feature 2 — Override Logging +
/// Explainable Decision Reports).
class OverrideLogEntry {
  final String url;
  final String? domain;
  final int finalScore;
  final String finalLevel;
  final bool overrideApplied;
  final String? overrideReason;
  final bool hasConflict;

  /// "Source: Level" lines, for the explainable report.
  final List<String> sourceSummary;
  final DateTime timestamp;

  const OverrideLogEntry({
    required this.url,
    required this.domain,
    required this.finalScore,
    required this.finalLevel,
    required this.overrideApplied,
    required this.overrideReason,
    required this.hasConflict,
    required this.sourceSummary,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'domain': domain,
        'finalScore': finalScore,
        'finalLevel': finalLevel,
        'overrideApplied': overrideApplied,
        'overrideReason': overrideReason,
        'hasConflict': hasConflict,
        'sourceSummary': sourceSummary,
        'timestamp': timestamp.toIso8601String(),
      };

  factory OverrideLogEntry.fromJson(Map<String, dynamic> j) => OverrideLogEntry(
        url: j['url'] as String,
        domain: j['domain'] as String?,
        finalScore: (j['finalScore'] as num).toInt(),
        finalLevel: j['finalLevel'] as String,
        overrideApplied: j['overrideApplied'] as bool? ?? false,
        overrideReason: j['overrideReason'] as String?,
        hasConflict: j['hasConflict'] as bool? ?? false,
        sourceSummary:
            (j['sourceSummary'] as List).map((e) => e.toString()).toList(),
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

/// Persists arbitration overrides/conflicts to the prefs box (JSON, capped).
class OverrideLogService {
  static const _key = 'arbitration_log';
  static const int _maxEntries = 100;

  const OverrideLogService();

  /// Record [fusion] for [url] if (and only if) it represents a disagreement
  /// or an override worth surfacing. No-op for unanimous verdicts.
  Future<void> maybeLog(String url, String? domain, FusionResult fusion) async {
    if (!fusion.overrideApplied && !fusion.hasConflict) return;
    final entry = OverrideLogEntry(
      url: url,
      domain: domain,
      finalScore: fusion.unifiedScore,
      // Store the enum name (not a label) so the UI localizes it on display.
      finalLevel: fusion.level.name,
      overrideApplied: fusion.overrideApplied,
      overrideReason: fusion.overrideReason,
      hasConflict: fusion.hasConflict,
      sourceSummary: fusion.verdicts
          .map((v) => '${v.sourceName}: ${v.level.label} (${v.maliciousScore})')
          .toList(),
      timestamp: DateTime.now(),
    );
    final all = all0()..add(entry);
    final trimmed = all.length > _maxEntries
        ? all.sublist(all.length - _maxEntries)
        : all;
    await HiveService.setPref(
        _key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  /// All logged entries, newest first.
  static List<OverrideLogEntry> all() =>
      all0().reversed.toList();

  static List<OverrideLogEntry> all0() {
    final raw = HiveService.getPref(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) =>
              OverrideLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() => HiveService.setPref(_key, '');
}
