import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/platform/app_platform.dart';
import '../../data/services/hive_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/blink_card.dart';
import '../../core/utils/automation_ids.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isGrantingPermissions = false;

  late List<_OnboardingPage> _pages = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = _buildPages(context);
  }

  List<_OnboardingPage> _buildPages(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      _OnboardingPage(
        tile: BlinkCard.mintTile,
        accent: BlinkCard.mintAccent,
        icon: Icons.security_rounded,
        title: l.onboardAiSecurityTitle,
        description: l.onboardAiSecurityDesc,
      ),
      _OnboardingPage(
        tile: BlinkCard.blueTile,
        accent: BlinkCard.blueAccent,
        icon: Icons.link_rounded,
        title: l.onboardPhishingTitle,
        description: l.onboardPhishingDesc,
      ),
      _OnboardingPage(
        tile: BlinkCard.peachTile,
        accent: BlinkCard.peachAccent,
        icon: Icons.bug_report_rounded,
        title: l.onboardMalwareTitle,
        description: l.onboardMalwareDesc,
      ),
      _OnboardingPage(
        tile: BlinkCard.roseTile,
        accent: BlinkCard.roseAccent,
        icon: Icons.lock_person_rounded,
        title: l.onboardBreachTitle,
        description: l.onboardBreachDesc,
      ),
      _OnboardingPage(
        tile: BlinkCard.lavenderTile,
        accent: BlinkCard.lavenderAccent,
        icon: Icons.verified_user_rounded,
        title: l.onboardPermsTitle,
        description: l.onboardPermsDesc,
      ),
    ];
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _grantPermissionsAndFinish();
    }
  }

  Future<void> _grantPermissionsAndFinish() async {
    setState(() => _isGrantingPermissions = true);
    try {
      // Only Android and iOS have runtime permissions to request. On the
      // desktops there is nothing to prompt for, and permission_handler has no
      // Linux implementation, so this would throw instead of returning.
      if (AppPlatform.hasRuntimePermissions) {
        if (AppPlatform.canReadSms) await Permission.sms.request();
        await Permission.location.request();
        await Permission.notification.request();
      }
    } finally {
      if (mounted) {
        final settings = HiveService.getSettings();
        await HiveService.saveSettings(
            settings.copyWith(onboardingComplete: true));
        if (mounted) context.go('/dashboard');
      }
    }
  }

  void _skip() async {
    final settings = HiveService.getSettings();
    await HiveService.saveSettings(settings.copyWith(onboardingComplete: true));
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final currentAccent = _pages[_currentPage].accent;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPageView(page: _pages[i]),
          ),

          // Skip
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  identifier: AutoId.onboardingSkip,
                  button: true,
                  container: true,
                  child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    AppLocalizations.of(context)!.onboardSkip,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xB3FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? currentAccent
                                : const Color(0x4DFFFFFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    BlinkButton(
                      autoIdent: AutoId.onboardingNext,
                      label: _currentPage == _pages.length - 1
                          ? AppLocalizations.of(context)!.onboardGrantStart
                          : AppLocalizations.of(context)!.onboardContinue,
                      icon: _currentPage == _pages.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      color: currentAccent,
                      onTap: _nextPage,
                      isLoading: _isGrantingPermissions,
                      height: 54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final Color tile;
  final Color accent;
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.tile,
    required this.accent,
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 160),
      child: Column(
        children: [
          // Big icon hero
          Expanded(
            flex: 3,
            child: Center(
              child: _AnimatedIcon(icon: page.icon, accent: page.accent),
            ),
          ),

          // Blinkit pastel card with copy
          Expanded(
            flex: 2,
            child: BlinkCard(
              tile: page.tile,
              accent: page.accent,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    page.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: BlinkCard.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    page.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: BlinkCard.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color accent;

  const _AnimatedIcon({required this.icon, required this.accent});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedIcon old) {
    super.didUpdateWidget(old);
    if (old.icon != widget.icon) {
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
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: widget.accent,
              borderRadius: BorderRadius.circular(44),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(widget.icon, size: 78, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
