import 'package:uuid/uuid.dart';

import '../../core/config/api_keys.dart';
import '../../core/utils/url_extractor.dart';
import '../models/alert_model.dart';
import '../models/scan_result_model.dart';
import '../services/hive_service.dart';
import '../services/interceptor_prefs.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../services/threat_intel/local_ml_source.dart';
import '../services/threat_intel/mock_reputation_source.dart';
import '../services/threat_intel/override_log_service.dart';
import '../services/threat_intel/risk_engine.dart';
import '../services/threat_intel/safe_browsing_source.dart';
import '../services/threat_intel/threat_cache.dart';
import '../services/threat_intel/threat_fusion_service.dart';
import '../services/threat_intel/threat_intel_source.dart';

/// Orchestrates the Smart Link Interceptor pipeline:
///
///   intercept → assemble sources → fusion → risk decision → (opt-in) persist
///
/// All external sources are gated behind the user's cloud-intel opt-in, so by
/// default the entire pipeline runs on-device. URLs are persisted **only**
/// when the user has explicitly enabled link history.
class LinkInterceptorRepository {
  static const _uuid = Uuid();

  final ThreatFusionService _fusion;
  final RiskEngine _risk;
  final ReportService _reports;
  final ThreatCache _cache;
  final OverrideLogService _overrideLog;

  LinkInterceptorRepository({
    ThreatFusionService? fusion,
    RiskEngine? risk,
    ReportService? reports,
    ThreatCache? cache,
    OverrideLogService? overrideLog,
  })  : _fusion = fusion ?? const ThreatFusionService(),
        _risk = risk ?? const RiskEngine(),
        _reports = reports ?? ReportService(),
        _cache = cache ?? const ThreatCache(),
        _overrideLog = overrideLog ?? const OverrideLogService();

  /// Build the active source list. The on-device model is always present;
  /// the (mock) external reputation sources only run when the user opts in.
  List<ThreatIntelSource> buildSources() {
    return [
      LocalMlSource(),
      // Live Google Safe Browsing (gated by API key + cloud-intel opt-in).
      SafeBrowsingSource(),
      // VirusTotal stays mocked until its API key is configured.
      MockReputationSource(
        name: 'VirusTotal',
        trustWeight: TrustWeights.virusTotal,
        enabledResolver: () =>
            InterceptorPrefs.cloudIntelEnabled && ApiKeys.virusTotal.isNotEmpty,
      ),
    ];
  }

  /// Run fusion for [url] with a TTL cache in front. A fresh cached result
  /// short-circuits external lookups; otherwise we query all enabled sources
  /// and store the result. Offline fallback is automatic — network sources
  /// that can't reach their API return `unavailable` and are excluded, so the
  /// on-device model always yields a verdict.
  Future<FusionResult> fusionFor(String url) async {
    final normalized = UrlExtractor.normalize(url);
    final cached = _cache.get(normalized);
    if (cached != null) return cached;
    final fusion = await _fusion.analyze(normalized, buildSources());
    await _cache.put(normalized, fusion);
    // Feature 2: record disagreements / trusted overrides for the audit log.
    await _overrideLog.maybeLog(
        normalized, UrlExtractor.getDomain(normalized), fusion);
    return fusion;
  }

  /// Analyze a single intercepted [url]. [sourceApp] is the originating app
  /// label (e.g. "WhatsApp", "Browser", "QR scan") for attribution.
  Future<LinkRisk> analyze(String url, {String? sourceApp}) async {
    final domain = UrlExtractor.getDomain(UrlExtractor.normalize(url));
    final fusion = await fusionFor(url);
    final risk = _risk.build(
      url: url,
      domain: domain,
      sourceApp: sourceApp,
      fusion: fusion,
    );

    await _persistIfEnabled(risk);
    await _notifyIfMalicious(risk);
    return risk;
  }

  /// Manual fusion scan (Feature 4) — used by the Threat Scan screen. Persists
  /// to history if enabled, but doesn't fire interceptor notifications.
  Future<LinkRisk> scanUrl(String url) async {
    final domain = UrlExtractor.getDomain(UrlExtractor.normalize(url));
    final fusion = await fusionFor(url);
    final risk = _risk.build(
      url: url,
      domain: domain,
      sourceApp: null,
      fusion: fusion,
    );
    await _persistIfEnabled(risk);
    return risk;
  }

  /// Persist the verdict to scan history — only when the user enabled link
  /// history. Reuses the existing `scan_results` box (type `link_intercept`)
  /// so it shows up in history without a new Hive adapter.
  Future<void> _persistIfEnabled(LinkRisk risk) async {
    if (!InterceptorPrefs.linkHistoryEnabled) return;
    await HiveService.saveScanResult(
      ScanResultModel(
        id: _uuid.v4(),
        type: 'link_intercept',
        input: risk.url,
        verdict: risk.level.label.toLowerCase(),
        confidence: risk.riskScore,
        shapReasons: risk.reasons.take(5).toList(),
        timestamp: risk.timestamp,
      ),
    );
  }

  /// Fire an alert + notification for warn/block verdicts so the event is
  /// visible in the Alerts feed even if the user dismissed the screen.
  Future<void> _notifyIfMalicious(LinkRisk risk) async {
    if (!risk.shouldWarn) return;
    await HiveService.saveAlert(
      AlertModel(
        id: _uuid.v4(),
        type: risk.action == LinkAction.block ? 'critical' : 'warning',
        title: risk.action == LinkAction.block
            ? 'Dangerous link blocked'
            : 'Suspicious link warning',
        description:
            '${risk.riskScore}% risk · ${risk.domain ?? risk.url}'
            '${risk.sourceApp != null ? ' (from ${risk.sourceApp})' : ''}',
        module: 'interceptor',
        timestamp: risk.timestamp,
      ),
    );
    if (risk.action == LinkAction.block) {
      await NotificationService.showCriticalThreat(
        title: 'Dangerous link blocked',
        body: '${risk.domain ?? risk.url} scored ${risk.riskScore}% risk.',
        id: 20,
      );
    } else {
      await NotificationService.showWarning(
        title: 'Suspicious link',
        body: '${risk.domain ?? risk.url} scored ${risk.riskScore}% risk.',
        id: 21,
      );
    }
  }

  /// One-tap report — queues the link locally (and, in future, to a backend).
  Future<void> reportLink(LinkRisk risk, {String? userNote}) {
    return _reports.report(
      LinkReport(
        url: risk.url,
        riskScore: risk.riskScore,
        verdict: risk.level.label,
        sourceApp: risk.sourceApp,
        userNote: userNote,
        timestamp: DateTime.now(),
      ),
    );
  }
}
