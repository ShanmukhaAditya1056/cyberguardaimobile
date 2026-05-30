import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../provider/dashboard_provider.dart';

class StatsRow extends StatelessWidget {
  final DashboardStats stats;

  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = [
      _StatItem(
        label: l.statTotalScans,
        value: '${stats.totalScans}',
        icon: Icons.shield_outlined,
        tile: const Color(0xFFE0EBFF),
        accent: const Color(0xFF3B82F6),
      ),
      _StatItem(
        label: l.statThreats,
        value: '${stats.threatsFound}',
        icon: stats.threatsFound > 0
            ? Icons.warning_amber_rounded
            : Icons.task_alt_rounded,
        tile: stats.threatsFound > 0
            ? const Color(0xFFFFD9DE)
            : const Color(0xFFD4F5E2),
        accent: stats.threatsFound > 0
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
      ),
      _StatItem(
        label: l.statLastScan,
        value: stats.lastScanDate != null
            ? DateFormatter.timeAgo(stats.lastScanDate!)
            : l.statNever,
        icon: Icons.schedule_rounded,
        tile: const Color(0xFFFFF3D6),
        accent: const Color(0xFFCA8A04),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _StatCard(item: items[i])),
            if (i < items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color tile;
  final Color accent;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.tile,
    required this.accent,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tile = isDark
        ? Color.lerp(item.tile, const Color(0xFF121212), 0.82)!
        : item.tile;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tile,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: item.accent.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, color: Colors.white, size: 15),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
