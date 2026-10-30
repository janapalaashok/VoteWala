import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'info_screens.dart';
import 'login_screen.dart';

/// First screen: language, sign in / register with email, or Google (which
/// creates the account on first use).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: wide
            ? Row(children: [
                const Expanded(flex: 6, child: _Scene(rounded: false, big: true)),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Align(alignment: Alignment.centerRight, child: _LanguageToggle()),
                          SizedBox(height: 12),
                          Center(child: VoteWalaLogo(markSize: 72, horizontal: true)),
                          SizedBox(height: 28),
                          AuthForm(),
                        ]),
                      ),
                    ),
                  ),
                ),
              ])
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Align(alignment: Alignment.centerRight, child: _LanguageToggle()),
                      Center(child: VoteWalaLogo(markSize: 76)),
                      SizedBox(height: 14),
                      _Scene(rounded: true, big: false),
                      SizedBox(height: 20),
                      AuthForm(),
                    ]),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Andhra Pradesh at sunset: Tirumala, the Vizag coast and its lighthouse.
class _Scene extends StatelessWidget {
  const _Scene({required this.rounded, required this.big});

  final bool rounded;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final image = Stack(fit: StackFit.expand, children: [
      // Keep Tirumala in view when the tall desktop panel crops the sides.
      Image.asset('assets/brand/ap_scene.jpg', fit: BoxFit.cover, alignment: Alignment(big ? -0.75 : -0.2, 0)),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x00000000), Color(0xB3140C2A)],
          ),
        ),
      ),
      Positioned(
        left: big ? 48 : 18,
        right: big ? 48 : 18,
        bottom: big ? 48 : 14,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Andhra Pradesh Political Opinion Polls',
            style: TextStyle(color: Colors.white, fontSize: big ? 34 : 17, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 4),
          Text('ఆంధ్రప్రదేశ్ రాజకీయ అభిప్రాయ సేకరణ',
              style: TextStyle(color: const Color(0xFFFFE2B8), fontSize: big ? 18 : 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
    if (!rounded) return image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(aspectRatio: 16 / 9, child: image),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        selectedBackgroundColor: AppColors.orange,
        selectedForegroundColor: Colors.white,
      ),
      segments: const [
        ButtonSegment(value: 'en', label: Text('English')),
        ButtonSegment(value: 'te', label: Text('తెలుగు')),
      ],
      selected: {state.language},
      onSelectionChanged: (s) => state.setLanguage(s.first),
    );
  }
}

/// Sign in / register with email and password, or continue with Google.
class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AppUser> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await action();
      if (!mounted) return;
      // The app switches to the home (or verify-email) screen by itself.
      await AppScope.read(context).signIn(user);
    } catch (e) {
      if (mounted) setState(() => _error = context.tr(authMessage(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    final email = _email.text.trim();
    final password = _password.text;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = context.tr('invalidEmail'));
      return;
    }
    if (password.length < 6) {
      setState(() => _error = context.tr('weakPassword'));
      return;
    }
    if (_register && password != _confirm.text) {
      setState(() => _error = context.tr('passwordsDontMatch'));
      return;
    }
    _run(() => _register ? authService.registerWithEmail(email, password) : authService.signInWithEmail(email, password));
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = context.tr('enterEmailFirst'));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final sent = context.tr('resetSent', {'email': email});
    try {
      await authService.sendPasswordReset(email);
      messenger.showSnackBar(SnackBar(content: Text(sent)));
    } catch (e) {
      if (mounted) setState(() => _error = context.tr(authMessage(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700);
    void openInfo(String title, String body) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => InfoScreen(titleKey: title, bodyKey: body)));

    return AutofillGroup(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            selectedBackgroundColor: AppColors.orange.withValues(alpha: 0.12),
            selectedForegroundColor: AppColors.orange,
          ),
          segments: [
            ButtonSegment(value: false, label: Text(context.tr('signInTab'))),
            ButtonSegment(value: true, label: Text(context.tr('registerTab'))),
          ],
          selected: {_register},
          onSelectionChanged: (s) => setState(() {
            _register = s.first;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: context.tr('email'), prefixIcon: const Icon(Icons.mail_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: !_showPassword,
          autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
          textInputAction: _register ? TextInputAction.next : TextInputAction.done,
          onSubmitted: _register ? null : (_) => _submit(),
          decoration: InputDecoration(
            labelText: context.tr('password'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        if (_register) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: context.tr('confirmPassword'), prefixIcon: const Icon(Icons.lock_reset)),
          ),
        ] else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _busy ? null : _forgot, child: Text(context.tr('forgotPassword'))),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _busy
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text(context.tr(_register ? 'createAccount' : 'signInBtn'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(context.tr('or'), style: const TextStyle(color: AppColors.muted)),
          ),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _busy ? null : () => _run(authService.signInWithGoogle),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const GoogleMark(),
            const SizedBox(width: 12),
            Text(context.tr('continueGoogle'),
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15.5)),
          ]),
        ),
        const SizedBox(height: 8),
        Text(context.tr('googleCreates'),
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        if (authService.supportsPhone)
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.phone_iphone),
            label: Text(context.tr('continueMobile')),
          ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
            children: [
              TextSpan(text: '${context.tr('agree')} '),
              TextSpan(
                text: context.tr('terms'),
                style: linkStyle,
                recognizer: TapGestureRecognizer()..onTap = () => openInfo('terms', 'termsBody'),
              ),
              TextSpan(text: ' ${context.tr('and')} '),
              TextSpan(
                text: context.tr('privacyPolicy'),
                style: linkStyle,
                recognizer: TapGestureRecognizer()..onTap = () => openInfo('privacyPolicy', 'privacyBody'),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

/// Shown after registering with email until the address is verified.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final u = await AppScope.read(context).refreshUser();
      if (mounted && u?.emailVerified != true) setState(() => _message = context.tr('notVerifiedYet'));
    } catch (e) {
      if (mounted) setState(() => _message = context.tr(authMessage(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await authService.sendVerificationEmail();
      if (mounted) setState(() => _message = context.tr('verificationSent'));
    } catch (e) {
      if (mounted) setState(() => _message = context.tr(authMessage(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AppScope.of(context).user?.email ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(Icons.mark_email_unread_outlined, size: 72, color: AppColors.orange),
                const SizedBox(height: 16),
                Text(context.tr('verifyTitle'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(context.tr('verifyBody', {'email': email}),
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.45)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _check,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(context.tr('iVerified')),
                ),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _busy ? null : _resend, child: Text(context.tr('resendEmail'))),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_message!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => AppScope.read(context).signOut(),
                  child: Text(context.tr('useAnotherAccount')),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
