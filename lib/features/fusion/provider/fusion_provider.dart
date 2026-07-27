import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/threat_intel/risk_engine.dart';
import '../../interceptor/provider/interceptor_provider.dart';

class FusionScanState {
  final bool isScanning;
  final LinkRisk? result;
  final String? error;

  const FusionScanState({this.isScanning = false, this.result, this.error});

  FusionScanState copyWith({
    bool? isScanning,
    LinkRisk? result,
    String? error,
    bool clearResult = false,
  }) =>
      FusionScanState(
        isScanning: isScanning ?? this.isScanning,
        result: clearResult ? null : (result ?? this.result),
        error: error,
      );
}

class FusionScanNotifier extends StateNotifier<FusionScanState> {
  final Ref _ref;
  FusionScanNotifier(this._ref) : super(const FusionScanState());

  Future<void> scan(String url) async {
    if (url.trim().isEmpty) return;
    state = state.copyWith(isScanning: true, error: null, clearResult: true);
    try {
      final risk =
          await _ref.read(linkInterceptorRepoProvider).scanUrl(url.trim());
      state = state.copyWith(isScanning: false, result: risk);
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
    }
  }

  void clear() => state = const FusionScanState();
}

final fusionScanProvider =
    StateNotifierProvider<FusionScanNotifier, FusionScanState>(
  (ref) => FusionScanNotifier(ref),
);
