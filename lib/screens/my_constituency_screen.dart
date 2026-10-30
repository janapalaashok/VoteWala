import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/civic.dart';
import '../data/grievance.dart';
import '../l10n/strings.dart';
import '../services/photo_prep.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/vote_flow.dart';
import 'priorities_dashboard_screen.dart';

void openMyConstituency(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MyConstituencyScreen()));

/// Home entry for local feedback and "If you were the MLA".
class YourConstituencyCard extends StatelessWidget {
  const YourConstituencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final done = state.myIssueChoices != null && state.myPriority != null;
    return AppCard(
      onTap: () => openMyConstituency(context),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.orange, AppColors.green]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.location_city, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('yourConstituency'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              state.homeConstituency == null
                  ? context.tr('yourConstituencySub')
                  : '${state.homeConstituency!.name(context.isTelugu)} · ${context.tr('yourConstituencySub')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.3),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        done ? Icon(Icons.check_circle, color: AppColors.green) : Icon(Icons.chevron_right, color: AppColors.orange),
      ]),
    );
  }
}

class MyConstituencyScreen extends StatelessWidget {
  const MyConstituencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    // Feedback stays with the constituency it was given for this month.
    final c = ApData.byIdOrNull(state.myIssueConstituency ?? '') ?? state.homeConstituency;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('yourConstituency')),
        actions: [
          IconButton(
            tooltip: context.tr('publicPriorities'),
            icon: const Icon(Icons.insights),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const PrioritiesDashboardScreen())),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        PageBody(
          maxWidth: 720,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _ConstituencyPicker(current: c, locked: state.myIssueConstituency != null),
            const SizedBox(height: 16),
            if (c == null)
              EmptyState(icon: Icons.location_on_outlined, message: context.tr('pickConstituencyFirst'))
            else ...[
              _IssuesSection(constituency: c, key: ValueKey('issues-${c.id}')),
              const SizedBox(height: 20),
              _PrioritySection(constituency: c, key: ValueKey('priority-${c.id}')),
              const SizedBox(height: 20),
              _GrievanceList(grievances: [for (final g in state.grievances) if (g.constituencyId == c.id) g]),
              ResultsDisclaimer(participants: state.issueStats(c.id).values.fold(0, (a, s) => a > s.total ? a : s.total)),

            ],
          ]),
        ),
      ]),
    );
  }
}

class _ConstituencyPicker extends StatelessWidget {
  const _ConstituencyPicker({required this.current, required this.locked});

  final Constituency? current;

  /// This month's feedback is already tied to a constituency.
  final bool locked;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDialog<Constituency>(context: context, builder: (_) => const _PickDialog());
    if (picked != null && context.mounted) AppScope.read(context).setHomeConstituency(picked);
  }

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    return AppCard(
      onTap: locked ? null : () => _pick(context),
      child: Row(children: [
        Icon(Icons.location_on, color: AppColors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('myAssemblyConstituency'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(current?.name(te) ?? context.tr('chooseConstituency'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            if (current != null)
              Text(ApData.districts.firstWhere((d) => d.id == current!.districtIds.first).name(te),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ]),
        ),
        if (locked)
          Tooltip(message: context.tr('lockedForMonth'), child: const Icon(Icons.lock_outline, color: AppColors.muted))
        else
          Text(context.tr(current == null ? 'choose' : 'change'),
              style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _PickDialog extends StatefulWidget {
  const _PickDialog();

  @override
  State<_PickDialog> createState() => _PickDialogState();
}

class _PickDialogState extends State<_PickDialog> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final q = _q.trim().toLowerCase();
    final list = [
      for (final c in ApData.mla)
        if (q.isEmpty || c.en.toLowerCase().contains(q) || c.te.contains(q) || c.name(te).toLowerCase().contains(q)) c,
    ];
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            SearchField(hint: context.tr('searchConstituency'), onChanged: (v) => setState(() => _q = v)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text('${list[i].no}. ${list[i].name(te)}'),
                  subtitle: Text(list[i].name(!te)),
                  onTap: () => Navigator.pop(context, list[i]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ local issues

class _IssuesSection extends StatefulWidget {
  const _IssuesSection({super.key, required this.constituency});

  final Constituency constituency;

  @override
  State<_IssuesSection> createState() => _IssuesSectionState();
}

class _IssuesSectionState extends State<_IssuesSection> {
  final _choices = <String, int>{};
  final _other = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = AppScope.read(context);
    final otherSlot = civic.categories.where((c) => c.isOther).firstOrNull?.slot;
    final text = _choices.containsKey(otherSlot) ? _other.text : null;
    await submitVote(context, () => state.castIssues(widget.constituency, Map.of(_choices), otherText: text));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final mine = state.myIssueChoices;
    final stats = state.issueStats(widget.constituency.id);
    final submitted = mine != null;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.tr('facilitiesQuestion', {'name': widget.constituency.name(te)}),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, height: 1.3)),
        const SizedBox(height: 4),
        Text(context.tr(submitted ? 'feedbackThanks' : 'facilitiesHint'),
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.35)),
        const SizedBox(height: 10),
        for (final cat in civic.activeCategories)
          _CategoryRow(
            category: cat,
            choice: submitted ? mine[cat.slot] : _choices[cat.slot],
            stat: stats[cat.slot] ?? const IssueStat(),
            submitted: submitted,
            onChoice: submitted
                ? null
                : (v) => setState(() => _choices[cat.slot] == v ? _choices.remove(cat.slot) : _choices[cat.slot] = v),
            constituency: widget.constituency,
          ),
        if (!submitted && civic.categories.any((c) => c.isOther && _choices.containsKey(c.slot)))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: _other,
              maxLength: 80,
              decoration: InputDecoration(hintText: context.tr('otherIssueHint'), isDense: true),
            ),
          ),
        if (!submitted) ...[
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _choices.isEmpty || !state.recordLoaded ? null : _submit,
            child: Text(_choices.isEmpty
                ? context.tr('pickAtLeastOne')
                : context.tr('submitFeedback', {'n': '${_choices.length}'})),
          ),
          const SizedBox(height: 4),
          Text(context.tr('oncePerMonth'),
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
        ],
      ]),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.choice,
    required this.stat,
    required this.submitted,
    required this.onChoice,
    required this.constituency,
  });

  final CivicCategory category;
  final int? choice;
  final IssueStat stat;
  final bool submitted;
  final ValueChanged<int>? onChoice;
  final Constituency constituency;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final state = AppScope.of(context);
    Widget pill(int value) {
      final selected = choice == value;
      final color = value == 0 ? AppColors.green : AppColors.red;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: ChoiceChip(
          label: Text(context.tr(value == 0 ? 'good' : 'bad')),
          avatar: Icon(value == 0 ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
              size: 16, color: selected ? Colors.white : color),
          selected: selected,
          showCheckmark: false,
          selectedColor: color,
          labelStyle: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w700),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          onSelected: onChoice == null ? null : (_) => onChoice!(value),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(category.iconData, color: AppColors.ink, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(category.label(te), style: const TextStyle(fontWeight: FontWeight.w600))),
          if (!submitted || choice != null) ...[
            if (!submitted || choice == 0) pill(0),
            if (!submitted || choice == 1) pill(1),
          ] else
            Text(context.tr('skipped'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
        if (submitted) ...[
          const SizedBox(height: 6),
          _GoodBadBar(stat: stat),
          if (choice != null && !state.hasPhoto(category.slot))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                onPressed: () => showPhotoSheet(context, category),
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(context.tr('addPhotoOptional')),
              ),
            )
          else if (state.hasPhoto(category.slot))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(context.tr('photoSubmitted'), style: TextStyle(color: AppColors.green, fontSize: 12)),
            ),
        ],
      ]),
    );
  }
}

/// GOOD vs BAD bar with counts and the evidence-supported count.
class _GoodBadBar extends StatelessWidget {
  const _GoodBadBar({required this.stat});

  final IssueStat stat;

  @override
  Widget build(BuildContext context) {
    if (stat.total == 0) {
      return Text(context.tr('beFirst'), style: const TextStyle(color: AppColors.muted, fontSize: 12));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 8,
          child: Row(children: [
            if (stat.good > 0) Expanded(flex: stat.good, child: Container(color: AppColors.green)),
            if (stat.bad > 0) Expanded(flex: stat.bad, child: Container(color: AppColors.red)),
          ]),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        context.tr('goodBadLine', {
          'g': '${(stat.goodShare * 100).round()}',
          'b': '${(stat.badShare * 100).round()}',
          'n': formatIndian(stat.total),
          'p': formatIndian(stat.withPhoto),
        }),
        style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
      ),
    ]);
  }
}

/// Optional evidence photo with a short caption.
Future<void> showPhotoSheet(BuildContext context, CivicCategory category) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PhotoSheet(category: category),
    );

class _PhotoSheet extends StatefulWidget {
  const _PhotoSheet({required this.category});

  final CivicCategory category;

  @override
  State<_PhotoSheet> createState() => _PhotoSheetState();
}

class _PhotoSheetState extends State<_PhotoSheet> {
  final _caption = TextEditingController();
  Uint8List? _jpeg;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final jpeg = await pickEvidencePhoto(camera: camera);
      if (jpeg != null) setState(() => _jpeg = jpeg);
    } on PhotoRejected catch (e) {
      setState(() => _error = context.tr(e.messageKey));
    } catch (e) {
      debugPrint('Photo pick failed: $e');
      setState(() => _error = context.tr('photoFormat'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final state = AppScope.read(context);
    final navigator = Navigator.of(context);
    final jpeg = _jpeg!;
    final ok = await submitVote(context, () async {
      await state.addIssuePhoto(widget.category.slot, jpeg, _caption.text);
      return const VoteOutcome();
    });
    if (ok != null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.tr('addPhotoTitle', {'x': widget.category.label(context.isTelugu)}),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(context.tr('photoPrivacy'), style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.35)),
            const SizedBox(height: 12),
            if (_jpeg != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_jpeg!, height: 200, fit: BoxFit.cover),
              )
            else
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(true),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(context.tr('camera')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(context.tr('gallery')),
                  ),
                ),
              ]),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: AppColors.red)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              maxLength: 140,
              decoration: InputDecoration(hintText: context.tr('captionHint'), isDense: true),
            ),
            FilledButton(onPressed: _jpeg == null || _busy ? null : _send, child: Text(context.tr('submitPhoto'))),
          ]),
        ),
      );
}

// ------------------------------------------------------ if you were the MLA

class _PrioritySection extends StatefulWidget {
  const _PrioritySection({super.key, required this.constituency});

  final Constituency constituency;

  @override
  State<_PrioritySection> createState() => _PrioritySectionState();
}

class _PrioritySectionState extends State<_PrioritySection> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final mine = state.myPriority;
    final votes = state.priorityVotes(constituencyId: widget.constituency.id);
    final total = votes.fold(0, (a, b) => a + b);
    final order = List.generate(votes.length, (i) => i)..sort((a, b) => votes[b].compareTo(votes[a]));
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.emoji_objects_outlined, color: AppColors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(context.tr('ifYouWereMla'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(context.tr('ifYouWereMlaQ', {'name': widget.constituency.name(te)}),
            style: const TextStyle(color: AppColors.muted, height: 1.35)),
        const SizedBox(height: 10),
        if (mine == null) ...[
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < civic.priorities.length; i++)
              ChoiceChip(
                avatar: Icon(civic.priorities[i].iconData, size: 18),
                label: Text(civic.priorities[i].label(te)),
                selected: _selected == i,
                onSelected: (_) => setState(() => _selected = i),
              ),
          ]),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _selected == null || !state.recordLoaded
                ? null
                : () => submitVote(context, () => state.castPriority(widget.constituency, _selected!)),
            child: Text(context.tr('submitPriority')),
          ),
        ] else ...[
          Text(context.tr('yourChoice', {'x': civic.priorities[mine].label(te)}),
              style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final i in order.take(5))
            PriorityBar(label: civic.priorities[i].label(te), icon: civic.priorities[i].iconData, votes: votes[i], total: total),
          Text(context.tr('totalParticipants', {'n': formatIndian(total)}),
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ]),
    );
  }
}

/// One option's share as a labelled bar.
class PriorityBar extends StatelessWidget {
  const PriorityBar({super.key, required this.label, required this.icon, required this.votes, required this.total, this.color});

  final String label;
  final IconData icon;
  final int votes, total;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : votes / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
              Text('${(share * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 7,
                backgroundColor: AppColors.border,
                color: color ?? AppColors.orange,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// --------------------------------------------------------------- grievances

class _GrievanceList extends StatelessWidget {
  const _GrievanceList({required this.grievances});

  final List<Grievance> grievances;

  @override
  Widget build(BuildContext context) {
    if (grievances.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(context.tr('raisedIssues')),
      for (final g in grievances) GrievanceTile(grievance: g),
      const SizedBox(height: 8),
    ]);
  }
}

/// Public status of a grievance: only what an admin recorded, with dates.
class GrievanceTile extends StatelessWidget {
  const GrievanceTile({super.key, required this.grievance, this.showConstituency = false});

  final Grievance grievance;
  final bool showConstituency;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final g = grievance;
    final last = g.steps.isEmpty ? null : g.steps.last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(g.category?.iconData ?? Icons.report_outlined, color: AppColors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                showConstituency
                    ? '${g.category?.label(te) ?? g.slot} · ${g.constituency?.name(te) ?? g.constituencyId}'
                    : g.category?.label(te) ?? g.slot,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            GrievanceStatusChip(g.status),
          ]),
          const SizedBox(height: 6),
          Text(context.tr('grievanceCounts', {'b': formatIndian(g.bad), 'n': formatIndian(g.good + g.bad), 'p': formatIndian(g.badWithPhoto)}),
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          if (last != null) ...[
            const SizedBox(height: 4),
            Text('${formatDate(last.at.toLocal())}${last.note.isEmpty ? '' : ' · ${last.note}'}',
                style: const TextStyle(fontSize: 12.5)),
          ],
        ]),
      ),
    );
  }
}

class GrievanceStatusChip extends StatelessWidget {
  const GrievanceStatusChip(this.status, {super.key});

  final GrievanceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      GrievanceStatus.resolved => AppColors.green,
      GrievanceStatus.actionReported || GrievanceStatus.responseReceived => AppColors.blue,
      GrievanceStatus.sentToMla || GrievanceStatus.reportGenerated => AppColors.orange,
      GrievanceStatus.threshold => AppColors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(context.tr('gs_${status.name}'), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5)),
    );
  }
}
