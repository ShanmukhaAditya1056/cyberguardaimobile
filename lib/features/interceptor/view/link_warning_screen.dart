import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/i18n/feature_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/threat_intel/risk_engine.dart';
import '../../../data/services/threat_intel/threat_intel_source.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../provider/interceptor_provider.dart';

/// The ⚠ warning shown before the user reaches a risky site (Feature 1).
class LinkWarningScreen extends ConsumerWidget {
  const LinkWarningScreen({super.key});

  Color _levelColor(ThreatLevel l) => switch (l) {
        ThreatLevel.critical => AppColors.critical,
        ThreatLevel.dangerous => AppColors.danger,
        ThreatLevel.suspicious => AppColors.warning,
        ThreatLevel.safe => AppColors.safe,
      };

  LinearGradient _levelGradient(ThreatLevel l) => switch (l) {
        ThreatLevel.critical => AppGradients.critical,
        ThreatLevel.dangerous => AppGradients.danger,
        ThreatLevel.suspicious => AppGradients.warning,
        ThreatLevel.safe => AppGradients.safe,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final risk = ref.watch(interceptorProvider.select((s) => s.pending));

    if (risk == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && context.canPop()) context.pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final color = _levelColor(risk.level);
    final isBlock = risk.action == LinkAction.block;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(interceptorProvider.notifier).dismiss();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(l, risk.level, color),
                const SizedBox(height: 24),
                _riskRing(l, risk.riskScore, color),
                const SizedBox(height: 24),
                if (risk.fusion.overrideApplied) _overrideBanner(l, risk),
                if (risk.fusion.hasConflict && !risk.fusion.overrideApplied)
                  _conflictBanner(l),
                _urlCard(l, risk),
                const SizedBox(height: 16),
                _reasonsCard(l, risk),
                const SizedBox(height: 16),
                _sourcesCard(l, risk),
                const SizedBox(height: 28),
                _actions(context, ref, l, risk, isBlock),
                const SizedBox(height: 12),
                _privacyNote(l),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l, ThreatLevel level, Color color) {
    return Column(
      children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 56),
        const SizedBox(height: 12),
        Text(
          level == ThreatLevel.critical || level == ThreatLevel.dangerous
              ? l.warnDangerousTitle
              : l.warnSuspiciousTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headline.copyWith(color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _riskRing(AppLocalizations l, int score, Color color) {
    return Center(
      child: CircularPercentIndicator(
        radius: 92,
        lineWidth: 12,
        animation: true,
        animationDuration: 900,
        percent: (score / 100).clamp(0.0, 1.0),
        circularStrokeCap: CircularStrokeCap.round,
        backgroundColor: AppColors.divider,
        progressColor: color,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$score%',
                style: AppTextStyles.display.copyWith(color: color)),
            Text(l.warnRiskScore,
                style: AppTextStyles.scoreLabel.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _overrideBanner(AppLocalizations l, LinkRisk risk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.criticalLightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_rounded, color: AppColors.critical, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              risk.fusion.overrideReason ?? l.warnOverrideDefault,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.criticalDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conflictBanner(AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.warnConflict,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.warningDark)),
          ),
        ],
      ),
    );
  }

  Widget _urlCard(AppLocalizations l, LinkRisk risk) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded,
                  size: 16, color: AppColors.textLight),
              const SizedBox(width: 6),
              Text(l.warnDestination,
                  style:
                      AppTextStyles.label.copyWith(color: AppColors.textLight)),
              const Spacer(),
              if (risk.sourceApp != null)
                Text(l.warnVia(risk.sourceApp!),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 8),
          Text(risk.url,
              style: AppTextStyles.mono.copyWith(color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _reasonsCard(AppLocalizations l, LinkRisk risk) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.warnWhyFlagged,
              style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
          const SizedBox(height: 12),
          ...risk.reasons.take(6).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle,
                            size: 6, color: AppColors.textMedium),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textMedium)),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _sourcesCard(AppLocalizations l, LinkRisk risk) {
    final verdicts = risk.fusion.verdicts;
    if (verdicts.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.warnSources,
                  style:
                      AppTextStyles.label.copyWith(color: AppColors.textLight)),
              const Spacer(),
              Text(l.confidencePct((risk.fusion.confidence * 100).round()),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: verdicts.map((v) {
              final c = _levelColor(v.level);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.withValues(alpha: 0.3)),
                ),
                child: Text('${v.sourceName} · ${l.threatLevelLabel(v.level)}',
                    style: AppTextStyles.captionMedium.copyWith(color: c)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, WidgetRef ref, AppLocalizations l,
      LinkRisk risk, bool isBlock) {
    return Column(
      children: [
        GradientButton(
          label: l.warnGoBack,
          icon: Icons.arrow_back_rounded,
          gradient: AppGradients.safe,
          onTap: () {
            ref.read(interceptorProvider.notifier).dismiss();
            if (context.canPop()) context.pop();
          },
        ),
        const SizedBox(height: 12),
        GradientButton(
          label: l.warnContinue,
          icon: Icons.open_in_new_rounded,
          gradient: _levelGradient(risk.level),
          onTap: () => _continueAnyway(context, ref, l, isBlock),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () async {
            await ref.read(interceptorProvider.notifier).report();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.warnReported)),
              );
            }
          },
          icon: const Icon(Icons.flag_outlined, size: 18),
          label: Text(l.warnReport),
        ),
      ],
    );
  }

  Future<void> _continueAnyway(BuildContext context, WidgetRef ref,
      AppLocalizations l, bool isBlock) async {
    if (isBlock) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.warnOpenDangerousTitle),
          content: Text(l.warnOpenDangerousBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.commonCancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.warnOpenAnyway,
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await ref.read(interceptorProvider.notifier).continueAnyway();
    if (context.mounted && context.canPop()) context.pop();
  }

  Widget _privacyNote(AppLocalizations l) {
    return Text(
      l.warnPrivacyNote,
      textAlign: TextAlign.center,
      style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
    );
  }
}
