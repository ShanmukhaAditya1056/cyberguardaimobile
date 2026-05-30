import '../models/alert_model.dart';
import '../services/hive_service.dart';

class AlertRepository {
  List<AlertModel> getAll() => HiveService.getAlerts();

  List<AlertModel> getByType(String type) =>
      HiveService.getAlerts().where((a) => a.type == type).toList();

  List<AlertModel> getByModule(String module) =>
      HiveService.getAlerts().where((a) => a.module == module).toList();

  int getUnreadCount() => HiveService.getUnreadAlertCount();

  Future<void> markRead(String id) => HiveService.markAlertRead(id);

  Future<void> delete(String id) => HiveService.deleteAlert(id);

  Future<void> add(AlertModel alert) => HiveService.saveAlert(alert);

  Future<void> markAllRead() async {
    final alerts = HiveService.getAlerts().where((a) => !a.isRead);
    for (final alert in alerts) {
      alert.isRead = true;
      await alert.save();
    }
  }
}
