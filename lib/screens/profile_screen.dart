import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'achievements_screen.dart';
import 'login_screen.dart';
import 'info_screens.dart';
import 'legal_screens.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _chooseLanguage(BuildContext context) async {
    final state = AppScope.read(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (code, label) in [('en', 'English'), ('te', 'తెలుగు')])
            ListTile(
              title: Text(label),
              trailing: state.language == code ? Icon(Icons.check, color: AppColors.orange) : null,
              onTap: () {
                state.setLanguage(code);
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('signOutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('signOut'))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    AppScope.read(context).signOut();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  /// Lets a Google user also sign in with email + password.
  Future<void> _setPassword(BuildContext context) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final state = AppScope.read(context);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ctx.tr('setPassword')),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(ctx.tr('setPasswordSub', {'email': state.user?.email ?? ''}),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: ctx.tr('password'))),
              const SizedBox(height: 8),
              TextField(controller: confirm, obscureText: true, decoration: InputDecoration(labelText: ctx.tr('confirmPassword'))),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
            FilledButton(
              onPressed: () async {
                if (password.text.length < 6) return setLocal(() => error = ctx.tr('weakPassword'));
                if (password.text != confirm.text) return setLocal(() => error = ctx.tr('passwordsDontMatch'));
                final done = ctx.tr('passwordSet');
                try {
                  await state.auth.setPassword(password.text);
                  await state.refreshUser();
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(SnackBar(content: Text(done)));
                } catch (e) {
                  setLocal(() => error = ctx.tr(authMessage(e)));
                }
              },
              child: Text(ctx.tr('save')),
            ),
          ],
        ),
      ),
    );
    password.dispose();
    confirm.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user;
    final initials = (user?.name ?? 'V').trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

    Widget item(IconData icon, String label, VoidCallback onTap, {String? trailing}) => ListTile(
          leading: Icon(icon, color: AppColors.ink),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (trailing != null) Text(trailing, style: const TextStyle(color: AppColors.muted)),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
          onTap: onTap,
        );

    Widget verifiedChip() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFE8F6EC), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle, size: 13, color: AppColors.green),
            const SizedBox(width: 4),
            Text(context.tr('verified'),
                style: TextStyle(color: AppColors.green, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ]),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(context.tr('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _push(context, const NotificationSettingsScreen()),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        PageBody(
          maxWidth: 640,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                  child: Text(initials,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.orange)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    verifiedChip(),
                    if (user?.email != null) ...[
                      const SizedBox(height: 6),
                      Text(user!.email!, style: const TextStyle(color: AppColors.muted)),
                    ],
                    if (user?.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Text(user!.phone!, style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(width: 8),
                        verifiedChip(),
                      ]),
                    ],
                  ]),
                ),
              ]),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: AchievementsStrip()),
            const Divider(),
            if (user != null && user.email != null && !user.hasPassword && user.provider == 'google')
              item(Icons.password, context.tr('setPassword'), () => _setPassword(context)),
            item(Icons.how_to_vote_outlined, context.tr('myParticipation'),
                () => _push(context, const MyParticipationScreen()),
                trailing: '${state.voteHistory.length}'),
            item(Icons.bookmark_border, context.tr('savedCandidates'),
                () => _push(context, const SavedCandidatesScreen()),
                trailing: '${state.savedCandidates.length}'),
            item(Icons.notifications_none, context.tr('notificationSettings'),
                () => _push(context, const NotificationSettingsScreen())),
            item(Icons.language, context.tr('language'), () => _chooseLanguage(context),
                trailing: state.isTelugu ? 'తెలుగు' : 'English'),
            item(Icons.privacy_tip_outlined, context.tr('privacyPolicy'), () => openLegal(context, 'privacy')),
            item(Icons.description_outlined, context.tr('terms'), () => openLegal(context, 'terms')),
            item(Icons.gavel_outlined, context.tr('legalPolicies'), () => openLegalIndex(context)),
            item(Icons.info_outline, context.tr('aboutApp'),
                () => _push(context, const InfoScreen(titleKey: 'aboutApp', bodyKey: 'aboutBody', showVersion: true))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: OutlinedButton(
                onPressed: () => _signOut(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                ),
                child: Text(context.tr('signOut')),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
