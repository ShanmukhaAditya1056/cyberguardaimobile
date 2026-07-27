import 'dart:convert';

import '../services/hive_service.dart';
import '../services/predictive_risk_service.dart';

/// A single point on the personal-risk timeline.
class RiskPoint {
  final DateTime date;
  final int score;
  const RiskPoint(this.date, this.score);
}

/// Feature 5 — gathers on-device signals, runs [PredictiveRiskService], and
/// maintains a daily risk timeline in the prefs box. Fully local.
class PredictiveRiskRepository {
  static const _timelineKey = 'risk_timeline';
  static const int _windowDays = 7;

  final PredictiveRiskService _service;
  PredictiveRiskRepository([PredictiveRiskService? service])
      : _service = service ?? const PredictiveRiskService();

  /// Build [RiskSignals] from local history over the recent window.
  RiskSignals collectSignals() {
    final cutoff = DateTime.now().subtract(const Duration(days: _windowDays));

    final phishingHits = HiveService.getScanResults(type: 'phishing')
        .where((r) => r.timestamp.isAfter(cutoff) && r.isThreat)
        .length;

    final interceptorBlocks = HiveService.getScanResults(type: 'link_intercept')
        .where((r) =>
            r.timestamp.isAfter(cutoff) &&
            (r.verdict == 'dangerous' || r.verdict == 'critical'))
        .length;

    final suspiciousSms = HiveService.getAlerts()
        .where((a) => a.timestamp.isAfter(cutoff) && a.module == 'phishing')
        .length;

    final unknownWifi = HiveService.getWifiScans()
        .where((w) => w.timestamp.isAfter(cutoff) && w.trustScore < 60)
        .length;

    final malwareDetections = HiveService.getAllAppScans()
        .where((a) =>
            a.riskLevel.toLowerCase() == 'high' ||
            a.riskLevel.toLowerCase() == 'critical')
        .length;

    final breachActive = HiveService.getSettings().hasActiveBreach;

    // Security-score trend over the window (negative = worsening).
    final history = HiveService.getScoreHistory(days: _windowDays);
    int delta = 0;
    if (history.length >= 2) {
      delta = history.last.unifiedScore - history.first.unifiedScore;
    }

    return RiskSignals(
      phishingHits: phishingHits,
      suspiciousSms: suspiciousSms,
      unknownWifi: unknownWifi,
      malwareDetections: malwareDetections,
      interceptorBlocks: interceptorBlocks,
      breachActive: breachActive,
      securityScoreDelta: delta,
    );
  }

  /// Run the assessment and persist today's snapshot to the timeline.
  Future<RiskAssessment> assess() async {
    final assessment = _service.assess(collectSignals());
    await _recordSnapshot(assessment.riskScore);
    return assessment;
  }

  Future<void> _recordSnapshot(int score) async {
    final map = _readTimeline();
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    map[key] = score;
    // Keep only the last 30 days.
    final entries = map.entries.toList()
      ..sort((a, b) => _parse(a.key).compareTo(_parse(b.key)));
    final capped = entries.length > 30
        ? entries.sublist(entries.length - 30)
        : entries;
    await HiveService.setPref(
        _timelineKey, jsonEncode({for (final e in capped) e.key: e.value}));
  }

  /// Risk timeline points over the recent window, oldest first.
  List<RiskPoint> timeline() {
    final map = _readTimeline();
    final points = map.entries
        .map((e) => RiskPoint(_parse(e.key), (e.value as num).toInt()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final cutoff = DateTime.now().subtract(const Duration(days: _windowDays));
    return points.where((p) => p.date.isAfter(cutoff)).toList();
  }

  Map<String, dynamic> _readTimeline() {
    final raw = HiveService.getPref(_timelineKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  DateTime _parse(String key) {
    final p = key.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }
}
