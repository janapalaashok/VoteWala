import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_app.dart';
import 'config/config_service.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'state/deep_link.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await ConfigService.instance.init(prefs);
  // The admin panel is part of the website only: https://<site>/#/admin
  if (kIsWeb) DeepLink.parse(Uri.base.fragment);
  if (kIsWeb && Uri.base.fragment.startsWith('/admin')) {
    runApp(AdminApp(prefs: prefs));
    return;
  }
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
            title: appConfig.branding.appName,
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
