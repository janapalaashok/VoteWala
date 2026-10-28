import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'ap_map_screen.dart';
import 'constituency_list_screen.dart';
import 'main_shell.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  ElectionType _type = ElectionType.mla;
  DateTime? _day; // null = today

  Future<void> _pickDate() async {
    final today = istToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? today,
      firstDate: today.subtract(const Duration(days: 60)),
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _day = DateUtils.isSameDay(picked, today) ? null : DateTime.utc(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final day = _day ?? istToday();
    final polls = [for (final c in ApData.of(_type)) state.snapshot(c, day: day)];
    final closed = polls.where((p) => p.closed).length;
    final participation = polls.fold(0, (a, p) => a + p.total);
    final districts = [for (final d in ApData.districts) state.districtSummary(d, _type, day: day)]
      ..sort((a, b) => b.total.compareTo(a.total));
    final dateLabel = _day == null ? '${context.tr('today')} (${formatDate(day)})' : formatDate(day);

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
            AppCard(
              onTap: _pickDate,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                const Icon(Icons.calendar_month_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _StatCard(label: context.tr('totalPolls'), value: '${polls.length}'),
              const SizedBox(width: 10),
              _StatCard(label: context.tr('active'), value: '${polls.length - closed}', dot: AppColors.green),
              const SizedBox(width: 10),
              _StatCard(label: context.tr('closed'), value: '$closed'),
            ]),
            const SizedBox(height: 10),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('totalParticipation'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(formatIndian(participation), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                Text(context.tr('verifiedAccounts'), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
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
                  if (i > 0) const Divider(indent: 64),
                  ListTile(
                    leading: Blob(color: districts[i].leadingParty.color, seed: districts[i].district.firstAc * 3),
                    title: Text(districts[i].district.name(te), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${formatCompact(districts[i].total)} ${context.tr('votes')} · '
                      '${districts[i].leadingParty.short} ${context.tr('leading')}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.dot});

  final String label;
  final String value;
  final Color? dot;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              if (dot != null) ...[
                Icon(Icons.circle, size: 10, color: dot),
                const SizedBox(width: 4),
              ],
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
      );
}
