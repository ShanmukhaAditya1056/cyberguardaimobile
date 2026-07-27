import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/predictive_risk_repository.dart';
import '../../../data/services/predictive_risk_service.dart';

class RiskState {
  final bool isLoading;
  final RiskAssessment? assessment;
  final List<RiskPoint> timeline;
  final String? error;

  const RiskState({
    this.isLoading = false,
    this.assessment,
    this.timeline = const [],
    this.error,
  });

  RiskState copyWith({
    bool? isLoading,
    RiskAssessment? assessment,
    List<RiskPoint>? timeline,
    String? error,
  }) =>
      RiskState(
        isLoading: isLoading ?? this.isLoading,
        assessment: assessment ?? this.assessment,
        timeline: timeline ?? this.timeline,
        error: error,
      );
}

class RiskNotifier extends StateNotifier<RiskState> {
  final PredictiveRiskRepository _repo;

  RiskNotifier(this._repo) : super(const RiskState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final assessment = await _repo.assess();
      state = state.copyWith(
        isLoading: false,
        assessment: assessment,
        timeline: _repo.timeline(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final predictiveRiskRepoProvider =
    Provider((_) => PredictiveRiskRepository());

final riskProvider = StateNotifierProvider<RiskNotifier, RiskState>(
  (ref) => RiskNotifier(ref.read(predictiveRiskRepoProvider)),
);
