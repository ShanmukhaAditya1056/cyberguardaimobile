import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/link_interceptor_repository.dart';
import '../../../data/services/interceptor_prefs.dart';
import '../../../data/services/link_interceptor_channel.dart';
import '../../../data/services/threat_intel/risk_engine.dart';

class InterceptorState {
  /// The most recent analyzed link awaiting user action, or null.
  final LinkRisk? pending;

  /// True while a link is being analyzed.
  final bool isAnalyzing;

  /// Bumped each time a new [pending] verdict needs the warning screen shown.
  /// The bootstrap listener watches this to trigger navigation exactly once.
  final int navToken;

  final String? error;

  const InterceptorState({
    this.pending,
    this.isAnalyzing = false,
    this.navToken = 0,
    this.error,
  });

  InterceptorState copyWith({
    LinkRisk? pending,
    bool? isAnalyzing,
    int? navToken,
    String? error,
    bool clearPending = false,
  }) {
    return InterceptorState(
      pending: clearPending ? null : (pending ?? this.pending),
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      navToken: navToken ?? this.navToken,
      error: error,
    );
  }
}

class InterceptorNotifier extends StateNotifier<InterceptorState> {
  final LinkInterceptorRepository _repo;
  final LinkInterceptorChannel _channel;
  StreamSubscription<InterceptedLink>? _sub;

  InterceptorNotifier(this._repo, this._channel)
      : super(const InterceptorState()) {
    _listen();
  }

  /// Begin listening for intercepted links (warm starts) and consume any
  /// cold-start link.
  void _listen() {
    _sub = _channel.stream.listen(
      (link) => handleIntercept(link),
      onError: (_) {},
    );
    // Cold start: a link that launched the app.
    _channel.getInitialLink().then((link) {
      if (link != null) handleIntercept(link);
    });
  }

  /// Analyze an intercepted link and, if it isn't safe, surface it for the
  /// warning screen. Safe links are allowed through silently.
  Future<void> handleIntercept(InterceptedLink link) async {
    if (!InterceptorPrefs.interceptorEnabled) {
      // Interceptor disabled — hand straight back to the browser.
      await _channel.openInBrowser(link.url);
      return;
    }
    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final risk = await _repo.analyze(link.url, sourceApp: link.sourceApp);
      // analyze() can hit the network, and links arrive from other apps at
      // arbitrary moments — if the provider was torn down while it was in
      // flight, touching `state` throws "Cannot use ... after dispose". The
      // browser hand-off below still has to happen either way.
      if (!mounted) {
        if (risk.action == LinkAction.allow) {
          await _channel.openInBrowser(link.url);
        }
        return;
      }
      if (risk.action == LinkAction.allow) {
        // No threat — open without nagging the user.
        state = state.copyWith(isAnalyzing: false, clearPending: true);
        await _channel.openInBrowser(link.url);
      } else {
        state = state.copyWith(
          isAnalyzing: false,
          pending: risk,
          navToken: state.navToken + 1,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isAnalyzing: false, error: e.toString());
    }
  }

  /// User chose "Continue Anyway" — open the URL in a real browser.
  Future<void> continueAnyway() async {
    final risk = state.pending;
    if (risk == null) return;
    await _channel.openInBrowser(risk.url);
    // Handing off to the browser routinely backgrounds this app, so the
    // notifier may be gone by the time we get here.
    if (!mounted) return;
    state = state.copyWith(clearPending: true);
  }

  /// One-tap report for the pending link.
  Future<void> report({String? note}) async {
    final risk = state.pending;
    if (risk == null) return;
    await _repo.reportLink(risk, userNote: note);
  }

  /// User chose "Go Back" / dismissed.
  void dismiss() => state = state.copyWith(clearPending: true);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final linkInterceptorRepoProvider =
    Provider((_) => LinkInterceptorRepository());

final linkInterceptorChannelProvider =
    Provider((_) => const LinkInterceptorChannel());

final interceptorProvider =
    StateNotifierProvider<InterceptorNotifier, InterceptorState>(
  (ref) => InterceptorNotifier(
    ref.read(linkInterceptorRepoProvider),
    ref.read(linkInterceptorChannelProvider),
  ),
);
