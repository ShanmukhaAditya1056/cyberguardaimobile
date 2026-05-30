import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/phishing_repository.dart';
import '../../../data/services/permission_service.dart';
import '../../../data/services/platform_channel_service.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/blink_card.dart';
import '../../../shared/widgets/risk_badge.dart';
import '../../../shared/widgets/shap_bar.dart';
import '../../../shared/widgets/smart_back_button.dart';
import '../provider/phishing_provider.dart';

class PhishingScreen extends ConsumerStatefulWidget {
  const PhishingScreen({super.key});

  @override
  ConsumerState<PhishingScreen> createState() => _PhishingScreenState();
}

class _PhishingScreenState extends ConsumerState<PhishingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _urlCtrl = TextEditingController();
  final _urlFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _urlCtrl.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final text = await FlutterClipboard.paste();
    if (text.isNotEmpty) {
      _urlCtrl.text = text;
      _urlCtrl.selection =
          TextSelection.collapsed(offset: _urlCtrl.text.length);
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _scan() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    _urlFocus.unfocus();
    await ref.read(phishingProvider.notifier).scanUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phishingProvider);
    final score = 85; // Could read from settings

    return GradientScaffold(
      score: score,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: kToolbarHeight + 48),
          // Tabs
          _GlassTabBar(controller: _tabs),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _UrlScannerTab(
                  state: state,
                  urlCtrl: _urlCtrl,
                  urlFocus: _urlFocus,
                  onPaste: _paste,
                  onScan: _scan,
                  onDeleteHistory: (id) =>
                      ref.read(phishingProvider.notifier).deleteHistory(id),
                ),
                _SmsScannerTab(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Text(AppLocalizations.of(context)!.phishingScanner,
            style: AppTextStyles.title),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.scanQrCode,
            icon: const Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.textDark),
            onPressed: () => GoRouter.of(context).push('/phishing/qr'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textDark),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassCard(
        radius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.phishingHowItWorks,
                style: AppTextStyles.headline2),
            const SizedBox(height: 12),
            Text(
              l.phishingHowItWorksBody,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: l.phishingGotIt,
              gradient: AppGradients.blue,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Glass Tab Bar ──────────────────────────────────────────────────────────

class _GlassTabBar extends StatelessWidget {
  final TabController controller;
  const _GlassTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.12), width: 0.5),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: BlinkCard.blueAccent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: BlinkCard.blueAccent.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.white50,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: l.phishingUrlTab),
            Tab(text: l.phishingSmsTab),
          ],
        ),
      ),
    );
  }
}

// ─── URL Scanner Tab ─────────────────────────────────────────────────────────

class _UrlScannerTab extends StatelessWidget {
  final PhishingState state;
  final TextEditingController urlCtrl;
  final FocusNode urlFocus;
  final VoidCallback onPaste;
  final VoidCallback onScan;
  final void Function(String id) onDeleteHistory;

  const _UrlScannerTab({
    required this.state,
    required this.urlCtrl,
    required this.urlFocus,
    required this.onPaste,
    required this.onScan,
    required this.onDeleteHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Input hero card (Blinkit style)
        BlinkCard(
          tile: BlinkCard.blueTile,
          accent: BlinkCard.blueAccent,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BlinkCard.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.link_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.phishingCheckLink,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: BlinkCard.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            )),
                        Text(l.phishingPasteHint,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: BlinkCard.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BlinkInput(
                controller: urlCtrl,
                focusNode: urlFocus,
                hint: 'https://example.com',
                icon: Icons.public_rounded,
                keyboardType: TextInputType.url,
                onSubmitted: (_) => onScan(),
                suffix: urlCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Color(0xFF94A3B8), size: 18),
                        onPressed: () => urlCtrl.clear(),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: BlinkButton(
                      label: l.phishingPaste,
                      icon: Icons.content_paste_go_rounded,
                      onTap: onPaste,
                      color: Colors.white,
                      textColor: BlinkCard.blueAccent,
                      height: 46,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: BlinkButton(
                      label: l.phishingScanNow,
                      icon: Icons.search_rounded,
                      onTap: onScan,
                      isLoading: state.isScanning,
                      color: BlinkCard.blueAccent,
                      height: 46,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Result
        if (state.isScanning)
          _ScanningWidget()
        else if (state.result != null)
          _ResultWidget(result: state.result!),

        const SizedBox(height: 24),

        // History
        Row(
          children: [
            Text(l.phishingScanHistory, style: AppTextStyles.title),
            const Spacer(),
            Text(l.phishingScans(state.history.length), style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 12),

        if (state.history.isEmpty)
          EmptyState(
            icon: Icons.history,
            title: l.phishingNoScansTitle,
            subtitle: l.phishingNoScansSub,
            iconColor: AppColors.blue,
          )
        else
          ...state.history
              .take(50)
              .toList()
              .asMap()
              .entries
              .map((e) => _HistoryItem(
                    result: e.value,
                    index: e.key,
                    onDelete: () => onDeleteHistory(e.value.id),
                  )),
      ],
    );
  }
}

class _ScanningWidget extends StatefulWidget {
  @override
  State<_ScanningWidget> createState() => _ScanningWidgetState();
}

class _ScanningWidgetState extends State<_ScanningWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  final _dots = ['', '.', '..', '...'];
  int _dotIdx = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _ctrl.addListener(() {
      if (_ctrl.value > 0.9) {
        setState(() => _dotIdx = (_dotIdx + 1) % _dots.length);
      }
    });
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          FadeTransition(
            opacity: _opacity,
            child: const Icon(Icons.security_outlined,
                size: 48, color: AppColors.blue),
          ),
          const SizedBox(height: 12),
          Text('${l.phishingAnalysingTitle}${_dots[_dotIdx]}',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(l.phishingAnalysingSub,
              style: AppTextStyles.caption),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            backgroundColor: AppColors.white15,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
        ],
      ),
    );
  }
}

class _ResultWidget extends StatefulWidget {
  final PhishingResult result;
  const _ResultWidget({required this.result});

  @override
  State<_ResultWidget> createState() => _ResultWidgetState();
}

class _ResultWidgetState extends State<_ResultWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final gradient = r.isPhishing ? AppGradients.danger : AppGradients.safe;
    final color = r.isPhishing ? AppColors.danger : AppColors.safe;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verdict header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          r.isPhishing
                              ? Icons.warning_rounded
                              : Icons.verified_user,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          r.isPhishing
                              ? AppLocalizations.of(context)!.phishingVerdictPhishing
                              : AppLocalizations.of(context)!.phishingVerdictSafe,
                          style: AppTextStyles.badge
                              .copyWith(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(AppLocalizations.of(context)!.phishingConfidence,
                          style: AppTextStyles.caption),
                      Text('${r.confidence}%',
                          style: AppTextStyles.title.copyWith(color: color)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Text(
                r.url.length > 60 ? r.url.substring(0, 60) + '...' : r.url,
                style: AppTextStyles.mono,
              ),

              if (r.shapReasons.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.phishingWhyFlagged,
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                ...r.shapReasons
                    .asMap()
                    .entries
                    .map((e) => ShapBar(reason: e.value, index: e.key)),
              ],

              if (r.triggeredRules.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: r.triggeredRules
                      .map((rule) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.white08,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.glassBorder, width: 0.5),
                            ),
                            child: Text(rule,
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 11)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatefulWidget {
  final dynamic result;
  final int index;
  final VoidCallback onDelete;

  const _HistoryItem(
      {required this.result, required this.index, required this.onDelete});

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    final delayMs = (widget.index < 8) ? widget.index * 40 : 0;
    if (delayMs == 0) {
      _ctrl.forward();
    } else {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isPhishing = r.verdict == 'phishing';
    final color = isPhishing ? AppColors.danger : AppColors.safe;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Dismissible(
          key: Key(r.id as String),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onDelete(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.dangerGlow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
          child: GlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            borderColor: isPhishing
                ? AppColors.danger.withValues(alpha: 0.3)
                : AppColors.glassBorder,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPhishing ? Icons.warning : Icons.verified_user,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (r.input as String).length > 45
                            ? (r.input as String).substring(0, 45) + '…'
                            : r.input as String,
                        style: AppTextStyles.bodySmall
                            ,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.timeAgo(r.timestamp as DateTime),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RiskBadge(
                      level: isPhishing ? 'high' : 'low',
                      compact: true,
                      showIcon: false,
                    ),
                    const SizedBox(height: 2),
                    Text('${r.confidence}%',
                        style: AppTextStyles.caption.copyWith(color: color)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SMS Scanner Tab ──────────────────────────────────────────────────────────

class _SmsScannerTab extends ConsumerWidget {
  final PhishingState state;
  const _SmsScannerTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Permission + Scan All hero (Blinkit style)
        BlinkCard(
          tile: BlinkCard.lavenderTile,
          accent: BlinkCard.lavenderAccent,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BlinkCard.lavenderAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sms_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.phishingSmsTitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: BlinkCard.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            )),
                        Text(l.phishingSmsSub,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: BlinkCard.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: BlinkButton(
                      label: l.phishingSmsLoad,
                      icon: Icons.refresh_rounded,
                      height: 44,
                      color: BlinkCard.lavenderAccent,
                      onTap: () async {
                        final granted =
                            await PermissionService.requestSmsPermission(
                                context);
                        if (granted) {
                          final platform = PlatformChannelService();
                          await ref
                              .read(phishingProvider.notifier)
                              .loadSmsMessages(platform.getRecentSms);
                        }
                      },
                      isLoading: state.isSmsLoading,
                    ),
                  ),
                  if (state.smsMessages.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        label: l.phishingSmsScanAll,
                        gradient: AppGradients.warning,
                        icon: Icons.radar,
                        height: 40,
                        onTap: () =>
                            ref.read(phishingProvider.notifier).scanAllSms(),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (state.isSmsLoading)
          ...List.generate(5, (_) => const ShimmerListTile())
        else if (state.smsMessages.isEmpty)
          EmptyState(
            icon: Icons.sms_outlined,
            title: l.phishingSmsNoneTitle,
            subtitle: l.phishingSmsNoneSub,
            iconColor: AppColors.blue,
          )
        else
          ...state.smsMessages.asMap().entries.map((e) => _SmsCard(
                message: e.value,
                index: e.key,
                onScan: () =>
                    ref.read(phishingProvider.notifier).scanSmsUrls(e.key),
              )),
      ],
    );
  }
}

class _SmsCard extends StatefulWidget {
  final SmsMessage message;
  final int index;
  final VoidCallback onScan;

  const _SmsCard(
      {required this.message, required this.index, required this.onScan});

  @override
  State<_SmsCard> createState() => _SmsCardState();
}

class _SmsCardState extends State<_SmsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    // Cap staggered delay so fast-scrolled items never appear blank.
    final delayMs = (widget.index < 8) ? widget.index * 40 : 0;
    if (delayMs == 0) {
      _ctrl.forward();
    } else {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final msg = widget.message;
    final borderColor = msg.isSuspicious
        ? AppColors.danger.withValues(alpha: 0.5)
        : AppColors.glassBorder;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.person_outline,
                        size: 16, color: AppColors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.address.isNotEmpty ? msg.address : l.phishingSmsUnknown,
                          style: AppTextStyles.bodyMedium
                              ,
                        ),
                        Text(
                          DateFormatter.timeAgo(msg.date),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  if (msg.isSuspicious)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.dangerGlow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.5),
                            width: 0.5),
                      ),
                      child: Text(l.phishingSmsSuspicious,
                          style: AppTextStyles.badge
                              .copyWith(color: AppColors.danger)),
                    ),
                  if (msg.isScanned && !msg.isSuspicious)
                    const Icon(Icons.verified, size: 18, color: AppColors.safe),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                msg.body.length > 120
                    ? msg.body.substring(0, 120) + '...'
                    : msg.body,
                style: AppTextStyles.body,
              ),
              if (msg.urls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: msg.urls
                      .take(3)
                      .map((url) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.blueGlow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              url.length > 30
                                  ? url.substring(0, 30) + '…'
                                  : url,
                              style: AppTextStyles.mono.copyWith(
                                  fontSize: 10, color: AppColors.blue),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: msg.isScanned
                      ? (msg.isSuspicious
                          ? l.phishingSmsLinksSuspicious
                          : l.phishingSmsLinksScannedSafe)
                      : l.phishingSmsScanLinks(msg.urls.length),
                  gradient: msg.isScanned
                      ? (msg.isSuspicious
                          ? AppGradients.danger
                          : AppGradients.safe)
                      : AppGradients.blue,
                  onTap: msg.isScanned ? null : widget.onScan,
                  height: 36,
                  icon: msg.isScanned
                      ? (msg.isSuspicious ? Icons.warning : Icons.check)
                      : Icons.search,
                ),
              ] else
                Text(l.phishingSmsNoUrls,
                    style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}
