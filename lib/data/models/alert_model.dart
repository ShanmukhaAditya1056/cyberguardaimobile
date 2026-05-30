import 'package:hive/hive.dart';

part 'alert_model.g.dart';

@HiveType(typeId: 1)
class AlertModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String type; // 'critical', 'warning', 'safe', 'info'

  @HiveField(2)
  late String title;

  @HiveField(3)
  late String description;

  @HiveField(4)
  late String module; // 'phishing', 'malware', 'breach', 'wifi'

  @HiveField(5)
  late DateTime timestamp;

  @HiveField(6)
  late bool isRead;

  @HiveField(7)
  String? actionData; // extra data for action button

  AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.module,
    required this.timestamp,
    this.isRead = false,
    this.actionData,
  });

  bool get isCritical => type == 'critical';
  bool get isWarning => type == 'warning';
}
