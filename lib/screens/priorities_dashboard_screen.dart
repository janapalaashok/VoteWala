import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/civic.dart';
import '../data/poll_month.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'my_constituency_screen.dart';
import 'results_screen.dart';

/// What people expect from their representatives: "If you were the MLA"
/// priorities and GOOD/BAD feedback, statewide and per constituency.
class PrioritiesDashboardScreen extends StatefulWidget {
  const PrioritiesDashboardScreen({super.key});

  @override
  State<PrioritiesDashboardScreen> createState() => _PrioritiesDashboardScreenState();
}

class _PrioritiesDashboardScreenState extends State<PrioritiesDashboardScreen> {
  PollMonth _month = PollMonth.current();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final votes = state.priorityVotes(month: _month);
    final total = votes.fold(0, (a, b) => a + b);
    final order = List.generate(votes.length, (i) => i)..sort((a, b) => votes[b].compareTo(votes[a]));
    final byC = state.priorityByConstituency(month: _month);
    final issues = state.issueStatsStatewide(month: _month);
    final q = _query.trim().toLowerCase();
    final ranked = [
      for (final e in byC.entries)
        if (ApData.byIdOrNull(e.key) case final c?)
          if (q.isEmpty || c.en.toLowerCase().contains(q) || c.te.contains(q)) (c, e.value),
    ]..sort((a, b) => b.$2.fold(0, (x, y) => x + y).compareTo(a.$2.fold(0, (x, y) => x + y)));
    final grievances = state.grievances;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('publicPriorities'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        PageBody(
          maxWidth: 820,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            MonthSelector(month: _month, onChanged: (m) => setState(() => _month = m)),
            const SizedBox(height: 12),
            Row(children: [
              _Stat(value: formatIndian(total), label: context.tr('participantsLabel'), color: AppColors.blue),
              const SizedBox(width: 10),
              _Stat(
                value: total == 0 ? '—' : civic.priorities[order.first].label(te),
                label: context.tr('topPriority'),
                color: AppColors.orange,
                small: true,
              ),
              const SizedBox(width: 10),
              _Stat(value: '${byC.length}', label: context.tr('constituenciesTakingPart'), color: AppColors.green),
            ]),
            SectionHeader(context.tr('overallPriorities')),
            AppCard(
              child: total == 0
                  ? Text(context.tr('beFirst'), style: const TextStyle(color: AppColors.muted))
                  : Column(children: [
                      for (final i in order)
                        PriorityBar(
                          label: civic.priorities[i].label(te),
                          icon: civic.priorities[i].iconData,
                          votes: votes[i],
                          total: total,
                        ),
                    ]),
            ),
            SectionHeader(context.tr('satisfactionByCategory')),
            AppCard(
              child: Column(children: [
                for (final c in civic.activeCategories)
                  PriorityBar(
                    label: '${c.label(te)} · ${context.tr('badShort')}',
                    icon: c.iconData,
                    votes: issues[c.slot]?.bad ?? 0,
                    total: issues[c.slot]?.total ?? 0,
                    color: AppColors.red,
                  ),
                Text(context.tr('evidenceNote'), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ]),
            ),
            SectionHeader(context.tr('constituencyRankings')),
            SearchField(hint: context.tr('searchConstituency'), onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 8),
            if (ranked.isEmpty)
              EmptyState(icon: Icons.insights, message: context.tr('beFirst'))
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final (c, v) in ranked.take(q.isEmpty ? 30 : 175)) _ConstituencyRow(constituency: c, votes: v),
                ]),
              ),
            if (grievances.isNotEmpty) ...[
              SectionHeader(context.tr('raisedIssues')),
              for (final g in grievances.take(20)) GrievanceTile(grievance: g, showConstituency: true),
            ],
            ResultsDisclaimer(participants: total),
          ]),
        ),
      ]),
    );
  }
}

class _ConstituencyRow extends StatelessWidget {
  const _ConstituencyRow({required this.constituency, required this.votes});

  final Constituency constituency;
  final List<int> votes;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final total = votes.fold(0, (a, b) => a + b);
    final order = List.generate(votes.length, (i) => i)..sort((a, b) => votes[b].compareTo(votes[a]));
    final top = civic.priorities[order.first];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.orange.withValues(alpha: 0.12),
        child: Icon(top.iconData, color: AppColors.orange, size: 20),
      ),
      title: Text(constituency.name(te), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${context.tr('topPriority')}: ${top.label(te)} (${total == 0 ? 0 : (votes[order.first] * 100 / total).round()}%)'
        '${order.length > 1 && votes[order[1]] > 0 ? ' · #2 ${civic.priorities[order[1]].label(te)}' : ''}',
      ),
      trailing: Text(formatCompact(total), style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color, this.small = false});

  final String value, label;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: small ? 14 : 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ]),
        ),
      );
}
