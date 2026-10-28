import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'info_screens.dart';
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
              trailing: state.language == code ? const Icon(Icons.check, color: AppColors.orange) : null,
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
            const Icon(Icons.check_circle, size: 13, color: AppColors.green),
            const SizedBox(width: 4),
            Text(context.tr('verified'),
                style: const TextStyle(color: AppColors.green, fontSize: 11.5, fontWeight: FontWeight.w600)),
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.orange)),
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
            const Divider(),
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
            item(Icons.privacy_tip_outlined, context.tr('privacyPolicy'),
                () => _push(context, const InfoScreen(titleKey: 'privacyPolicy', bodyKey: 'privacyBody'))),
            item(Icons.description_outlined, context.tr('terms'),
                () => _push(context, const InfoScreen(titleKey: 'terms', bodyKey: 'termsBody'))),
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
