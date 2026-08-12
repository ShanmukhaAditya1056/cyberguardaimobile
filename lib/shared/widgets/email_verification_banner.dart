import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// Prompts an unverified account to confirm its address.
///
/// Shown rather than enforced. The account works while unverified, because
/// every scanner runs on the submitted input alone and blocking them would
/// strand someone whose mail is slow or filtered — on an app that needs no
/// account to do its job. This is a nudge with a working resend button, not
/// a gate.
///
/// It never appears for Google sign-in: Google verifies the address before
/// issuing the credential, so `emailVerified` is already true there and
/// [AuthService.needsEmailVerification] is false.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner>
    with WidgetsBindingObserver {
  bool _visible = AuthService.needsEmailVerification;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The link opens in a browser or mail app, so the way back is a resume.
    // Re-checking here is what makes the banner disappear on its own instead
    // of surviving until the next cold start.
    if (state == AppLifecycleState.resumed) _recheck();
  }

  Future<void> _recheck() async {
    if (!AuthService.needsEmailVerification) {
      if (mounted && _visible) setState(() => _visible = false);
      return;
    }
    // `emailVerified` is baked into the cached ID token, so it stays false
    // locally until the token is refreshed.
    final verified = await AuthService.refreshEmailVerified();
    if (!mounted) return;
    if (verified && _visible) {
      setState(() => _visible = false);
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.verifyEmailDone),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.safe,
        ),
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final ok = await AuthService.resendEmailVerification();
    if (!mounted) return;
    setState(() => _sending = false);
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l.verifyEmailSent : l.verifyEmailFailed),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.textDark : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final email = AuthService.currentUser?.email ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningLightBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mark_email_unread_outlined,
                size: 20, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.verifyEmailTitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l.verifyEmailBody(email),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _sending ? null : _resend,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l.verifyEmailResend,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.blue,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
