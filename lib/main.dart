import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_app.dart';
import 'config/config_service.dart';
import 'l10n/legal.dart';
import 'screens/legal_screens.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_client.dart';
import 'services/traffic.dart';
import 'services/vote_service.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'state/deep_link.dart';
import 'state/url_sync.dart';
import 'theme.dart';

/// flutter build web --dart-define=VOTEWALA_DEMO=true: offline UI review.
const _demo = bool.fromEnvironment('VOTEWALA_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await ConfigService.instance.init(prefs);
  // Clean page addresses (votewala.in/results); older #/ links still work.
  usePathUrlStrategy();
  final path = kIsWeb ? startPath(Uri.base) : '/';
  // The admin panel is part of the website only: https://<site>/admin
  if (kIsWeb) DeepLink.parse(path);
  if (kIsWeb && (path == '/admin' || path.startsWith('/admin/'))) {
    runApp(AdminApp(prefs: prefs));
    return;
  }
  final settings = ConfigService.instance.settings;
  final VoteService votes;
  if (_demo) {
    // UI review build: simulated sign-in, votes kept in memory only.
    authService = DemoAuthService();
    votes = VoteService(MemoryStore(), MemoryPhotoStore(), minGap: Duration.zero);
  } else {
    try {
      authService = await FirebaseAuthService.init(settings);
    } catch (e) {
      debugPrint('Firebase unavailable: $e');
      authService = const UnavailableAuthService();
    }
    votes = VoteService(
      FirestoreClient(settings, idToken: authService.idToken),
      FirebasePhotoStore(settings, authService.idToken),
    );
  }
  if (!_demo) traffic = Traffic(votes.store, prefs);
  final state = AppState(prefs, auth: authService, votes: votes);
  await state.restoreSession();
  unawaited(traffic?.visit(signedIn: state.user != null));
  runApp(VoteWalaApp(state: state));
}

class VoteWalaApp extends StatelessWidget {
  const VoteWalaApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
        state: state,
        child: ListenableBuilder(
          listenable: Listenable.merge([state, DeepLink.legal]),
          builder: (context, _) => _app(context),
        ),
      );

  Widget _app(BuildContext context) {
    final legalDoc = legalById(DeepLink.legal.value ?? '');
    appLinkHome = () => DeepLink.legal.value = null;
    // Address shown under all pages; the main screen sets its tab's address.
    if (legalDoc != null) {
      UrlSync.instance.setRoot('/legal/${legalDoc.id}');
    } else if (state.user == null || !state.user!.emailVerified) {
      UrlSync.instance.setRoot('/');
    }
    return MaterialApp(
      title: appConfig.branding.appName,
      initialRoute: '/',
      navigatorObservers: [UrlSync.instance],
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: Locale(state.language),
      supportedLocales: const [Locale('en'), Locale('te')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: legalDoc != null
          ? LegalScreen(doc: legalDoc, standalone: true)
          : state.user == null
              ? const WelcomeScreen()
              : !state.user!.emailVerified
                  ? const VerifyEmailScreen()
                  : const MainShell(),
    );
  }
}
