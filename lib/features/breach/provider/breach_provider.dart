import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/hash_utils.dart';
import '../../../data/models/breach_model.dart';
import '../../../data/models/scan_result_model.dart';
import '../../../data/repositories/breach_repository.dart';
import '../../../data/services/hibp_service.dart';

class BreachState {
  final bool isChecking;
  final BreachCheckResult? result;
  final List<ScanResultModel> history;
  final BreachCheckStep currentStep;
  final String? error;
  final String credential;
  final String hashPreview;
  final bool isEmail; // true=email, false=password

  const BreachState({
    this.isChecking = false,
    this.result,
    this.history = const [],
    this.currentStep = BreachCheckStep.idle,
    this.error,
    this.credential = '',
    this.hashPreview = '',
    this.isEmail = true,
  });

  BreachState copyWith({
    bool? isChecking,
    BreachCheckResult? result,
    List<ScanResultModel>? history,
    BreachCheckStep? currentStep,
    String? error,
    String? credential,
    String? hashPreview,
    bool? isEmail,
  }) {
    return BreachState(
      isChecking: isChecking ?? this.isChecking,
      result: result ?? this.result,
      history: history ?? this.history,
      currentStep: currentStep ?? this.currentStep,
      error: error,
      credential: credential ?? this.credential,
      hashPreview: hashPreview ?? this.hashPreview,
      isEmail: isEmail ?? this.isEmail,
    );
  }
}

class BreachNotifier extends StateNotifier<BreachState> {
  final BreachRepository _repo;

  BreachNotifier(this._repo) : super(const BreachState()) {
    _loadHistory();
  }

  void _loadHistory() {
    final history = _repo.getHistory();
    state = state.copyWith(history: history);
  }

  void updateCredential(String value) {
    if (value.isEmpty) {
      state = state.copyWith(credential: value, hashPreview: '');
      return;
    }
    final preview = value.length >= 3 ? HashUtils.hibpPrefix(value) : '';
    state = state.copyWith(credential: value, hashPreview: preview);
  }

  void setMode(bool isEmail) {
    state = state.copyWith(
        isEmail: isEmail, credential: '', hashPreview: '', result: null);
  }

  Future<void> checkBreach(String apiKey) async {
    final cred = state.credential.trim();
    if (cred.isEmpty) return;

    state = state.copyWith(
      isChecking: true,
      error: null,
      result: null,
      currentStep: BreachCheckStep.idle,
    );

    try {
      BreachCheckResult result;
      if (state.isEmail) {
        result = await _repo.checkEmail(
          cred,
          apiKey,
          onStep: (step) {
            if (!mounted) return;
            state = state.copyWith(currentStep: step);
          },
        );
      } else {
        result = await _repo.checkPassword(
          cred,
          onStep: (step) {
            if (!mounted) return;
            state = state.copyWith(currentStep: step);
          },
        );
      }

      _loadHistory();
      state = state.copyWith(
        isChecking: false,
        result: result,
        currentStep: BreachCheckStep.complete,
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: e.toString().replaceFirst('Exception: ', ''),
        currentStep: BreachCheckStep.error,
      );
    }
  }
}

final _hibpProvider = Provider((_) => HibpService());
final _breachRepoProvider =
    Provider((ref) => BreachRepository(ref.read(_hibpProvider)));

final breachProvider = StateNotifierProvider<BreachNotifier, BreachState>(
  (ref) => BreachNotifier(ref.read(_breachRepoProvider)),
);
