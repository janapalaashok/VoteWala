import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'constituency_detail_screen.dart';
import 'constituency_list_screen.dart';
import 'home_screen.dart';

/// Global search across districts and MLA / MP constituencies.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final q = _query.trim().toLowerCase();
    final districts = q.isEmpty
        ? const <District>[]
        : ApData.districts.where((d) => d.en.toLowerCase().contains(q) || d.te.contains(q)).toList();
    final constituencies = q.isEmpty
        ? const <Constituency>[]
        : [...ApData.mp, ...ApData.mla].where((c) => c.en.toLowerCase().contains(q) || c.te.contains(q)).toList();
    final people = q.length < 3
        ? const <Candidate>[]
        : [
            for (final c in [...ApData.mla, ...ApData.mp])
              for (final cand in PollRepository.candidates(c))
                if (cand.isPerson && cand.name(false).toLowerCase().contains(q)) cand,
          ];

    return Scaffold(
      appBar: PageBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SearchField(
            hint: context.tr('searchHint'),
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ),
      body: PageBody(
        child: q.isEmpty
            ? const SizedBox()
            : districts.isEmpty && constituencies.isEmpty && people.isEmpty
                ? EmptyState(icon: Icons.search_off, message: context.tr('noMatches'))
                : ListView(children: [
                    for (final d in districts)
                      ListTile(
                        leading: Icon(Icons.map_outlined, color: AppColors.green),
                        title: Text(d.name(te), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${context.tr('district')} · ${context.tr('nConstituencies', {'n': '${d.mlaCount}'})}'),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ConstituencyListScreen(type: ElectionType.mla, districtId: d.id),
                        )),
                      ),
                    for (final c in constituencies)
                      ListTile(
                        leading: Icon(c.isMla ? Icons.account_balance_outlined : Icons.museum_outlined,
                            color: AppColors.orange),
                        title: Text(c.name(te), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${c.isMla ? 'MLA' : 'MP'} · ${c.name(!te)}'),
                        onTap: () => openConstituency(context, c),
                      ),
                    for (final cand in people)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: CandidateListCard(candidate: cand, showConstituency: true),
                      ),
                  ]),
      ),
    );
  }
}

/// All open polls, busiest first.
class LivePollsScreen extends StatefulWidget {
  const LivePollsScreen({super.key});

  @override
  State<LivePollsScreen> createState() => _LivePollsScreenState();
}

class _LivePollsScreenState extends State<LivePollsScreen> {
  ElectionType _type = ElectionType.mla;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final polls = state.snapshots(_type)..sort((a, b) => b.total.compareTo(a.total));
    return Scaffold(
      appBar: PageBar(title: Text(context.tr('livePolls'))),
      body: PageBody(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: PillToggle(
              labels: [context.tr('mlaPolls'), context.tr('mpPolls')],
              selected: _type.index,
              onChanged: (i) => setState(() => _type = ElectionType.values[i]),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: polls.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => PollCard(snapshot: polls[i]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Browse every candidate, filterable by party and constituency.
class CandidatesDirectoryScreen extends StatefulWidget {
  const CandidatesDirectoryScreen({super.key});

  @override
  State<CandidatesDirectoryScreen> createState() => _CandidatesDirectoryScreenState();
}

class _CandidatesDirectoryScreenState extends State<CandidatesDirectoryScreen> {
  ElectionType _type = ElectionType.mla;
  String? _partyId;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final list = [
      for (final c in ApData.of(_type))
        if (c.matches(_query))
          for (final cand in PollRepository.candidates(c))
            if (cand.isPerson && (_partyId == null || cand.party.group == _partyId)) cand,
    ];
    return Scaffold(
      appBar: PageBar(title: Text(context.tr('candidates'))),
      body: PageBody(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: PillToggle(
              labels: [context.tr('mla'), context.tr('mp')],
              selected: _type.index,
              onChanged: (i) => setState(() => _type = ElectionType.values[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchField(hint: context.tr('searchConstituency'), onChanged: (v) => setState(() => _query = v)),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                for (final g in [null, ...seatGroups])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      avatar: g == null ? null : PartyDot(groupColor(g), size: 14),
                      label: Text(g == null ? context.tr('all') : groupLabel(context, g)),
                      selected: _partyId == g,
                      selectedColor: AppColors.orange.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _partyId = g),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(icon: Icons.search_off, message: context.tr('noMatches'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => CandidateListCard(candidate: list[i], showConstituency: true),
                  ),
          ),
        ]),
      ),
    );
  }
}
