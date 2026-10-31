import 'package:flutter/material.dart';

import '../../data/ap_data.dart';
import '../../data/civic.dart';
import '../../data/grievance.dart';
import '../../data/poll_month.dart';
import '../admin_widgets.dart';
import 'issues_page.dart';

/// All submitted photos, pending first.
class PhotosPage extends StatefulWidget {
  const PhotosPage({super.key});

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  Future<Map<String, Map<String, Object?>>>? _load;
  String _filter = 'pending';
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= AdminScope.read(context).data?.photos();
  }

  @override
  Widget build(BuildContext context) {
    final data = AdminScope.of(context).data;
    if (data == null) return const NeedsFirebase(title: 'Photo review');
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        final all = snap.data ?? const {};
        final shown = [
          for (final e in all.entries)
            if (_filter == 'all' || e.value['status'] == _filter) e,
        ]..sort((a, b) => ((b.value['at'] as DateTime?) ?? DateTime(0)).compareTo((a.value['at'] as DateTime?) ?? DateTime(0)));
        final pending = all.values.where((p) => p['status'] == 'pending').length;
        return AdminPage(
          title: 'Photo review',
          subtitle: 'Evidence photos are private. Approve only relevant photos without faces, names, phone numbers or '
              'other personal details. A photo is never treated as verified proof.',
          actions: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'pending', label: Text('Pending ($pending)')),
                const ButtonSegment(value: 'approved', label: Text('Approved')),
                const ButtonSegment(value: 'rejected', label: Text('Rejected')),
                const ButtonSegment(value: 'all', label: Text('All')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: () => setState(() => _load = data.photos()), icon: const Icon(Icons.refresh)),
          ],
          children: [
            if (snap.hasError) AdminCard(child: Text('Could not load: ${snap.error}')),
            if (snap.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator()),
            if (snap.hasData)
              AdminCard(
                child: shown.isEmpty
                    ? const Text('Nothing here.')
                    : Wrap(spacing: 14, runSpacing: 14, children: [
                        for (final e in shown.take(120))
                          PhotoReviewTile(
                            id: e.key,
                            photo: e.value,
                            busy: _busy,
                            subtitle: '${categoryBySlot('${e.value['slot']}')?.en ?? e.value['slot']} · '
                                '${ApData.byIdOrNull('${e.value['bucket']}')?.en ?? e.value['bucket']}',
                            onReview: (status) async {
                              setState(() => _busy = true);
                              try {
                                await data.reviewPhoto(e.key, status);
                                e.value['status'] = status;
                              } catch (err) {
                                if (context.mounted) showAdminSnack(context, '$err', error: true);
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                          ),
                      ]),
              ),
          ],
        );
      },
    );
  }
}

/// Raised grievances and their public status.
class GrievancesPage extends StatefulWidget {
  const GrievancesPage({super.key});

  @override
  State<GrievancesPage> createState() => _GrievancesPageState();
}

class _GrievancesPageState extends State<GrievancesPage> {
  Future<List<Grievance>>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= AdminScope.read(context).data?.grievances();
  }

  @override
  Widget build(BuildContext context) {
    final data = AdminScope.of(context).data;
    if (data == null) return const NeedsFirebase(title: 'Grievances');
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        final list = [...?snap.data]..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
        return AdminPage(
          title: 'Grievances',
          subtitle: 'Issues raised with representatives. Statuses are public; record each step only with evidence '
              '(sent email, written reply, reported action).',
          actions: [IconButton(onPressed: () => setState(() => _load = data.grievances()), icon: const Icon(Icons.refresh))],
          children: [
            if (snap.hasError) AdminCard(child: Text('Could not load: ${snap.error}')),
            if (snap.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator()),
            if (snap.hasData && list.isEmpty)
              const AdminCard(child: Text('No grievances yet. Open an issue from "Local issues & alerts" to create one.')),
            for (final g in list)
              AdminCard(
                title: '${g.category?.en ?? g.slot} · ${g.constituency?.en ?? g.constituencyId}',
                subtitle: '${PollMonth.parse(g.monthKey).label(false)} · ${g.bad} of ${g.good + g.bad} said BAD · '
                    '${g.badWithPhoto} with photos',
                trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Chip(label: Text(grievanceLabel(g.status))),
                  FilledButton(
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => IssueDetailDialog(
                          row: IssueRow(PollMonth.parse(g.monthKey), g.constituencyId, g.slot, const {}),
                        ),
                      );
                      if (mounted) setState(() => _load = data.grievances());
                    },
                    child: const Text('Open'),
                  ),
                ]),
                child: Text(g.steps.isEmpty
                    ? 'No steps recorded.'
                    : '${g.steps.last.at.toLocal().toString().substring(0, 16)} · ${g.steps.last.note}'),
              ),
          ],
        );
      },
    );
  }
}
