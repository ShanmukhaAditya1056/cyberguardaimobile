import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../data/models/alert_model.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/blink_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/smart_back_button.dart';
import '../provider/alerts_provider.dart';
import '../../../core/utils/automation_ids.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alertsProvider);

    return GradientScaffold(
      score: 75,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Row(
          children: [
            Text(AppLocalizations.of(context)!.alerts,
                style: AppTextStyles.title),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppGradients.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: AppTextStyles.badge.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (state.alerts.isNotEmpty) ...[
            if (state.unreadCount > 0)
              TextButton(
                onPressed: () =>
                    ref.read(alertsProvider.notifier).markAllRead(),
                child: Text(AppLocalizations.of(context)!.alertsMarkAllRead,
                    style: AppTextStyles.captionMedium
                        .copyWith(color: AppColors.blue)),
              ),
            Semantics(
              identifier: AutoId.alertsClearBtn,
              button: true,
              container: true,
              label: 'Clear all alerts',
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: AppColors.white50),
                onPressed: () => _confirmClear(context, ref),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 16, 20, 0),
            child: _FilterChips(
              selected: state.filter,
              onSelect: (f) =>
                  ref.read(alertsProvider.notifier).setFilter(f),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.isLoading
                ? const _LoadingList()
                : state.filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: state.filter == 'all'
                            ? AppLocalizations.of(context)!.noAlerts
                            : AppLocalizations.of(context)!.alertsNoFilter(state.filter),
                        subtitle: state.filter == 'all'
                            ? AppLocalizations.of(context)!.noAlertsDescription
                            : AppLocalizations.of(context)!.alertsTryDifferent,
                        iconColor: AppColors.blue,
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: state.filtered.length,
                        itemBuilder: (ctx, i) {
                          final alert = state.filtered[i];
                          return Dismissible(
                            key: Key(alert.id),
                            direction: DismissDirection.endToStart,
                            background: _DismissBackground(),
                            onDismissed: (_) => ref
                                .read(alertsProvider.notifier)
                                .deleteAlert(alert.id),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: _AlertCard(
                                alert: alert,
                                onTap: () {
                                  ref
                                      .read(alertsProvider.notifier)
                                      .markRead(alert.id);
                                  _routeForAlert(context, alert);
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _routeForAlert(BuildContext context, AlertModel alert) {
    switch (alert.module) {
      case 'phishing':
        context.push('/phishing');
        break;
      case 'malware':
        context.push('/malware');
        break;
      case 'breach':
        context.push('/breach');
        break;
      case 'wifi':
        context.push('/wifi');
        break;
      case 'settings':
        context.push('/settings');
        break;
      default:
        // Unknown module — fall back to dashboard, never crash on bad data.
        context.push('/dashboard');
    }
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.alertsClearTitle,
            style: AppTextStyles.titleMedium),
        content: Text(AppLocalizations.of(context)!.alertsClearBody,
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.dialogCancel,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.white50)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(alertsProvider.notifier).clearAll();
            },
            child: Text(AppLocalizations.of(context)!.dialogClearAll,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final filters = [
      ('all', l.alertsFilterAll, AppColors.blue),
      ('phishing', l.alertsFilterPhishing, AppColors.warning),
      ('malware', l.alertsFilterMalware, AppColors.danger),
      ('breach', l.alertsFilterBreach, AppColors.critical),
      ('wifi', l.alertsFilterWifi, AppColors.safe),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          return GestureDetector(
            onTap: () => onSelect(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? f.$3.withValues(alpha: 0.2)
                    : AppColors.glass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? f.$3.withValues(alpha: 0.6)
                      : AppColors.glassBorder,
                  width: isSelected ? 1 : 0.5,
                ),
              ),
              child: Text(
                f.$2,
                style: AppTextStyles.captionMedium.copyWith(
                  color: isSelected ? f.$3 : AppColors.white50,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  ({Color tile, Color accent}) _palette() {
    switch (alert.type) {
      case 'critical':
      case 'high':
        return (tile: BlinkCard.roseTile, accent: BlinkCard.roseAccent);
      case 'medium':
        return (tile: BlinkCard.peachTile, accent: BlinkCard.peachAccent);
      default:
        return (tile: BlinkCard.mintTile, accent: BlinkCard.mintAccent);
    }
  }

  IconData _alertIcon() {
    switch (alert.type) {
      case 'critical':
        return Icons.dangerous_rounded;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final isUnread = !alert.isRead;

    return BlinkCard(
      tile: p.tile,
      accent: p.accent,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_alertIcon(), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: BlinkCard.textPrimary,
                          fontSize: 14.5,
                          fontWeight:
                              isUnread ? FontWeight.w800 : FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: BlinkCard.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        alert.module.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: p.accent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormatter.timeAgo(alert.timestamp),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: BlinkCard.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dismiss Background ───────────────────────────────────────────────────────

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.4), width: 0.5),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline,
          color: AppColors.danger, size: 22),
    );
  }
}

// ─── Loading List ─────────────────────────────────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: const [
        ShimmerListTile(),
        ShimmerListTile(),
        ShimmerListTile(),
        ShimmerListTile(),
      ],
    );
  }
}
