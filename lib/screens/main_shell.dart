import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../state/deep_link.dart';
import '../state/url_sync.dart';
import '../widgets/common.dart';
import '../widgets/daily_poll.dart';
import 'constituency_list_screen.dart';
import 'desktop/desktop_home.dart';
import 'desktop/desktop_pages.dart';
import 'desktop/desktop_shell.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'results_screen.dart';

/// Lets tab pages switch the active tab (e.g. Home -> MLA).
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.go, required super.child});

  final ValueChanged<int> go;

  static ShellScope? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class ShellTab {
  static const home = 0, mla = 1, mp = 2, results = 3, profile = 4;
}

/// Bottom navigation on phones, navigation rail on tablets and desktop web.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = DeepLink.takeTab() ?? 0;

  /// Shows tab [i]; the browser address follows (/, /mla, /mp, /results, /profile).
  void _go(int i) {
    setState(() => _index = i);
    UrlSync.instance.setRoot(UrlSync.tabPaths[i]);
  }

  AppState? _state;
  bool _dailyShown = false;

  /// Today's poll pops up once the voter's record is known, until answered.
  void _maybeShowDaily() {
    final state = _state;
    if (state == null || _dailyShown || !mounted || !state.dailyPending) return;
    final poll = state.todaysPoll!;
    _dailyShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDailyPollPopup(context, poll);
      // Not answered (e.g. answered elsewhere and the popup closed): ask
      // again only after the next change.
      if (mounted) _dailyShown = !state.dailyPending;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (!identical(state, _state)) {
      _state?.removeListener(_maybeShowDaily);
      _state = state..addListener(_maybeShowDaily);
    }
    _maybeShowDaily();
  }

  @override
  void dispose() {
    _state?.removeListener(_maybeShowDaily);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    UrlSync.instance.setRoot(UrlSync.tabPaths[_index]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) DeepLink.openPending(context);
    });
  }

  static const _pages = [
    HomeScreen(),
    ConstituencyListScreen(type: ElectionType.mla, embedded: true),
    ConstituencyListScreen(type: ElectionType.mp, embedded: true),
    ResultsScreen(embedded: true),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, context.tr('home')),
      (Icons.account_balance_outlined, Icons.account_balance, context.tr('mla')),
      (Icons.museum_outlined, Icons.museum, context.tr('mp')),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, context.tr('results')),
      (Icons.person_outline, Icons.person, context.tr('profile')),
    ];
    final body = ShellScope(
      go: _go,
      child: IndexedStack(index: _index, children: _pages),
    );

    if (kIsWeb && isWide(context)) {
      return ShellScope(
        go: _go,
        child: DesktopShell(
          index: _index,
          onSelect: _go,
          body: IndexedStack(index: _index, children: const [
            DesktopHome(),
            DesktopConstituencies(type: ElectionType.mla),
            DesktopConstituencies(type: ElectionType.mp),
            DesktopResults(),
            DesktopProfile(),
          ]),
        ),
      );
    }
    if (isWide(context)) {
      final extended = MediaQuery.sizeOf(context).width >= 1200;
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            extended: extended,
            selectedIndex: _index,
            onDestinationSelected: _go,
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: VoteWalaLogo(markSize: extended ? 64 : 48, horizontal: extended, tagline: false),
            ),
            destinations: [
              for (final it in items)
                NavigationRailDestination(icon: Icon(it.$1), selectedIcon: Icon(it.$2), label: Text(it.$3)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          for (final it in items) NavigationDestination(icon: Icon(it.$1), selectedIcon: Icon(it.$2), label: it.$3),
        ],
      ),
    );
  }
}

/// Back button for tab pages: returns to Home inside the shell, pops otherwise.
Widget? shellBackButton(BuildContext context, {required bool embedded}) {
  if (!embedded) return null;
  if (isWide(context)) return null;
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => ShellScope.maybeOf(context)?.go(ShellTab.home),
  );
}
