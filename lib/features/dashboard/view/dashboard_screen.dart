import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/automation_ids.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/wifi_repository.dart';
import '../../../data/services/platform_channel_service.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/email_verification_banner.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/section_title.dart';
import '../provider/dashboard_provider.dart';
import '../widgets/module_card.dart';
import '../widgets/score_chart_widget.dart';
import '../widgets/stats_row.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _quickScanning = false;

  Future<void> _runQuickScan() async {
    if (_quickScanning) return;
    setState(() => _quickScanning = true);

    int? wifiResult;

    // Opportunistic Wi-Fi check — never blocks the scan and never surfaces
    // an error to the user. If location perm isn't already granted or Wi-Fi
    // is off, we silently skip it and the scan still "succeeds".
    try {
      // Either permission unlocks the SSID — checking only `location` meant
      // Android 13+ users who granted nearby-devices instead had the Wi-Fi
      // leg of the quick scan skipped silently. Mirrors PermissionService.
      final granted = await Permission.location.isGranted ||
          await Permission.nearbyWifiDevices.isGranted;
      if (granted) {
        final repo = WifiRepository(PlatformChannelService());
        final result = await repo.analyzeCurrentNetwork();
        ref
            .read(dashboardProvider.notifier)
            .updateScore(wifi: result.trustScore);
        wifiResult = result.trustScore;
      }
    } catch (_) {
      // Silently swallow — Wi-Fi off / disconnected / etc.
    }

    // Always refresh the dashboard: recompute the unified score from the
    // latest cached module scores and bump lastScanDate.
    await ref.read(dashboardProvider.notifier).markScanned();

    if (mounted) {
      final l = AppLocalizations.of(context)!;
      final msg = wifiResult != null
          ? l.dashboardRefreshedWithWifi(wifiResult)
          : l.dashboardRefreshed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (mounted) setState(() => _quickScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final neverScanned = state.stats.lastScanDate == null;

    return GradientScaffold(
      score: neverScanned ? 70 : state.unifiedScore,
      body: Semantics(
        identifier: AutoId.dashboardRoot,
        child: CustomScrollView(
        slivers: [
          // Transparent AppBar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Text(AppLocalizations.of(context)!.appName,
                    style: AppTextStyles.titleMedium),
                const Spacer(),
                Semantics(
                  identifier: AutoId.dashboardAlertsBtn,
                  button: true,
                  container: true,
                  label: 'Alerts',
                  child: GestureDetector(
                  onTap: () => context.push('/alerts'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: AppColors.textDark),
                      if (state.recentAlerts.where((a) => !a.isRead).isNotEmpty)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.critical,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.bg, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                '${state.recentAlerts.where((a) => !a.isRead).length}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  ),
                ),
                const SizedBox(width: 16),
                Semantics(
                  identifier: AutoId.dashboardSettingsBtn,
                  button: true,
                  container: true,
                  label: 'Settings',
                  child: GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: const Icon(Icons.settings_outlined,
                        color: AppColors.textDark),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: state.isLoading
                ? _LoadingState()
                : _DashboardContent(
                    state: state,
                    neverScanned: neverScanned,
                  ),
          ),
        ],
        ),
      ),
      floatingActionButton: _ScanFab(
        onTap: _runQuickScan,
        isLoading: _quickScanning,
        neverScanned: neverScanned,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          ShimmerCard(height: 280),
          ShimmerCard(height: 100),
          ShimmerCard(height: 220),
          ShimmerCard(height: 200),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardState state;
  final bool neverScanned;

  const _DashboardContent({required this.state, required this.neverScanned});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Above the score, because it is about the account rather than about
        // any finding — and because it renders to nothing for a verified or
        // Google-backed account, which is the common case.
        const EmailVerificationBanner(),

        // Score header
        _ScoreHeader(state: state, neverScanned: neverScanned),
        const SizedBox(height: 20),

        // Stats row
        StatsRow(stats: state.stats),
        const SizedBox(height: 24),

        // Module grid
        SectionTitle(title: AppLocalizations.of(context)!.protectionModules),
        const SizedBox(height: 12),
        ModuleGrid(state: state),
        const SizedBox(height: 24),

        // Cyber Defense tools (Features 2-5)
        SectionTitle(title: AppLocalizations.of(context)!.cyberDefense),
        const SizedBox(height: 12),
        const _DefenseGrid(),
        const SizedBox(height: 24),

        // Score chart
        if (state.scoreHistory.isNotEmpty) ...[
          SectionTitle(title: AppLocalizations.of(context)!.sevenDayScore),
          const SizedBox(height: 12),
          ScoreChartWidget(history: state.scoreHistory),
          const SizedBox(height: 24),
        ],

        // The week's scan list used to sit here. It duplicated what each
        // module screen already shows in more detail, and pushed the score
        // trend — the one thing on this screen that says something the
        // module tiles cannot — off the bottom of the viewport. Per-scan
        // history lives on the module screens; alerts stay on the bell.
        const SizedBox(height: 100), // Bottom padding for FAB
      ],
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final DashboardState state;
  final bool neverScanned;

  const _ScoreHeader({required this.state, required this.neverScanned});

  ({Color tile, Color accent, String greeting, String headline, IconData icon})
      _palette(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (neverScanned) {
      return (
        tile: const Color(0xFFE0EBFF),
        accent: const Color(0xFF3B82F6),
        greeting: l.scoreGreetingFirstScan,
        headline: l.scoreHeadlineFirstScan,
        icon: Icons.rocket_launch_rounded,
      );
    }
    final s = state.unifiedScore;
    if (s >= 70) {
      return (
        tile: const Color(0xFFD4F5E2),
        accent: const Color(0xFF059669),
        greeting: l.scoreGreetingProtected,
        headline: l.scoreHeadlineProtected,
        icon: Icons.verified_user_rounded,
      );
    }
    if (s >= 40) {
      return (
        tile: const Color(0xFFFFE7D6),
        accent: const Color(0xFFD97706),
        greeting: l.scoreGreetingAtRisk,
        headline: l.scoreHeadlineAtRisk,
        icon: Icons.warning_amber_rounded,
      );
    }
    return (
      tile: const Color(0xFFFFD9DE),
      accent: const Color(0xFFDC2626),
      greeting: l.scoreGreetingCritical,
      headline: l.scoreHeadlineCritical,
      icon: Icons.priority_high_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    final score = state.unifiedScore;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark
        ? Color.lerp(p.tile, const Color(0xFF121212), 0.82)!
        : p.tile;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: p.accent.withValues(alpha: isDark ? 0.4 : 0.25),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            // Score ring (smaller, on left)
            SizedBox(
              width: 110,
              height: 110,
              child: _MiniScoreRing(
                score: score,
                accent: p.accent,
                placeholder: neverScanned,
              ),
            ),
            const SizedBox(width: 16),
            // Right side: greeting + headline + last scan pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(p.icon, size: 14, color: p.accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          p.greeting,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: p.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.headline,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isDark
                          ? const Color(0xFFEAEAEA)
                          : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.white)
                          .withValues(alpha: isDark ? 0.12 : 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 11, color: p.accent),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            state.stats.lastScanDate != null
                                ? AppLocalizations.of(context)!.scannedAgo(
                                    DateFormatter.timeAgo(state.stats.lastScanDate!))
                                : AppLocalizations.of(context)!.neverScanned,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: isDark
                                  ? const Color(0xFFEAEAEA)
                                  : const Color(0xFF334155),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact ring rendered inside the new hero tile.
class _MiniScoreRing extends StatefulWidget {
  final int score;
  final Color accent;
  final bool placeholder;
  const _MiniScoreRing({
    required this.score,
    required this.accent,
    required this.placeholder,
  });

  @override
  State<_MiniScoreRing> createState() => _MiniScoreRingState();
}

class _MiniScoreRingState extends State<_MiniScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late Animation<int> _counter;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _counter = IntTween(begin: 0, end: widget.score)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _MiniScoreRing old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _counter = IntTween(begin: _counter.value, end: widget.score)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _MiniRingPainter(
            progress: widget.placeholder ? 0 : _progress.value,
            accent: widget.accent,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(builder: (ctx) {
                  final isDark =
                      Theme.of(ctx).brightness == Brightness.dark;
                  final l = AppLocalizations.of(ctx)!;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        identifier: AutoId.dashboardScoreValue,
                        child: Text(
                        widget.placeholder ? '—' : '${_counter.value}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111111),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.placeholder ? l.scoreLabel : l.scoreSuffix,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : const Color(0xFF555555),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  _MiniRingPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 6;

    // Track
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    // Progress arc
    if (progress > 0) {
      final arc = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708, // -pi/2
        6.2832 * progress, // 2*pi*progress
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.progress != progress || old.accent != accent;
}

/// Quick-access grid for the proactive cyber-defense tools (Features 2-5).
class _DefenseGrid extends StatelessWidget {
  const _DefenseGrid();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tiles = <(IconData, String, Color, String)>[
      (Icons.travel_explore_rounded, l.defenseThreatFusion, AppColors.blue, '/fusion'),
      (Icons.image_search_rounded, l.defenseScreenshotScan, AppColors.safe, '/screenshot'),
      (Icons.online_prediction_rounded, l.defensePredictiveRisk, AppColors.warning, '/risk'),
      (Icons.balance_rounded, l.defenseArbitrationLog, AppColors.critical, '/arbitration'),
    ];
    return Semantics(
      identifier: AutoId.dashboardDefenseGrid,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
        children: tiles
            .map((t) => Semantics(
                  // Route slug doubles as the tile's automation id, so
                  // `/fusion` is addressable as cg_dashboard_defense_fusion.
                  identifier: AutoId.defenseTile(t.$4.replaceAll('/', '')),
                  button: true,
                  container: true,
                  label: t.$2,
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => context.push(t.$4),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: t.$3.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(t.$1, color: t.$3, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(t.$2,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool neverScanned;

  const _ScanFab({
    required this.onTap,
    required this.isLoading,
    required this.neverScanned,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GradientButton(
        label: isLoading ? l.scanning : l.scanNow,
        gradient: AppGradients.blue,
        icon: Icons.security,
        onTap: isLoading ? null : onTap,
        isLoading: isLoading,
        height: 52,
        autoIdent: AutoId.dashboardScanFab,
      ),
    );
  }
}
