import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/platform/app_platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../provider/dashboard_provider.dart';

class ModuleGrid extends StatelessWidget {
  final DashboardState state;

  const ModuleGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final modules = [
      _ModuleData(
        title: l.moduleTitlePhishing,
        subtitle: l.moduleSubtitlePhishing,
        icon: Icons.link_rounded,
        accent: const Color(0xFF3B82F6),
        tileColor: const Color(0xFFE0EBFF),
        score: state.phishingScore,
        route: '/phishing',
      ),
      _ModuleData(
        title: l.moduleTitleMalware,
        subtitle: l.moduleSubtitleMalware,
        icon: Icons.bug_report_rounded,
        accent: const Color(0xFFEA580C),
        tileColor: const Color(0xFFFFE7D6),
        score: state.malwareScore,
        route: '/malware',
      ),
      _ModuleData(
        title: l.moduleTitleBreach,
        subtitle: l.moduleSubtitleBreach,
        icon: Icons.lock_person_rounded,
        accent: const Color(0xFFE11D48),
        tileColor: const Color(0xFFFFD9DE),
        score: state.breachScore,
        route: '/breach',
      ),
      _ModuleData(
        title: l.moduleTitleWifi,
        subtitle: l.moduleSubtitleWifi,
        icon: Icons.wifi_rounded,
        accent: const Color(0xFF10B981),
        tileColor: const Color(0xFFD4F5E2),
        score: state.wifiScore,
        route: '/wifi',
      ),
    ]
        // A module the host cannot run is dropped rather than shown disabled.
        // Its route still resolves — to an explanation screen — so anything
        // that deep-links to it lands somewhere sensible, but the dashboard
        // should not offer a scan that cannot happen. The grid is two columns
        // and reflows on its own, so removing one leaves no gap.
        .where((m) => AppPlatform.isModuleAvailable(m.route.substring(1)))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemCount: modules.length,
        itemBuilder: (_, i) => _StaggeredModuleCard(
          data: modules[i],
          index: i,
        ),
      ),
    );
  }
}

class _ModuleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color tileColor;
  final int score;
  final String route;

  const _ModuleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.tileColor,
    required this.score,
    required this.route,
  });
}

class _StaggeredModuleCard extends StatefulWidget {
  final _ModuleData data;
  final int index;

  const _StaggeredModuleCard({required this.data, required this.index});

  @override
  State<_StaggeredModuleCard> createState() => _StaggeredModuleCardState();
}

class _StaggeredModuleCardState extends State<_StaggeredModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: _ModuleCardWidget(data: widget.data),
      ),
    );
  }
}

class _ModuleCardWidget extends StatefulWidget {
  final _ModuleData data;
  const _ModuleCardWidget({required this.data});

  @override
  State<_ModuleCardWidget> createState() => _ModuleCardWidgetState();
}

class _ModuleCardWidgetState extends State<_ModuleCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFF059669);
    if (score >= 40) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final score = data.score;
    final scoreColor = _scoreColor(score);

    return GestureDetector(
      onTapDown: (_) {
        _press.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        _press.reverse();
        context.push(data.route);
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final tile = isDark
              ? Color.lerp(data.tileColor, const Color(0xFF1E1E1E), 0.78)!
              : data.tileColor;
          return Container(
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: data.accent.withValues(alpha: isDark ? 0.4 : 0.25),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top: icon bubble + arrow
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: data.accent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: data.accent.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(data.icon, size: 22, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: data.accent,
                    ),
                  ),
                ],
              ),

              // Middle: title + subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: (isDark
                              ? const Color(0xFFB0B0B0)
                              : const Color(0xFF334155))
                          .withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              // Bottom: score chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scoreColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$score',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: scoreColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      '/100',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          );
        }),
      ),
    );
  }
}

/// Small status pulse dot (kept as a public widget for compatibility).
class PulseDot extends StatefulWidget {
  final String status;
  final double size;

  const PulseDot({super.key, required this.status, this.size = 8});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _color() {
    switch (widget.status) {
      case 'safe':
        return AppColors.safe;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return AppColors.danger;
      default:
        return AppColors.white50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _color().withValues(alpha: 0.6 + _ctrl.value * 0.4),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _color().withValues(alpha: 0.4 * _ctrl.value),
              blurRadius: 8 * _ctrl.value,
              spreadRadius: 1 * _ctrl.value,
            ),
          ],
        ),
      ),
    );
  }
}
