import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/hive_service.dart';
import '../../features/alerts/provider/alerts_provider.dart';
import '../../features/dashboard/provider/dashboard_provider.dart';
import '../../features/settings/provider/settings_provider.dart';

/// Refreshes dashboard + alerts after any scan completes
void refreshGlobalState(WidgetRef ref) {
  ref.read(dashboardProvider.notifier).loadDashboard();
  ref.read(alertsProvider.notifier).loadAlerts();
}

/// Whether onboarding has been completed
final onboardingCompleteProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.onboardingComplete;
});

/// Current HIBP API key from settings
final hibpApiKeyProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).hibpApiKey;
});

/// App-wide initialisation flag
final appInitProvider = FutureProvider<bool>((ref) async {
  await HiveService.init();
  return true;
});
