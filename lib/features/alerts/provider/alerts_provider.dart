import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/repositories/alert_repository.dart';
import '../../../data/services/hive_service.dart';
import '../../dashboard/provider/dashboard_provider.dart';

class AlertsState {
  final List<AlertModel> alerts;
  final List<AlertModel> filtered;
  final String filter; // 'all', 'phishing', 'malware', 'breach', 'wifi'
  final bool isLoading;
  final int unreadCount;

  const AlertsState({
    this.alerts = const [],
    this.filtered = const [],
    this.filter = 'all',
    this.isLoading = false,
    this.unreadCount = 0,
  });

  AlertsState copyWith({
    List<AlertModel>? alerts,
    List<AlertModel>? filtered,
    String? filter,
    bool? isLoading,
    int? unreadCount,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      filtered: filtered ?? this.filtered,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  final AlertRepository _repo;
  final Ref _ref;

  AlertsNotifier(this._repo, this._ref) : super(const AlertsState()) {
    loadAlerts();
  }

  void loadAlerts() {
    state = state.copyWith(isLoading: true);
    final alerts = _repo.getAll();
    final unread = alerts.where((a) => !a.isRead).length;
    state = state.copyWith(
      isLoading: false,
      alerts: alerts,
      filtered: _applyFilter(alerts, state.filter),
      unreadCount: unread,
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(
      filter: filter,
      filtered: _applyFilter(state.alerts, filter),
    );
  }

  void _syncDashboard() {
    // Dashboard caches its own copy of recentAlerts from Hive; reload it so
    // the notification badge and the "Recent Alerts" card under the security
    // score reflect deletions / read-state changes immediately.
    _ref.read(dashboardProvider.notifier).loadDashboard();
  }

  void markRead(String id) {
    _repo.markRead(id);
    loadAlerts();
    _syncDashboard();
  }

  void markAllRead() {
    _repo.markAllRead();
    loadAlerts();
    _syncDashboard();
  }

  void deleteAlert(String id) {
    _repo.delete(id);
    loadAlerts();
    _syncDashboard();
  }

  void clearAll() {
    HiveService.clearAlerts();
    loadAlerts();
    _syncDashboard();
  }

  List<AlertModel> _applyFilter(List<AlertModel> alerts, String filter) {
    if (filter == 'all') return alerts;
    return alerts.where((a) => a.module == filter).toList();
  }
}

final _alertRepoProvider = Provider((_) => AlertRepository());

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AlertsState>(
  (ref) => AlertsNotifier(ref.read(_alertRepoProvider), ref),
);

/// Exposes unread count for bottom nav badge
final alertUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(alertsProvider).unreadCount;
});
