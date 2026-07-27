import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/i18n/feature_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/threat_level_style.dart';
import '../../../data/services/threat_intel/risk_engine.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/smart_back_button.dart';
import '../provider/fusion_provider.dart';
import '../../../core/utils/automation_ids.dart';

/// Feature 4 — Threat Intelligence Fusion. Paste any URL and see the unified
/// 0-100 score, category band, confidence and per-source attribution.
class ThreatScanScreen extends ConsumerStatefulWidget {
  const ThreatScanScreen({super.key});

  @override
  ConsumerState<ThreatScanScreen> createState() => _ThreatScanScreenState();
}

class _ThreatScanScreenState extends ConsumerState<ThreatScanScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(fusionScanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Text(l.fusionTitle, style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.fusionPrompt,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textDark)),
                const SizedBox(height: 12),
                Semantics(
                  identifier: AutoId.fusionUrlInput,
                  textField: true,
                  container: true,
                  child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: AppTextStyles.body.copyWith(color: AppColors.textDark),
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/login',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  onSubmitted: (v) =>
                      ref.read(fusionScanProvider.notifier).scan(v),
                ),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: l.fusionRunScan,
                  icon: Icons.travel_explore_rounded,
                  gradient: AppGradients.blue,
                  autoIdent: AutoId.fusionScanBtn,
                  isLoading: state.isScanning,
                  onTap: () =>
                      ref.read(fusionScanProvider.notifier).scan(_ctrl.text),
                ),
              ],
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(state.error!,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
          ],
          if (state.result != null) ...[
            const SizedBox(height: 20),
            _ResultView(risk: state.result!),
          ],
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final LinkRisk risk;
  const _ResultView({required this.risk});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final level = risk.level;
    final color = ThreatLevelStyle.color(level);
    final fusion = risk.fusion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircularPercentIndicator(
            radius: 84,
            lineWidth: 12,
            animation: true,
            percent: (risk.riskScore / 100).clamp(0.0, 1.0),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: AppColors.divider,
            progressColor: color,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${risk.riskScore}',
                    style: AppTextStyles.display.copyWith(color: color)),
                Text(l.fusionUnified,
                    style: AppTextStyles.scoreLabel.copyWith(color: color)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ThreatLevelStyle.icon(level), size: 16, color: color),
                const SizedBox(width: 6),
                Text(l.threatBandLabel(level),
                    style: AppTextStyles.captionMedium.copyWith(color: color)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (fusion.overrideApplied)
          _banner(fusion.overrideReason ?? l.warnOverrideDefault,
              AppColors.critical, Icons.gavel_rounded),
        if (fusion.hasConflict && !fusion.overrideApplied)
          _banner(l.fusionConflict, AppColors.warning,
              Icons.info_outline_rounded),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l.fusionSourceAttribution,
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textLight)),
                  const Spacer(),
                  Text(l.confidencePct((fusion.confidence * 100).round()),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textLight)),
                ],
              ),
              const SizedBox(height: 12),
              ...fusion.verdicts.map((v) {
                final c = ThreatLevelStyle.color(v.level);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            '${v.sourceName} · ${l.fusionTrust(v.trustWeight)}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textDark)),
                      ),
                      Text('${v.maliciousScore}',
                          style: AppTextStyles.bodyMedium.copyWith(color: c)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.fusionExplanation,
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textLight)),
              const SizedBox(height: 10),
              ...fusion.explanation.take(8).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $e',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMedium)),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _banner(String text, Color color, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: AppTextStyles.bodySmall.copyWith(color: color))),
          ],
        ),
      );
}
