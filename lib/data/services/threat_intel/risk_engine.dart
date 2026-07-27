import 'threat_fusion_service.dart';
import 'threat_intel_source.dart';

/// The action the interceptor takes on an intercepted URL.
enum LinkAction {
  allow, // open silently
  warn, // show the warning screen, default to "Go Back"
  block; // show the warning screen, "Continue Anyway" requires a hold-to-confirm

  String get label => switch (this) {
        LinkAction.allow => 'Allow',
        LinkAction.warn => 'Warn',
        LinkAction.block => 'Block',
      };
}

/// The full risk decision for one intercepted link — what the warning screen
/// renders and what the repository persists (if history is enabled).
class LinkRisk {
  final String url;
  final String? domain;
  final String? sourceApp; // e.g. "WhatsApp", "Browser", "QR scan"
  final FusionResult fusion;
  final LinkAction action;
  final DateTime timestamp;

  const LinkRisk({
    required this.url,
    required this.domain,
    required this.sourceApp,
    required this.fusion,
    required this.action,
    required this.timestamp,
  });

  int get riskScore => fusion.unifiedScore;
  ThreatLevel get level => fusion.level;
  List<String> get reasons => fusion.explanation;
  bool get shouldWarn => action != LinkAction.allow;
}

/// Maps a [FusionResult] onto a concrete [LinkAction] using the spec's
/// score bands, with a hard safety rail: a trusted-override result is always
/// at least a warning, never silently allowed.
class RiskEngine {
  const RiskEngine();

  LinkAction decide(FusionResult fusion) {
    if (fusion.overrideApplied) {
      // Critical override ⇒ block, otherwise warn.
      return fusion.level == ThreatLevel.critical
          ? LinkAction.block
          : LinkAction.warn;
    }
    return switch (fusion.level) {
      ThreatLevel.safe => LinkAction.allow,
      ThreatLevel.suspicious => LinkAction.warn,
      ThreatLevel.dangerous => LinkAction.warn,
      ThreatLevel.critical => LinkAction.block,
    };
  }

  LinkRisk build({
    required String url,
    required String? domain,
    required String? sourceApp,
    required FusionResult fusion,
  }) {
    return LinkRisk(
      url: url,
      domain: domain,
      sourceApp: sourceApp,
      fusion: fusion,
      action: decide(fusion),
      timestamp: DateTime.now(),
    );
  }
}
