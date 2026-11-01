import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/achievements_screen.dart';
import '../screens/ap_map_screen.dart';
import '../screens/browse_screens.dart';
import '../screens/candidate_detail_screen.dart';
import '../screens/closed_polls_screen.dart';
import '../screens/constituency_detail_screen.dart';
import '../screens/constituency_list_screen.dart';
import '../screens/featured_poll_screen.dart';
import '../screens/info_screens.dart';
import '../screens/legal_screens.dart';
import '../screens/live_results_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/my_constituency_screen.dart';
import '../screens/priorities_dashboard_screen.dart';
import '../screens/results_screen.dart';

/// The page address a visit started on: the path, or the part after `#` for
/// older links such as `/#/f/cm-2026`.
String startPath(Uri uri) {
  if (uri.fragment.startsWith('/')) return uri.fragment.split('?').first;
  final p = uri.path.length > 1 && uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
  return p.isEmpty ? '/' : p;
}

/// Shows the address of the page on screen in the browser's address bar
/// (website only). Pages still open exactly as before (Navigator.push);
/// this observer only works out each page's address and reports it, so a
/// refresh or a copied link opens the same page (see DeepLink).
class UrlSync extends NavigatorObserver {
  UrlSync._();

  static final instance = UrlSync._();

  /// Main-screen tabs, by tab index (ShellTab).
  static const tabPaths = ['/', '/mla', '/mp', '/results', '/profile'];

  /// Pages without parameters, by address.
  static final simplePages = <String, Widget Function()>{
    '/search': () => const SearchScreen(),
    '/live-polls': () => const LivePollsScreen(),
    '/candidates': () => const CandidatesDirectoryScreen(),
    '/map': () => const ApMapScreen(),
    '/closed-polls': () => const ClosedPollsScreen(),
    '/my-constituency': () => const MyConstituencyScreen(),
    '/priorities': () => const PrioritiesDashboardScreen(),
    '/achievements': () => const AchievementsScreen(),
    '/notifications': () => const NotificationSettingsScreen(),
    '/my-votes': () => const MyParticipationScreen(),
    '/saved': () => const SavedCandidatesScreen(),
    '/about': () => const InfoScreen(titleKey: 'aboutApp', bodyKey: 'aboutBody', showVersion: true),
    '/legal': () => const LegalIndexScreen(),
  };

  /// The address of [page], or null to keep the current address.
  static String? pathOf(Widget page) => switch (page) {
        FeaturedPollScreen(:final poll) => '/f/${poll.id}',
        ConstituencyDetailScreen(:final constituency) => '/c/${constituency.id}',
        LiveResultsScreen(:final constituency) => '/c/${constituency.id}/results',
        CandidateDetailScreen(:final candidate) => '/c/${candidate.constituency.id}/candidate/${candidate.index}',
        ConstituencyListScreen(:final type, :final districtId, embedded: false) =>
          districtId == null ? '/${type.name}' : '/${type.name}/district/$districtId',
        ResultsScreen(embedded: false) => '/results',
        LegalScreen(:final doc) => '/legal/${doc.id}',
        LoginScreen() => '/login',
        OtpScreen() => '/login',
        InfoScreen(titleKey: 'aboutApp') => '/about',
        _ => _simplePathOf(page),
      };

  static String? _simplePathOf(Widget page) {
    for (final e in simplePages.entries) {
      if (e.value().runtimeType == page.runtimeType) return e.key;
    }
    return null;
  }

  /// Address of the page under all others (the main-screen tab, the welcome
  /// page or a policy page opened from its address).
  String _root = '/';
  final _startPath = kIsWeb ? startPath(Uri.base) : '/';
  final _startQuery = kIsWeb ? Uri.base.query : '';
  final _stack = <Route<dynamic>>[];
  String? _shown;

  void setRoot(String path) {
    if (_root == path) return;
    _root = path;
    _update();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _stack[i] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _update();
  }

  /// Address of the top page; dialogs and sheets keep the page's address.
  String _current() {
    final context = navigator?.context;
    for (final route in _stack.reversed) {
      if (route is! PageRoute) continue;
      if (route.isFirst) return _root;
      if (route is MaterialPageRoute && context != null) {
        try {
          final page = route.builder(context);
          if (page is MainShell || page is WelcomeScreen || page is VerifyEmailScreen) return _root;
          final path = pathOf(page);
          if (path != null) return path;
        } catch (_) {}
      }
      return _shown ?? _root;
    }
    return _root;
  }

  void _update() {
    if (!kIsWeb) return;
    // After the frame, so the Navigator's own "/" report comes first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = _current();
      if (path == _shown) return;
      _shown = path;
      // The link's ?query (e.g. ?src=fb) stays while on the page it opened.
      final query = path == _startPath && _startQuery.isNotEmpty ? '?$_startQuery' : '';
      SystemNavigator.routeInformationUpdated(uri: Uri.parse('$path$query'), replace: true);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}
