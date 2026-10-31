import 'package:flutter/material.dart';

import '../config/config_service.dart';
import '../data/ap_data.dart';
import '../data/featured_polls.dart';
import '../data/poll_month.dart';
import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';
import 'ap_map_screen.dart';
import 'browse_screens.dart';
import 'closed_polls_screen.dart';
import 'constituency_detail_screen.dart';
import 'featured_poll_screen.dart';
import 'live_results_screen.dart';
import 'main_shell.dart';
import 'my_constituency_screen.dart';

void openConstituency(BuildContext context, Constituency c, {int tab = 0}) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ConstituencyDetailScreen(constituency: c, initialTab: tab)),
    );

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    AppScope.of(context); // rebuild when the admin config changes
    final home = appConfig.home;
    void push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            PageBody(
              maxWidth: 1000,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const _TopBar(),
                const SizedBox(height: 12),
                _Hero(onSearch: () => push(const SearchScreen())),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _PollTypeCard(
                      title: context.tr('mlaPolls'),
                      subtitle: context.tr('nConstituencies', {'n': '175'}),
                      color: AppColors.orange,
                      onTap: () => shell?.go(ShellTab.mla),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PollTypeCard(
                      title: context.tr('mpPolls'),
                      subtitle: context.tr('nConstituencies', {'n': '25'}),
                      color: AppColors.green,
                      onTap: () => shell?.go(ShellTab.mp),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _QuickAction(
                    icon: Icons.radio_button_checked,
                    label: context.tr('livePolls'),
                    color: AppColors.ink,
                    onTap: () => push(const LivePollsScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.insert_chart_outlined,
                    label: context.tr('results'),
                    color: AppColors.green,
                    onTap: () => shell?.go(ShellTab.results),
                  ),
                  _QuickAction(
                    icon: Icons.person_search_outlined,
                    label: context.tr('candidates'),
                    color: AppColors.blue,
                    onTap: () => push(const CandidatesDirectoryScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.map_outlined,
                    label: context.tr('apMap'),
                    color: AppColors.ink,
                    onTap: () => push(const ApMapScreen()),
                  ),
                ]),
                const SizedBox(height: 12),
                const SizedBox(height: 4),
                if (home.showMonthlyVotes) ...[
                  const MonthlyVotesCard(),
                  const SizedBox(height: 8),
                ],
                const YourConstituencyCard(),
                const SizedBox(height: 8),
                if (home.showTopSeats) ...[
                  SectionHeader(context.tr('topMlaSeats'),
                      action: context.tr('viewAll'), onAction: () => shell?.go(ShellTab.mla)),
                  _TopSeats(ids: home.topMla),
                  const SizedBox(height: 8),
                  SectionHeader(context.tr('topMpSeats'),
                      action: context.tr('viewAll'), onAction: () => shell?.go(ShellTab.mp)),
                  _TopSeats(ids: home.topMp),
                  const SizedBox(height: 8),
                ],
                if (home.showFeatured && (featuredPolls.isNotEmpty || closedFeaturedPolls.isNotEmpty)) ...[
                  SectionHeader(
                    context.tr('featuredPolls'),
                    action: closedFeaturedPolls.isEmpty ? null : context.tr('closedPolls'),
                    onAction: () => openClosedPolls(context),
                  ),
                  const _FeaturedPolls(),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Row(children: [
      if (!isWide(context)) const VoteWalaLogo(markSize: 46, horizontal: true),
      const Spacer(),
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          for (final (code, label) in [('en', 'EN'), ('te', 'తెలుగు')])
            GestureDetector(
              onTap: () => state.setLanguage(code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.language == code ? const Color(0xFFF1F2F4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: state.language == code ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ),
        ]),
      ),
    ]);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: wide ? 300 : 280,
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: HeroScenePainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((context.isTelugu ? appConfig.home.heroTitleTe : appConfig.home.heroTitleEn) ?? context.tr('heroTitle'),
                  style: TextStyle(
                      color: Colors.white, fontSize: wide ? 32 : 26, fontWeight: FontWeight.w800, height: 1.15)),
              if (!context.isTelugu) ...[
                const SizedBox(height: 6),
                const Text('మీ అభిప్రాయం. మీ ఎంపిక.',
                    style: TextStyle(color: AppColors.amber, fontSize: 19, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text((context.isTelugu ? appConfig.home.heroSubtitleTe : appConfig.home.heroSubtitleEn) ?? context.tr('heroSub'),
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4)),
              ),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SearchField(hint: context.tr('searchHint'), onTap: onSearch),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PollTypeCard extends StatelessWidget {
  const _PollTypeCard({required this.title, required this.subtitle, required this.color, required this.onTap});

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text(context.tr('voteNow'), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AppCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );
}

class MonthlyVotesCard extends StatelessWidget {
  const MonthlyVotesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final month = PollMonth.current();
    final shell = ShellScope.maybeOf(context);
    Widget row(ElectionType type, String label, int tab) {
      final vote = state.monthlyVote(type);
      return InkWell(
        onTap: () => vote == null ? shell?.go(tab) : openConstituency(context, vote.constituency),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Icon(vote == null ? Icons.how_to_vote_outlined : Icons.check_circle,
                color: vote == null ? AppColors.orange : AppColors.green, size: 22),
            const SizedBox(width: 10),
            SizedBox(width: 44, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
            Expanded(
              child: Text(
                vote == null
                    ? context.tr('voteAvailable')
                    : context.tr('voteUsedIn', {'name': '${vote.name(te)} (${vote.constituency.name(te)})'}),
                style: TextStyle(color: vote == null ? AppColors.orange : AppColors.ink, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
        ),
      );
    }

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.tr('yourVotesMonth', {'month': month.label(te)}),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        row(ElectionType.mla, 'MLA', ShellTab.mla),
        row(ElectionType.mp, 'MP', ShellTab.mp),
        const SizedBox(height: 6),
        Text(context.tr('monthlyRule'), style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)),
      ]),
    );
  }
}

bool _validId(String id) {
  try {
    ApData.byId(id);
    return true;
  } catch (_) {
    return false;
  }
}

class _TopSeats extends StatelessWidget {
  const _TopSeats({required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return LayoutBuilder(builder: (context, box) {
      final columns = box.maxWidth >= 900 ? 3 : (box.maxWidth >= 600 ? 2 : 1);
      final w = (box.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(spacing: 12, runSpacing: 10, children: [
        for (final id in ids)
          if (_validId(id)) SizedBox(width: w, child: PollCard(snapshot: state.snapshot(ApData.byId(id)))),
      ]);
    });
  }
}

class _FeaturedPolls extends StatelessWidget {
  const _FeaturedPolls();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final columns = box.maxWidth >= 900 ? 3 : (box.maxWidth >= 600 ? 2 : 1);
      final w = (box.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final p in featuredPolls) SizedBox(width: w, child: FeaturedPollCard(poll: p)),
      ]);
    });
  }
}

/// Summary card for a poll: name, live state, share bar, leader and a vote button.
class PollCard extends StatelessWidget {
  const PollCard({super.key, required this.snapshot});

  final PollSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = snapshot.constituency;
    final te = context.isTelugu;
    final leader = snapshot.candidates[snapshot.leader];
    final state = AppScope.of(context);
    final voted = state.choiceIndex(c) != null;
    return AppCard(
      onTap: () => openConstituency(context, c),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: 66,
            height: 42,
            child: Stack(children: [
              CandidateAvatar(snapshot.candidates[0], size: 42),
              Positioned(left: 26, child: CandidateAvatar(snapshot.candidates[1], size: 42)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name(te), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(
                '${c.name(!te)} · ${c.isMla ? context.tr('mla') : context.tr('mp')}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ]),
          ),
          LiveBadge(closed: snapshot.closed),
        ]),
        const SizedBox(height: 12),
        ShareBar(snapshot),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
              snapshot.hasVotes
                  ? '${leader.name(te)} (${leader.party.shortName(te)}) ${context.tr('leading')} · '
                      '${votesText(context, snapshot.total)}'
                  : context.tr('beFirst'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ),
          if (!snapshot.closed && state.canVote(c))
            SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: () => openConstituency(context, c),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(context.tr('voteNow')),
              ),
            )
          else ...[
            if (voted) ...[
              Icon(Icons.check_circle, color: AppColors.green, size: 20),
              const SizedBox(width: 6),
            ],
            SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => LiveResultsScreen(constituency: c))),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(context.tr('seeResults')),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}
