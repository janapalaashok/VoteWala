import 'package:flutter/material.dart';

import '../../data/daily_polls.dart';
import '../../services/vote_service.dart';
import '../admin_widgets.dart';

/// "Today's poll": one question per date. On that day (India time) every
/// signed-in voter sees it in a popup when the site opens and must answer it
/// once; afterwards it appears with results on the dashboard.
class DailyPollsPage extends StatelessWidget {
  const DailyPollsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final polls = [...admin.draft.daily]..sort((a, b) => b.date.compareTo(a.date));
    final today = todayKey();
    void save(List<DailyPoll> list) => admin.update((c) => c.copyWith(daily: list));

    Future<void> edit(DailyPoll? poll) async {
      final taken = {
        for (final p in admin.draft.daily)
          if (p.date != poll?.date) p.date,
      };
      final result = await showDialog<DailyPoll>(
        context: context,
        builder: (_) => _DailyEditor(poll: poll, takenDates: taken),
      );
      if (result == null) return;
      save([
        for (final p in admin.draft.daily)
          if (p.date != poll?.date) p,
        result,
      ]);
    }

    final upcoming = polls.where((p) => p.date.compareTo(today) >= 0).toList().reversed.toList();
    final past = polls.where((p) => p.date.compareTo(today) < 0).toList();

    return AdminPage(
      title: "Today's poll",
      subtitle:
          'Schedule one question per date. On that day every signed-in voter gets it as a popup when the site '
          'opens and must answer to continue; then it shows with results on the dashboard. Press Publish after changes.',
      actions: [
        FilledButton.icon(
          onPressed: () => edit(null),
          icon: const Icon(Icons.add),
          label: const Text('Schedule a poll'),
        ),
      ],
      children: [
        if (!polls.any((p) => p.date == today))
          AdminCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AdminColors.muted),
                const SizedBox(width: 10),
                const Expanded(child: Text('No poll is scheduled for today, so no popup is shown today.')),
              ],
            ),
          ),
        AdminCard(
          title: 'Today and upcoming',
          child: upcoming.isEmpty
              ? const Text('Nothing scheduled yet.', style: TextStyle(color: AdminColors.muted))
              : Column(
                  children: [
                    for (final p in upcoming)
                      _PollRow(
                        poll: p,
                        today: today,
                        onEdit: () => edit(p),
                        onDelete: () => save([...admin.draft.daily]..removeWhere((x) => x.date == p.date)),
                      ),
                  ],
                ),
        ),
        if (past.isNotEmpty)
          AdminCard(
            title: 'Past polls',
            subtitle: 'Shown on the dashboard as "Earlier polls" (latest three).',
            child: Column(
              children: [
                for (final p in past)
                  _PollRow(
                    poll: p,
                    today: today,
                    onEdit: () => edit(p),
                    onDelete: () => save([...admin.draft.daily]..removeWhere((x) => x.date == p.date)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PollRow extends StatelessWidget {
  const _PollRow({required this.poll, required this.today, required this.onEdit, required this.onDelete});

  final DailyPoll poll;
  final String today;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final isToday = poll.date == today;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(poll.dateLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdminColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(color: AdminColors.success, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(poll.questionEn, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (poll.questionTe.isNotEmpty) Text(poll.questionTe, style: const TextStyle(color: AdminColors.muted)),
                const SizedBox(height: 4),
                _Results(poll: poll),
              ],
            ),
          ),
          IconButton(tooltip: 'Edit', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete this poll?'),
                  content: Text(
                    '${poll.dateLabel}: ${poll.questionEn}\nVotes already cast stay recorded but are no longer shown.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) onDelete();
            },
            icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
          ),
        ],
      ),
    );
  }
}

/// Answers with their vote counts (live data; hidden in demo mode).
class _Results extends StatefulWidget {
  const _Results({required this.poll});

  final DailyPoll poll;

  @override
  State<_Results> createState() => _ResultsState();
}

class _ResultsState extends State<_Results> {
  Future<List<int>>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = AdminScope.read(context).data;
    if (_load == null && data != null && widget.poll.date.compareTo(todayKey()) <= 0) {
      _load = data.db
          .list('tallies/${PollIds.daily(widget.poll.date)}/buckets')
          .then(
            (buckets) => [
              for (var i = 0; i < widget.poll.options.length; i++)
                buckets.values.fold<int>(0, (a, b) => a + ((b['o$i'] as int?) ?? 0)),
            ],
          );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
    future: _load,
    builder: (context, snap) {
      final counts = snap.data;
      final total = counts?.fold(0, (a, b) => a + b) ?? 0;
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (var i = 0; i < widget.poll.options.length; i++)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                counts == null
                    ? widget.poll.options[i].en
                    : '${widget.poll.options[i].en}: ${counts[i]}'
                          '${total == 0 ? '' : ' (${(counts[i] * 100 / total).round()}%)'}',
              ),
            ),
          if (counts != null) Chip(visualDensity: VisualDensity.compact, label: Text('$total votes')),
        ],
      );
    },
  );
}

class _DailyEditor extends StatefulWidget {
  const _DailyEditor({this.poll, required this.takenDates});

  final DailyPoll? poll;
  final Set<String> takenDates;

  @override
  State<_DailyEditor> createState() => _DailyEditorState();
}

class _DailyEditorState extends State<_DailyEditor> {
  late String _date = widget.poll?.date ?? _firstFreeDate();
  late final _qEn = TextEditingController(text: widget.poll?.questionEn ?? '');
  late final _qTe = TextEditingController(text: widget.poll?.questionTe ?? '');
  late final List<(TextEditingController, TextEditingController)> _options = [
    for (final o in widget.poll?.options ?? const [DailyOption('Yes', 'అవును'), DailyOption('No', 'కాదు')])
      (TextEditingController(text: o.en), TextEditingController(text: o.te)),
  ];
  String? _error;

  String _firstFreeDate() {
    var d = DateTime.parse(todayKey());
    while (widget.takenDates.contains(todayKey(d))) {
      d = d.add(const Duration(days: 1));
    }
    return todayKey(d);
  }

  void _save() {
    final poll = DailyPoll(
      date: _date,
      questionEn: _qEn.text.trim(),
      questionTe: _qTe.text.trim(),
      options: [
        for (final (en, te) in _options)
          if (en.text.trim().isNotEmpty) DailyOption(en.text.trim(), te.text.trim()),
      ],
    );
    final problem = widget.takenDates.contains(_date)
        ? 'Another poll is already scheduled for this date.'
        : poll.questionEn.isEmpty
        ? 'Write the question in English.'
        : poll.options.length < 2
        ? 'Give at least two answers.'
        : null;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.pop(context, poll);
  }

  @override
  Widget build(BuildContext context) {
    final p = DailyPoll(date: _date, questionEn: '', questionTe: '', options: const []);
    final started = widget.poll != null && widget.poll!.date.compareTo(todayKey()) <= 0;
    return AlertDialog(
      title: Text(widget.poll == null ? "Schedule today's poll" : 'Edit poll'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(_date),
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = todayKey(picked));
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text('Date: ${p.dateLabel}'),
              ),
              if (started)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'This poll has started: changing the answers'
                    "'"
                    ' order mixes up votes already cast.',
                    style: TextStyle(color: AdminColors.danger, fontSize: 12.5),
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _qEn,
                maxLines: 2,
                minLines: 1,
                decoration: const InputDecoration(labelText: 'Question (English)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _qTe,
                maxLines: 2,
                minLines: 1,
                decoration: const InputDecoration(labelText: 'Question (Telugu)'),
              ),
              const SizedBox(height: 16),
              const Text('Answers (2 to 8)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (var i = 0; i < _options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminFieldRow(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _options[i].$1,
                          decoration: InputDecoration(labelText: 'Answer ${i + 1} (English)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _options[i].$2,
                          decoration: InputDecoration(labelText: 'Answer ${i + 1} (Telugu)'),
                        ),
                      ),
                      if (_options.length > 2)
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () => setState(() => _options.removeAt(i)),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
              if (_options.length < 8)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _options.add((TextEditingController(), TextEditingController()))),
                    icon: const Icon(Icons.add),
                    label: const Text('Add answer'),
                  ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: AdminColors.danger, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
