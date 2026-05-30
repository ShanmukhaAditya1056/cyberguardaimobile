import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 4)
class SettingsModel extends HiveObject {
  @HiveField(0)
  late bool realTimeAlerts;

  @HiveField(1)
  late bool clipboardScan;

  @HiveField(2)
  late String autoScanFrequency;

  @HiveField(3)
  late bool wifiAutoScan;

  @HiveField(4)
  late String hibpApiKey;

  @HiveField(5)
  late String language;

  @HiveField(6)
  late bool onboardingComplete;

  @HiveField(7)
  DateTime? lastScanDate;

  @HiveField(8)
  late int phishingScore;

  @HiveField(9)
  late int malwareScore;

  @HiveField(10)
  late int breachScore;

  @HiveField(11)
  late int wifiScore;

  @HiveField(12)
  late bool hasActiveBreach;

  SettingsModel({
    this.realTimeAlerts = true,
    this.clipboardScan = true,
    this.autoScanFrequency = 'Weekly',
    this.wifiAutoScan = true,
    this.hibpApiKey = '',
    this.language = 'English',
    this.onboardingComplete = false,
    this.lastScanDate,
    this.phishingScore = 85,
    this.malwareScore = 85,
    this.breachScore = 85,
    this.wifiScore = 85,
    this.hasActiveBreach = false,
  });

  int get unifiedScore {
    final weighted = (phishingScore * 0.30) +
        (malwareScore * 0.35) +
        (breachScore * 0.25) +
        (wifiScore * 0.10);
    final score = weighted.round().clamp(0, 100);
    return hasActiveBreach ? score.clamp(0, 45) : score;
  }

  SettingsModel copyWith({
    bool? realTimeAlerts,
    bool? clipboardScan,
    String? autoScanFrequency,
    bool? wifiAutoScan,
    String? hibpApiKey,
    String? language,
    bool? onboardingComplete,
    DateTime? lastScanDate,
    int? phishingScore,
    int? malwareScore,
    int? breachScore,
    int? wifiScore,
    bool? hasActiveBreach,
  }) {
    return SettingsModel(
      realTimeAlerts: realTimeAlerts ?? this.realTimeAlerts,
      clipboardScan: clipboardScan ?? this.clipboardScan,
      autoScanFrequency: autoScanFrequency ?? this.autoScanFrequency,
      wifiAutoScan: wifiAutoScan ?? this.wifiAutoScan,
      hibpApiKey: hibpApiKey ?? this.hibpApiKey,
      language: language ?? this.language,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      lastScanDate: lastScanDate ?? this.lastScanDate,
      phishingScore: phishingScore ?? this.phishingScore,
      malwareScore: malwareScore ?? this.malwareScore,
      breachScore: breachScore ?? this.breachScore,
      wifiScore: wifiScore ?? this.wifiScore,
      hasActiveBreach: hasActiveBreach ?? this.hasActiveBreach,
    );
  }
}
