import 'package:cyberguard_ai/data/models/scan_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// ScanResultModel.isThreat drives getThreatCount(), which is what the
/// dashboard's "Threats Found" tile shows. It used to match only 'phishing',
/// 'malicious', 'breached' and 'unsafe' — but no writer ever produces
/// 'malicious' or 'unsafe', while malware writes 'threats_found' and the link
/// interceptor writes lowercased ThreatLevel labels. Every malware detection
/// and every blocked link was therefore counted as clean.
///
/// The table below is the contract: it mirrors the `verdict:` argument at each
/// AlertModel/ScanResultModel call site in lib/data/repositories. If a new
/// scanner adds a verdict, add it here too.

ScanResultModel _result(String verdict) => ScanResultModel(
      id: 'x',
      type: 'phishing',
      input: 'https://example.com',
      verdict: verdict,
      confidence: 90,
      shapReasons: const [],
      timestamp: DateTime(2026, 1, 1),
    );

void main() {
  group('verdicts that must count as threats', () {
    const threats = <String, String>{
      'phishing': 'phishing_repository',
      'threats_found': 'malware_repository — regression: was counted clean',
      'breached': 'breach_repository',
      'dangerous': 'link_interceptor — ThreatLevel.dangerous',
      'critical': 'link_interceptor — ThreatLevel.critical',
      'malicious': 'legacy records',
      'unsafe': 'legacy records',
    };

    threats.forEach((verdict, source) {
      test('"$verdict" is a threat ($source)', () {
        expect(_result(verdict).isThreat, isTrue);
      });
    });

    test('matching is case-insensitive', () {
      expect(_result('Threats_Found').isThreat, isTrue);
      expect(_result('CRITICAL').isThreat, isTrue);
    });
  });

  group('verdicts that must NOT count as threats', () {
    const clean = <String, String>{
      'safe': 'phishing / breach / interceptor clean result',
      'clean': 'malware_repository clean result',
      // Mirrors ThreatLevel.isMalicious, which is dangerous||critical only.
      'suspicious': 'link_interceptor — below the malicious band',
      '': 'empty/unset verdict must never inflate the count',
    };

    clean.forEach((verdict, source) {
      test('"$verdict" is not a threat ($source)', () {
        expect(_result(verdict).isThreat, isFalse);
      });
    });

    test('an unrecognised verdict is not assumed hostile', () {
      expect(_result('something_new').isThreat, isFalse);
    });
  });
}
