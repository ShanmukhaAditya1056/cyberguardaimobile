import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/url_extractor.dart';
import '../../../data/models/scan_result_model.dart';
import '../../../data/repositories/phishing_repository.dart';

class SmsMessage {
  final String address;
  final String body;
  final DateTime date;
  final List<String> urls;
  bool isScanned;
  bool isSuspicious;

  SmsMessage({
    required this.address,
    required this.body,
    required this.date,
    required this.urls,
    this.isScanned = false,
    this.isSuspicious = false,
  });
}

class PhishingState {
  final bool isScanning;
  final PhishingResult? result;
  final List<ScanResultModel> history;
  final List<SmsMessage> smsMessages;
  final bool isSmsLoading;
  final String? error;
  final String currentUrl;

  const PhishingState({
    this.isScanning = false,
    this.result,
    this.history = const [],
    this.smsMessages = const [],
    this.isSmsLoading = false,
    this.error,
    this.currentUrl = '',
  });

  PhishingState copyWith({
    bool? isScanning,
    PhishingResult? result,
    List<ScanResultModel>? history,
    List<SmsMessage>? smsMessages,
    bool? isSmsLoading,
    String? error,
    String? currentUrl,
  }) {
    return PhishingState(
      isScanning: isScanning ?? this.isScanning,
      result: result ?? this.result,
      history: history ?? this.history,
      smsMessages: smsMessages ?? this.smsMessages,
      isSmsLoading: isSmsLoading ?? this.isSmsLoading,
      error: error,
      currentUrl: currentUrl ?? this.currentUrl,
    );
  }
}

class PhishingNotifier extends StateNotifier<PhishingState> {
  final PhishingRepository _repo;

  PhishingNotifier(this._repo) : super(const PhishingState()) {
    _loadHistory();
  }

  void _loadHistory() {
    final history = _repo.getHistory();
    state = state.copyWith(history: history);
  }

  Future<void> scanUrl(String url) async {
    if (url.trim().isEmpty) return;
    state = state.copyWith(isScanning: true, error: null, currentUrl: url);
    try {
      final result = await _repo.scanAndSave(url);
      final history = _repo.getHistory();
      state = state.copyWith(
        isScanning: false,
        result: result,
        history: history,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadSmsMessages(
      Future<List<Map<String, String>>> Function() getSms) async {
    state = state.copyWith(isSmsLoading: true);
    try {
      final rawMessages = await getSms();
      final messages = rawMessages.map((m) {
        final body = m['body'] ?? '';
        final urls = UrlExtractor.extractUrls(body);
        final dateMs = int.tryParse(m['date'] ?? '0') ?? 0;
        return SmsMessage(
          address: m['address'] ?? '',
          body: body,
          date: dateMs > 0
              ? DateTime.fromMillisecondsSinceEpoch(dateMs)
              : DateTime.now(),
          urls: urls,
        );
      }).toList();
      state = state.copyWith(smsMessages: messages, isSmsLoading: false);
    } catch (e) {
      state = state.copyWith(
          isSmsLoading: false, error: 'SMS access denied or unavailable');
    }
  }

  Future<void> scanSmsUrls(int smsIndex) async {
    if (smsIndex >= state.smsMessages.length) return;
    final sms = state.smsMessages[smsIndex];
    if (sms.urls.isEmpty) return;

    bool anySuspicious = false;
    for (final url in sms.urls) {
      final result = await _repo.scanAndSave(url);
      if (result.isPhishing) anySuspicious = true;
    }

    final updated = List<SmsMessage>.from(state.smsMessages);
    updated[smsIndex] = SmsMessage(
      address: sms.address,
      body: sms.body,
      date: sms.date,
      urls: sms.urls,
      isScanned: true,
      isSuspicious: anySuspicious,
    );

    final history = _repo.getHistory();
    state = state.copyWith(smsMessages: updated, history: history);
  }

  Future<void> scanAllSms() async {
    for (int i = 0; i < state.smsMessages.length; i++) {
      await scanSmsUrls(i);
    }
  }

  Future<void> deleteHistory(String id) async {
    await _repo.deleteHistory(id);
    _loadHistory();
  }

  void clearResult() {
    state = state.copyWith(currentUrl: '');
  }
}

final phishingRepoProvider = Provider((_) => PhishingRepository());

final phishingProvider = StateNotifierProvider<PhishingNotifier, PhishingState>(
  (ref) => PhishingNotifier(ref.read(phishingRepoProvider)),
);
