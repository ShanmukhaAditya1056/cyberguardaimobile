import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/wifi_scan_model.dart';
import '../../../data/repositories/wifi_repository.dart';
import '../../../data/services/hive_service.dart';
import '../../../data/services/platform_channel_service.dart';

class WifiState {
  final bool isScanning;
  final WifiScanModel? current;
  final List<WifiScanModel> history;
  final String? error;
  final bool hasPermission;

  const WifiState({
    this.isScanning = false,
    this.current,
    this.history = const [],
    this.error,
    this.hasPermission = true,
  });

  WifiState copyWith({
    bool? isScanning,
    WifiScanModel? current,
    List<WifiScanModel>? history,
    String? error,
    bool? hasPermission,
  }) {
    return WifiState(
      isScanning: isScanning ?? this.isScanning,
      current: current ?? this.current,
      history: history ?? this.history,
      error: error,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class WifiNotifier extends StateNotifier<WifiState> {
  final WifiRepository _repo;

  WifiNotifier(this._repo) : super(const WifiState()) {
    _loadHistory();
  }

  void _loadHistory() {
    final history = HiveService.getWifiHistory();
    state = state.copyWith(history: history, current: null);
  }

  Future<void> scanNetwork() async {
    state = state.copyWith(isScanning: true, error: null);
    try {
      await _repo.analyzeCurrentNetwork();
      final history = HiveService.getWifiHistory();
      final current = history.isNotEmpty ? history.first : null;
      state = state.copyWith(
        isScanning: false,
        current: current,
        history: history,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      // Case-insensitive: the platform messages start sentences with
      // "Location", which a lowercase-only match would miss.
      final lower = msg.toLowerCase();
      final isPermission =
          lower.contains('permission') || lower.contains('location');
      state = state.copyWith(
        isScanning: false,
        error: msg,
        hasPermission: !isPermission,
      );
    }
  }

  void clearHistory() {
    HiveService.clearWifiHistory();
    state = state.copyWith(history: [], current: null);
  }
}

final _platformProvider = Provider((_) => PlatformChannelService());

final _wifiRepoProvider =
    Provider((ref) => WifiRepository(ref.watch(_platformProvider)));

final wifiProvider = StateNotifierProvider<WifiNotifier, WifiState>(
  (ref) => WifiNotifier(ref.read(_wifiRepoProvider)),
);
