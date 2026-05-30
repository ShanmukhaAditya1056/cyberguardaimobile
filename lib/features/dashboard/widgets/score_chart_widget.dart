import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/score_entry_model.dart';
import '../../../shared/widgets/glass_card.dart';

/// Zomato-clean 7-day security score line chart.
///
/// - Reads a list of ScoreEntryModel from Hive.
/// - Groups by day (today − 6 … today), uses 50 as a neutral fallback for
///   days with no data so the line never crashes / breaks.
/// - Never crashes on empty history — shows a flat line with overlay text.
class ScoreChartWidget extends StatelessWidget {
  final List<ScoreEntryModel> history;

  const ScoreChartWidget({super.key, required this.history});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Builds a strict 7-day series ending today.
  List<_DayPoint> _buildSeries() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Bucket history by date.
    final byDay = <DateTime, int>{};
    for (final entry in history) {
      final d = entry.date;
      final key = DateTime(d.year, d.month, d.day);
      // If we already have a score for that day, prefer the latest.
      final existing = byDay[key];
      final score = entry.unifiedScore.clamp(0, 100);
      if (existing == null) {
        byDay[key] = score;
      } else {
        byDay[key] = score; // override with later entry
      }
    }

    return List.generate(7, (i) {
      final day = todayDate.subtract(Duration(days: 6 - i));
      final label = _dayLabels[day.weekday - 1];
      final raw = byDay[day];
      // null = no data → 50 neutral fallback (so chart stays plotted)
      final score = (raw ?? 50).clamp(0, 100).toDouble();
      return _DayPoint(day: day, label: label, score: score, hasData: raw != null);
    });
  }

  Color _colorFor(int score) {
    if (score >= 70) return AppColors.safe;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final series = _buildSeries();
    final scoresWithData =
        series.where((p) => p.hasData).map((p) => p.score.toInt()).toList();
    final hasAnyData = scoresWithData.isNotEmpty;

    final avg = hasAnyData
        ? (scoresWithData.reduce((a, b) => a + b) / scoresWithData.length)
            .round()
        : 0;
    final best = hasAnyData
        ? scoresWithData.reduce((a, b) => a > b ? a : b)
        : 0;
    final worst = hasAnyData
        ? scoresWithData.reduce((a, b) => a < b ? a : b)
        : 0;
    final currentScore =
        hasAnyData ? series.last.score.toInt() : 50;
    final lineColor = _colorFor(currentScore);

    final spots = series
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        radius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Text(
                  'Security Score — Last 7 Days',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOn(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row (Avg / Best / Worst)
            Row(
              children: [
                _StatPill(
                  label: 'Avg',
                  value: hasAnyData ? '$avg' : '—',
                  color: _colorFor(avg),
                ),
                const SizedBox(width: 10),
                _StatPill(
                  label: 'Best',
                  value: hasAnyData ? '$best' : '—',
                  color: AppColors.safe,
                ),
                const SizedBox(width: 10),
                _StatPill(
                  label: 'Worst',
                  value: hasAnyData ? '$worst' : '—',
                  color: hasAnyData ? _colorFor(worst) : AppColors.textLight,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),

            // Chart
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFF5F5F5),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= series.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  series[idx].label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (series.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.textDark,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          getTooltipItems: (spots) => spots.map((s) {
                            final idx = s.x.toInt();
                            final label = (idx >= 0 && idx < series.length)
                                ? series[idx].label
                                : '';
                            return LineTooltipItem(
                              '$label · ${s.y.toInt()}',
                              const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.25,
                          color: lineColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, idx) {
                              final hasData = series[idx].hasData;
                              return FlDotCirclePainter(
                                radius: hasData ? 5 : 3,
                                color: hasData ? lineColor : AppColors.border,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withValues(alpha: 0.10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!hasAnyData)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.border, width: 1),
                        ),
                        child: const Text(
                          'Start scanning to see trends',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPoint {
  final DateTime day;
  final String label;
  final double score;
  final bool hasData;

  _DayPoint({
    required this.day,
    required this.label,
    required this.score,
    required this.hasData,
  });
}
