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

  /// Every verdict string the writers actually produce that means "this was a
  /// threat". Keep in step with the `verdict:` arguments in the repositories:
  ///
  ///   phishing_repository        'phishing' | 'safe'
  ///   malware_repository         'threats_found' | 'clean'
  ///   breach_repository          'breached' | 'safe'
  ///   link_interceptor_repository ThreatLevel.label.toLowerCase(), i.e.
  ///                              'safe' | 'suspicious' | 'dangerous' | 'critical'
  ///
  /// 'threats_found' and the two malicious interceptor bands were missing, so
  /// getThreatCount() — and the "Threats Found" tile on the dashboard — did
  /// not count a single malware detection or blocked link.
  ///
  /// 'suspicious' is deliberately excluded, matching ThreatLevel.isMalicious,
  /// which treats only dangerous/critical as malicious. 'malicious' and
  /// 'unsafe' are kept for records written by older builds.
  static const _threatVerdicts = <String>{
    'phishing',
    'threats_found',
    'breached',
    'dangerous',
    'critical',
    'malicious',
    'unsafe',
  };

  bool get isThreat => _threatVerdicts.contains(verdict.toLowerCase());
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
