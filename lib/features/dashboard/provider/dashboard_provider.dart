import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/score_calculator.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/score_entry_model.dart';
import '../../../data/services/hive_service.dart';

class DashboardStats {
  final int totalScans;
  final int threatsFound;
  final DateTime? lastScanDate;

  const DashboardStats({
    required this.totalScans,
    required this.threatsFound,
    required this.lastScanDate,
  });
}

class DashboardState {
  final int unifiedScore;
  final int phishingScore;
  final int malwareScore;
  final int breachScore;
  final int wifiScore;
  final DashboardStats stats;
  final List<ScoreEntryModel> scoreHistory;
  final List<AlertModel> recentAlerts;
  final bool isLoading;
  final String? error;

  const DashboardState({
    required this.unifiedScore,
    required this.phishingScore,
    required this.malwareScore,
    required this.breachScore,
    required this.wifiScore,
    required this.stats,
    required this.scoreHistory,
    required this.recentAlerts,
    required this.isLoading,
    this.error,
  });

  factory DashboardState.initial() => DashboardState(
        unifiedScore: 85,
        phishingScore: 85,
        malwareScore: 85,
        breachScore: 85,
        wifiScore: 85,
        stats: const DashboardStats(
          totalScans: 0,
          threatsFound: 0,
          lastScanDate: null,
        ),
        scoreHistory: [],
        recentAlerts: [],
        isLoading: false,
      );

  DashboardState copyWith({
    int? unifiedScore,
    int? phishingScore,
    int? malwareScore,
    int? breachScore,
    int? wifiScore,
    DashboardStats? stats,
    List<ScoreEntryModel>? scoreHistory,
    List<AlertModel>? recentAlerts,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      unifiedScore: unifiedScore ?? this.unifiedScore,
      phishingScore: phishingScore ?? this.phishingScore,
      malwareScore: malwareScore ?? this.malwareScore,
      breachScore: breachScore ?? this.breachScore,
      wifiScore: wifiScore ?? this.wifiScore,
      stats: stats ?? this.stats,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      recentAlerts: recentAlerts ?? this.recentAlerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(DashboardState.initial()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final settings = HiveService.getSettings();
      final totalScans = HiveService.getTotalScans();
      final threatsFound = HiveService.getThreatCount();
      final scoreHistory = HiveService.getScoreHistory(days: 7);
      final alerts = HiveService.getAlerts().take(5).toList();

      final unified = ScoreCalculator.calculate(
        phishingScore: settings.phishingScore,
        malwareScore: settings.malwareScore,
        breachScore: settings.breachScore,
        wifiScore: settings.wifiScore,
        breachActive: settings.hasActiveBreach,
      );

      state = state.copyWith(
        unifiedScore: unified,
        phishingScore: settings.phishingScore,
        malwareScore: settings.malwareScore,
        breachScore: settings.breachScore,
        wifiScore: settings.wifiScore,
        stats: DashboardStats(
          totalScans: totalScans,
          threatsFound: threatsFound,
          lastScanDate: settings.lastScanDate,
        ),
        scoreHistory: scoreHistory,
        recentAlerts: alerts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Stamp a successful "I ran a scan" without changing any module score.
  /// Used by the dashboard "Scan Now" so the UI exits the never-scanned
  /// state even when no individual scanner produced a value.
  Future<void> markScanned() async {
    final settings = HiveService.getSettings();
    await HiveService.saveSettings(
      settings.copyWith(lastScanDate: DateTime.now()),
    );
    await loadDashboard();
  }

  void updateScore({
    int? phishing,
    int? malware,
    int? breach,
    int? wifi,
    bool? breachActive,
  }) {
    final settings = HiveService.getSettings();
    final newSettings = settings.copyWith(
      phishingScore: phishing,
      malwareScore: malware,
      breachScore: breach,
      wifiScore: wifi,
      hasActiveBreach: breachActive,
      lastScanDate: DateTime.now(),
    );
    HiveService.saveSettings(newSettings);

    final unified = ScoreCalculator.calculate(
      phishingScore: phishing ?? settings.phishingScore,
      malwareScore: malware ?? settings.malwareScore,
      breachScore: breach ?? settings.breachScore,
      wifiScore: wifi ?? settings.wifiScore,
      breachActive: breachActive ?? settings.hasActiveBreach,
    );

    // Save score history entry
    final entry = ScoreEntryModel(
      date: DateTime.now(),
      unifiedScore: unified,
      phishingScore: phishing ?? settings.phishingScore,
      malwareScore: malware ?? settings.malwareScore,
      breachScore: breach ?? settings.breachScore,
      wifiScore: wifi ?? settings.wifiScore,
    );
    HiveService.saveScoreEntry(entry);

    loadDashboard();
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);
