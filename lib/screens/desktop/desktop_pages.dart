import 'package:flutter/material.dart';

import '../../data/ap_data.dart';
import '../../data/civic.dart';
import '../../data/poll_month.dart';
import '../../data/poll_repository.dart';
import '../../l10n/legal.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../achievements_screen.dart';
import '../ap_map_screen.dart';
import '../constituency_list_screen.dart';
import '../home_screen.dart';
import '../info_screens.dart';
import '../legal_screens.dart';
import '../live_results_screen.dart';
import '../profile_screen.dart';
import '../results_screen.dart';

const _maxWidth = 1240.0;

BoxDecoration _card() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 28, offset: Offset(0, 12))],
    );

/// Page title band shared by the desktop pages.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFFF4EA), Color(0xFFF4F8FF)]),
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                ]),
              ),
              ?trailing,
            ]),
          ),
        ),
      );
}

Widget _body(Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 56),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: _maxWidth), child: child)),
    );

void _results(BuildContext context, Constituency c) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiveResultsScreen(constituency: c)));

// ------------------------------------------------------------ constituencies

/// MLA or MP polls: district filter on the left, constituency cards on the right.
class DesktopConstituencies extends StatefulWidget {
  const DesktopConstituencies({super.key, required this.type});

  final ElectionType type;

  @override
  State<DesktopConstituencies> createState() => _DesktopConstituenciesState();
}

class _DesktopConstituenciesState extends State<DesktopConstituencies> {
  String _query = '';
  String? _district;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final mla = widget.type == ElectionType.mla;
    final all = ApData.of(widget.type);
    final shown = [
      for (final c in all)
        if (c.matches(_query) && (_district == null || c.districtIds.contains(_district))) c,
    ];
    final vote = state.monthlyVote(widget.type);
    final tally = SeatTally(state.snapshots(widget.type));

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: _Header(
          title: context.tr(mla ? 'mlaConstituencies' : 'mpConstituencies'),
          subtitle: '${all.length} ${context.tr('constituenciesWord')} · ${PollMonth.current().label(te)}',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: _card(),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(vote == null ? Icons.how_to_vote_outlined : Icons.check_circle,
                  color: vote == null ? AppColors.orange : AppColors.green),
              const SizedBox(width: 10),
              Text(
                vote == null
                    ? context.tr('voteAvailable')
                    : context.tr('voteUsedIn', {'name': '${vote.name(te)} (${vote.constituency.name(te)})'}),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 56),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 280,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SearchField(hint: context.tr('searchConstituency'), onChanged: (v) => setState(() => _query = v)),
                    const SizedBox(height: 16),
                    Container(
                      decoration: _card(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(children: [
                        _filter(context.tr('allDistricts'), all.length, null),
                        for (final d in ApData.districts)
                          _filter(d.name(te), all.where((c) => c.districtIds.contains(d.id)).length, d.id),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: _card(),
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(context.tr('seatsLeading'), style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        SeatTallyView(tally, majority: all.length ~/ 2 + 1),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: shown.isEmpty
                      ? EmptyState(icon: Icons.search_off, message: context.tr('noMatches'))
                      : LayoutBuilder(builder: (context, box) {
                          final cols = box.maxWidth >= 860 ? 3 : 2;
                          final w = (box.maxWidth - (cols - 1) * 18) / cols;
                          return Wrap(spacing: 18, runSpacing: 18, children: [
                            for (final c in shown) SizedBox(width: w, child: _ConstituencyCard(snapshot: state.snapshot(c))),
                          ]);
                        }),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _filter(String label, int count, String? id) {
    final selected = _district == id;
    return Material(
      color: selected ? AppColors.orange.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _district = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? AppColors.orange : AppColors.ink,
                  )),
            ),
            Text('$count', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ]),
        ),
      ),
    );
  }
}

class _ConstituencyCard extends StatelessWidget {
  const _ConstituencyCard({required this.snapshot});

  final PollSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final c = snapshot.constituency;
    final district = ApData.districts.firstWhere((d) => d.id == c.districtIds.first);
    final voted = state.choiceIndex(c) != null;
    final canVote = !snapshot.closed && state.canVote(c);

    Widget person(int i) {
      final cand = snapshot.candidates[i];
      return Row(children: [
        CandidateAvatar(cand, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cand.name(te), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(cand.party.shortName(te), style: TextStyle(color: cand.party.color, fontWeight: FontWeight.w800, fontSize: 11.5)),
          ]),
        ),
        if (snapshot.hasVotes)
          Text('${(snapshot.share(i) * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
      ]);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => openConstituency(context, c),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _card(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('#${c.no}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(width: 8),
            Expanded(child: Text(district.name(te), style: const TextStyle(color: AppColors.muted, fontSize: 12.5))),
            if (voted) Icon(Icons.check_circle, color: AppColors.green, size: 18),
          ]),
          const SizedBox(height: 4),
          Text(c.name(te), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(c.name(!te), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 14),
          person(0),
          const SizedBox(height: 10),
          person(1),
          const SizedBox(height: 12),
          ShareBar(snapshot, height: 6),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Text(snapshot.hasVotes ? votesText(context, snapshot.total) : context.tr('beFirst'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ),
            canVote
                ? FilledButton(
                    onPressed: () => openConstituency(context, c),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: Text(context.tr('voteNow')),
                  )
                : OutlinedButton(
                    onPressed: () => _results(context, c),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    child: Text(context.tr('seeResults')),
                  ),
          ]),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ results

class DesktopResults extends StatefulWidget {
  const DesktopResults({super.key});

  @override
  State<DesktopResults> createState() => _DesktopResultsState();
}

class _DesktopResultsState extends State<DesktopResults> {
  ElectionType _type = ElectionType.mla;
  PollMonth _month = PollMonth.current();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final snaps = state.snapshots(_type, month: _month);
    final tally = SeatTally(snaps);
    final total = ApData.of(_type).length;
    final withVotes = snaps.where((s) => s.hasVotes).length;
    final districts = [for (final d in ApData.districts) state.districtSummary(d, _type, month: _month)];
    final q = _query.trim().toLowerCase();
    final rows = [
      for (final s in snaps)
        if (q.isEmpty || s.constituency.matches(q)) s,
    ]..sort((a, b) => b.total.compareTo(a.total));

    return ListView(children: [
      _Header(
        title: context.tr('results'),
        subtitle: '${_month.label(te)} · ${context.tr('resultsSub')}',
        trailing: SizedBox(
          width: 420,
          child: Column(children: [
            PillToggle(
              labels: [context.tr('mlaResults'), context.tr('mpResults')],
              selected: _type.index,
              onChanged: (i) => setState(() => _type = ElectionType.values[i]),
            ),
            const SizedBox(height: 10),
            MonthSelector(month: _month, onChanged: (m) => setState(() => _month = m)),
          ]),
        ),
      ),
      _body(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: _card(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(context.tr('seatsLeading'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    LiveBadge(closed: _month.isPast),
                  ]),
                  const SizedBox(height: 4),
                  Text(context.tr('majority', {'n': '${total ~/ 2 + 1}'}), style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 20),
                  for (final g in seatGroups)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(children: [
                        PartyDot(groupColor(g), size: 14),
                        const SizedBox(width: 10),
                        SizedBox(width: 74, child: Text(groupLabel(context, g), style: const TextStyle(fontWeight: FontWeight.w700))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: tally.seats[g]! / total,
                              minHeight: 14,
                              backgroundColor: const Color(0xFFEFF1F5),
                              color: groupColor(g),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 54,
                          child: Text('${tally.seats[g]}',
                              textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        ),
                      ]),
                    ),
                  ResultsDisclaimer(participants: tally.votes),
                ]),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Stat(icon: Icons.how_to_vote, color: AppColors.orange, value: formatIndian(tally.votes), label: context.tr('totalVotes')),
                const SizedBox(height: 16),
                _Stat(
                  icon: Icons.location_city,
                  color: AppColors.green,
                  value: '$withVotes / $total',
                  label: context.tr('constituenciesWithVotes'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ApMapScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(colors: [Color(0xFF0B1B33), Color(0xFF16406B)]),
                      ),
                      child: Row(children: [
                        const Icon(Icons.map, color: Colors.white, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(context.tr('apMap'),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 32),
        Text(context.tr('districtWise'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 3 * 16) / 4;
          return Wrap(spacing: 16, runSpacing: 16, children: [
            for (final d in districts)
              SizedBox(
                width: w,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ConstituencyListScreen(type: _type, districtId: d.district.id),
                  )),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _card(),
                    child: Row(children: [
                      SeatDonut(d.tally, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.district.name(te), style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            d.tally.total == 0
                                ? context.tr('beFirst')
                                : [
                                    for (final g in seatGroups)
                                      if (d.tally.seats[g]! > 0) '${groupLabel(context, g)} ${d.tally.seats[g]}',
                                  ].join(' · '),
                            maxLines: 2,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
          ]);
        }),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: Text(context.tr('constituencyResults'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          SizedBox(width: 320, child: SearchField(hint: context.tr('searchConstituency'), onChanged: (v) => setState(() => _query = v))),
        ]),
        const SizedBox(height: 14),
        Container(
          decoration: _card(),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Container(
              color: const Color(0xFFF7F8FA),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Expanded(flex: 3, child: Text(context.tr('constituency'), style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(flex: 4, child: Text(context.tr('leading'), style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(flex: 3, child: Text(context.tr('shareCol'), style: const TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 100, child: Text(context.tr('totalVotes'), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
            for (final s in rows.take(q.isEmpty ? 40 : 175)) _ResultRow(snapshot: s),
          ]),
        ),
      ])),
    ]);
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.snapshot});

  final PollSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final s = snapshot;
    final leader = s.candidates[s.leader];
    return InkWell(
      onTap: () => _results(context, s.constituency),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Expanded(flex: 3, child: Text(s.constituency.name(te), style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
            flex: 4,
            child: s.hasVotes
                ? Row(children: [
                    CandidateAvatar(leader, size: 28),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${leader.name(te)} · ${leader.party.shortName(te)}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ])
                : Text(context.tr('beFirst'), style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(flex: 3, child: Padding(padding: const EdgeInsets.only(right: 20), child: ShareBar(s, height: 8))),
          SizedBox(width: 100, child: Text(formatIndian(s.total), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value, label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _card(),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: AppColors.muted)),
            ]),
          ),
        ]),
      );
}

// ------------------------------------------------------------------ profile

class DesktopProfile extends StatelessWidget {
  const DesktopProfile({super.key});

  void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final user = state.user;
    final name = user?.name ?? '';
    final history = state.voteHistory;

    Widget item(IconData icon, String label, VoidCallback onTap, {String? trailing, Color? color}) => ListTile(
          leading: Icon(icon, color: color ?? AppColors.ink),
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (trailing != null) Text(trailing, style: const TextStyle(color: AppColors.muted)),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
          onTap: onTap,
        );

    Widget group(String title, List<Widget> children) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: _card(),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(title.toUpperCase(),
                  style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)),
            ),
            ...children,
          ]),
        );

    return ListView(children: [
      _Header(title: context.tr('profile'), subtitle: user?.email ?? user?.phone ?? ''),
      _body(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 380,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: _card(),
              child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                  child: Text(
                    name.trim().isEmpty ? 'V' : name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase(),
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(user?.email ?? user?.phone ?? '', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 10),
                StatusBadge(label: context.tr('verified'), color: AppColors.green, icon: Icons.verified),
                const SizedBox(height: 20),
                Row(children: [
                  _MiniStat(value: '${state.voteCount}', label: context.tr('votesLabel')),
                  _MiniStat(value: '${state.earnedBadges.length}/${civic.badges.length}', label: context.tr('achievements')),
                  _MiniStat(value: '${state.savedCandidates.length}', label: context.tr('savedShort')),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            const AchievementsStrip(),
          ]),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            group(context.tr('myParticipation'), [
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                  child: Text(context.tr('noVotesYet'), style: const TextStyle(color: AppColors.muted)),
                )
              else
                for (final v in history.take(6))
                  ListTile(
                    leading: CandidateAvatar(v.candidate, size: 36),
                    title: Text('${v.candidate.name(te)} · ${v.candidate.party.shortName(te)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${v.candidate.constituency.name(te)} · ${v.month.label(te)}'),
                    trailing: TextButton(
                      onPressed: () => _results(context, v.candidate.constituency),
                      child: Text(context.tr('seeResults')),
                    ),
                  ),
              if (history.length > 6)
                item(Icons.history, context.tr('viewAll'), () => _push(context, const MyParticipationScreen())),
            ]),
            group(context.tr('account'), [
              if (user != null && user.email != null && !user.hasPassword && user.provider == 'google')
                item(Icons.password, context.tr('setPassword'), () => ProfileScreen.setPasswordFlow(context)),
              item(Icons.bookmark_border, context.tr('savedCandidates'), () => _push(context, const SavedCandidatesScreen()),
                  trailing: '${state.savedCandidates.length}'),
              item(Icons.notifications_none, context.tr('notificationSettings'),
                  () => _push(context, const NotificationSettingsScreen())),
              item(Icons.language, context.tr('language'), () => ProfileScreen.chooseLanguage(context),
                  trailing: te ? 'తెలుగు' : 'English'),
              item(Icons.emoji_events_outlined, context.tr('achievements'), () => _push(context, const AchievementsScreen())),
            ]),
            group(context.tr('legalPolicies'), [
              for (final d in legalDocs) item(Icons.description_outlined, d.title(te), () => openLegal(context, d.id)),
              item(Icons.info_outline, context.tr('aboutApp'),
                  () => _push(context, const InfoScreen(titleKey: 'aboutApp', bodyKey: 'aboutBody', showVersion: true))),
            ]),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => ProfileScreen.confirmSignOut(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  minimumSize: const Size(180, 46),
                ),
                icon: const Icon(Icons.logout),
                label: Text(context.tr('signOut')),
              ),
            ),
          ]),
        ),
      ])),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
      );
}
