import 'package:hive/hive.dart';

part 'scan_result_model.g.dart';

enum ScanType { phishing, malware, breach, wifi }

@HiveType(typeId: 0)
class ScanResultModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String type; // 'phishing', 'malware', 'breach', 'wifi'

  @HiveField(2)
  late String input;

  @HiveField(3)
  late String verdict;

  @HiveField(4)
  late int confidence;

  @HiveField(5)
  late List<String> shapReasons;

  @HiveField(6)
  late DateTime timestamp;

  @HiveField(7)
  late bool isRead;

  @HiveField(8)
  String? extraData; // JSON string for extra info

  ScanResultModel({
    required this.id,
    required this.type,
    required this.input,
    required this.verdict,
    required this.confidence,
    required this.shapReasons,
    required this.timestamp,
    this.isRead = false,
    this.extraData,
  });

  bool get isThreat => verdict.toLowerCase() == 'phishing' ||
      verdict.toLowerCase() == 'malicious' ||
      verdict.toLowerCase() == 'breached' ||
      verdict.toLowerCase() == 'unsafe';
}

@HiveType(typeId: 5)
class AppScanModel extends HiveObject {
  @HiveField(0)
  late String packageName;

  @HiveField(1)
  late String appName;

  @HiveField(2)
  late int riskScore;

  @HiveField(3)
  late String riskLevel;

  @HiveField(4)
  late List<String> dangerousPermissions;

  @HiveField(5)
  late List<String> shapReasons;

  @HiveField(6)
  late DateTime scannedAt;

  @HiveField(7)
  late int permissionCount;

  AppScanModel({
    required this.packageName,
    required this.appName,
    required this.riskScore,
    required this.riskLevel,
    required this.dangerousPermissions,
    required this.shapReasons,
    required this.scannedAt,
    required this.permissionCount,
  });
}
