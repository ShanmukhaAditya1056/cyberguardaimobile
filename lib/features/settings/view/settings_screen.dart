import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/smart_back_button.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../data/services/report_export_service.dart';
import '../../../data/services/sms_stream_service.dart';
import '../provider/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _apiKeyVisible = false;
  bool _apiKeyEditing = false;
  bool _smsLive = SmsStreamService.isRunning;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiKeyCtrl.text = settings.hibpApiKey;
  }

  Future<void> _toggleSmsLive(bool value) async {
    if (value) {
      final ok = await SmsStreamService.start();
      if (!mounted) return;
      setState(() => _smsLive = ok);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.smsPermissionDenied),
        ));
      }
    } else {
      await SmsStreamService.stop();
      if (!mounted) return;
      setState(() => _smsLive = false);
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l = AppLocalizations.of(context)!;

    return GradientScaffold(
      score: 80,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SmartBackButton(),
        title: Text(l.settings, style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 16, 20, 100),
        children: [
          // ── Notifications ──────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.notifications_outlined, title: l.notifications),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _ToggleTile(
                  title: l.settingRealTimeAlerts,
                  subtitle: l.settingRealTimeAlertsSub,
                  value: settings.realTimeAlerts,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setRealTimeAlerts(v),
                ),
                _Divider(),
                _ToggleTile(
                  title: l.settingClipboardScan,
                  subtitle: l.settingClipboardScanSub,
                  value: settings.clipboardScan,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setClipboardScan(v),
                ),
                _Divider(),
                _ToggleTile(
                  title: l.settingWifiAutoScan,
                  subtitle: l.settingWifiAutoScanSub,
                  value: settings.wifiAutoScan,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setWifiAutoScan(v),
                ),
                _Divider(),
                _ToggleTile(
                  title: l.liveSmsGuard,
                  subtitle: l.liveSmsGuardSubtitle,
                  value: _smsLive,
                  onChanged: _toggleSmsLive,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Language ───────────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.translate_rounded, title: l.language),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _LanguagePicker(
              current: ref.watch(localeProvider),
              onChanged: (l) =>
                  ref.read(localeProvider.notifier).setLocale(l),
            ),
          ),

          const SizedBox(height: 20),

          // ── Scan Frequency ─────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.schedule_outlined, title: l.settingsAutoScanFrequency),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  // Default stored value is the friendly string "Weekly"
                  // (which doesn't parse) — map known labels to hours, then
                  // fall back to 24h if the value still isn't numeric.
                  double hoursFromSetting(String raw) {
                    switch (raw.trim().toLowerCase()) {
                      case 'hourly':
                        return 1.0;
                      case 'daily':
                        return 24.0;
                      case 'weekly':
                        return 24.0; // treat as daily so the UX is usable
                      case 'monthly':
                        return 72.0;
                      default:
                        return double.tryParse(raw) ?? 24.0;
                    }
                  }

                  final hours =
                      hoursFromSetting(settings.autoScanFrequency).clamp(1.0, 72.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.settingsBackgroundScanEvery(hours.round()),
                        style: AppTextStyles.bodyMedium
                            ,
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.blue,
                          inactiveTrackColor: AppColors.white15,
                          thumbColor: AppColors.blue,
                          overlayColor:
                              AppColors.blue.withValues(alpha: 0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: hours,
                          min: 1,
                          max: 72,
                          divisions: 71,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setAutoScanFrequency(v.round()),
                        ),
                      ),
                    ],
                  );
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1h', style: AppTextStyles.caption),
                    Text('24h', style: AppTextStyles.caption),
                    Text('72h', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── HIBP API Key ───────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.vpn_key_outlined, title: l.settingsHibpTitle),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l.settingsHibpDesc,
              style: AppTextStyles.caption,
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: !_apiKeyVisible,
                  style: AppTextStyles.mono
                      .copyWith(fontSize: 13, color: AppColors.textDark),
                  onChanged: (_) => setState(() => _apiKeyEditing = true),
                  decoration: InputDecoration(
                    hintText: l.settingsHibpPasteHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _apiKeyVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.white50,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _apiKeyVisible = !_apiKeyVisible),
                    ),
                  ),
                ),
                if (_apiKeyEditing) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          label: l.settingsHibpSave,
                          gradient: AppGradients.blue,
                          icon: Icons.save_outlined,
                          height: 40,
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .setHibpApiKey(_apiKeyCtrl.text.trim());
                            setState(() => _apiKeyEditing = false);
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.settingsHibpSaved,
                                    style: AppTextStyles.body),
                                backgroundColor:
                                    AppColors.safe.withValues(alpha: 0.8),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      GradientIconButton(
                        icon: Icons.clear,
                        gradient: AppGradients.danger,
                        size: 40,
                        onTap: () {
                          _apiKeyCtrl.clear();
                          ref.read(settingsProvider.notifier).clearHibpApiKey();
                          setState(() => _apiKeyEditing = false);
                        },
                      ),
                    ],
                  ),
                ],
                if (!_apiKeyEditing && settings.hibpApiKey.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.safe, size: 14),
                      const SizedBox(width: 6),
                      Text(l.settingsHibpConfigured,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.safe)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Privacy & Data ─────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.privacy_tip_outlined, title: l.settingsPrivacy),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        color: AppColors.safe, size: 16),
                    const SizedBox(width: 8),
                    Text(l.settingsKAnon,
                        style: AppTextStyles.bodyMedium
                            ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l.settingsKAnonDesc,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.storage_outlined,
                        color: AppColors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(l.settingsLocalStorage,
                        style: AppTextStyles.bodyMedium
                            ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l.settingsLocalStorageDesc,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Reports ────────────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.description_outlined, title: l.reports),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ExportTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: l.exportPdf,
                  subtitle: l.exportPdfSubtitle,
                  iconColor: AppColors.danger,
                  onTap: () => _exportPdf(context),
                ),
                _Divider(),
                _ExportTile(
                  icon: Icons.table_view_outlined,
                  title: l.exportCsv,
                  subtitle: l.exportCsvSubtitle,
                  iconColor: AppColors.safe,
                  onTap: () => _exportCsv(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── About ──────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.info_outline, title: l.settingsAbout),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AboutRow(l.settingsAboutVersion, '1.0.0'),
                _AboutRow(l.settingsAboutEngine, 'RF + LightGBM + GNN Ensemble'),
                _AboutRow(l.settingsAboutSources, 'HIBP, PackageManager, WifiManager'),
                _AboutRow(l.settingsAboutModel, 'SHAP-explainable permission scoring'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Danger Zone ────────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.warning_amber_outlined,
              title: l.settingsDangerZone,
              color: AppColors.danger),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.danger.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsResetDesc,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: l.settingsResetBtn,
                    gradient: AppGradients.danger,
                    icon: Icons.restore,
                    height: 44,
                    onTap: () => _confirmReset(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(l.exportGenerating),
      duration: const Duration(seconds: 1),
    ));
    try {
      await ReportExportService.exportPdf();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(l.exportFailed(e.toString())),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ReportExportService.exportCsv();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(l.exportFailed(e.toString())),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.settingsResetTitle,
            style: AppTextStyles.titleMedium),
        content: Text(AppLocalizations.of(context)!.settingsResetBody,
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
              ref.read(settingsProvider.notifier).resetAll();
              _apiKeyCtrl.clear();
              setState(() => _apiKeyEditing = false);
            },
            child: Text(AppLocalizations.of(context)!.dialogReset,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? AppColors.blue;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: c, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF111111);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: titleColor, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            // Force a clearly contrasting on/off track + thumb so the
            // state is unmistakable regardless of light / dark theme.
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.blue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark
                ? const Color(0xFF3A3A3A)
                : const Color(0xFFCCCCCC),
            trackOutlineColor:
                WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 0.5,
        color: AppColors.glassBorder,
      );
}

class _LanguagePicker extends StatelessWidget {
  final Locale? current;
  final ValueChanged<Locale?> onChanged;
  const _LanguagePicker({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = <(Locale?, String)>[
      (null, l.themeSystem),
      (const Locale('en'), l.languageEnglish),
      (const Locale('hi'), l.languageHindi),
      (const Locale('ta'), l.languageTamil),
      (const Locale('te'), l.languageTelugu),
    ];
    return RadioGroup<Locale?>(
      groupValue: current,
      onChanged: onChanged,
      child: Column(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i != 0) _Divider(),
            RadioListTile<Locale?>(
              value: options[i].$1,
              activeColor: AppColors.blue,
              controlAffinity: ListTileControlAffinity.trailing,
              contentPadding: EdgeInsets.zero,
              title: Text(options[i].$2,
                  style: AppTextStyles.bodyMedium
                      ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMedium
                          ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? Colors.white : const Color(0xFF111111);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.body),
          ),
          const SizedBox(width: 8),
          // Wrap value text so multi-line values (e.g. "RF + LightGBM + GNN
          // Ensemble") don't overflow the row.
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(color: valueColor),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
