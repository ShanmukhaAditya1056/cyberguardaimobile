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

/// Highest trust score a network can reach when the host could not read its
/// encryption, signal or access point. Sits just under the 80-point "low risk"
/// threshold, so an unverifiable network lands in "medium" — not alarming, but
/// never presented as clean.
const int _unverifiedNetworkCeiling = 75;

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

  /// False when the host cannot see who it is connected to — currently iOS
  /// without the Wi-Fi entitlement. The SSID, BSSID, signal and encryption
  /// fields are then placeholders, and the UI must say so instead of
  /// presenting them as findings.
  final bool identityAvailable;

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
    this.identityAvailable = true,
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
    // Android redacts the SSID rather than failing, so without these the scan
    // would quietly record a network called "Unknown". Both messages contain
    // the words the provider looks for to flag this as a permission problem.
    if (status == 'permission_required') {
      throw Exception((wifiData['message'] as String?) ??
          'Location permission is needed to read the Wi-Fi network name');
    }
    if (status == 'location_off') {
      throw Exception((wifiData['message'] as String?) ??
          'Turn on Location to read the Wi-Fi network name');
    }
    if (status == 'error') {
      throw Exception(
          (wifiData['message'] as String?) ?? 'Failed to read Wi-Fi state');
    }

    // Hosts that cannot see the network's identity say so explicitly. iOS is
    // the only one today: SSID, BSSID, signal and cipher all need the Wi-Fi
    // entitlement. The reachability checks below need none of that, so the
    // module still runs — it just reports on what it can actually observe
    // rather than on placeholder values.
    final identityAvailable = wifiData['identityAvailable'] as bool? ?? true;

    final ssid = wifiData['ssid'] as String? ?? 'Unknown';
    final bssid = wifiData['bssid'] as String? ?? '';
    final rssi = wifiData['rssi'] as int? ?? -100;
    final linkSpeed = wifiData['linkSpeed'] as int? ?? 0;
    final frequency = wifiData['frequency'] as int? ?? 0;
    final ipAddress = wifiData['ipAddress'] as String? ?? '0.0.0.0';
    final isSecured = wifiData['isSecured'] as bool? ?? true;
    final hasInternet = wifiData['hasInternet'] as bool? ?? false;
    // Desktops report the negotiated cipher by name ("WPA3 Personal",
    // "WEP (broken encryption)"), which is more useful than a yes/no.
    final securityLabel = wifiData['securityLabel'] as String?;

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

    // 4. Run all checks. The reachability trio applies to every host; the
    // first three depend on being able to see the network itself.
    final checks = <WifiCheckResult>[
      if (identityAvailable) ...[
        WifiCheckResult(
          name: 'Encryption',
          passed: isSecured,
          detail: isSecured
              ? 'Network is encrypted (${securityLabel ?? 'WPA2/WPA3'})'
              : securityLabel != null && securityLabel.startsWith('WEP')
                  ? 'WEP encryption — broken since 2001, treat as open'
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
      ],
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
      if (identityAvailable)
        WifiCheckResult(
          name: 'BSSID Consistency',
          passed: !bssidChanged,
          detail: bssidChanged
              ? 'BSSID changed! Possible Evil Twin attack'
              : bssid.isEmpty
                  ? 'Access point address not visible — Evil Twin check skipped'
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
      if (!identityAvailable)
        const WifiCheckResult(
          name: 'Network identity',
          passed: false,
          detail: 'iOS does not expose the network name, access point or '
              'encryption to apps without a special entitlement, so those '
              'checks could not run.',
          icon: 'visibility_off',
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

    // A host that cannot inspect the network has not verified it is safe, so
    // the score is capped below the "low risk" band. Anything higher would let
    // an unverifiable network read as clean, which is the one outcome a
    // security tool must not produce. The ML model is skipped for the same
    // reason: its features are the encryption, signal and BSSID fields that
    // this host could not read.
    if (!identityAvailable) {
      final cappedScore = baseScore.clamp(0, _unverifiedNetworkCeiling);
      return _buildResult(
        ssid: ssid,
        bssid: bssid,
        rssi: rssi,
        trustScore: cappedScore,
        checks: checks,
        ipAddress: ipAddress,
        frequency: frequency,
        linkSpeed: linkSpeed,
        isSecured: isSecured,
        dnsHealthy: dnsHealthy,
        latencyMs: latencyMs,
        bssidChanged: bssidChanged,
        identityAvailable: false,
      );
    }

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

    return _buildResult(
      ssid: ssid,
      bssid: bssid,
      rssi: rssi,
      trustScore: trustScore,
      checks: checks,
      ipAddress: ipAddress,
      frequency: frequency,
      linkSpeed: linkSpeed,
      isSecured: isSecured,
      dnsHealthy: dnsHealthy,
      latencyMs: latencyMs,
      bssidChanged: bssidChanged,
      identityAvailable: true,
    );
  }

  /// Records the scan, raises an alert when the network is dangerous, and
  /// returns the result. Shared by both exits from [analyzeCurrentNetwork] so
  /// a host that can only run the reachability checks still gets its scan
  /// written to history and still triggers an alert.
  Future<WifiAnalysisResult> _buildResult({
    required String ssid,
    required String bssid,
    required int rssi,
    required int trustScore,
    required List<WifiCheckResult> checks,
    required String ipAddress,
    required int frequency,
    required int linkSpeed,
    required bool isSecured,
    required bool dnsHealthy,
    required int latencyMs,
    required bool bssidChanged,
    required bool identityAvailable,
  }) async {
    final riskLevel = _riskLevel(trustScore);

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

    if (riskLevel == 'critical' || riskLevel == 'high') {
      final failed = checks.where((c) => !c.passed).map((c) => c.name).join(', ');
      final label = ssid.isEmpty ? 'This network' : '"$ssid"';
      final alert = AlertModel(
        id: _uuid.v4(),
        type: riskLevel == 'critical' ? 'critical' : 'warning',
        title: riskLevel == 'critical'
            ? 'Dangerous Wi-Fi Network'
            : 'Unsafe Wi-Fi Network',
        description: '$label — $failed failed',
        module: 'wifi',
        timestamp: DateTime.now(),
      );
      await HiveService.saveAlert(alert);
      await NotificationService.showUnsafeWifi(
        ssid.isEmpty ? 'your current network' : ssid,
      );
    }

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
      identityAvailable: identityAvailable,
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
