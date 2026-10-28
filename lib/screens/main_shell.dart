import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';
import 'constituency_list_screen.dart';
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
  int _index = 0;

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
      go: (i) => setState(() => _index = i),
      child: IndexedStack(index: _index, children: _pages),
    );

    if (isWide(context)) {
      final extended = MediaQuery.sizeOf(context).width >= 1200;
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            extended: extended,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: VoteWalaLogo(markSize: 44, horizontal: extended, tagline: false),
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
        onDestinationSelected: (i) => setState(() => _index = i),
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
