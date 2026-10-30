import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';
import 'info_screens.dart';
import 'main_shell.dart';

void enterApp(BuildContext context, AppUser user) {
  AppScope.read(context).signIn(user);
  TextInput.finishAutofillContext();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const MainShell()),
    (_) => false,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      final user = await authService.signInWithGoogle();
      if (mounted) enterApp(context, user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(authMessage(e)))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _error = context.tr('invalidPhone'));
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final user = await authService.sendOtp(phone);
      if (!mounted) return;
      if (user != null) {
        // Android verified the number by itself.
        enterApp(context, user);
        return;
      }
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OtpScreen(phone: phone)));
    } catch (e) {
      if (mounted) setState(() => _error = context.tr(authMessage(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Center(child: VoteWalaLogo(markSize: 80, horizontal: true)),
                const SizedBox(height: 36),
                Text(context.tr('signInTitle'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(context.tr('signInSub'),
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 32),
                if (authService.supportsGoogle) ...[
                  OutlinedButton(
                    onPressed: _busy ? null : _google,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const _GoogleG(),
                      const SizedBox(width: 12),
                      Text(context.tr('continueGoogle'), style: const TextStyle(color: AppColors.blue)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(context.tr('or'), style: const TextStyle(color: AppColors.muted)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 20),
                ],
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  onSubmitted: (_) => _sendOtp(),
                  decoration: InputDecoration(
                    hintText: context.tr('mobileNumber'),
                    errorText: _error,
                    prefixIcon: Container(
                      width: 64,
                      margin: const EdgeInsets.only(right: 10),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
                      child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _sendOtp,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text(context.tr('sendOtp')),
                ),
                const SizedBox(height: 28),
                Text(context.tr('agree'),
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const InfoScreen(titleKey: 'terms', bodyKey: 'termsBody'))),
                  child: Text(context.tr('termsPrivacy'), style: const TextStyle(color: AppColors.blue)),
                ),
                const SizedBox(
                  height: 110,
                  child: CustomPaint(painter: SkylinePainter()),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(() => _error = context.tr('invalidOtp'));
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final user = await authService.verifyOtp(widget.phone, _code.text);
      if (mounted) enterApp(context, user);
    } catch (e) {
      if (mounted) setState(() => _error = context.tr(authMessage(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: Text(context.tr('verifyOtp'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Icon(Icons.sms_outlined, size: 56, color: AppColors.orange),
              const SizedBox(height: 16),
              Text(context.tr('enterOtp', {'phone': '+91 ${widget.phone}'}),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
              const SizedBox(height: 24),
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, letterSpacing: 14, fontWeight: FontWeight.w700),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onSubmitted: (_) => _verify(),
                decoration: InputDecoration(hintText: '······', errorText: _error),
              ),
              const SizedBox(height: 8),
              if (authService is DemoAuthService)
                Text(context.tr('demoOtpHint'),
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _verify,
                style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(context.tr('verifyContinue')),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final sent = context.tr('otpSent');
                  try {
                    final user = await authService.sendOtp(widget.phone);
                    if (user != null && context.mounted) return enterApp(context, user);
                    messenger.showSnackBar(SnackBar(content: Text(sent)));
                  } catch (e) {
                    if (context.mounted) messenger.showSnackBar(SnackBar(content: Text(context.tr(authMessage(e)))));
                  }
                },
                child: Text(context.tr('resendOtp')),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Message key for a sign-in error.
String authMessage(Object e) => e is AuthFailure ? e.messageKey : 'signInFailed';

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (r) => const SweepGradient(
          colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4), Color(0xFFEA4335)],
        ).createShader(r),
        child: const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      );
}
