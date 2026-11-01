import 'package:flutter/material.dart';

import '../../data/featured_polls.dart';
import '../../utils.dart';
import '../admin_widgets.dart';

class FeaturedPage extends StatelessWidget {
  const FeaturedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final polls = admin.draft.featured;
    void setAll(List<FeaturedPoll> list) => admin.update((c) => c.copyWith(featured: list));

    return AdminPage(
      title: 'Featured polls',
      subtitle: 'Statewide polls on the home page (Vote for CM, Vote for AP, recent activity). One vote per user per '
          'poll. At most 5 are shown at a time.',
      actions: [
        FilledButton.icon(
          onPressed: () async {
            final now = istToday();
            final poll = await showDialog<FeaturedPoll>(
              context: context,
              builder: (_) => FeaturedEditor(
                poll: FeaturedPoll(
                  id: 'poll-${DateTime.now().millisecondsSinceEpoch}',
                  kind: FeaturedKind.activity,
                  titleEn: 'Recent activity',
                  titleTe: 'ఇటీవలి పరిణామం',
                  questionEn: '',
                  questionTe: '',
                  start: now,
                  end: now.add(const Duration(days: 10)),
                  monthlyVotes: 36000,
                  options: const [
                    FeaturedOption('Support', 'సమర్థిస్తాను', iconName: 'up', weight: 60),
                    FeaturedOption('Do not support', 'సమర్థించను', iconName: 'down', weight: 40),
                  ],
                ),
              ),
            );
            if (poll != null) setAll([...polls, poll]);
          },
          icon: const Icon(Icons.add),
          label: const Text('New poll'),
        ),
      ],
      children: [
        if (polls.where((p) => p.enabled).length > admin.draft.civic.maxFeatured)
          AdminCard(
            child: Text(
              'More than ${admin.draft.civic.maxFeatured} polls are visible. Only the first '
              '${admin.draft.civic.maxFeatured} visible polls (in this order) are shown on the home page; switch the others off.',
              style: const TextStyle(color: AdminColors.danger, fontWeight: FontWeight.w600),
            ),
          ),
        for (var i = 0; i < polls.length; i++)
          AdminCard(
            title: polls[i].titleEn,
            subtitle: '${polls[i].kind.name.toUpperCase()} · ${formatDate(polls[i].start)} → '
                '${formatDate(polls[i].end.subtract(const Duration(days: 1)))} · ${polls[i].options.length} options'
                '${polls[i].isOpen ? ' · LIVE' : ''}',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Visible', style: TextStyle(color: AdminColors.muted)),
              Switch(
                value: polls[i].enabled,
                onChanged: (v) => setAll([...polls]..[i] = FeaturedPoll.fromJson({...polls[i].toJson(), 'enabled': v})),
              ),
              IconButton(
                tooltip: 'Move up',
                onPressed: i == 0 ? null : () => setAll([...polls]..removeAt(i)..insert(i - 1, polls[i])),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () async {
                  final p = await showDialog<FeaturedPoll>(context: context, builder: (_) => FeaturedEditor(poll: polls[i]));
                  if (p != null) setAll([...polls]..[i] = p);
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete "${polls[i].titleEn}"?'),
                      content: const Text('Votes already cast in this poll stay on users\' devices but the poll disappears.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) setAll([...polls]..removeAt(i));
                },
                icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
              ),
            ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(polls[i].questionEn, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final o in polls[i].options)
                  Chip(
                    avatar: o.photoUrl != null
                        ? CircleAvatar(backgroundImage: NetworkImage(o.photoUrl!))
                        : (o.icon != null ? Icon(o.icon, size: 18) : null),
                    label: Text(o.en),
                  ),
              ]),
            ]),
          ),
      ],
    );
  }
}

class FeaturedEditor extends StatefulWidget {
  const FeaturedEditor({super.key, required this.poll});

  final FeaturedPoll poll;

  @override
  State<FeaturedEditor> createState() => _FeaturedEditorState();
}

class _FeaturedEditorState extends State<FeaturedEditor> {
  late Map<String, dynamic> _j = widget.poll.toJson();
  late List<Map<String, dynamic>> _options = [for (final o in widget.poll.options) o.toJson()];

  void _set(String key, Object? value) => setState(() => _j = {..._j, key: value});

  Future<void> _pickDate(String key) async {
    final cur = DateTime.parse(_j[key] as String);
    final picked = await showDatePicker(
      context: context,
      initialDate: key == 'end' ? cur.subtract(const Duration(days: 1)) : cur,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    // "end" is exclusive: store the day after the last poll day.
    final d = DateTime.utc(picked.year, picked.month, picked.day + (key == 'end' ? 1 : 0));
    _set(key, d.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final parties = admin.draft.parties;
    Widget field(String key, String label, {int lines = 1}) => DraftField(
          key: ValueKey('f-$key'),
          label: label,
          value: _j[key] as String?,
          maxLines: lines,
          onChanged: (v) => _j = {..._j, key: v.isEmpty ? null : v},
        );

    return AlertDialog(
      title: Text(widget.poll.questionEn.isEmpty ? 'New featured poll' : 'Edit featured poll'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AdminFieldRow(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _j['kind'] as String,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'cm', child: Text('CM poll (monthly updates)')),
                    DropdownMenuItem(value: 'issues', child: Text('Issues poll (monthly updates)')),
                    DropdownMenuItem(value: 'activity', child: Text('Recent activity (short poll)')),
                  ],
                  onChanged: (v) => _set('kind', v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate('start'),
                  icon: const Icon(Icons.event),
                  label: Text('Starts ${formatDate(DateTime.parse(_j['start'] as String))}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate('end'),
                  icon: const Icon(Icons.event_busy),
                  label: Text('Last day ${formatDate(DateTime.parse(_j['end'] as String).subtract(const Duration(days: 1)))}'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: field('titleEn', 'Title (English)')),
              const SizedBox(width: 12),
              Expanded(child: field('titleTe', 'Title (Telugu)')),
            ]),
            const SizedBox(height: 14),
            field('questionEn', 'Question (English)', lines: 2),
            const SizedBox(height: 14),
            field('questionTe', 'Question (Telugu)', lines: 2),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: field('detailEn', 'Details (English, optional)', lines: 2)),
              const SizedBox(width: 12),
              Expanded(child: field('detailTe', 'Details (Telugu, optional)', lines: 2)),
            ]),
            const SizedBox(height: 14),
            field('sourceUrl', 'Source link (news article, optional)'),
            const SizedBox(height: 22),
            Row(children: [
              const Expanded(child: Text('Options', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              TextButton.icon(
                onPressed: () => setState(() => _options = [..._options, {'en': '', 'te': '', 'weight': 10.0}]),
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
            ]),
            for (var i = 0; i < _options.length; i++)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Column(children: [
                  AdminFieldRow(children: [
                    Expanded(
                      child: DraftField(
                        key: ValueKey('o$i-en-${_options.length}'),
                        label: 'Option ${i + 1} (English)',
                        value: _options[i]['en'] as String?,
                        onChanged: (v) => _options[i] = {..._options[i], 'en': v},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DraftField(
                        key: ValueKey('o$i-te-${_options.length}'),
                        label: 'Telugu',
                        value: _options[i]['te'] as String?,
                        onChanged: (v) => _options[i] = {..._options[i], 'te': v},
                      ),
                    ),
                    IconButton(
                      onPressed: _options.length <= 2 ? null : () => setState(() => _options = [..._options]..removeAt(i)),
                      icon: const Icon(Icons.close),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  AdminFieldRow(children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _options[i]['partyId'] as String?,
                        decoration: const InputDecoration(labelText: 'Party (for people)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          for (final p in parties) DropdownMenuItem(value: p.id, child: Text(p.short)),
                        ],
                        onChanged: (v) => setState(() => _options[i] = {..._options[i], 'partyId': v}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _options[i]['icon'] as String?,
                        decoration: const InputDecoration(labelText: 'Icon (for issues)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          for (final e in featuredIcons.entries)
                            DropdownMenuItem(
                              value: e.key,
                              child: Row(children: [Icon(e.value, size: 18), const SizedBox(width: 8), Text(e.key)]),
                            ),
                        ],
                        onChanged: (v) => setState(() => _options[i] = {..._options[i], 'icon': v}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final u = await admin.uploadImage('featured');
                        if (u != null) setState(() => _options[i] = {..._options[i], 'photoUrl': u});
                      },
                      icon: _options[i]['photoUrl'] != null
                          ? CircleAvatar(radius: 12, backgroundImage: NetworkImage(_options[i]['photoUrl'] as String))
                          : const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: Text(_options[i]['photoUrl'] != null ? 'Change photo' : 'Photo'),
                    ),
                    if (_options[i]['photoUrl'] != null)
                      IconButton(
                        tooltip: 'Remove photo',
                        onPressed: () => setState(() => _options[i] = {..._options[i]}..remove('photoUrl')),
                        icon: const Icon(Icons.hide_image_outlined),
                      ),
                  ]),
                ]),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final opts = _options.where((o) => (o['en'] as String? ?? '').isNotEmpty).toList();
            if ((_j['questionEn'] as String? ?? '').isEmpty || opts.length < 2) {
              showAdminSnack(context, 'Add a question and at least two options', error: true);
              return;
            }
            Navigator.pop(context, FeaturedPoll.fromJson({..._j, 'options': opts}));
          },
          child: const Text('Save to draft'),
        ),
      ],
    );
  }
}
