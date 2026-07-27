import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/i18n/feature_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/screenshot_scam_classifier.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/smart_back_button.dart';
import '../provider/screenshot_provider.dart';
import '../../../core/utils/automation_ids.dart';

/// Feature 3 — Screenshot AI Scanner. Upload a screenshot of a suspicious page;
/// on-device OCR extracts the text and the classifier flags scam indicators.
class ScreenshotScannerScreen extends ConsumerWidget {
  const ScreenshotScannerScreen({super.key});

  Color _color(int p) {
    if (p >= 70) return AppColors.critical;
    if (p >= 40) return AppColors.danger;
    if (p >= 20) return AppColors.warning;
    return AppColors.safe;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(screenshotProvider);
    final notifier = ref.read(screenshotProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Text(l.screenshotTitle, style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.screenshotPrompt,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(l.screenshotDesc, style: AppTextStyles.caption),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: l.screenshotGallery,
                        icon: Icons.photo_library_outlined,
                        gradient: AppGradients.blue,
                        autoIdent: AutoId.screenshotPickBtn,
                        isLoading: state.isScanning,
                        onTap: () =>
                            notifier.pickAndScan(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: l.screenshotCamera,
                        icon: Icons.camera_alt_outlined,
                        gradient: AppGradients.safe,
                        isLoading: state.isScanning,
                        onTap: () => notifier.pickAndScan(ImageSource.camera),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (state.imagePath != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(state.imagePath!),
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(state.error!,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
          ],
          if (state.result != null) ...[
            const SizedBox(height: 20),
            _Result(result: state.result!, color: _color),
          ],
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final ScreenshotScanResult result;
  final Color Function(int) color;
  const _Result({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = color(result.scamProbability);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            animation: true,
            percent: (result.scamProbability / 100).clamp(0.0, 1.0),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: AppColors.divider,
            progressColor: c,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${result.scamProbability}%',
                    style: AppTextStyles.display.copyWith(color: c, fontSize: 32)),
                Text(l.screenshotScam,
                    style: AppTextStyles.scoreLabel.copyWith(color: c)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            result.isScam
                ? l.scamCategoryLabel(result.category)
                : l.screenshotLooksClean,
            style: AppTextStyles.titleMedium.copyWith(color: c),
          ),
        ),
        if (result.detectedBrand != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(l.screenshotBrand(result.detectedBrand!),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMedium)),
          ),
        ],
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.screenshotIndicators,
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textLight)),
              const SizedBox(height: 10),
              ...result.reasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${l.scamReasonText(r)}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMedium)),
                  )),
            ],
          ),
        ),
        if (result.textPreview.isNotEmpty) ...[
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.screenshotExtractedText,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textLight)),
                const SizedBox(height: 8),
                Text(result.textPreview,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMedium)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
