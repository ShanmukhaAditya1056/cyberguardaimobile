import 'package:hive/hive.dart';

part 'score_entry_model.g.dart';

@HiveType(typeId: 3)
class ScoreEntryModel extends HiveObject {
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late int unifiedScore;

  @HiveField(2)
  late int phishingScore;

  @HiveField(3)
  late int malwareScore;

  @HiveField(4)
  late int breachScore;

  @HiveField(5)
  late int wifiScore;

  ScoreEntryModel({
    required this.date,
    required this.unifiedScore,
    required this.phishingScore,
    required this.malwareScore,
    required this.breachScore,
    required this.wifiScore,
  });
}
