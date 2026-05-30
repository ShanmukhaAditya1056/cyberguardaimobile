import 'package:hive/hive.dart';

part 'wifi_scan_model.g.dart';

@HiveType(typeId: 2)
class WifiScanModel extends HiveObject {
  @HiveField(0)
  late String ssid;

  @HiveField(1)
  late String bssid;

  @HiveField(2)
  late int rssi;

  @HiveField(3)
  late int trustScore;

  @HiveField(4)
  late String riskLevel;

  @HiveField(5)
  late List<String> checks; // JSON-encoded check results

  @HiveField(6)
  late DateTime timestamp;

  @HiveField(7)
  late String ipAddress;

  @HiveField(8)
  late int frequency;

  @HiveField(9)
  late int linkSpeed;

  @HiveField(10)
  late bool isEncrypted;

  @HiveField(11)
  late bool dnsHealthy;

  @HiveField(12)
  late int latencyMs;

  WifiScanModel({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.trustScore,
    required this.riskLevel,
    required this.checks,
    required this.timestamp,
    required this.ipAddress,
    required this.frequency,
    required this.linkSpeed,
    this.isEncrypted = true,
    this.dnsHealthy = true,
    this.latencyMs = 0,
  });

  String get signalLabel {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    if (rssi >= -80) return 'Poor';
    return 'Very Poor';
  }

  int get signalBars {
    if (rssi >= -50) return 5;
    if (rssi >= -60) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -80) return 2;
    return 1;
  }

  String get frequencyBand {
    if (frequency == 0) return 'Unknown';
    return frequency < 3000 ? '2.4 GHz' : '5 GHz';
  }
}
