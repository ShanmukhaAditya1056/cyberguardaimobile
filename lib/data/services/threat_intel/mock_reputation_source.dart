import '../../../core/utils/url_extractor.dart';
import 'threat_intel_source.dart';

/// A stand-in for a real external reputation API (Google Safe Browsing,
/// VirusTotal, OpenPhish, PhishTank …) until API keys are wired in.
///
/// IMPORTANT DESIGN POINTS:
///  * It implements the exact same [ThreatIntelSource] contract a real client
///    will, so swapping in `SafeBrowsingSource` later touches nothing else.
///  * [requiresNetwork] is true and [isEnabled] is driven by the user's
///    cloud-intel opt-in — so with the default privacy posture this source
///    never runs and nothing leaves the device.
///  * Verdicts are *deterministic* functions of the URL (no randomness) so
///    demos and tests are reproducible. A real client would hit the network
///    here — using Safe Browsing's hash-prefix API so the full URL is never
///    transmitted, mirroring the app's existing HIBP k-Anonymity approach.
class MockReputationSource implements ThreatIntelSource {
  @override
  final String name;
  @override
  final int trustWeight;

  /// Supplied by the orchestration layer from the user's opt-in flag.
  final bool Function() enabledResolver;

  /// A tiny bundled "known bad" list to make the mock behave like a feed.
  static const Set<String> _knownBadDomains = {
    'paytm-kyc-verify.xyz',
    'sbi-secure-login.top',
    'free-jio-recharge.tk',
    'hdfc-netbanking-update.click',
  };

  const MockReputationSource({
    required this.name,
    required this.trustWeight,
    required this.enabledResolver,
  });

  @override
  bool get requiresNetwork => true;

  @override
  bool get isEnabled => enabledResolver();

  @override
  Future<SourceVerdict> lookup(String url) async {
    // Simulate a small network round-trip without doing any real I/O.
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final domain = UrlExtractor.getDomain(UrlExtractor.normalize(url)) ?? '';

    if (_knownBadDomains.contains(domain)) {
      return SourceVerdict(
        sourceName: name,
        trustWeight: trustWeight,
        maliciousScore: 95,
        confidence: 0.95,
        reasons: ['Domain present on $name blocklist feed'],
        fromCache: true,
      );
    }

    // Deterministic heuristic stand-in: dangerous TLD + brand token ⇒ flag.
    const dangerousTlds = ['.xyz', '.tk', '.ml', '.ga', '.cf', '.top', '.click', '.loan'];
    const brands = ['paytm', 'phonepe', 'sbi', 'hdfc', 'icici', 'amazon', 'flipkart', 'jio'];
    final lower = url.toLowerCase();
    final badTld = dangerousTlds.any(domain.endsWith);
    final brandSpoof = brands.any(lower.contains);

    if (badTld && brandSpoof) {
      return SourceVerdict(
        sourceName: name,
        trustWeight: trustWeight,
        maliciousScore: 85,
        confidence: 0.8,
        reasons: ['Brand impersonation on suspicious TLD'],
      );
    }
    if (badTld) {
      return SourceVerdict(
        sourceName: name,
        trustWeight: trustWeight,
        maliciousScore: 55,
        confidence: 0.6,
        reasons: ['Domain uses a high-abuse TLD'],
      );
    }

    return SourceVerdict(
      sourceName: name,
      trustWeight: trustWeight,
      maliciousScore: 5,
      confidence: 0.7,
      reasons: ['No reputation hits'],
    );
  }
}
