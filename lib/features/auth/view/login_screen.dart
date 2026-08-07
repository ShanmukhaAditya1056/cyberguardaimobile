import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Sign-in / registration.
///
/// Sign-in is mandatory — the router guard sends every protected route here —
/// so this screen deliberately offers no way past it. The only exception is a
/// build with no Firebase credentials, where signing in is impossible; the
/// guard stands down there and this shows an explanation rather than a form
/// that cannot work.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _registerMode = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
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
        // Dismissing the Google chooser is not an error worth shouting about.
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
      // The router guard reacts to the auth state change and releases the
      // gate, so there is nothing to navigate to explicitly.
      setState(() => _busy = false);
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
    // Identical wording whether or not the address exists — anything else
    // would let a stranger enumerate registered accounts.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.authResetSent),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      // resizeToAvoidBottomInset defaults to true; the scroll view below keeps
      // the form reachable once the keyboard covers half the screen.
      body: Column(
        children: [
          _Hero(fade: _fade, l: l, registerMode: _registerMode),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: AuthService.isConfigured
                      ? _buildCard(l)
                      : _buildUnavailable(l),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown only when the build has no Firebase credentials. An explanation,
  /// not a disabled form — controls that cannot possibly work read as a bug.
  Widget _buildUnavailable(AppLocalizations l) => Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.warningLightBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.warning, size: 24),
            ),
            const SizedBox(height: 14),
            Text(l.authUnavailableTitle,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l.authUnavailableBody,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  static final _cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  Widget _buildCard(AppLocalizations l) => Transform.translate(
        // Lift the card so it overlaps the hero's curved base.
        offset: const Offset(0, -28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          decoration: _cardDecoration,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ModeTabs(
                  registerMode: _registerMode,
                  enabled: !_busy,
                  signInLabel: l.authTabSignIn,
                  registerLabel: l.authTabRegister,
                  onChanged: (v) => setState(() {
                    _registerMode = v;
                    _error = null;
                    _formKey.currentState?.reset();
                  }),
                ),
                const SizedBox(height: 20),
                _Field(
                  controller: _emailCtrl,
                  enabled: !_busy,
                  label: l.breachTabEmail,
                  hint: l.enterEmail,
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    // Loose on purpose: the server is the authority on whether
                    // an address exists, and strict client regexes reject
                    // perfectly valid addresses.
                    if (value.isEmpty ||
                        !value.contains('@') ||
                        !value.contains('.')) {
                      return l.authErrInvalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _passwordCtrl,
                  enabled: !_busy,
                  label: l.authPassword,
                  hint: l.enterPassword,
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  autofill: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitEmail(),
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                      color: AppColors.textLight,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.isEmpty) return l.authErrWeakPassword;
                    // Firebase's own floor, and only meaningful when creating
                    // an account — an existing one may predate any rule here.
                    if (_registerMode && value.length < 6) {
                      return l.authErrWeakPassword;
                    }
                    return null;
                  },
                ),
                if (!_registerMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _forgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l.authForgotPassword,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.blue)),
                    ),
                  ),
                if (_error != null && _error!.isNotEmpty) _ErrorBanner(_error!),
                const SizedBox(height: 16),
                _PrimaryButton(
                  label: _registerMode ? l.authSignUp : l.authSignIn,
                  busyLabel: l.authSigningIn,
                  busy: _busy,
                  onTap: _submitEmail,
                ),
                const SizedBox(height: 18),
                _OrDivider(label: l.authOr),
                const SizedBox(height: 18),
                _GoogleButton(
                  label: l.authContinueGoogle,
                  enabled: !_busy,
                  onTap: () => _runAuth(AuthService.signInWithGoogle),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 12, color: AppColors.textLight),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        l.authSecuredNote,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textLight, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Branded gradient header with a curved base the form card overlaps.
class _Hero extends StatelessWidget {
  final Animation<double> fade;
  final AppLocalizations l;
  final bool registerMode;

  const _Hero({required this.fade, required this.l, required this.registerMode});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 34,
          bottom: 62,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(gradient: AppGradients.blue),
        child: FadeTransition(
          opacity: fade,
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                registerMode ? l.authCreateAccountTitle : l.authWelcomeBack,
                style: AppTextStyles.headline.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l.authHeroTagline,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Concave sweep across the bottom edge of the hero.
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 34)
      ..quadraticBezierTo(
          size.width / 2, size.height + 16, size.width, size.height - 34)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Sliding segmented control for sign-in vs register.
class _ModeTabs extends StatelessWidget {
  final bool registerMode;
  final bool enabled;
  final String signInLabel;
  final String registerLabel;
  final ValueChanged<bool> onChanged;

  const _ModeTabs({
    required this.registerMode,
    required this.enabled,
    required this.signInLabel,
    required this.registerLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment:
                registerMode ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tab(signInLabel, !registerMode, () => onChanged(false)),
              _tab(registerLabel, registerMode, () => onChanged(true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: AppTextStyles.bodySmall.copyWith(
                color: active ? AppColors.blue : AppColors.textMedium,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<String>? autofill;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.autofill,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofill,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: AppTextStyles.body.copyWith(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.bg,
        prefixIcon: Icon(icon, size: 19, color: AppColors.textLight),
        suffixIcon: suffix,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMedium),
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
        floatingLabelStyle: AppTextStyles.bodySmall
            .copyWith(color: AppColors.blue, fontWeight: FontWeight.w600),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.blue, 1.6),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.6),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.danger),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.dangerLightBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.dangerDark)),
            ),
          ],
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final String busyLabel;
  final bool busy;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.busyLabel,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          gradient: AppGradients.blue,
          borderRadius: BorderRadius.circular(14),
          boxShadow: busy
              ? null
              : [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: busy
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(busyLabel,
                        style: AppTextStyles.button.copyWith(fontSize: 14)),
                  ],
                )
              : Text(label, style: AppTextStyles.button),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textLight,
                    fontSize: 10,
                    letterSpacing: 1)),
          ),
          const Expanded(child: Divider(color: AppColors.border, height: 1)),
        ],
      );
}

class _GoogleButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _GoogleButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleGlyph(size: 19),
              const SizedBox(width: 11),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google's four-colour "G", drawn rather than shipped as an asset so there is
/// no binary logo in the repo and it stays crisp at any size.
class _GoogleGlyph extends StatelessWidget {
  final double size;
  const _GoogleGlyph({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleGlyphPainter());
}

class _GoogleGlyphPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.22;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four arcs, quarter-ish each, in Google's brand order.
    canvas.drawArc(rect, -0.32, 1.30, false, p..color = _green);
    canvas.drawArc(rect, 0.98, 1.30, false, p..color = _yellow);
    canvas.drawArc(rect, 2.28, 1.45, false, p..color = _red);
    canvas.drawArc(rect, 3.73, 1.55, false, p..color = _blue);

    // The horizontal bar of the G.
    final bar = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTWH(s * 0.5, s * 0.42, s * 0.5 - stroke / 2, stroke * 0.92),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
