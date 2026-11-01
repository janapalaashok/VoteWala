import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils.dart';
import '../state/url_sync.dart';
import 'admin_controller.dart';
import 'admin_widgets.dart';
import 'pages/branding_page.dart';
import 'pages/candidates_page.dart';
import 'pages/constituencies_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/analytics_page.dart';
import 'pages/traffic_page.dart';
import 'pages/civic_settings_page.dart';
import 'pages/featured_page.dart';
import 'pages/issues_page.dart';
import 'pages/review_pages.dart';
import 'pages/team_pages.dart';
import 'pages/home_page.dart';
import 'pages/parties_page.dart';
import 'pages/profile_page.dart';
import 'pages/publish_page.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final AdminController _controller = AdminController(widget.prefs);

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: AdminColors.accent, primary: AdminColors.accent, surface: Colors.white);
    const radius = BorderRadius.all(Radius.circular(12));
    return AdminScope(
      controller: _controller,
      child: MaterialApp(
        title: 'VoteWala Admin',
        // The admin console keeps its own address: votewala.in/admin
        initialRoute: '/',
        navigatorObservers: [UrlSync.instance..setRoot('/admin')],
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: AdminColors.bg,
          inputDecorationTheme: const InputDecorationThemeData(
            filled: true,
            fillColor: Color(0xFFF8FAFC),
            isDense: true,
            border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AdminColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AdminColors.border)),
            focusedBorder:
                OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AdminColors.accent, width: 1.6)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: radius),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: radius),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              side: const BorderSide(color: AdminColors.border),
            ),
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        home: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => !_controller.signedIn
              ? const AdminLoginPage()
              : _controller.mustChangePassword
                  ? const ForcePasswordChangePage()
                  : const AdminShell(),
        ),
      ),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF3B1D0A)],
          ),
        ),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 440,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 480 ? 24 : 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 60, offset: Offset(0, 24))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Image.asset('assets/brand/logo.png', height: 64)),
              const SizedBox(height: 24),
              const Text('Admin Console',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Manage branding, candidates, polls and website content',
                  textAlign: TextAlign.center, style: TextStyle(color: AdminColors.muted)),
              const SizedBox(height: 28),
              if (admin.demo) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Text(
                    'Demo mode: Firebase is not connected yet. Changes are saved in this browser only and do not '
                    'reach the app or other visitors. See docs/FIREBASE_SETUP.md to connect.',
                    style: TextStyle(fontSize: 13, height: 1.45),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: admin.enterDemo, child: const Text('Enter demo admin')),
              ] else ...[
                TextField(
                  controller: _email,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => admin.signIn(_email.text.trim(), _password.text),
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                if (admin.error != null) ...[
                  const SizedBox(height: 12),
                  Text(admin.error!, style: const TextStyle(color: AdminColors.danger)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: admin.busy ? null : () => admin.signIn(_email.text.trim(), _password.text),
                  child: admin.busy
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                      : const Text('Sign in'),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.page);

  final IconData icon;
  final String label;
  final Widget page;
}

const _nav = [
  _NavItem(Icons.space_dashboard_outlined, 'Dashboard', DashboardPage()),
  _NavItem(Icons.palette_outlined, 'Branding', BrandingPage()),
  _NavItem(Icons.flag_outlined, 'Parties', PartiesPage()),
  _NavItem(Icons.people_alt_outlined, 'Candidates', CandidatesPage()),
  _NavItem(Icons.map_outlined, 'Constituencies', ConstituenciesPage()),
  _NavItem(Icons.how_to_vote_outlined, 'Featured polls', FeaturedPage()),
  _NavItem(Icons.web_outlined, 'Home & website', HomeContentPage()),
  _NavItem(Icons.report_outlined, 'Local issues & alerts', IssuesPage()),
  _NavItem(Icons.photo_library_outlined, 'Photo review', PhotosPage()),
  _NavItem(Icons.gavel_outlined, 'Grievances', GrievancesPage()),
  _NavItem(Icons.travel_explore_outlined, 'Traffic', TrafficPage()),
  _NavItem(Icons.insights_outlined, 'Analytics', AnalyticsPage()),
  _NavItem(Icons.tune_outlined, 'Issues, badges & sharing', CivicSettingsPage()),
  _NavItem(Icons.people_alt_outlined, 'Users', UsersPage()),
  _NavItem(Icons.article_outlined, 'Legal pages', LegalPagesPage()),
  _NavItem(Icons.admin_panel_settings_outlined, 'Admins', AdminsPage()),
  _NavItem(Icons.cloud_upload_outlined, 'Publish & backup', PublishPage()),
  _NavItem(Icons.account_circle_outlined, 'My profile', AdminProfilePage()),
];

/// Lets pages jump to another section.
class AdminNav extends InheritedWidget {
  const AdminNav({super.key, required this.go, required super.child});

  final void Function(String label) go;

  static AdminNav of(BuildContext context) => context.getInheritedWidgetOfExactType<AdminNav>()!;

  @override
  bool updateShouldNotify(AdminNav oldWidget) => false;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 1000;

    final sidebar = Container(
      width: narrow ? 76 : 260,
      color: AdminColors.sidebar,
      child: Column(children: [
        const SizedBox(height: 24),
        Container(
          margin: EdgeInsets.symmetric(horizontal: narrow ? 10 : 20),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: narrow
              ? Image.asset('assets/brand/mark.png', height: 34)
              : Image.asset('assets/brand/logo.png', height: 40),
        ),
        if (!narrow)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('ADMIN CONSOLE',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 22),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (var i = 0; i < _nav.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: i == _index ? AdminColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    hoverColor: AdminColors.sidebarHover,
                    onTap: () => setState(() => _index = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: narrow ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          Icon(_nav[i].icon, color: Colors.white, size: 21),
                          if (!narrow) ...[
                            const SizedBox(width: 12),
                            Text(_nav[i].label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: i == _index ? FontWeight.w700 : FontWeight.w500,
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        if (!narrow)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              InkWell(
                onTap: () => setState(() => _index = _nav.length - 1),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AdminColors.accent,
                  child: Text((admin.username.isEmpty ? 'A' : admin.username)[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(admin.displayName?.isNotEmpty == true ? admin.displayName! : admin.username,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: admin.signOut,
                icon: const Icon(Icons.logout, color: Color(0xFF94A3B8), size: 20),
              ),
            ]),
          ),
      ]),
    );

    final updated = admin.published.updatedAt;
    final compact = MediaQuery.sizeOf(context).width < 1180;
    final topBar = Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _StatusPills(admin: admin, updated: updated, iconsOnly: compact),
          ),
        ),
        const SizedBox(width: 12),
        if (admin.busy) const Padding(
          padding: EdgeInsets.only(right: 16),
          child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
        ),
        if (compact)
          IconButton(tooltip: 'View website', onPressed: launchSite, icon: const Icon(Icons.open_in_new))
        else
          TextButton(
            onPressed: () => launchSite(),
            child: const Text('View website'),
          ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: admin.dirty ? admin.discardDraft : null,
          child: const Text('Discard'),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: admin.dirty && !admin.busy ? () => _publish(context, admin) : null,
          icon: const Icon(Icons.rocket_launch_outlined, size: 18),
          label: const Text('Publish'),
        ),
      ]),
    );

    final errorBanner = admin.error != null && admin.signedIn
        ? MaterialBanner(
            backgroundColor: const Color(0xFFFEF2F2),
            content: Text(admin.error!, style: const TextStyle(color: AdminColors.danger)),
            actions: [TextButton(onPressed: admin.clearError, child: const Text('Dismiss'))],
          )
        : null;

    if (isAdminPhone(context)) {
      return AdminNav(
        go: (label) => setState(() => _index = _nav.indexWhere((n) => n.label == label)),
        child: _PhoneShell(
          index: _index,
          onSelect: (i) => setState(() => _index = i),
          errorBanner: errorBanner,
        ),
      );
    }

    return AdminNav(
      go: (label) => setState(() => _index = _nav.indexWhere((n) => n.label == label)),
      child: Scaffold(
        body: Row(children: [
          sidebar,
          Expanded(
            child: Column(children: [
              topBar,
              ?errorBanner,
              Expanded(child: _nav[_index].page),
            ]),
          ),
        ]),
      ),
    );
  }
}

Future<void> _publish(BuildContext context, AdminController admin) async {
  final ok = await admin.publish();
  if (context.mounted) {
    showAdminSnack(context, ok ? 'Published. Users see the changes on next open.' : admin.error ?? 'Failed', error: !ok);
  }
}

class _StatusPills extends StatelessWidget {
  const _StatusPills({required this.admin, required this.updated, this.iconsOnly = false});

  final AdminController admin;
  final DateTime? updated;
  final bool iconsOnly;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        if (admin.demo)
          _Pill(icon: Icons.science_outlined, label: 'Demo mode', color: const Color(0xFFEA580C), iconOnly: iconsOnly)
        else
          _Pill(
              icon: Icons.cloud_done_outlined, label: 'Firebase connected', color: AdminColors.success, iconOnly: iconsOnly),
        const SizedBox(width: 8),
        if (admin.dirty)
          _Pill(icon: Icons.edit_note, label: 'Unpublished changes', color: const Color(0xFF2563EB))
        else
          _Pill(
            icon: Icons.check_circle_outline,
            label: updated == null ? 'Using built-in defaults' : 'Published ${formatDate(updated!.toLocal())}',
            color: AdminColors.muted,
          ),
      ]);
}

/// Phone layout: top bar with the page name, menu drawer with every
/// section, and Publish always within reach.
class _PhoneShell extends StatelessWidget {
  const _PhoneShell({required this.index, required this.onSelect, this.errorBanner});

  final int index;
  final ValueChanged<int> onSelect;
  final Widget? errorBanner;

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final updated = admin.published.updatedAt;
    final name = admin.displayName?.isNotEmpty == true ? admin.displayName! : admin.username;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        shape: const Border(bottom: BorderSide(color: AdminColors.border)),
        title: Text(_nav[index].label,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          if (admin.busy)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 38),
              ),
              onPressed: admin.dirty && !admin.busy ? () => _publish(context, admin) : null,
              child: const Text('Publish'),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) => switch (v) {
              'site' => launchSite(),
              'discard' => admin.discardDraft(),
              'out' => admin.signOut(),
              _ => null,
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'site', child: Text('View website')),
              PopupMenuItem(value: 'discard', enabled: admin.dirty, child: const Text('Discard changes')),
              const PopupMenuItem(value: 'out', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AdminColors.sidebar,
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Image.asset('assets/brand/logo.png', height: 36),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 14),
              child: Text('ADMIN CONSOLE',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                for (var i = 0; i < _nav.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Material(
                      color: i == index ? AdminColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: Icon(_nav[i].icon, color: Colors.white, size: 21),
                        title: Text(_nav[i].label,
                            style: TextStyle(
                                color: Colors.white, fontSize: 14.5, fontWeight: i == index ? FontWeight.w700 : FontWeight.w500)),
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(i);
                        },
                      ),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
              child: Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AdminColors.accent,
                  child: Text((name.isEmpty ? 'A' : name)[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: admin.signOut,
                  icon: const Icon(Icons.logout, color: Color(0xFF94A3B8), size: 20),
                ),
              ]),
            ),
          ]),
        ),
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _StatusPills(admin: admin, updated: updated),
          ),
        ),
        ?errorBanner,
        Expanded(child: _nav[index].page),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color, this.iconOnly = false});

  final IconData icon;
  final String label;
  final Color color;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: iconOnly ? 8 : 12, vertical: 7),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: color),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ]),
        ),
      );
}

/// Opens the public website (same origin, without the admin route).
void launchSite() => launchUrl(Uri.base.removeFragment(), webOnlyWindowName: '_blank');
