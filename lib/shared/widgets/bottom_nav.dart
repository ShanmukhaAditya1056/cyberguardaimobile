import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}

class CyberGuardBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadAlerts;

  const CyberGuardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadAlerts = 0,
  });

  @override
  State<CyberGuardBottomNav> createState() => _CyberGuardBottomNavState();
}

class _CyberGuardBottomNavState extends State<CyberGuardBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pillAnim;
  int _prevIndex = 0;

  static const _items = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    _NavItem(Icons.link_outlined, Icons.link, 'Phishing'),
    _NavItem(Icons.bug_report_outlined, Icons.bug_report, 'Scanner'),
    _NavItem(Icons.lock_outlined, Icons.lock, 'Breach'),
    _NavItem(Icons.wifi_outlined, Icons.wifi, 'Wi-Fi'),
    _NavItem(Icons.notifications_outlined, Icons.notifications, 'Alerts'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pillAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _prevIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant CyberGuardBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prevIndex = old.currentIndex;
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
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / _items.length;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70 + MediaQuery.of(context).padding.bottom,
          decoration: const BoxDecoration(
            color: Color(0xCC0A1628),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Stack(
              children: [
                // Animated pill indicator
                AnimatedBuilder(
                  animation: _pillAnim,
                  builder: (_, __) {
                    final from = _prevIndex * itemWidth + itemWidth / 2 - 28;
                    final to = widget.currentIndex * itemWidth + itemWidth / 2 - 28;
                    final x = lerpDouble(from, to, _pillAnim.value)!;
                    return Positioned(
                      top: 8,
                      left: x,
                      child: Container(
                        width: 56,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppGradients.blue,
                          borderRadius: BorderRadius.circular(1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blueGlow,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Nav items
                Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isActive = index == widget.currentIndex;
                    final showBadge =
                        index == 5 && widget.unreadAlerts > 0;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onTap(index);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 14),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: ShaderMask(
                                    key: ValueKey(isActive),
                                    shaderCallback: (bounds) => (isActive
                                            ? AppGradients.blue
                                            : const LinearGradient(
                                                colors: [
                                                  AppColors.white30,
                                                  AppColors.white30
                                                ],
                                              ))
                                        .createShader(bounds),
                                    child: Icon(
                                      isActive ? item.activeIcon : item.icon,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (showBadge)
                                  Positioned(
                                    top: -4,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: AppColors.critical,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF0A1628),
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        widget.unreadAlerts > 9
                                            ? '9+'
                                            : '${widget.unreadAlerts}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: AppTextStyles.caption.copyWith(
                                color: isActive
                                    ? AppColors.blue
                                    : AppColors.white30,
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
