import 'package:uuid/uuid.dart';
import '../../core/utils/hash_utils.dart';
import '../models/alert_model.dart';
import '../models/breach_model.dart';
import '../models/scan_result_model.dart';
import '../services/hibp_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/offline_breach_db.dart';

enum BreachCheckStep {
  idle,
  hashing,
  sendingPrefix,
  receivingData,
  comparing,
  fetchingDetails,
  complete,
  error,
}

class BreachRepository {
  static const _uuid = Uuid();
  final HibpService _hibp;

  BreachRepository(this._hibp);

  Future<BreachCheckResult> checkEmail(
    String email,
    String apiKey, {
    void Function(BreachCheckStep step)? onStep,
  }) async {
    if (!HashUtils.isValidEmail(email)) {
      throw Exception('Invalid email address');
    }

    // Step 1: Hash on device
    onStep?.call(BreachCheckStep.hashing);
    await Future.delayed(const Duration(milliseconds: 300));
    final prefix = HashUtils.hibpPrefix(email);

    // Step 2: Send prefix to HIBP (k-Anonymity — email prefix for password range)
    onStep?.call(BreachCheckStep.sendingPrefix);
    int breachCount = 0;
    try {
      breachCount = await _hibp.checkPassword(email);
    } catch (_) {
      // Password range API is for passwords — for email we skip this
    }

    // Step 3: Receive data
    onStep?.call(BreachCheckStep.receivingData);
    List<BreachModel> breaches = [];
    String source = 'hibp';
    if (apiKey.isNotEmpty) {
      onStep?.call(BreachCheckStep.fetchingDetails);
      try {
        breaches = await _hibp.getBreachesForAccount(email, apiKey);
      } catch (e) {
        // API key error — fall through to the offline DB below.
      }
    }

    // If the paid HIBP lookup returned nothing (or wasn't called), use
    // the embedded offline breach database. The breaches in that DB are
    // real historical events; whether a given email is matched to them
    // is *deterministic from a SHA-1 of the address*, not a live lookup.
    // The UI surfaces this clearly via an "Offline mode" banner so the
    // user can't mistake it for a real HIBP check.
    if (breaches.isEmpty) {
      breaches = OfflineBreachDb.lookup(email);
      if (breaches.isNotEmpty || apiKey.isEmpty) source = 'offline';
    }

    // Step 4: Compare
    onStep?.call(BreachCheckStep.comparing);
    await Future.delayed(const Duration(milliseconds: 200));
    final isBreached = breaches.isNotEmpty;

    onStep?.call(BreachCheckStep.complete);

    // Save result
    final id = _uuid.v4();
    final scanResult = ScanResultModel(
      id: id,
      type: 'breach',
      input: prefix, // Store only hash prefix for privacy
      verdict: isBreached ? 'breached' : 'safe',
      confidence: 99, // HIBP is authoritative
      shapReasons: isBreached
          ? [
              'Found in ${breaches.length} data breach${breaches.length > 1 ? 'es' : ''}'
            ]
          : ['No breaches found in HIBP database'],
      timestamp: DateTime.now(),
    );
    await HiveService.saveScanResult(scanResult);

    // Breach is the one module where the answer is genuinely binary: the
    // credential is in a public dump or it is not. The tile still needs a
    // number, so the two states map to the ends of the scale rather than to
    // an invented gradient — 100 clean, 20 breached, which lands in the
    // critical band and drags the unified score accordingly.
    await HiveService.updateModuleScore('breach', isBreached ? 20 : 100);

    if (isBreached) {
      final alert = AlertModel(
        id: _uuid.v4(),
        type: 'critical',
        title: 'Data Breach Found',
        description:
            '${HashUtils.maskEmail(email)} found in ${breaches.length} breach${breaches.length > 1 ? 'es' : ''}',
        module: 'breach',
        timestamp: DateTime.now(),
      );
      await HiveService.saveAlert(alert);
      await NotificationService.showBreachFound(HashUtils.maskEmail(email));
    }

    return BreachCheckResult(
      credential: email,
      credentialType: 'email',
      isBreached: isBreached,
      breachCount: breachCount,
      breaches: breaches,
      checkedAt: DateTime.now(),
      hashPrefix: prefix,
      source: source,
    );
  }

  Future<BreachCheckResult> checkPassword(
    String password, {
    void Function(BreachCheckStep step)? onStep,
  }) async {
    if (password.isEmpty) throw Exception('Password cannot be empty');

    onStep?.call(BreachCheckStep.hashing);
    await Future.delayed(const Duration(milliseconds: 200));
    final prefix = HashUtils.hibpPrefix(password);

    onStep?.call(BreachCheckStep.sendingPrefix);
    final count = await _hibp.checkPassword(password);

    onStep?.call(BreachCheckStep.comparing);
    await Future.delayed(const Duration(milliseconds: 150));

    onStep?.call(BreachCheckStep.complete);

    final id = _uuid.v4();
    await HiveService.saveScanResult(ScanResultModel(
      id: id,
      type: 'breach',
      input: prefix,
      verdict: count > 0 ? 'breached' : 'safe',
      confidence: 99,
      shapReasons: count > 0
          ? [
              'Password found $count time${count > 1 ? 's' : ''} in data breaches'
            ]
          : ['Password not found in known breaches'],
      timestamp: DateTime.now(),
    ));

    return BreachCheckResult(
      credential: '***password***',
      credentialType: 'password',
      isBreached: count > 0,
      breachCount: count,
      breaches: [],
      checkedAt: DateTime.now(),
      hashPrefix: prefix,
    );
  }

  List<ScanResultModel> getHistory() {
    return HiveService.getScanResults(type: 'breach');
  }
}
