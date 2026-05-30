import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../core/utils/score_calculator.dart';
import '../models/alert_model.dart';
import '../models/wifi_scan_model.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/platform_channel_service.dart';
import '../services/wifi_ml_service.dart';

// Single shared Isolation Forest instance, loaded lazily on first scan.
final _wifiMl = WifiMlService();

class WifiCheckResult {
  final String name;
  final bool passed;
  final String detail;
  final String icon;

  const WifiCheckResult({
    required this.name,
    required this.passed,
    required this.detail,
    required this.icon,
  });
}

class WifiAnalysisResult {
  final String ssid;
  final String bssid;
  final int rssi;
  final int trustScore;
  final String riskLevel;
  final List<WifiCheckResult> checks;
  final String ipAddress;
  final int frequency;
  final int linkSpeed;
  final bool isEncrypted;
  final bool dnsHealthy;
  final int latencyMs;
  final bool bssidChanged;

  const WifiAnalysisResult({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.trustScore,
    required this.riskLevel,
    required this.checks,
    required this.ipAddress,
    required this.frequency,
    required this.linkSpeed,
    required this.isEncrypted,
    required this.dnsHealthy,
    required this.latencyMs,
    required this.bssidChanged,
  });
}

class WifiRepository {
  static const _uuid = Uuid();
  final PlatformChannelService _platform;

  WifiRepository(this._platform);

  Future<WifiAnalysisResult> analyzeCurrentNetwork() async {
    // 1. Get real network data
    final wifiData = await _platform.getWifiDetails();
    final status = wifiData['status'] as String? ?? 'connected';
    if (status == 'wifi_off') {
      throw Exception('Wi-Fi is turned off. Enable Wi-Fi and try again.');
    }
    if (status == 'not_connected') {
      throw Exception(
          'You are not connected to any Wi-Fi network. Connect first, then scan.');
    }
    if (status == 'error') {
      throw Exception(
          (wifiData['message'] as String?) ?? 'Failed to read Wi-Fi state');
    }

    final ssid = wifiData['ssid'] as String? ?? 'Unknown';
    final bssid = wifiData['bssid'] as String? ?? '';
    final rssi = wifiData['rssi'] as int? ?? -100;
    final linkSpeed = wifiData['linkSpeed'] as int? ?? 0;
    final frequency = wifiData['frequency'] as int? ?? 0;
    final ipAddress = wifiData['ipAddress'] as String? ?? '0.0.0.0';
    final isSecured = wifiData['isSecured'] as bool? ?? true;
    final hasInternet = wifiData['hasInternet'] as bool? ?? false;

    // 2. DNS health check using real lookup
    final dnsResult = await _testDns();
    final dnsHealthy = dnsResult.healthy;
    final latencyMs = dnsResult.latencyMs;

    // 3. BSSID consistency check
    final storedBssid = HiveService.getStoredBssid(ssid);
    final bssidChanged = storedBssid != null &&
        storedBssid.isNotEmpty &&
        storedBssid != bssid &&
        bssid.isNotEmpty;

    // 4. Run all checks
    final checks = <WifiCheckResult>[
      WifiCheckResult(
        name: 'Encryption',
        passed: isSecured,
        detail: isSecured
            ? 'Network is encrypted (WPA2/WPA3)'
            : 'OPEN network — no encryption!',
        icon: isSecured ? 'lock' : 'lock_open',
      ),
      WifiCheckResult(
        name: 'Signal Quality',
        passed: rssi >= -80,
        detail: rssi >= -50
            ? 'Excellent signal ($rssi dBm)'
            : rssi >= -70
                ? 'Good signal ($rssi dBm)'
                : rssi >= -80
                    ? 'Fair signal ($rssi dBm)'
                    : 'Weak signal ($rssi dBm) — possibly monitored',
        icon: 'signal_wifi_4_bar',
      ),
      WifiCheckResult(
        name: 'DNS Health',
        passed: dnsHealthy,
        detail: dnsHealthy
            ? 'DNS resolution healthy (${latencyMs}ms)'
            : 'DNS lookup failed or extremely slow',
        icon: 'dns',
      ),
      WifiCheckResult(
        name: 'Internet Access',
        passed: hasInternet,
        detail:
            hasInternet ? 'Internet connection active' : 'No internet access',
        icon: 'public',
      ),
      WifiCheckResult(
        name: 'BSSID Consistency',
        passed: !bssidChanged,
        detail: bssidChanged
            ? 'BSSID changed! Possible Evil Twin attack'
            : storedBssid == null
                ? 'First time on this network — BSSID recorded'
                : 'BSSID matches previous connection',
        icon: 'router',
      ),
      WifiCheckResult(
        name: 'Latency',
        passed: latencyMs < 200,
        detail: latencyMs == 0
            ? 'Latency check failed'
            : latencyMs < 100
                ? 'Low latency (${latencyMs}ms)'
                : latencyMs < 200
                    ? 'Normal latency (${latencyMs}ms)'
                    : 'High latency (${latencyMs}ms) — suspicious',
        icon: 'speed',
      ),
    ];

    // 5. Calculate trust score from real data
    final baseScore = ScoreCalculator.wifiTrustScore(
      isEncrypted: isSecured,
      dnsHealthy: dnsHealthy,
      bssidConsistent: !bssidChanged,
      rssi: rssi,
      isPublic: !isSecured,
    );

    // 5b. Run the on-device Isolation Forest. When the model isn't yet
    // loaded the future returns and we fall back to the rules score.
    if (!_wifiMl.isReady) {
      await _wifiMl.load();
    }
    int trustScore = baseScore;
    if (_wifiMl.isReady) {
      final encCode = isSecured ? 2 : 0; // 0=open, 2=WPA2/WPA3-ish
      final feats = WifiMlService.extractFeatures(
        rssi: rssi,
        encryptionCode: encCode,
        isPublic: !isSecured,
        dnsResponseMs: dnsHealthy ? latencyMs.clamp(5, 200) : 800,
        bssidChanges: bssidChanged ? 1 : 0,
        rssiVariance: 1.0,
        frequencyGhz: frequency > 4000 ? 5.0 : 2.4,
      );
      final r = _wifiMl.predict(feats);
      if (r != null && r.isAnomaly) {
        // Anomalous network: shave 25 points off the trust score.
        trustScore = (baseScore - 25).clamp(0, 100);
        checks.add(WifiCheckResult(
          name: 'ML anomaly',
          passed: false,
          detail:
              'On-device Isolation Forest flagged this network as anomalous '
              '(score=${r.anomalyScore.toStringAsFixed(3)})',
          icon: 'science',
        ));
      } else if (r != null) {
        // Blend the rules-based score with the ML trust score.
        trustScore = ((baseScore + r.trustScore) / 2).round().clamp(0, 100);
      }
    }

    final riskLevel = _riskLevel(trustScore);

    // 6. Save to Hive
    final scanModel = WifiScanModel(
      ssid: ssid,
      bssid: bssid,
      rssi: rssi,
      trustScore: trustScore,
      riskLevel: riskLevel,
      checks:
          checks.map((c) => '${c.name}:${c.passed ? 'pass' : 'fail'}').toList(),
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      frequency: frequency,
      linkSpeed: linkSpeed,
      isEncrypted: isSecured,
      dnsHealthy: dnsHealthy,
      latencyMs: latencyMs,
    );
    await HiveService.saveWifiScan(scanModel);

    // 7. Create alert if dangerous
    if (riskLevel == 'critical' || riskLevel == 'high') {
      final alert = AlertModel(
        id: _uuid.v4(),
        type: riskLevel == 'critical' ? 'critical' : 'warning',
        title: riskLevel == 'critical'
            ? 'Dangerous Wi-Fi Network'
            : 'Unsafe Wi-Fi Network',
        description:
            '"$ssid" — ${checks.where((c) => !c.passed).map((c) => c.name).join(', ')} failed',
        module: 'wifi',
        timestamp: DateTime.now(),
      );
      await HiveService.saveAlert(alert);
      await NotificationService.showUnsafeWifi(ssid);
    }

    // 8. Store BSSID for future comparison
    // (already stored via saveWifiScan)

    return WifiAnalysisResult(
      ssid: ssid,
      bssid: bssid,
      rssi: rssi,
      trustScore: trustScore,
      riskLevel: riskLevel,
      checks: checks,
      ipAddress: ipAddress,
      frequency: frequency,
      linkSpeed: linkSpeed,
      isEncrypted: isSecured,
      dnsHealthy: dnsHealthy,
      latencyMs: latencyMs,
      bssidChanged: bssidChanged,
    );
  }

  Future<({bool healthy, int latencyMs})> _testDns() async {
    final sw = Stopwatch()..start();
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      sw.stop();
      final healthy = result.isNotEmpty && sw.elapsedMilliseconds < 500;
      return (healthy: healthy, latencyMs: sw.elapsedMilliseconds);
    } catch (_) {
      sw.stop();
      return (healthy: false, latencyMs: sw.elapsedMilliseconds);
    }
  }

  String _riskLevel(int trustScore) {
    if (trustScore >= 80) return 'low';
    if (trustScore >= 60) return 'medium';
    if (trustScore >= 40) return 'high';
    return 'critical';
  }

  List<WifiScanModel> getHistory() {
    return HiveService.getWifiScans();
  }
}
