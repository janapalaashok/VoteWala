import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils.dart';
import 'admin_controller.dart';
import 'admin_widgets.dart';
import 'pages/branding_page.dart';
import 'pages/candidates_page.dart';
import 'pages/constituencies_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/analytics_page.dart';
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
            padding: const EdgeInsets.all(36),
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
    final topBar = Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(children: [
        if (admin.demo)
          _Pill(icon: Icons.science_outlined, label: 'Demo mode', color: const Color(0xFFEA580C))
        else
          _Pill(icon: Icons.cloud_done_outlined, label: 'Firebase connected', color: AdminColors.success),
        const SizedBox(width: 10),
        if (admin.dirty)
          _Pill(icon: Icons.edit_note, label: 'Unpublished changes', color: const Color(0xFF2563EB))
        else
          _Pill(
            icon: Icons.check_circle_outline,
            label: updated == null ? 'Using built-in defaults' : 'Published ${formatDate(updated.toLocal())}',
            color: AdminColors.muted,
          ),
        const Spacer(),
        if (admin.busy) const Padding(
          padding: EdgeInsets.only(right: 16),
          child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
        ),
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
          onPressed: admin.dirty && !admin.busy
              ? () async {
                  final ok = await admin.publish();
                  if (context.mounted) {
                    showAdminSnack(context, ok ? 'Published. Users see the changes on next open.' : admin.error ?? 'Failed',
                        error: !ok);
                  }
                }
              : null,
          icon: const Icon(Icons.rocket_launch_outlined, size: 18),
          label: const Text('Publish'),
        ),
      ]),
    );

    return AdminNav(
      go: (label) => setState(() => _index = _nav.indexWhere((n) => n.label == label)),
      child: Scaffold(
        body: Row(children: [
          sidebar,
          Expanded(
            child: Column(children: [
              topBar,
              if (admin.error != null && admin.signedIn)
                MaterialBanner(
                  backgroundColor: const Color(0xFFFEF2F2),
                  content: Text(admin.error!, style: const TextStyle(color: AdminColors.danger)),
                  actions: [TextButton(onPressed: admin.clearError, child: const Text('Dismiss'))],
                ),
              Expanded(child: _nav[_index].page),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
}

/// Opens the public website (same origin, without the admin route).
void launchSite() => launchUrl(Uri.base.removeFragment(), webOnlyWindowName: '_blank');
