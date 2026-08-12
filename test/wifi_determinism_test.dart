import 'package:cyberguard_ai/core/utils/score_calculator.dart';
import 'package:cyberguard_ai/data/repositories/wifi_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scanning one network twice must give one answer.
///
/// It did not. Two inputs to the score are live measurements that drift while
/// nothing about the network changes — RSSI wanders by several dBm second to
/// second, and DNS latency varies with whatever else is on the link. Both fed
/// the rules score and the Isolation Forest's feature vector directly, so
/// pressing Scan repeatedly on the same access point produced a different
/// number nearly every time, and the app looked like it was guessing.
///
/// The fix is to band them before scoring while still *displaying* the real
/// measurement. These pin the property that matters: within a band, the score
/// cannot move; across a band, it still can, because that is a real change.

void main() {
  group('RSSI banding', () {
    test('ordinary drift inside a band collapses to one value', () {
      // A phone sitting still on a desk reports this spread for one router.
      const drift = [-52, -54, -55, -58, -60];
      final banded = drift.map(WifiRepository.quantiseRssi).toSet();

      expect(banded, hasLength(1),
          reason: 'readings inside one band must score identically');
    });

    test('a genuine change of band still moves', () {
      expect(
        WifiRepository.quantiseRssi(-45),
        isNot(WifiRepository.quantiseRssi(-85)),
      );
    });

    test('is monotonic — a weaker signal never bands stronger', () {
      var previous = WifiRepository.quantiseRssi(-30);
      for (var rssi = -30; rssi >= -100; rssi--) {
        final current = WifiRepository.quantiseRssi(rssi);
        expect(current, lessThanOrEqualTo(previous));
        previous = current;
      }
    });
  });

  group('latency banding', () {
    test('readings either side of the old 200ms threshold agree', () {
      // This pair is the original bug in miniature: 195 passed the latency
      // check and 205 failed it, on one network, seconds apart.
      expect(
        WifiRepository.quantiseLatency(195),
        WifiRepository.quantiseLatency(205),
      );
    });

    test('normal jitter collapses to one value', () {
      const jitter = [58, 61, 70, 88, 95, 110];
      expect(jitter.map(WifiRepository.quantiseLatency).toSet(), hasLength(1));
    });

    test('a failed lookup stays distinct from a fast one', () {
      expect(WifiRepository.quantiseLatency(0), 0);
      expect(WifiRepository.quantiseLatency(0),
          isNot(WifiRepository.quantiseLatency(25)));
    });

    test('a genuinely slow network still bands worse', () {
      expect(
        WifiRepository.quantiseLatency(2000),
        greaterThan(WifiRepository.quantiseLatency(30)),
      );
    });
  });

  group('the resulting score', () {
    /// The rules half of the score, fed banded values as the repository does.
    int scoreFor({required int rssi, required bool encrypted}) =>
        ScoreCalculator.wifiTrustScore(
          isEncrypted: encrypted,
          dnsHealthy: true,
          bssidConsistent: true,
          rssi: WifiRepository.quantiseRssi(rssi),
          isPublic: !encrypted,
        );

    test('is identical across a realistic run of repeat scans', () {
      const readings = [-52, -55, -49, -58, -53, -51];
      final scores =
          readings.map((r) => scoreFor(rssi: r, encrypted: true)).toSet();

      expect(scores, hasLength(1),
          reason: 'six scans of one unchanged network, one score');
    });

    test('still separates a secured network from an open one', () {
      expect(
        scoreFor(rssi: -55, encrypted: true),
        greaterThan(scoreFor(rssi: -55, encrypted: false)),
      );
    });
  });
}
