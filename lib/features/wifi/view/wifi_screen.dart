import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../data/models/wifi_scan_model.dart';
import '../../../data/services/permission_service.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/blink_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/risk_badge.dart';
import '../../../shared/widgets/smart_back_button.dart';
import '../provider/wifi_provider.dart';
import '../../../core/utils/automation_ids.dart';

class WifiScreen extends ConsumerStatefulWidget {
  const WifiScreen({super.key});

  @override
  ConsumerState<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends ConsumerState<WifiScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiProvider);
    final score = state.current?.trustScore ?? 70;

    return GradientScaffold(
      score: score,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Text(AppLocalizations.of(context)!.wifiScanner,
            style: AppTextStyles.title),
        actions: [
          if (!state.isScanning && state.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: AppColors.white50),
              tooltip: AppLocalizations.of(context)!.wifiClearHistoryTooltip,
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, kToolbarHeight + 16, 20, 0),
              child: Column(
                children: [
                  // Current network card
                  _CurrentNetworkCard(
                    scan: state.current,
                    isScanning: state.isScanning,
                    pulseCtrl: _pulseCtrl,
                  ),
                  const SizedBox(height: 16),

                  // Scan button (Blinkit)
                  BlinkButton(
                    label: state.isScanning
                        ? AppLocalizations.of(context)!.scanning
                        : AppLocalizations.of(context)!.wifiScanThis,
                    icon: Icons.wifi_find_rounded,
                    height: 52,
                    autoIdent: AutoId.wifiScanBtn,
                    color: BlinkCard.mintAccent,
                    isLoading: state.isScanning,
                    onTap: state.isScanning
                        ? null
                        : () async {
                            final ok = await PermissionService
                                .requestLocationPermission(context);
                            if (!ok) return;
                            ref.read(wifiProvider.notifier).scanNetwork();
                          },
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorCard(error: state.error!),
                  ],

                  if (state.current != null) ...[
                    const SizedBox(height: 16),
                    _SecurityChecksCard(scan: state.current!),
                    const SizedBox(height: 16),
                    _NetworkDetailsCard(scan: state.current!),
                  ],

                  if (state.history.length > 1) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(AppLocalizations.of(context)!.phishingScanHistory,
                          style: AppTextStyles.titleMedium),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),

          // History list (skip index 0 — already shown as current)
          if (state.history.length > 1)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final scan = state.history[i + 1];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _HistoryTile(scan: scan),
                  );
                },
                childCount: state.history.length - 1,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.wifiClearTitle,
            style: AppTextStyles.titleMedium),
        content: Text(AppLocalizations.of(context)!.wifiClearBody,
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.dialogCancel,
                style: AppTextStyles.body.copyWith(color: AppColors.white50)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(wifiProvider.notifier).clearHistory();
            },
            child: Text(AppLocalizations.of(context)!.wifiClear,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Current Network Card ────────────────────────────────────────────────────

class _CurrentNetworkCard extends StatelessWidget {
  final WifiScanModel? scan;
  final bool isScanning;
  final AnimationController pulseCtrl;

  const _CurrentNetworkCard({
    required this.scan,
    required this.isScanning,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (isScanning) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      AppColors.blue.withValues(alpha: 0.1 + pulseCtrl.value * 0.15),
                  border: Border.all(
                    color:
                        AppColors.blue.withValues(alpha: 0.3 + pulseCtrl.value * 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.wifi_find,
                    color: AppColors.blue, size: 36),
              ),
            ),
            const SizedBox(height: 12),
            Text(l.wifiScanning, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(l.wifiScanningSub,
                style: AppTextStyles.caption),
          ],
        ),
      );
    }

    if (scan == null) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glass,
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: const Icon(Icons.wifi_off,
                  color: AppColors.white50, size: 36),
            ),
            const SizedBox(height: 12),
            Text(l.wifiNoScan, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(l.wifiNoScanSub,
                style: AppTextStyles.caption),
          ],
        ),
      );
    }

    final color = AppColors.forRiskLevel(scan!.riskLevel);
    final gradient = AppGradients.forRiskLevel(scan!.riskLevel);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Signal icon with gradient bg
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _wifiIcon(scan!.signalBars),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan!.ssid.isNotEmpty ? scan!.ssid : l.wifiUnknownSsid,
                      style: AppTextStyles.headline2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RiskBadge(level: scan!.riskLevel),
                        const SizedBox(width: 8),
                        Text(
                          l.wifiTrust(scan!.trustScore),
                          style:
                              AppTextStyles.bodyMedium.copyWith(color: color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Trust bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: scan!.trustScore / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: AppColors.white15,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(l.wifiTrustScore, style: AppTextStyles.caption),
              const Spacer(),
              Text(
                '${scan!.trustScore}/100',
                style: AppTextStyles.captionMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Signal bars row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(
                  label: l.wifiSignal,
                  value: scan!.signalLabel,
                  icon: Icons.signal_wifi_4_bar),
              _MiniStat(
                  label: l.wifiBand, value: scan!.frequencyBand, icon: Icons.radio),
              _MiniStat(
                  label: l.wifiSpeed,
                  value: '${scan!.linkSpeed} Mbps',
                  icon: Icons.speed),
              _MiniStat(
                  label: l.wifiEncrypted,
                  value: scan!.isEncrypted ? l.wifiYes : l.wifiNo,
                  icon: scan!.isEncrypted ? Icons.lock : Icons.lock_open,
                  valueColor:
                      scan!.isEncrypted ? AppColors.safe : AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  IconData _wifiIcon(int bars) {
    switch (bars) {
      case 1:
        return Icons.signal_wifi_0_bar;
      case 2:
        return Icons.network_wifi_1_bar;
      case 3:
        return Icons.network_wifi_2_bar;
      case 4:
        return Icons.network_wifi_3_bar;
      default:
        return Icons.signal_wifi_4_bar;
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white50, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.captionMedium.copyWith(
            color: valueColor ?? AppColors.white,
          ),
        ),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

// ─── Security Checks Card ────────────────────────────────────────────────────

class _SecurityChecksCard extends StatelessWidget {
  final WifiScanModel scan;
  const _SecurityChecksCard({required this.scan});

  Map<String, bool> _parseChecks(List<String> checksList) {
    final checks = <String, bool>{};
    for (final check in checksList) {
      final parts = check.split(':');
      if (parts.length == 2) {
        checks[parts[0]] = parts[1] == 'pass';
      }
    }
    return checks;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final checks = _parseChecks(scan.checks);
    final passed = checks.values.where((v) => v).length;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(l.wifiSecurityChecks, style: AppTextStyles.titleMedium),
              const Spacer(),
              Text(
                l.wifiChecksPassed(passed, checks.length),
                style: AppTextStyles.captionMedium.copyWith(
                  color: _passRatio(checks) > 0.7
                      ? AppColors.safe
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...checks.entries.map((e) => _CheckRow(
                label: _checkLabel(l, e.key),
                passed: e.value,
                description: _checkDescription(l, e.key, scan),
              )),
        ],
      ),
    );
  }

  double _passRatio(Map<String, bool> checks) {
    if (checks.isEmpty) return 1.0;
    return checks.values.where((v) => v).length / checks.length;
  }

  String _checkLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'encrypted':
        return l.wifiCheckEncryption;
      case 'strongSignal':
        return l.wifiCheckSignalStrength;
      case 'dnsHealthy':
        return l.wifiCheckDnsHealth;
      case 'noEvilTwin':
        return l.wifiCheckEvilTwin;
      case 'goodLatency':
        return l.wifiCheckLatency;
      case 'modernBand':
        return l.wifiCheckModernBand;
      default:
        return key;
    }
  }

  String _checkDescription(AppLocalizations l, String key, WifiScanModel scan) {
    switch (key) {
      case 'encrypted':
        return scan.isEncrypted ? l.wifiEncDescYes : l.wifiEncDescNo;
      case 'strongSignal':
        return l.wifiSignalDesc(scan.rssi, scan.signalLabel);
      case 'dnsHealthy':
        return scan.dnsHealthy
            ? l.wifiDnsDescYes(scan.latencyMs)
            : l.wifiDnsDescNo;
      case 'noEvilTwin':
        return l.wifiBssidDesc(scan.bssid);
      case 'goodLatency':
        return scan.latencyMs > 0
            ? l.wifiLatencyDesc(scan.latencyMs)
            : l.wifiLatencyDescNone;
      case 'modernBand':
        return scan.frequencyBand == '5GHz'
            ? l.wifiBandDesc5
            : l.wifiBandDesc24;
      default:
        return '';
    }
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool passed;
  final String description;

  const _CheckRow({
    required this.label,
    required this.passed,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.safe : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              passed ? Icons.check : Icons.close,
              size: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        ),
                if (description.isNotEmpty)
                  Text(description,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Network Details Card ────────────────────────────────────────────────────

class _NetworkDetailsCard extends StatelessWidget {
  final WifiScanModel scan;
  const _NetworkDetailsCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.router_outlined,
                  size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(l.wifiNetworkDetails, style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(l.wifiDetailSsid, scan.ssid.isNotEmpty ? scan.ssid : l.wifiUnknown),
          _DetailRow(l.wifiDetailBssid, scan.bssid),
          _DetailRow(
              l.wifiDetailIp, scan.ipAddress.isNotEmpty ? scan.ipAddress : l.wifiNA),
          _DetailRow(l.wifiDetailFrequency, '${scan.frequency} MHz'),
          _DetailRow(l.wifiDetailBand, scan.frequencyBand),
          _DetailRow(l.wifiDetailLinkSpeed, '${scan.linkSpeed} Mbps'),
          _DetailRow(l.wifiDetailSignal, '${scan.rssi} dBm'),
          _DetailRow(l.wifiDetailDnsLatency,
              scan.latencyMs > 0 ? '${scan.latencyMs}ms' : l.wifiNA),
          _DetailRow(l.wifiDetailScanned, DateFormatter.timeAgo(scan.timestamp)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? Colors.white : const Color(0xFF111111);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed-width label column so every value lines up vertically.
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.body),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: valueColor),
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Tile ────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final WifiScanModel scan;
  const _HistoryTile({required this.scan});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forRiskLevel(scan.riskLevel);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.wifi, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.ssid.isNotEmpty ? scan.ssid : AppLocalizations.of(context)!.wifiUnknownSsid,
                  style:
                      AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.timeAgo(scan.timestamp),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RiskBadge(level: scan.riskLevel, compact: true),
              const SizedBox(height: 2),
              Text(
                '${scan.trustScore}%',
                style: AppTextStyles.captionMedium.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Error Card ──────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.danger.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
