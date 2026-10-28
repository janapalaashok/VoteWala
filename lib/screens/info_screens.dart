import 'package:flutter/material.dart';

import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'constituency_detail_screen.dart';
import 'home_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.titleKey, required this.bodyKey, this.showVersion = false});

  final String titleKey;
  final String bodyKey;
  final bool showVersion;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, title: Text(context.tr(titleKey))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          PageBody(
            maxWidth: 640,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (showVersion) ...[
                const Center(child: VoteWalaLogo(markSize: 90)),
                const SizedBox(height: 24),
              ],
              Text(context.tr(bodyKey), style: const TextStyle(height: 1.6, fontSize: 15)),
              if (showVersion) ...[
                const SizedBox(height: 24),
                Text(context.tr('version'), style: const TextStyle(color: AppColors.muted)),
              ],
            ]),
          ),
        ]),
      );
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    Widget toggle(String key, String title, String sub) => SwitchListTile(
          value: state.notification(key),
          onChanged: (v) => state.setNotification(key, v),
          title: Text(context.tr(title), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(context.tr(sub)),
        );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: Text(context.tr('notificationSettings'))),
      body: PageBody(
        maxWidth: 640,
        child: ListView(children: [
          toggle('daily', 'dailyReminders', 'dailyRemindersSub'),
          toggle('results', 'resultUpdates', 'resultUpdatesSub'),
          toggle('featured', 'featuredAlerts', 'featuredAlertsSub'),
        ]),
      ),
    );
  }
}

class MyParticipationScreen extends StatelessWidget {
  const MyParticipationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = AppScope.of(context).voteHistory;
    final te = context.isTelugu;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('myParticipation'))),
      body: history.isEmpty
          ? EmptyState(icon: Icons.how_to_vote_outlined, message: context.tr('noVotesYet'))
          : PageBody(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final v = history[i];
                  final cand = v.candidate;
                  final c = cand.constituency;
                  return AppCard(
                    onTap: () => openConstituency(context, c),
                    child: Row(children: [
                      CandidateAvatar(cand, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${c.name(te)} · ${c.isMla ? 'MLA' : 'MP'}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${cand.name(te)} (${cand.party.shortName(te)})',
                              style: const TextStyle(color: AppColors.muted)),
                        ]),
                      ),
                      Text(v.month.label(te), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ]),
                  );
                },
              ),
            ),
    );
  }
}

class SavedCandidatesScreen extends StatelessWidget {
  const SavedCandidatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = AppScope.of(context).savedCandidates.map(Candidate.byId).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('savedCandidates'))),
      body: saved.isEmpty
          ? EmptyState(icon: Icons.bookmark_border, message: context.tr('noSaved'))
          : PageBody(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: saved.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => CandidateListCard(candidate: saved[i], showConstituency: true),
              ),
            ),
    );
  }
}
