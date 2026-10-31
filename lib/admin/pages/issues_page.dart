import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/ap_data.dart';
import '../../data/civic.dart';
import '../../data/grievance.dart';
import '../../data/poll_month.dart';
import '../../services/vote_service.dart';
import '../admin_data.dart';
import '../admin_widgets.dart';
import '../file_pick.dart';
import '../report_pdf.dart';

/// Counts of one constituency + category in one month.
class IssueRow {
  IssueRow(this.month, this.constituencyId, this.slot, Map<String, Object?> t)
      : good = (t['o0'] as int?) ?? 0,
        bad = (t['o1'] as int?) ?? 0,
        goodPhoto = (t['p0'] as int?) ?? 0,
        badPhoto = (t['p1'] as int?) ?? 0;

  final PollMonth month;
  final String constituencyId, slot;
  final int good, bad, goodPhoto, badPhoto;

  int get total => good + bad;
  String get pollId => PollIds.issues(month);
  String get grievanceId => Grievance.idFor(pollId, constituencyId, slot);
  String get constituencyName => ApData.byIdOrNull(constituencyId)?.en ?? constituencyId;
  String get categoryName => categoryBySlot(slot)?.en ?? slot;
  ReportCounts get counts => ReportCounts(good: good, bad: bad, goodPhoto: goodPhoto, badPhoto: badPhoto);
}

/// Shown when the panel runs without Firebase.
class NeedsFirebase extends StatelessWidget {
  const NeedsFirebase({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => AdminPage(title: title, children: const [
        AdminCard(child: Text('Connect Firebase to see live votes, photos and grievances (docs/FIREBASE_SETUP.md).')),
      ]);
}

class IssuesPage extends StatefulWidget {
  const IssuesPage({super.key});

  @override
  State<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  PollMonth _month = PollMonth.current();
  late Future<(List<IssueRow>, Map<String, Map<String, Object?>>, Map<String, int>)> _load;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload();
  }

  void _reload() {
    final data = AdminScope.read(context).data;
    if (data == null) return;
    _load = () async {
      final (tallies, alerts, limits) = await (
        data.db.list('tallies/${PollIds.issues(_month)}/buckets'),
        data.alerts(),
        data.setting('thresholds'),
      ).wait;
      final rows = [
        for (final e in tallies.entries)
          if (e.key.split('_') case [final c, final slot]) IssueRow(_month, c, slot, e.value),
      ]..sort((a, b) => b.bad.compareTo(a.bad));
      final bySlot = (limits['bySlot'] as Map?) ?? const {};
      final fallback = (limits['default'] as int?) ?? 100;
      return (rows, alerts, {for (final c in civic.categories) c.slot: (bySlot[c.slot] as int?) ?? fallback});
    }();
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final data = admin.data;
    if (data == null) return const NeedsFirebase(title: 'Local issues');
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        final months = PollMonth.available();
        return AdminPage(
          title: 'Local issues & alerts',
          subtitle: 'GOOD / BAD feedback per constituency and category. Alerts appear when BAD votes reach the '
              'threshold (Settings → Thresholds). Nothing is sent to anyone automatically.',
          actions: [
            DropdownButton<PollMonth>(
              value: _month,
              items: [for (final m in months) DropdownMenuItem(value: m, child: Text(m.label(false)))],
              onChanged: (m) => setState(() {
                _month = m!;
                _reload();
              }),
            ),
            const SizedBox(width: 8),
            IconButton(tooltip: 'Refresh', onPressed: () => setState(_reload), icon: const Icon(Icons.refresh)),
          ],
          children: [
            if (snap.hasError) AdminCard(child: Text('Could not load: ${snap.error}')),
            if (!snap.hasData && !snap.hasError) const Center(child: CircularProgressIndicator()),
            if (snap.data case (final rows, final alerts, final limits)) ...[
              _AlertsCard(
                alerts: alerts,
                rows: rows,
                onOpen: (row) => _open(row),
                onSeen: (id) async {
                  await data.markAlertSeen(id);
                  setState(_reload);
                },
              ),
              AdminCard(
                title: 'All feedback · ${_month.label(false)}',
                trailing: SizedBox(
                  width: 240,
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Filter constituency', isDense: true, prefixIcon: Icon(Icons.search)),
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                child: rows.isEmpty
                    ? const Text('No feedback yet this month.')
                    : _IssueTable(
                        rows: [for (final r in rows) if (_query.isEmpty || r.constituencyName.toLowerCase().contains(_query)) r],
                        limits: limits,
                        onOpen: _open,
                      ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _open(IssueRow row) async {
    await showDialog<void>(context: context, builder: (_) => IssueDetailDialog(row: row));
    if (mounted) setState(_reload);
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts, required this.rows, required this.onOpen, required this.onSeen});

  final Map<String, Map<String, Object?>> alerts;
  final List<IssueRow> rows;
  final ValueChanged<IssueRow> onOpen;
  final ValueChanged<String> onSeen;

  @override
  Widget build(BuildContext context) {
    final list = alerts.entries.toList()
      ..sort((a, b) => ((b.value['at'] as DateTime?) ?? DateTime(0)).compareTo((a.value['at'] as DateTime?) ?? DateTime(0)));
    final unseen = list.where((e) => e.value['seen'] != true).length;
    return AdminCard(
      title: 'Threshold alerts',
      subtitle: unseen == 0 ? 'No new alerts' : '$unseen new',
      child: list.isEmpty
          ? const Text('No category has reached its threshold yet.')
          : Column(children: [
              for (final e in list.take(30))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notification_important,
                      color: e.value['seen'] == true ? AdminColors.muted : AdminColors.danger),
                  title: Text(
                      '${categoryBySlot('${e.value['slot']}')?.en ?? e.value['slot']} · '
                      '${ApData.byIdOrNull('${e.value['bucket']}')?.en ?? e.value['bucket']}'),
                  subtitle: Text('BAD votes reached ${e.value['threshold']} · ${e.value['pollId']}'),
                  trailing: Wrap(spacing: 8, children: [
                    if (e.value['seen'] != true) TextButton(onPressed: () => onSeen(e.key), child: const Text('Mark seen')),
                    FilledButton(
                      onPressed: () {
                        final pollId = '${e.value['pollId']}';
                        final row = rows.where((r) =>
                                r.pollId == pollId && r.constituencyId == e.value['bucket'] && r.slot == e.value['slot']).firstOrNull ??
                            IssueRow(PollMonth.parse(pollId.substring(7)), '${e.value['bucket']}', '${e.value['slot']}', const {});
                        onOpen(row);
                      },
                      child: const Text('Open'),
                    ),
                  ]),
                ),
            ]),
    );
  }
}

class _IssueTable extends StatelessWidget {
  const _IssueTable({required this.rows, required this.limits, required this.onOpen});

  final List<IssueRow> rows;
  final Map<String, int> limits;
  final ValueChanged<IssueRow> onOpen;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Constituency')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('GOOD'), numeric: true),
            DataColumn(label: Text('BAD'), numeric: true),
            DataColumn(label: Text('BAD %'), numeric: true),
            DataColumn(label: Text('With photo'), numeric: true),
            DataColumn(label: Text('Threshold')),
          ],
          rows: [
            for (final r in rows.take(300))
              DataRow(
                onSelectChanged: (_) => onOpen(r),
                cells: [
                  DataCell(Text(r.constituencyName)),
                  DataCell(Text(r.categoryName)),
                  DataCell(Text('${r.total}')),
                  DataCell(Text('${r.good}')),
                  DataCell(Text('${r.bad}', style: const TextStyle(color: AdminColors.danger, fontWeight: FontWeight.w700))),
                  DataCell(Text(r.total == 0 ? '-' : '${(r.bad * 100 / r.total).round()}%')),
                  DataCell(Text('${r.goodPhoto + r.badPhoto}')),
                  DataCell(r.bad >= (limits[r.slot] ?? 100)
                      ? const Chip(label: Text('Reached'), backgroundColor: Color(0xFFFEE2E2))
                      : Text('${r.bad} / ${limits[r.slot] ?? 100}')),
                ],
              ),
          ],
        ),
      );
}

/// Everything about one issue: counts, photos to review, grievance status,
/// and the PDF report.
class IssueDetailDialog extends StatefulWidget {
  const IssueDetailDialog({super.key, required this.row});

  final IssueRow row;

  @override
  State<IssueDetailDialog> createState() => _IssueDetailDialogState();
}

class _IssueDetailDialogState extends State<IssueDetailDialog> {
  late Future<void> _load;
  IssueRow? _row;
  Map<String, Map<String, Object?>> _photos = {};
  Grievance? _grievance;
  bool _busy = false;

  AdminData get _data => AdminScope.read(context).data!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load = _fetch();
  }

  Future<void> _fetch() async {
    final r = widget.row;
    final (tally, photos, grievance) = await (
      _data.db.get('tallies/${r.pollId}/buckets/${r.constituencyId}_${r.slot}'),
      _data.photos(),
      _data.db.get('grievances/${r.grievanceId}'),
    ).wait;
    _row = IssueRow(r.month, r.constituencyId, r.slot, tally ?? const {});
    _photos = {
      for (final e in photos.entries)
        if (e.value['pollId'] == r.pollId && e.value['bucket'] == r.constituencyId && e.value['slot'] == r.slot) e.key: e.value,
    };
    _grievance = grievance == null ? null : Grievance.fromFields(r.grievanceId, grievance);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAdminSnack(context, done);
      _load = _fetch();
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Grievance _fresh(IssueRow r, Grievance? old) => Grievance(
        id: r.grievanceId,
        pollId: r.pollId,
        constituencyId: r.constituencyId,
        slot: r.slot,
        good: r.good,
        bad: r.bad,
        badWithPhoto: r.badPhoto,
        steps: old?.steps ?? [GrievanceStep(GrievanceStatus.threshold, DateTime.now().toUtc(), 'BAD votes reached the threshold')],
      );

  Future<void> _report() => _run(() async {
        final r = _row!;
        final approved = [for (final p in _photos.values) if (p['status'] == 'approved') p];
        final photos = <ReportPhoto>[];
        for (final p in approved) {
          photos.add(ReportPhoto(await _data.photoBytes('${p['file']}'), '${p['caption'] ?? ''}', (p['choice'] as int?) ?? 1));
        }
        var g = _fresh(r, _grievance);
        final pdf = await buildGrievanceReport(
          grievance: g,
          constituencyName: r.constituencyName,
          categoryName: r.categoryName,
          counts: r.counts,
          photos: photos,
        );
        downloadBytes('VoteWala-${r.constituencyName}-${r.categoryName}-${r.month.key}.pdf'.replaceAll(' ', '_'), pdf,
            'application/pdf');
        if (g.status == GrievanceStatus.threshold) {
          g = g.withStep(GrievanceStep(GrievanceStatus.reportGenerated, DateTime.now().toUtc(), 'Report prepared'));
        }
        await _data.saveGrievance(g);
      }, 'Report downloaded');

  Future<void> _status() async {
    final g = _grievance;
    if (g == null) return;
    final result = await showDialog<GrievanceStep>(context: context, builder: (_) => StatusDialog(current: g.status));
    if (result == null) return;
    await _run(() => _data.saveGrievance(g.withStep(result)), 'Status updated');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 820),
        child: FutureBuilder(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Padding(padding: const EdgeInsets.all(24), child: Text('Could not load: ${snap.error}'));
            final r = _row!;
            final g = _grievance;
            return ListView(padding: const EdgeInsets.all(28), children: [
              Row(children: [
                Expanded(
                  child: Text('${r.categoryName} · ${r.constituencyName}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              Text(r.month.label(false), style: const TextStyle(color: AdminColors.muted)),
              const SizedBox(height: 18),
              AdminGrid(children: [
                StatTile(icon: Icons.how_to_vote, label: 'Total votes', value: '${r.total}', color: AdminColors.ink),
                StatTile(icon: Icons.thumb_up, label: 'GOOD', value: '${r.good} (${r.counts.pct(r.good)})', color: AdminColors.success),
                StatTile(icon: Icons.thumb_down, label: 'BAD', value: '${r.bad} (${r.counts.pct(r.bad)})', color: AdminColors.danger),
                StatTile(
                    icon: Icons.photo_camera,
                    label: 'Evidence supported (BAD / GOOD)',
                    value: '${r.badPhoto} / ${r.goodPhoto}',
                    color: AdminColors.accent),
                StatTile(icon: Icons.groups, label: 'Public opinion (no photo)', value: '${r.counts.publicOpinion}', color: AdminColors.muted),
              ]),
              const SizedBox(height: 20),
              AdminCard(
                title: 'Grievance',
                subtitle: g == null
                    ? 'Not raised yet'
                    : 'Status: ${grievanceLabel(g.status)} · ${g.steps.length} step(s) recorded',
                trailing: Wrap(spacing: 8, children: [
                  if (g == null)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _run(() => _data.saveGrievance(_fresh(r, null)), 'Grievance created'),
                      child: const Text('Create grievance record'),
                    ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _report,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate PDF'),
                  ),
                  if (g != null)
                    OutlinedButton(onPressed: _busy ? null : _status, child: const Text('Update status')),
                ]),
                child: g == null
                    ? const Text('Create a record to track this issue publicly. The PDF includes only totals and approved photos. '
                        'Email it yourself to the MLA or authority; VoteWala never sends anything automatically.')
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final s in g.steps)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(grievanceLabel(s.status)),
                            subtitle: Text('${s.at.toLocal().toString().substring(0, 16)}${s.note.isEmpty ? '' : ' · ${s.note}'}'),
                          ),
                      ]),
              ),
              AdminCard(
                title: 'Photos (${_photos.length})',
                subtitle: 'Approve photos that are relevant and contain no faces, names or personal details. '
                    'Only approved photos go into the report.',
                child: _photos.isEmpty
                    ? const Text('No photos for this issue.')
                    : Wrap(spacing: 14, runSpacing: 14, children: [
                        for (final e in _photos.entries)
                          PhotoReviewTile(
                            id: e.key,
                            photo: e.value,
                            busy: _busy,
                            onReview: (status) => _run(() => _data.reviewPhoto(e.key, status), 'Photo $status'),
                          ),
                      ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

String grievanceLabel(GrievanceStatus s) => switch (s) {
      GrievanceStatus.threshold => 'Threshold reached',
      GrievanceStatus.reportGenerated => 'Report generated',
      GrievanceStatus.sentToMla => 'Sent to MLA',
      GrievanceStatus.responseReceived => 'Response received',
      GrievanceStatus.actionReported => 'Action reported',
      GrievanceStatus.resolved => 'Resolved',
    };

/// Records the next status with a public note. Steps that speak for the MLA
/// need a note saying what confirms them.
class StatusDialog extends StatefulWidget {
  const StatusDialog({super.key, required this.current});

  final GrievanceStatus current;

  @override
  State<StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<StatusDialog> {
  late GrievanceStatus _status =
      GrievanceStatus.values[(widget.current.index + 1).clamp(0, GrievanceStatus.values.length - 1)];
  final _note = TextEditingController();
  bool _confirmed = false;

  bool get _needsEvidence => _status.index >= GrievanceStatus.sentToMla.index;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Update grievance status'),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<GrievanceStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'New status'),
              items: [for (final s in GrievanceStatus.values) DropdownMenuItem(value: s, child: Text(grievanceLabel(s)))],
              onChanged: (s) => setState(() => _status = s!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              maxLength: 200,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Public note',
                hintText: _needsEvidence ? 'e.g. Emailed to the MLA office (mla@...) on 3 Nov; reply received on 10 Nov' : 'Optional',
              ),
            ),
            if (_needsEvidence)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                title: const Text('I have evidence for this step (sent email, written reply or reported action). '
                    'The public page will show exactly this note.'),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _needsEvidence && (!_confirmed || _note.text.trim().length < 8)
                ? null
                : () => Navigator.pop(context, GrievanceStep(_status, DateTime.now().toUtc(), _note.text.trim())),
            child: const Text('Save'),
          ),
        ],
      );
}

/// A private photo with approve / reject.
class PhotoReviewTile extends StatelessWidget {
  const PhotoReviewTile({super.key, required this.id, required this.photo, required this.onReview, this.busy = false, this.subtitle});

  final String id;
  final Map<String, Object?> photo;
  final ValueChanged<String> onReview;
  final bool busy;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final data = AdminScope.read(context).data!;
    final status = '${photo['status']}';
    return Container(
      width: 220,
      decoration: BoxDecoration(border: Border.all(color: AdminColors.border), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 150,
          child: FutureBuilder<Uint8List>(
            future: data.photoBytes('${photo['file']}'),
            builder: (_, snap) => snap.hasData
                ? GestureDetector(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(snap.data!))),
                    ),
                    child: Image.memory(snap.data!, fit: BoxFit.cover),
                  )
                : snap.hasError
                    ? const Center(child: Icon(Icons.broken_image_outlined))
                    : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(photo['choice'] == 1 ? 'Rated BAD' : 'Rated GOOD',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: photo['choice'] == 1 ? AdminColors.danger : AdminColors.success)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
            if ('${photo['caption'] ?? ''}'.isNotEmpty) Text('${photo['caption']}', style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 6),
            Row(children: [
              Chip(
                label: Text(status),
                visualDensity: VisualDensity.compact,
                backgroundColor: switch (status) {
                  'approved' => const Color(0xFFDCFCE7),
                  'rejected' => const Color(0xFFFEE2E2),
                  _ => const Color(0xFFFEF3C7),
                },
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Approve',
                onPressed: busy || status == 'approved' ? null : () => onReview('approved'),
                icon: const Icon(Icons.check, color: AdminColors.success),
              ),
              IconButton(
                tooltip: 'Reject',
                onPressed: busy || status == 'rejected' ? null : () => onReview('rejected'),
                icon: const Icon(Icons.close, color: AdminColors.danger),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
