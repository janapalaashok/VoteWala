import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/poll_month.dart';
import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'ap_map_screen.dart';
import 'constituency_list_screen.dart';
import 'main_shell.dart';

/// Lets the user pick a poll month (newest first).
Future<PollMonth?> pickMonth(BuildContext context, PollMonth selected) {
  final te = context.isTelugu;
  return showModalBottomSheet<PollMonth>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(shrinkWrap: true, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(ctx.tr('selectMonth'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        for (final m in PollMonth.available())
          ListTile(
            title: Text(m.isCurrent ? '${ctx.tr('thisMonth')} (${m.label(te)})' : m.label(te)),
            trailing: m == selected ? const Icon(Icons.check, color: AppColors.orange) : null,
            onTap: () => Navigator.pop(ctx, m),
          ),
      ]),
    ),
  );
}

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key, required this.month, required this.onChanged});

  final PollMonth month;
  final ValueChanged<PollMonth> onChanged;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    return AppCard(
      onTap: () async {
        final m = await pickMonth(context, month);
        if (m != null) onChanged(m);
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        const Icon(Icons.calendar_month_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            month.isCurrent ? '${context.tr('thisMonth')} (${month.label(te)})' : month.label(te),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (month.isCurrent) StatusBadge(label: context.tr('live')) else StatusBadge(label: context.tr('closed'), color: AppColors.muted, icon: Icons.lock),
        const SizedBox(width: 4),
        const Icon(Icons.expand_more),
      ]),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  ElectionType _type = ElectionType.mla;
  PollMonth _month = PollMonth.current();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final tally = SeatTally(state.snapshots(_type, month: _month));
    final districts = [for (final d in ApData.districts) state.districtSummary(d, _type, month: _month)];
    final total = ApData.of(_type).length;

    return Scaffold(
      appBar: AppBar(
        leading: shellBackButton(context, embedded: widget.embedded),
        title: Text(context.tr('results')),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        PageBody(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PillToggle(
              labels: [context.tr('mlaResults'), context.tr('mpResults')],
              selected: _type.index,
              onChanged: (i) => setState(() => _type = ElectionType.values[i]),
            ),
            const SizedBox(height: 12),
            MonthSelector(month: _month, onChanged: (m) => setState(() => _month = m)),
            const SizedBox(height: 12),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(
                    child: Text(context.tr('seatsLeading'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  Text('$total ${context.tr('seats')}', style: const TextStyle(color: AppColors.muted)),
                ]),
                const SizedBox(height: 12),
                SeatTallyView(tally, majority: total ~/ 2 + 1),
              ]),
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('totalParticipation'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(formatIndian(tally.votes), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                Text('${context.tr('verifiedAccounts')} · ${_month.label(te)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
            ),
            SectionHeader(
              context.tr('districtWise'),
              action: context.tr('apMap'),
              onAction: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ApMapScreen())),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < districts.length; i++) ...[
                  if (i > 0) const Divider(indent: 72),
                  DistrictSeatsTile(
                    summary: districts[i],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => ConstituencyListScreen(type: _type, districtId: districts[i].district.id),
                    )),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// District row: party-representation circle, name and seats per party.
class DistrictSeatsTile extends StatelessWidget {
  const DistrictSeatsTile({super.key, required this.summary, this.onTap});

  final DistrictSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = summary.tally;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: SeatDonut(t, size: 42),
      title: Text(summary.district.name(context.isTelugu), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(spacing: 10, runSpacing: 2, children: [
          for (final g in seatGroups)
            if (t.seats[g]! > 0)
              Row(mainAxisSize: MainAxisSize.min, children: [
                PartyDot(groupColor(g), size: 10),
                const SizedBox(width: 4),
                Text('${groupLabel(context, g)} ${t.seats[g]}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ]),
          Text('· ${formatCompact(t.votes)} ${context.tr('votes')}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
