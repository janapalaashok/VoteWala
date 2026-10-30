import 'package:flutter/material.dart';

import '../../data/ap_data.dart';
import '../../data/civic.dart';
import '../../data/poll_month.dart';
import '../../services/vote_service.dart';
import '../admin_widgets.dart';
import 'issues_page.dart';

class _Analytics {
  _Analytics(this.mla, this.mp, this.featured, this.issues, this.priority, this.badges);

  final Map<String, Map<String, Object?>> mla, mp, issues, priority;
  final Map<String, int> featured;

  /// Badge id -> voters who reached it.
  final Map<String, int> badges;

  static int sum(Map<String, Map<String, Object?>> buckets, String field) =>
      buckets.values.fold(0, (a, b) => a + ((b[field] as int?) ?? 0));
}

/// Participation, badges and constituency-wise statistics (totals only).
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  PollMonth _month = PollMonth.current();
  Future<_Analytics>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  Future<_Analytics> _fetch() async {
    final admin = AdminScope.read(context);
    final data = admin.data!;
    final featured = admin.published.featured;
    final (mla, mp, issues, priority) = await (
      data.db.list('tallies/${PollIds.mla(_month)}/buckets'),
      data.db.list('tallies/${PollIds.mp(_month)}/buckets'),
      data.db.list('tallies/${PollIds.issues(_month)}/buckets'),
      data.db.list('tallies/${PollIds.priority(_month)}/buckets'),
    ).wait;
    final f = <String, int>{};
    for (final p in featured) {
      final shards = await data.db.list('tallies/${PollIds.featured(p.id)}/buckets');
      f[p.titleEn] = shards.entries.where((e) => e.key.startsWith(_month.key)).fold(0, (a, e) => a + ((e.value['total'] as int?) ?? 0));
    }
    final badges = <String, int>{};
    for (final b in admin.published.civic.badges) {
      try {
        badges[b.id] = await data.countAtLeast('users', 'voteCount', b.milestone);
      } catch (_) {
        badges[b.id] = -1;
      }
    }
    return _Analytics(mla, mp, f, issues, priority, badges);
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    if (admin.data == null) return const NeedsFirebase(title: 'Analytics');
    final civic = admin.published.civic;
    return FutureBuilder(
      future: _load,
      builder: (context, snap) => AdminPage(
        title: 'Analytics',
        subtitle: 'Totals only. Individual votes are never shown here.',
        actions: [
          DropdownButton<PollMonth>(
            value: _month,
            items: [for (final m in PollMonth.available()) DropdownMenuItem(value: m, child: Text(m.label(false)))],
            onChanged: (m) => setState(() {
              _month = m!;
              _load = _fetch();
            }),
          ),
          IconButton(onPressed: () => setState(() => _load = _fetch()), icon: const Icon(Icons.refresh)),
        ],
        children: [
          if (snap.hasError) AdminCard(child: Text('Could not load: ${snap.error}')),
          if (snap.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator()),
          if (snap.data case final a?) ...[
            AdminGrid(children: [
              StatTile(icon: Icons.account_balance, label: 'MLA votes', value: '${_Analytics.sum(a.mla, 'total')}',
                  color: AdminColors.accent, footer: '${a.mla.length} of 175 constituencies'),
              StatTile(icon: Icons.museum, label: 'MP votes', value: '${_Analytics.sum(a.mp, 'total')}',
                  color: AdminColors.success, footer: '${a.mp.length} of 25 constituencies'),
              StatTile(icon: Icons.local_fire_department, label: 'Featured poll votes',
                  value: '${a.featured.values.fold(0, (x, y) => x + y)}', color: const Color(0xFF8E44AD)),
              StatTile(icon: Icons.emoji_objects, label: 'MLA priority votes', value: '${_Analytics.sum(a.priority, 'total')}',
                  color: AdminColors.ink, footer: '${a.priority.length} constituencies'),
              StatTile(icon: Icons.fact_check, label: 'Local issue answers', value: '${_Analytics.sum(a.issues, 'total')}',
                  color: AdminColors.danger,
                  footer: '${_Analytics.sum(a.issues, 'p0') + _Analytics.sum(a.issues, 'p1')} with photos'),
            ]),
            const SizedBox(height: 20),
            AdminCard(
              title: 'Featured polls',
              child: Column(children: [
                for (final e in a.featured.entries)
                  ListTile(contentPadding: EdgeInsets.zero, title: Text(e.key), trailing: Text('${e.value} votes')),
              ]),
            ),
            AdminCard(
              title: 'Badges reached (all time)',
              child: Wrap(spacing: 16, runSpacing: 12, children: [
                for (final b in civic.badges)
                  Chip(
                    avatar: CircleAvatar(backgroundColor: b.colorValue, child: Icon(b.iconData, size: 14, color: Colors.white)),
                    label: Text('${b.en}: ${a.badges[b.id] == null || a.badges[b.id]! < 0 ? 'n/a' : a.badges[b.id]}'),
                  ),
              ]),
            ),
            AdminCard(
              title: '"If you were the MLA": statewide',
              child: _PriorityTable(rows: {'All constituencies': _priorityVotes(a.priority.values, civic)}, civic: civic),
            ),
            AdminCard(
              title: 'Constituency-wise priorities and feedback',
              subtitle: 'Top 50 by participation',
              child: _PriorityTable(
                civic: civic,
                rows: {
                  for (final e in (a.priority.entries.toList()
                        ..sort((x, y) => ((y.value['total'] as int?) ?? 0).compareTo((x.value['total'] as int?) ?? 0)))
                      .take(50))
                    ApData.byIdOrNull(e.key)?.en ?? e.key: _priorityVotes([e.value], civic),
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  static List<int> _priorityVotes(Iterable<Map<String, Object?>> buckets, CivicConfig civic) => [
        for (var i = 0; i < civic.priorities.length; i++) buckets.fold(0, (a, b) => a + ((b['o$i'] as int?) ?? 0)),
      ];
}

class _PriorityTable extends StatelessWidget {
  const _PriorityTable({required this.rows, required this.civic});

  final Map<String, List<int>> rows;
  final CivicConfig civic;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No votes yet.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Constituency')),
          const DataColumn(label: Text('Total'), numeric: true),
          const DataColumn(label: Text('Top priority')),
          for (final p in civic.priorities) DataColumn(label: Text(p.en), numeric: true),
        ],
        rows: [
          for (final e in rows.entries)
            DataRow(cells: () {
              final total = e.value.fold(0, (a, b) => a + b);
              final top = total == 0 ? -1 : e.value.indexOf(e.value.reduce((a, b) => a > b ? a : b));
              return [
                DataCell(Text(e.key)),
                DataCell(Text('$total')),
                DataCell(Text(top < 0 ? '-' : civic.priorities[top].en)),
                for (final v in e.value) DataCell(Text(total == 0 ? '-' : '${(v * 100 / total).round()}%')),
              ];
            }()),
        ],
      ),
    );
  }
}
