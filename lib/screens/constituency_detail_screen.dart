import 'dart:async';

import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'candidate_detail_screen.dart';
import 'home_screen.dart';
import 'live_results_screen.dart';

class ConstituencyDetailScreen extends StatelessWidget {
  const ConstituencyDetailScreen({super.key, required this.constituency, this.initialTab = 0});

  final Constituency constituency;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final c = constituency;
    final te = context.isTelugu;
    final snapshot = AppScope.of(context).snapshot(c);
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => sharePoll(context, c))],
        ),
        body: PageBody(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '${c.name(te)}\n${context.tr(c.isMla ? 'assemblyConstituency' : 'parliamentConstituency')}',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.25),
                    ),
                    const SizedBox(height: 4),
                    Text(c.name(!te), style: const TextStyle(fontSize: 16, color: AppColors.muted)),
                  ]),
                ),
                Blob(color: snapshot.candidates[snapshot.leader].party.color, seed: c.no + (c.isMla ? 0 : 500), size: 40),
              ]),
            ),
            TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
              Tab(text: context.tr('poll')),
              Tab(text: context.tr('candidates')),
              Tab(text: context.tr('results')),
              Tab(text: context.tr('about')),
            ]),
            Expanded(
              child: TabBarView(children: [
                _PollTab(constituency: c),
                _CandidatesTab(constituency: c),
                _ResultsTab(constituency: c),
                _AboutTab(constituency: c),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PollTab extends StatefulWidget {
  const _PollTab({required this.constituency});

  final Constituency constituency;

  @override
  State<_PollTab> createState() => _PollTabState();
}

class _PollTabState extends State<_PollTab> {
  int? _selected;

  Future<void> _submit(List<Candidate> candidates) async {
    final te = context.isTelugu;
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('selectCandidate'))));
      return;
    }
    final candidate = candidates[_selected!];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('confirmVote')),
        content: Text(ctx.tr('confirmVoteBody', {'name': candidate.name(te), 'party': candidate.party.short})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('confirm'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    AppScope.read(context).castVote(candidate);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.green,
      content: Text(context.tr('voteRecorded')),
    ));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LiveResultsScreen(constituency: widget.constituency)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.constituency;
    final te = context.isTelugu;
    final state = AppScope.of(context);
    final snapshot = state.snapshot(c);
    final candidates = snapshot.candidates;
    final voted = state.choiceIndex(c);
    final locked = voted != null || snapshot.closed;
    final typeLabel = context.tr(c.isMla ? 'assemblyConstituency' : 'parliamentConstituency');

    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        LiveBadge(closed: snapshot.closed, long: true),
        const Spacer(),
        if (!snapshot.closed) ...[
          Text(context.tr('closesIn'), style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          const SizedBox(width: 8),
          const _Countdown(),
        ],
      ]),
      const SizedBox(height: 18),
      Text(context.tr('question', {'name': c.name(te), 'type': typeLabel}),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3)),
      if (!te) ...[
        const SizedBox(height: 6),
        Text('${c.te} ${c.isMla ? 'అసెంబ్లీ నియోజకవర్గంలో' : 'పార్లమెంట్ నియోజకవర్గంలో'} మీ మద్దతు ఎవరికి?',
            style: const TextStyle(color: AppColors.muted, height: 1.3)),
      ],
      const SizedBox(height: 16),
      for (final cand in candidates)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CandidateOption(
            candidate: cand,
            selected: (voted ?? _selected) == cand.index,
            onTap: locked ? null : () => setState(() => _selected = cand.index),
          ),
        ),
      const SizedBox(height: 10),
      if (voted != null)
        _Notice(
          icon: Icons.check_circle,
          color: AppColors.green,
          text: context.tr('youVotedFor', {'name': '${candidates[voted].name(te)} (${candidates[voted].party.short})'}),
        )
      else if (snapshot.closed)
        _Notice(icon: Icons.lock_outline, color: AppColors.muted, text: '${context.tr('pollClosedBody')} ${context.tr('nextPoll')}'),
      const SizedBox(height: 10),
      if (locked)
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => LiveResultsScreen(constituency: c))),
          icon: const Icon(Icons.bar_chart_rounded),
          label: Text(context.tr('viewLiveResults')),
        )
      else
        FilledButton(onPressed: () => _submit(candidates), child: Text(context.tr('submitVote'))),
    ]);
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown();

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE8F6EC), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.schedule, size: 14, color: AppColors.green),
          const SizedBox(width: 4),
          Text(formatCountdown(timeUntilPollClose()),
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                fontFeatures: [FontFeature.tabularFigures()],
              )),
        ]),
      );
}

class _CandidateOption extends StatelessWidget {
  const _CandidateOption({required this.candidate, required this.selected, this.onTap});

  final Candidate candidate;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        borderColor: selected ? AppColors.orange : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          CandidateAvatar(candidate, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(candidate.name(context.isTelugu), style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(candidate.party.short, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ]),
          ),
          PartySymbolBadge(candidate.party, size: 42),
          const SizedBox(width: 16),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? AppColors.orange : AppColors.grey,
          ),
        ]),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
      );
}

class _CandidatesTab extends StatelessWidget {
  const _CandidatesTab({required this.constituency});

  final Constituency constituency;

  @override
  Widget build(BuildContext context) {
    final candidates = PollRepository.candidates(constituency);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: candidates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => CandidateListCard(candidate: candidates[i]),
    );
  }
}

class CandidateListCard extends StatelessWidget {
  const CandidateListCard({super.key, required this.candidate, this.showConstituency = false});

  final Candidate candidate;
  final bool showConstituency;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    return AppCard(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => CandidateDetailScreen(candidate: candidate))),
      child: Row(children: [
        CandidateAvatar(candidate, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(candidate.name(te), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(candidate.party.name(te), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            if (showConstituency)
              Text(candidate.constituency.name(te), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ]),
        ),
        PartySymbolBadge(candidate.party, size: 40),
        const Icon(Icons.chevron_right, color: AppColors.muted),
      ]),
    );
  }
}

class _ResultsTab extends StatelessWidget {
  const _ResultsTab({required this.constituency});

  final Constituency constituency;

  @override
  Widget build(BuildContext context) {
    final snapshot = AppScope.of(context).snapshot(constituency);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        LiveBadge(closed: snapshot.closed),
        const Spacer(),
        Text('${context.tr('totalVotes')}: ${formatIndian(snapshot.total)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      ]),
      const SizedBox(height: 8),
      for (final i in snapshot.ranking) ResultRow(snapshot: snapshot, index: i, highlight: i == snapshot.leader),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => LiveResultsScreen(constituency: constituency))),
        icon: const Icon(Icons.open_in_full),
        label: Text(context.tr('liveResults')),
      ),
    ]);
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.constituency});

  final Constituency constituency;

  @override
  Widget build(BuildContext context) {
    final c = constituency;
    final te = context.isTelugu;
    final pc = ApData.pcFor(c);
    Widget row(String label, String value, {VoidCallback? onTap}) => ListTile(
          title: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          subtitle: Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: onTap == null ? AppColors.ink : AppColors.blue,
              )),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right),
          onTap: onTap,
        );
    return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
      row(context.tr('constituencyNo'), '${c.no}'),
      row(context.tr('electionType'), context.tr(c.isMla ? 'assemblyMla' : 'parliamentMp')),
      row(context.tr(c.districtIds.length > 1 ? 'districts' : 'district'), c.districts.map((d) => d.name(te)).join(', ')),
      if (pc != null)
        row(context.tr('parliamentConstituency'), pc.name(te), onTap: () => openConstituency(context, pc)),
      row(context.tr('candidates'), '${parties.length}'),
      row(context.tr('pollSchedule'), context.tr('pollScheduleBody')),
      if (!c.isMla) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(context.tr('segments'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        for (final no in c.segments)
          ListTile(
            dense: true,
            leading: Text('$no', style: const TextStyle(color: AppColors.muted)),
            title: Text(ApData.mla[no - 1].name(te), style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openConstituency(context, ApData.mla[no - 1]),
          ),
      ],
    ]);
  }
}
