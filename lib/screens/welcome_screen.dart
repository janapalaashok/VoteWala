import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';
import 'login_screen.dart';

/// Splash / language choice.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context, String lang) {
    AppScope.read(context).setLanguage(lang);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(children: [
                const Spacer(),
                const VoteWalaLogo(markSize: 120),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFFFF4EA), Colors.white],
                      ),
                    ),
                    child: const CustomPaint(painter: SkylinePainter(color: Color(0xFFB3BAC5))),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Andhra Pradesh\nPolitical Opinion Polls',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
                ),
                const SizedBox(height: 4),
                const Text('ఆంధ్రప్రదేశ్ రాజకీయ అభిప్రాయ సేకరణ',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                const Spacer(),
                FilledButton(
                  onPressed: () => _start(context, 'te'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: const Text('తెలుగు లో కొనసాగండి', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _start(context, 'en'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: const Text('Continue in English'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
