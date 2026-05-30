import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/hash_utils.dart';
import '../../../data/models/breach_model.dart';
import '../../../data/models/scan_result_model.dart';
import '../../../data/services/hive_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/smart_back_button.dart';
import '../provider/breach_provider.dart';

/// HaveIBeenPwned-style breach monitor:
///   PART 1  Input section          (email / phone tab, k-anonymity note)
///   PART 2  Result                  (no breach / breach found)
///   PART 3  Past checks (history)
///   PART 4  Privacy explainer       (collapsible)
class BreachScreen extends ConsumerStatefulWidget {
  const BreachScreen({super.key});

  @override
  ConsumerState<BreachScreen> createState() => _BreachScreenState();
}

class _BreachScreenState extends ConsumerState<BreachScreen> {
  final _ctrl = TextEditingController();
  bool _isEmail = true;
  bool _privacyOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(breachProvider.notifier).setMode(true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _switchMode(bool isEmail) {
    if (_isEmail == isEmail) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isEmail = isEmail;
      _ctrl.clear();
    });
    ref.read(breachProvider.notifier).setMode(isEmail);
  }

  void _check() {
    FocusScope.of(context).unfocus();
    final apiKey = HiveService.getSettings().hibpApiKey;
    ref.read(breachProvider.notifier).checkBreach(apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(breachProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: Text(l.breachMonitor, style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _InputSection(
            isEmail: _isEmail,
            controller: _ctrl,
            isChecking: state.isChecking,
            onModeSwitch: _switchMode,
            onChanged: (v) =>
                ref.read(breachProvider.notifier).updateCredential(v),
            onCheck: state.credential.trim().isEmpty || state.isChecking
                ? null
                : _check,
          ),
          const SizedBox(height: 16),
          if (state.error != null)
            _ErrorBanner(message: state.error!)
          else if (state.result != null) ...[
            if (state.result!.source == 'offline')
              _OfflineSourceBanner(),
            if (state.result!.source == 'offline')
              const SizedBox(height: 12),
            _ResultSection(result: state.result!, isEmail: _isEmail),
          ] else if (!state.isChecking)
            const SizedBox.shrink(),
          if (state.history.isNotEmpty) ...[
            const SizedBox(height: 24),
            _HistorySection(history: state.history),
          ],
          const SizedBox(height: 24),
          _PrivacyExplainer(
            open: _privacyOpen,
            onToggle: () => setState(() => _privacyOpen = !_privacyOpen),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── PART 1: Input ─────────────────────────────────────────────────────

class _InputSection extends StatelessWidget {
  final bool isEmail;
  final TextEditingController controller;
  final bool isChecking;
  final ValueChanged<bool> onModeSwitch;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCheck;

  const _InputSection({
    required this.isEmail,
    required this.controller,
    required this.isChecking,
    required this.onModeSwitch,
    required this.onChanged,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 2)),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.breachInputTitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textOn(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.breachInputSubtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.subtextOn(context),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),

          // Tabs
          Row(
            children: [
              _Tab(
                  label: AppLocalizations.of(context)!.breachTabEmail,
                  icon: Icons.email_outlined,
                  selected: isEmail,
                  onTap: () => onModeSwitch(true)),
              const SizedBox(width: 20),
              _Tab(
                  label: AppLocalizations.of(context)!.breachTabPhone,
                  icon: Icons.phone_outlined,
                  selected: !isEmail,
                  onTap: () => onModeSwitch(false)),
            ],
          ),
          const SizedBox(height: 16),

          // Input
          TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: (_) => onCheck?.call(),
            keyboardType: isEmail
                ? TextInputType.emailAddress
                : TextInputType.phone,
            textInputAction: TextInputAction.go,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.textOn(context),
            ),
            decoration: InputDecoration(
              hintText: isEmail
                  ? AppLocalizations.of(context)!.breachInputHintEmail
                  : AppLocalizations.of(context)!.breachInputHintPhone,
              prefixIcon: Icon(
                isEmail ? Icons.email_outlined : Icons.phone_outlined,
                color: AppColors.textMedium,
                size: 18,
              ),
              prefixText: !isEmail ? '+91 ' : null,
              prefixStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: AppColors.textOn(context),
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFFAFAFA),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),

          // Check button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCheck,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(AppLocalizations.of(context)!.checkBreach,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),

          // Privacy footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 12, color: AppColors.safe),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.breachPrivacyFooter,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.subtextOn(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.blue : AppColors.subtextOn(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PART 2: Result ────────────────────────────────────────────────────

class _ResultSection extends StatelessWidget {
  final BreachCheckResult result;
  final bool isEmail;
  const _ResultSection({required this.result, required this.isEmail});

  @override
  Widget build(BuildContext context) {
    if (!result.isBreached) return _NoBreachCard(isEmail: isEmail);
    return _BreachFoundCard(result: result, isEmail: isEmail);
  }
}

class _NoBreachCard extends StatelessWidget {
  final bool isEmail;
  const _NoBreachCard({required this.isEmail});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.safeLightBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.safe, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.breachNoBreaches,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textOn(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEmail
                ? AppLocalizations.of(context)!.breachNoBreachesEmailDesc
                : AppLocalizations.of(context)!.breachNoBreachesPhoneDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.subtextOn(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.breachCheckedCount,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),
          const _StayProtected(),
        ],
      ),
    );
  }
}

class _StayProtected extends StatelessWidget {
  const _StayProtected();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tips = [l.breachTipUnique, l.breach2FA, l.breachPwManager];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.breachStayProtected,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textOn(context),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle,
                    size: 14, color: AppColors.safe),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textOn(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BreachFoundCard extends StatelessWidget {
  final BreachCheckResult result;
  final bool isEmail;
  const _BreachFoundCard({required this.result, required this.isEmail});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : AppColors.border;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.dangerLightBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                '${result.breaches.length} breach${result.breaches.length != 1 ? 'es' : ''} found',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEmail
                    ? AppLocalizations.of(context)!.breachFoundEmail
                    : AppLocalizations.of(context)!.breachFoundPhone,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.subtextOn(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final b in result.breaches) ...[
          _BreachCard(breach: b),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BreachCard extends StatefulWidget {
  final BreachModel breach;
  const _BreachCard({required this.breach});

  @override
  State<_BreachCard> createState() => _BreachCardState();
}

class _BreachCardState extends State<_BreachCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : AppColors.border;
    final b = widget.breach;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          // Left red border 3px
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Container(
              width: 3,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _BreachInitial(letter: b.title.isNotEmpty ? b.title[0] : '?'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textOn(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.domain,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.subtextOn(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      b.breachDate,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.subtextOn(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!
                      .breachAccountsAffected(b.formattedPwnCount),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.subtextOn(context),
                  ),
                ),
                if (b.dataClasses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.breachCompromisedData,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.subtextOn(context),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: b.dataClasses
                        .take(10)
                        .map((d) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.dangerLightBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _open = !_open),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.breachWhatToDo,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _open ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.blue,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_open) ...[
                  const SizedBox(height: 8),
                  for (final entry in [
                    ('1', AppLocalizations.of(context)!.breachStep1),
                    ('2', AppLocalizations.of(context)!.breachStep2),
                    ('3', AppLocalizations.of(context)!.breachStep3),
                    ('4', AppLocalizations.of(context)!.breachStep4),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.blueGlow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(entry.$1,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.blue,
                                )),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.$2,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textOn(context),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreachInitial extends StatelessWidget {
  final String letter;
  const _BreachInitial({required this.letter});

  @override
  Widget build(BuildContext context) {
    // Stable colour from the letter so each breach gets a unique avatar.
    final palette = const [
      Color(0xFFE23744), // red
      Color(0xFF1A73E8), // blue
      Color(0xFF1EA672), // green
      Color(0xFFF4831F), // orange
      Color(0xFF9C27B0), // purple
      Color(0xFF00BCD4), // cyan
    ];
    final c = palette[letter.codeUnitAt(0) % palette.length];
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: c,
        ),
      ),
    );
  }
}

// ─── PART 3: History ───────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final List<ScanResultModel> history;
  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            AppLocalizations.of(context)!.breachPastChecks,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textOn(context),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              for (var i = 0; i < history.take(10).length; i++) ...[
                if (i > 0) Divider(height: 1, color: borderColor),
                _HistoryRow(scan: history.take(10).toList()[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ScanResultModel scan;
  const _HistoryRow({required this.scan});

  @override
  Widget build(BuildContext context) {
    final isBreached = scan.verdict == 'breached';
    final color = isBreached ? AppColors.danger : AppColors.safe;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HashUtils.maskEmail(scan.input),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOn(context),
                  ),
                ),
                Text(
                  DateFormatter.timeAgo(scan.timestamp),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.subtextOn(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isBreached
                  ? AppLocalizations.of(context)!.breachStatusBreached
                  : AppLocalizations.of(context)!.breachStatusSafe,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PART 4: Privacy explainer ────────────────────────────────────────

class _PrivacyExplainer extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  const _PrivacyExplainer({required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : AppColors.border;
    final l = AppLocalizations.of(context)!;
    final steps = [
      ('🔐', l.breachPrivacyStep1),
      ('📤', l.breachPrivacyStep2),
      ('📥', l.breachPrivacyStep3),
      ('🔍', l.breachPrivacyStep4),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.blue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.breachPrivacyTitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOn(context),
                      ),
                    ),
                  ),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.subtextOn(context),
                  ),
                ],
              ),
            ),
          ),
          if (open) ...[
            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (emoji, text) in steps)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textOn(context),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Offline source banner ────────────────────────────────────────────

class _OfflineSourceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF3A2A14)
            : const Color(0xFFFFF3E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.breachOfflineBannerTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.breachOfflineBannerBody,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.subtextOn(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error banner ──────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerLightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
