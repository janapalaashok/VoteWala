import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(VoteWalaApp(state: AppState(prefs)));
}

class VoteWalaApp extends StatelessWidget {
  const VoteWalaApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
        state: state,
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) => MaterialApp(
            title: 'VoteWala',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            locale: Locale(state.language),
            supportedLocales: const [Locale('en'), Locale('te')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: state.user == null ? const WelcomeScreen() : const MainShell(),
          ),
        ),
      );
}
