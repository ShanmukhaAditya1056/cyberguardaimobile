import 'package:flutter/material.dart';

import '../../../core/i18n/feature_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/services/threat_intel/override_log_service.dart';
import '../../../data/services/threat_intel/threat_intel_source.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/smart_back_button.dart';

/// Feature 2 — Detection Disagreement Engine audit view. Lists every case where
/// sources disagreed or a trusted source overrode the local verdict, with the
/// explainable reasoning for each decision.
class ArbitrationLogScreen extends StatefulWidget {
  const ArbitrationLogScreen({super.key});

  @override
  State<ArbitrationLogScreen> createState() => _ArbitrationLogScreenState();
}

class _ArbitrationLogScreenState extends State<ArbitrationLogScreen> {
  late List<OverrideLogEntry> _entries = OverrideLogService.all();

  Future<void> _clear() async {
    await OverrideLogService.clear();
    setState(() => _entries = OverrideLogService.all());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Text(l.arbitrationTitle, style: AppTextStyles.title),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _clear,
              tooltip: l.arbitrationClear,
            ),
        ],
      ),
      body: _entries.isEmpty
          ? EmptyState(
              icon: Icons.balance_rounded,
              title: l.arbitrationEmptyTitle,
              subtitle: l.arbitrationEmptyBody,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: _entries.length,
              itemBuilder: (_, i) => _LogTile(entry: _entries[i]),
            ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final OverrideLogEntry entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = entry.overrideApplied ? AppColors.critical : AppColors.warning;
    // finalLevel is stored as an enum name; tolerate older English labels.
    final level = ThreatLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == entry.finalLevel.toLowerCase(),
      orElse: () => ThreatLevel.dangerous,
    );
    final levelLabel = l.threatLevelLabel(level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    entry.overrideApplied
                        ? Icons.gavel_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.overrideApplied
                        ? l.arbitrationOverride(levelLabel)
                        : l.arbitrationConflictTitle(levelLabel),
                    style: AppTextStyles.bodyMedium.copyWith(color: color),
                  ),
                ),
                Text('${entry.finalScore}',
                    style: AppTextStyles.titleMedium.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.domain ?? entry.url,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textDark)),
            if (entry.overrideReason != null) ...[
              const SizedBox(height: 6),
              Text(entry.overrideReason!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMedium)),
            ],
            const SizedBox(height: 10),
            ...entry.sourceSummary.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $s',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMedium)),
                )),
            const SizedBox(height: 8),
            Text(DateFormatter.timeAgo(entry.timestamp),
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}
