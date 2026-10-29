import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/featured_polls.dart';
import '../data/poll_month.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/share_card.dart';

const _palette = [
  Color(0xFFF47A1F), Color(0xFF2F6FDB), Color(0xFF1E9A3F), Color(0xFFE53935),
  Color(0xFF8E44AD), Color(0xFF00897B), Color(0xFF6D4C41), Color(0xFFF6B21A),
];

Color optionColor(FeaturedPoll p, int i) {
  if (p.kind == FeaturedKind.activity) return i == 0 ? AppColors.green : AppColors.red;
  final party = p.options[i].party;
  // Two TDP leaders in the CM poll: shade the second one.
  if (party != null && p.options.indexWhere((o) => o.partyId == party.id) == i) return party.color;
  return _palette[i % _palette.length];
}

List<int> _ranking(List<int> votes) =>
    List.generate(votes.length, (i) => i)..sort((a, b) => votes[b].compareTo(votes[a]));

String _pct(int v, int total) => total == 0 ? '0.0' : (v * 100 / total).toStringAsFixed(1);

/// Dashboard card for a featured poll.
class FeaturedPollCard extends StatelessWidget {
  const FeaturedPollCard({super.key, required this.poll});

  final FeaturedPoll poll;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final totals = state.featuredTotals(poll);
    final total = totals.fold(0, (a, b) => a + b);
    final lead = _ranking(totals).first;
    final mine = state.featuredChoice(poll);
    final month = PollMonth.current();
    final subtitle = poll.hasMonthlyUpdates
        ? '${month.label(te)}: ${context.tr('monthVotes', {'n': formatCompact(state.featuredVotesIn(poll, month).fold(0, (a, b) => a + b))})}'
        : poll.isOpen
            ? context.tr('daysLeft', {'n': '${timeUntil(poll.end).inDays + 1}'})
            : context.tr('closedOn', {'date': formatDate(poll.end.subtract(const Duration(days: 1)))});

    return AppCard(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => FeaturedPollScreen(poll: poll))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _KindIcon(poll.kind),
          const SizedBox(width: 10),
          Expanded(
            child: Text(poll.title(te), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          LiveBadge(closed: !poll.isOpen),
        ]),
        const SizedBox(height: 10),
        Text(poll.question(te), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.35)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(children: [
              for (final i in _ranking(totals))
                Expanded(flex: totals[i].clamp(1, 1 << 30), child: Container(color: optionColor(poll, i))),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('leadingNow', {'x': '${poll.options[lead].label(te)} ${_pct(totals[lead], total)}%'}),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Row(children: [
          Expanded(child: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
          if (mine != null)
            Icon(Icons.check_circle, color: AppColors.green, size: 20)
          else if (poll.isOpen)
            Text(context.tr('voteNow'), style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon(this.kind);

  final FeaturedKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      FeaturedKind.cm => (Icons.workspace_premium, AppColors.orange),
      FeaturedKind.issues => (Icons.flag, AppColors.green),
      FeaturedKind.activity => (Icons.campaign, AppColors.blue),
    };
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _OptionAvatar extends StatelessWidget {
  const _OptionAvatar(this.poll, this.index, {this.size = 44});

  final FeaturedPoll poll;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final o = poll.options[index];
    if (o.party != null) return PersonAvatar(photoUrl: o.photoUrl, party: o.party!, size: size);
    final color = optionColor(poll, index);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(o.icon ?? Icons.circle, color: color, size: size * 0.55),
    );
  }
}

class FeaturedPollScreen extends StatefulWidget {
  const FeaturedPollScreen({super.key, required this.poll});

  final FeaturedPoll poll;

  @override
  State<FeaturedPollScreen> createState() => _FeaturedPollScreenState();
}

class _FeaturedPollScreenState extends State<FeaturedPollScreen> {
  int? _selected;

  Future<void> _submit() async {
    final poll = widget.poll;
    final te = context.isTelugu;
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('selectCandidate'))));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('confirmVote')),
        content: Text('${poll.options[_selected!].label(te)}\n\n${ctx.tr('featuredOneVote')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('confirm'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (AppScope.read(context).castFeaturedVote(poll, _selected!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.green, content: Text(context.tr('voteRecorded'))),
      );
      _share();
    }
  }

  void _share() {
    final poll = widget.poll;
    showShareSheet(context, featuredShareData(context, poll, AppScope.read(context).featuredTotals(poll), (i) => optionColor(poll, i)));
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final mine = state.featuredChoice(poll);
    final canVote = poll.isOpen && mine == null && state.user != null;
    final totals = state.featuredTotals(poll);
    final total = totals.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(poll.title(te)),
        actions: [IconButton(icon: const Icon(Icons.share_outlined), onPressed: _share)],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        PageBody(
          maxWidth: 680,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              LiveBadge(closed: !poll.isOpen, long: true),
              const Spacer(),
              Text(
                poll.isOpen
                    ? '${context.tr('closesIn')} ${formatCountdown(timeUntil(poll.end))}'
                    : context.tr('closedOn', {'date': formatDate(poll.end.subtract(const Duration(days: 1)))}),
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              poll.hasMonthlyUpdates ? context.tr('yearlyPoll', {'year': '${poll.start.year}'}) : context.tr('tenDayPoll'),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Text(poll.question(te), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.3)),
            if (poll.detail(te) != null) ...[
              const SizedBox(height: 8),
              Text(poll.detail(te)!, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            ],
            if (poll.sourceUrl != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(poll.sourceUrl!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(context.tr('source')),
                ),
              ),
            const SizedBox(height: 12),
            if (canVote) ...[
              for (var i = 0; i < poll.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => setState(() => _selected = i),
                    borderColor: _selected == i ? AppColors.orange : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      _OptionAvatar(poll, i),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(poll.options[i].label(te), style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (poll.options[i].party != null)
                            Text(poll.options[i].party!.short,
                                style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        ]),
                      ),
                      Icon(_selected == i ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _selected == i ? AppColors.orange : AppColors.grey),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _submit, child: Text(context.tr('submitVote'))),
              const SizedBox(height: 8),
              Text(context.tr('featuredOneVote'),
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ] else ...[
              if (mine != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.check_circle, color: AppColors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text(context.tr('yourChoice', {'x': poll.options[mine].label(te)}))),
                  ]),
                ),
              if (mine != null) ...[
                const SizedBox(height: 12),
                ShareInviteButton(onPressed: _share),
              ],
              const SizedBox(height: 8),
              SectionHeader(context.tr('results')),
              for (final i in _ranking(totals))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    _OptionAvatar(poll, i, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(poll.options[i].label(te),
                                style: TextStyle(fontWeight: i == mine ? FontWeight.w800 : FontWeight.w600)),
                          ),
                          Text('${_pct(totals[i], total)}%',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : totals[i] / total,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFEDEFF2),
                            color: optionColor(poll, i),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${formatIndian(totals[i])} ${context.tr('votes')}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                      ]),
                    ),
                  ]),
                ),
              Text(context.tr('totalSoFar', {'n': formatIndian(total)}),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
            if (poll.hasMonthlyUpdates) ...[
              const SizedBox(height: 16),
              SectionHeader(context.tr('monthlyUpdates')),
              for (final m in poll.months.reversed) _MonthRow(poll: poll, month: m),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.poll, required this.month});

  final FeaturedPoll poll;
  final PollMonth month;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final votes = AppScope.of(context).featuredVotesIn(poll, month);
    final total = votes.fold(0, (a, b) => a + b);
    final order = _ranking(votes);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(month.label(te), style: const TextStyle(fontWeight: FontWeight.w700)),
          if (month.isCurrent) ...[
            const SizedBox(width: 8),
            StatusBadge(label: context.tr('live')),
          ],
          const Spacer(),
          Text('${formatCompact(total)} ${context.tr('votes')}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
            child: Row(children: [
              for (final i in order)
                Expanded(flex: votes[i].clamp(1, 1 << 30), child: Container(color: optionColor(poll, i))),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          order.take(3).map((i) => '${poll.options[i].label(te)} ${_pct(votes[i], total)}%').join(' · '),
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ]),
    );
  }
}
