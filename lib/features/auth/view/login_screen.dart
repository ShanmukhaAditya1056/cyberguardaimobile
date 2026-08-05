import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/animated_gradient_bg.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Email/password + Google sign-in.
///
/// Auth is optional in this app: it is a fully on-device security tool and
/// every scanner works without an account, so this screen always offers a way
/// past it rather than holding the app hostage. When the build has no Firebase
/// credentials at all ([AuthService.isConfigured] false) the form is replaced
/// by an explanation instead of a set of controls that silently fail.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _registerMode = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _messageFor(AuthFailure failure, AppLocalizations l) =>
      switch (failure) {
        AuthFailure.invalidEmail => l.authErrInvalidEmail,
        AuthFailure.wrongPassword => l.authErrWrongPassword,
        AuthFailure.userNotFound => l.authErrUserNotFound,
        AuthFailure.emailInUse => l.authErrEmailInUse,
        AuthFailure.weakPassword => l.authErrWeakPassword,
        AuthFailure.networkError => l.authErrNetwork,
        AuthFailure.notConfigured => l.authUnavailableTitle,
        // Dismissing the Google chooser is not a failure worth shouting about.
        AuthFailure.cancelled => '',
        AuthFailure.unknown => l.authErrUnknown,
      };

  Future<void> _runAuth(Future<AuthResult> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await action();
    if (!mounted) return;

    if (result.ok) {
      // Router redirect picks up the auth state change; go straight through.
      context.go('/dashboard');
      return;
    }

    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = false;
      _error = _messageFor(result.failure!, l);
    });
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _runAuth(() => _registerMode
        ? AuthService.registerWithEmail(_emailCtrl.text, _passwordCtrl.text)
        : AuthService.signInWithEmail(_emailCtrl.text, _passwordCtrl.text));
  }

  Future<void> _forgotPassword() async {
    final l = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l.authErrInvalidEmail);
      return;
    }
    await AuthService.sendPasswordReset(email);
    if (!mounted) return;
    // Always the same wording whether or not the address exists — saying
    // otherwise would let anyone enumerate registered accounts.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.authResetSent)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return GradientScaffold(
      score: 85,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppGradients.blue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(l.authTitle,
                    style: AppTextStyles.headline2, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  l.authSubtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMedium),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (AuthService.isConfigured)
                  _buildForm(l)
                else
                  _buildUnavailable(l),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _busy ? null : () => context.go('/dashboard'),
                  child: Text(
                    l.authContinueOffline,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMedium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shown when the build carries no Firebase credentials. Deliberately an
  /// explanation rather than a disabled form — a form that cannot possibly
  /// work reads as a bug.
  Widget _buildUnavailable(AppLocalizations l) => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.textMedium, size: 28),
            const SizedBox(height: 10),
            Text(l.authUnavailableTitle,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              l.authUnavailableBody,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildForm(AppLocalizations l) => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: l.breachTabEmail,
                  hintText: l.enterEmail,
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  // Intentionally loose: the server is the real authority on
                  // whether an address exists, and over-strict client regexes
                  // reject valid addresses.
                  if (value.isEmpty || !value.contains('@') ||
                      !value.contains('.')) {
                    return l.authErrInvalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                enabled: !_busy,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                style: AppTextStyles.body,
                onFieldSubmitted: (_) => _submitEmail(),
                decoration: InputDecoration(
                  labelText: l.authPassword,
                  hintText: l.enterPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  // Firebase's own minimum. Only enforced when registering:
                  // an existing account may predate any rule we apply here.
                  if (_registerMode && (v ?? '').length < 6) {
                    return l.authErrWeakPassword;
                  }
                  if ((v ?? '').isEmpty) return l.authErrWeakPassword;
                  return null;
                },
              ),
              if (_error != null && _error!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.danger)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              GradientButton(
                label: _registerMode ? l.authSignUp : l.authSignIn,
                gradient: AppGradients.blue,
                isLoading: _busy,
                onTap: _busy ? null : _submitEmail,
                height: 50,
              ),
              const SizedBox(height: 10),
              if (!_registerMode)
                TextButton(
                  onPressed: _busy ? null : _forgotPassword,
                  child: Text(l.authForgotPassword,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.blue)),
                ),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l.authOr,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMedium)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed:
                    _busy ? null : () => _runAuth(AuthService.signInWithGoogle),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                label: Text(l.authContinueGoogle, style: AppTextStyles.button
                    .copyWith(color: AppColors.textDark)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: AppColors.white50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _registerMode = !_registerMode;
                          _error = null;
                        }),
                child: Text(
                  _registerMode ? l.authHaveAccount : l.authNoAccount,
                  style: AppTextStyles.caption.copyWith(color: AppColors.blue),
                ),
              ),
            ],
          ),
        ),
      );
}
