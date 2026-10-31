import 'package:flutter/material.dart';

import '../../data/ap_data.dart';
import '../../data/featured_polls.dart';
import '../../data/poll_month.dart';
import '../../data/poll_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../featured_poll_screen.dart';
import '../home_screen.dart';
import '../live_results_screen.dart';
import '../main_shell.dart';

const _shadow = [BoxShadow(color: Color(0x0F0F172A), blurRadius: 32, offset: Offset(0, 14))];

BoxDecoration _card() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
      boxShadow: _shadow,
    );

void _openResults(BuildContext context, Constituency c) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiveResultsScreen(constituency: c)));

void _openFeatured(BuildContext context, FeaturedPoll p) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FeaturedPollScreen(poll: p)));

/// "Vote now" when the user can still vote, otherwise "See results".
class PollAction extends StatelessWidget {
  const PollAction({super.key, required this.canVote, required this.voted, required this.onVote, required this.onResults});

  final bool canVote;
  final bool voted;
  final VoidCallback onVote;
  final VoidCallback onResults;

  @override
  Widget build(BuildContext context) {
    if (canVote) {
      return FilledButton.icon(
        onPressed: onVote,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 18)),
        icon: const Icon(Icons.how_to_vote, size: 18),
        label: Text(context.tr('voteNow')),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (voted) ...[
        Icon(Icons.check_circle, color: AppColors.green, size: 18),
        const SizedBox(width: 4),
        Text(context.tr('voted'), style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(width: 10),
      ],
      OutlinedButton.icon(
        onPressed: onResults,
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 16)),
        icon: const Icon(Icons.insights, size: 18),
        label: Text(context.tr('seeResults')),
      ),
    ]);
  }
}

// ------------------------------------------------------------ featured polls

/// Featured Polls on the desktop dashboard: your monthly votes, then each
/// statewide poll, two per row with equal heights.
class DesktopFeatured extends StatelessWidget {
  const DesktopFeatured({super.key, required this.showMonthlyVotes});

  final bool showMonthlyVotes;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (showMonthlyVotes) const _MyVotesCard(),
      for (final p in featuredPolls) _FeaturedTile(poll: p),
    ];
    return Column(children: [
      for (var i = 0; i < items.length; i += 2)
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < items.length ? 20 : 0),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: items[i]),
              const SizedBox(width: 20),
              Expanded(child: i + 1 < items.length ? items[i + 1] : const SizedBox()),
            ]),
          ),
        ),
    ]);
  }
}

class _MyVotesCard extends StatelessWidget {
  const _MyVotesCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final shell = ShellScope.maybeOf(context);
    Widget tile(ElectionType type, String label, int tab) {
      final vote = state.monthlyVote(type);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (vote == null ? AppColors.orange : AppColors.green).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const Spacer(),
              Icon(vote == null ? Icons.radio_button_unchecked : Icons.check_circle,
                  color: vote == null ? const Color(0xFFFFB27A) : const Color(0xFF6EE7A0)),
            ]),
            const SizedBox(height: 14),
            Text(
              vote == null ? context.tr('voteAvailable') : context.tr('voted'),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              vote == null ? context.tr('pickConstituencyToVote') : '${vote.name(te)} · ${vote.constituency.name(te)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB9C7DA), fontSize: 13, height: 1.35),
            ),
            const Spacer(),
            const SizedBox(height: 14),
            vote == null
                ? FilledButton(
                    onPressed: () => shell?.go(tab),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                    child: Text(context.tr('voteNow')),
                  )
                : OutlinedButton(
                    onPressed: () => _openResults(context, vote.constituency),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: Text(context.tr('seeResults')),
                  ),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1B33), Color(0xFF16406B)],
        ),
        boxShadow: _shadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.how_to_vote, color: Color(0xFFFFB27A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(context.tr('yourVotesMonth', {'month': PollMonth.current().label(te)}),
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(context.tr('monthlyRule'), style: const TextStyle(color: Color(0xFF9FB2C8), fontSize: 12.5, height: 1.4)),
        const SizedBox(height: 18),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            tile(ElectionType.mla, 'MLA', ShellTab.mla),
            const SizedBox(width: 14),
            tile(ElectionType.mp, 'MP', ShellTab.mp),
          ]),
        ),
      ]),
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({required this.poll});

  final FeaturedPoll poll;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final totals = state.featuredTotals(poll);
    final total = totals.fold(0, (a, b) => a + b);
    final order = List.generate(totals.length, (i) => i)..sort((a, b) => totals[b].compareTo(totals[a]));
    final mine = state.featuredChoice(poll);
    final canVote = poll.isOpen && mine == null;
    final status = poll.isOpen
        ? (poll.hasMonthlyUpdates
            ? context.tr('closesOn', {'date': formatDate(poll.end.subtract(const Duration(days: 1)))})
            : context.tr('daysLeft', {'n': '${timeUntil(poll.end).inDays + 1}'}))
        : context.tr('closedOn', {'date': formatDate(poll.end.subtract(const Duration(days: 1)))});

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _openFeatured(context, poll),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _card(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            FeaturedKindIcon(poll.kind),
            const SizedBox(width: 12),
            Expanded(child: Text(poll.title(te), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
            LiveBadge(closed: !poll.isOpen),
          ]),
          const SizedBox(height: 12),
          Text(poll.question(te), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 16),
          for (final i in order.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                FeaturedOptionAvatar(poll, i, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(
                        child: Text(poll.options[i].label(te),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: i == mine ? FontWeight.w800 : FontWeight.w600)),
                      ),
                      if (i == mine) ...[
                        Icon(Icons.check_circle, size: 15, color: AppColors.green),
                        const SizedBox(width: 6),
                      ],
                      Text(total == 0 ? '—' : '${(totals[i] * 100 / total).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : totals[i] / total,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFEFF1F5),
                        color: optionColor(poll, i),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          if (poll.options.length > 3)
            Text(context.tr('moreOptions', {'n': '${poll.options.length - 3}'}),
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const Spacer(),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(total == 0 ? context.tr('beFirst') : votesText(context, total),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(status, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
            ),
            PollAction(
              canVote: canVote,
              voted: mine != null,
              onVote: () => _openFeatured(context, poll),
              onResults: () => _openFeatured(context, poll),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- top seats

/// Top MLA / MP seats as head-to-head cards.
class DesktopSeatColumn extends StatelessWidget {
  const DesktopSeatColumn({super.key, required this.title, required this.icon, required this.ids, required this.tab});

  final String title;
  final IconData icon;
  final List<String> ids;
  final int tab;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final seats = [
      for (final id in ids)
        if (ApData.byIdOrNull(id) case final c?) state.snapshot(c),
    ];
    return Container(
      decoration: _card(),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 14, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFFFF4EA), Colors.white]),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Icon(icon, color: AppColors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
            TextButton(onPressed: () => ShellScope.maybeOf(context)?.go(tab), child: Text('${context.tr('viewAll')} →')),
          ]),
        ),
        for (var i = 0; i < seats.length; i++) _SeatCard(rank: i + 1, snapshot: seats[i], last: i == seats.length - 1),
      ]),
    );
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({required this.rank, required this.snapshot, required this.last});

  final int rank;
  final PollSnapshot snapshot;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final c = snapshot.constituency;
    final a = snapshot.candidates[0];
    final b = snapshot.candidates[1];
    final voted = state.choiceIndex(c) != null;
    final canVote = !snapshot.closed && state.canVote(c);
    final has = snapshot.hasVotes;

    Widget side(Candidate cand, int i, {required bool right}) => Expanded(
          child: Column(crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            Text(cand.name(te),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: right ? TextAlign.right : TextAlign.left,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            Text(
              has ? '${cand.party.shortName(te)} · ${(snapshot.share(i) * 100).toStringAsFixed(1)}%' : cand.party.shortName(te),
              style: TextStyle(color: cand.party.color, fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ]),
        );

    return InkWell(
      onTap: () => openConstituency(context, c),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rank <= 3 ? AppColors.orange.withValues(alpha: 0.12) : const Color(0xFFF1F3F6),
              ),
              child: Text('$rank',
                  style: TextStyle(fontWeight: FontWeight.w900, color: rank <= 3 ? AppColors.orange : AppColors.muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name(te), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                Text(
                  '${c.name(!te)} · ${has ? votesText(context, snapshot.total) : context.tr('beFirst')}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ]),
            ),
            PollAction(
              canVote: canVote,
              voted: voted,
              onVote: () => openConstituency(context, c),
              onResults: () => _openResults(context, c),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            CandidateAvatar(a, size: 42),
            const SizedBox(width: 10),
            side(a, 0, right: false),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(10)),
              child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.muted)),
            ),
            side(b, 1, right: true),
            const SizedBox(width: 10),
            CandidateAvatar(b, size: 42),
          ]),
          const SizedBox(height: 10),
          _HeadToHeadBar(snapshot: snapshot),
        ]),
      ),
    );
  }
}

/// Winner-2024 share | others | runner-up share, grey until someone votes.
class _HeadToHeadBar extends StatelessWidget {
  const _HeadToHeadBar({required this.snapshot});

  final PollSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    if (!s.hasVotes) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(height: 8, color: const Color(0xFFEFF1F5)),
      );
    }
    int flex(int i) => (s.share(i) * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 8,
        child: Row(children: [
          if (flex(0) > 0) Expanded(flex: flex(0), child: Container(color: s.candidates[0].party.color)),
          if (flex(2) > 0) Expanded(flex: flex(2), child: Container(color: const Color(0xFFCBD2DC))),
          if (flex(1) > 0) Expanded(flex: flex(1), child: Container(color: s.candidates[1].party.color)),
        ]),
      ),
    );
  }
}
