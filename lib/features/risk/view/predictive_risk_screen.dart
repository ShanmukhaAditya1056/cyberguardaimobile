import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/i18n/feature_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/repositories/predictive_risk_repository.dart';
import '../../../data/services/predictive_risk_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/smart_back_button.dart';
import '../provider/risk_provider.dart';

/// Feature 5 — Predictive Risk dashboard: personal risk score, contributing
/// factors, attack forecast, recommendations and a 7-day risk timeline.
class PredictiveRiskScreen extends ConsumerWidget {
  const PredictiveRiskScreen({super.key});

  Color _bandColor(RiskBand b) => switch (b) {
        RiskBand.high => AppColors.danger,
        RiskBand.medium => AppColors.warning,
        RiskBand.low => AppColors.safe,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(riskProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Text(l.riskTitle, style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(riskProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading && state.assessment == null
          ? const Center(child: CircularProgressIndicator())
          : state.assessment == null
              ? Center(child: Text(state.error ?? l.riskNoData))
              : _Body(
                  assessment: state.assessment!,
                  timeline: state.timeline,
                  bandColor: _bandColor,
                ),
    );
  }
}

class _Body extends StatelessWidget {
  final RiskAssessment assessment;
  final List<RiskPoint> timeline;
  final Color Function(RiskBand) bandColor;
  const _Body({
    required this.assessment,
    required this.timeline,
    required this.bandColor,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = bandColor(assessment.band);
    final bandLabel = l.riskBandLabel(assessment.band);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Center(
          child: CircularPercentIndicator(
            radius: 90,
            lineWidth: 13,
            animation: true,
            percent: (assessment.riskScore / 100).clamp(0.0, 1.0),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: AppColors.divider,
            progressColor: color,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${assessment.riskScore}',
                    style: AppTextStyles.displayLarge
                        .copyWith(color: color, fontSize: 44)),
                Text(l.riskSuffix(bandLabel),
                    style: AppTextStyles.scoreLabel.copyWith(color: color)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Threat Forecast ────────────────────────────────────────────
        Text(l.riskForecastTitle,
            style: AppTextStyles.headline2.copyWith(color: AppColors.textDark)),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: assessment.forecast
                .map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(l.forecastCategoryLabel(f.category),
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textDark)),
                          ),
                          _likelihoodChip(l, f.likelihood),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),

        // ── Risk Timeline ──────────────────────────────────────────────
        if (timeline.isNotEmpty) ...[
          Text(l.riskTimelineTitle,
              style:
                  AppTextStyles.headline2.copyWith(color: AppColors.textDark)),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: _Timeline(points: timeline, bandColor: bandColor),
          ),
          const SizedBox(height: 20),
        ],

        // ── Contributing Factors ───────────────────────────────────────
        if (assessment.factors.isNotEmpty) ...[
          Text(l.riskWhyTitle(bandLabel.toLowerCase()),
              style:
                  AppTextStyles.headline2.copyWith(color: AppColors.textDark)),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: assessment.factors
                  .map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                size: 16, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.riskFactorTitle(f.type),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textDark)),
                                  Text(l.riskFactorDetail(f),
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textMedium)),
                                ],
                              ),
                            ),
                            Text('+${f.contribution}',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.danger)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Recommendations ────────────────────────────────────────────
        Text(l.riskRecommendations,
            style: AppTextStyles.headline2.copyWith(color: AppColors.textDark)),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: assessment.recommendations
                .map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: AppColors.safe),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(l.recommendationText(r),
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMedium)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _likelihoodChip(AppLocalizations l, RiskBand b) {
    final c = bandColor(b);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(l.riskBandLabel(b),
          style: AppTextStyles.captionMedium.copyWith(color: c)),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<RiskPoint> points;
  final Color Function(RiskBand) bandColor;
  const _Timeline({required this.points, required this.bandColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: points.map((p) {
          final c = bandColor(RiskBand.fromScore(p.score));
          final h = (p.score / 100 * 70).clamp(4.0, 70.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${p.score}',
                  style: AppTextStyles.caption.copyWith(color: c, fontSize: 10)),
              const SizedBox(height: 4),
              Container(
                width: 16,
                height: h,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text('${p.date.day}/${p.date.month}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textLight, fontSize: 9)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
