import 'dart:convert';

import 'hive_service.dart';

/// A user-submitted report about an intercepted link (Feature 1 — "One-Tap
/// Report"). Stored locally; a future backend can drain the local queue.
class LinkReport {
  final String url;
  final int riskScore;
  final String verdict;
  final String? sourceApp;
  final String? userNote;
  final DateTime timestamp;

  const LinkReport({
    required this.url,
    required this.riskScore,
    required this.verdict,
    required this.sourceApp,
    required this.userNote,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'riskScore': riskScore,
        'verdict': verdict,
        'sourceApp': sourceApp,
        'userNote': userNote,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LinkReport.fromJson(Map<String, dynamic> j) => LinkReport(
        url: j['url'] as String,
        riskScore: (j['riskScore'] as num).toInt(),
        verdict: j['verdict'] as String,
        sourceApp: j['sourceApp'] as String?,
        userNote: j['userNote'] as String?,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

/// Contract for shipping reports somewhere. Swap [LocalReportSink] for an
/// `HttpReportSink` once a backend exists — callers don't change.
abstract class ReportSink {
  Future<void> submit(LinkReport report);
}

/// Default sink: append to a local JSON queue in the prefs box. Fully
/// offline, privacy-preserving (the user explicitly chose to report).
class LocalReportSink implements ReportSink {
  static const _key = 'link_reports';

  @override
  Future<void> submit(LinkReport report) async {
    final reports = ReportService.all()..add(report);
    // Cap the queue so it can't grow unbounded.
    final trimmed =
        reports.length > 200 ? reports.sublist(reports.length - 200) : reports;
    await HiveService.setPref(
      _key,
      jsonEncode(trimmed.map((r) => r.toJson()).toList()),
    );
  }
}

/// Thin façade over the configured [ReportSink].
class ReportService {
  static const _key = 'link_reports';
  final ReportSink _sink;

  ReportService([ReportSink? sink]) : _sink = sink ?? LocalReportSink();

  Future<void> report(LinkReport report) => _sink.submit(report);

  /// All locally-queued reports (newest last).
  static List<LinkReport> all() {
    final raw = HiveService.getPref(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => LinkReport.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
