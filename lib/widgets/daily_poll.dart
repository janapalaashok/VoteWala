import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/daily_polls.dart';
import '../l10n/strings.dart';
import '../services/vote_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';
import 'election_lock.dart';
import 'vote_flow.dart';

const _palette = [
  Color(0xFFF47A1F),
  Color(0xFF1E9A3F),
  Color(0xFF2563EB),
  Color(0xFF9333EA),
  Color(0xFFDC2626),
  Color(0xFF0D9488),
  Color(0xFFCA8A04),
  Color(0xFF64748B),
];

Color dailyColor(int i) => _palette[i % _palette.length];

/// Shows today's poll as a popup that only closes after the voter answers.
Future<void> showDailyPollPopup(BuildContext context, DailyPoll poll) async {
  final outcome = await showDialog<VoteOutcome>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    // The whole site behind the popup is blurred.
    builder: (_) => BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: DailyPollDialog(poll: poll),
    ),
  );
  if (outcome == null || !context.mounted) return;
  for (final badge in outcome.newBadges) {
    if (!context.mounted) break;
    await showBadgeUnlocked(context, badge);
  }
}

class DailyPollDialog extends StatefulWidget {
  const DailyPollDialog({super.key, required this.poll});

  final DailyPoll poll;

  @override
  State<DailyPollDialog> createState() => _DailyPollDialogState();
}

class _DailyPollDialogState extends State<DailyPollDialog> {
  int? _selected;
  bool _busy = false;
  bool _done = false;
  String? _error;

  Future<void> _vote() async {
    final option = _selected;
    if (option == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final state = AppScope.read(context);
    try {
      final outcome = await state.castDailyVote(widget.poll, option);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      if (mounted) Navigator.of(context).pop(outcome);
    } on VoteException catch (e) {
      if (!mounted) return;
      // Already answered (e.g. on another device): nothing left to ask.
      if (e.error == VoteError.alreadyVoted) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _busy = false;
        _error = context.tr(e.messageKey);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = context.tr('voteRejected');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final poll = widget.poll;
    final width = MediaQuery.sizeOf(context).width;
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: width < 480 ? 16 : 40, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _done
                ? _thanks(context, te)
                : electionCodeActive
                    ? _paused(context, te, poll)
                    : _question(context, te, poll),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, DailyPoll poll) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.orange, AppColors.orange.withValues(alpha: 0.82)]),
    ),
    child: Row(
      children: [
        const Icon(Icons.today_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.tr('todaysPoll'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            poll.dateLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ),
      ],
    ),
  );

  Widget _question(BuildContext context, bool te, DailyPoll poll) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, poll),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(poll.question(te), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.3)),
              const SizedBox(height: 6),
              Text(context.tr('dailyPrompt'), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              for (var i = 0; i < poll.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: _selected == i ? AppColors.orange.withValues(alpha: 0.08) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: _selected == i ? AppColors.orange : AppColors.border,
                        width: _selected == i ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _busy ? null : () => setState(() => _selected = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Icon(
                              _selected == i ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: _selected == i ? AppColors.orange : AppColors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                poll.options[i].label(te),
                                style: TextStyle(
                                  fontWeight: _selected == i ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _selected == null || _busy ? null : _vote,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(context.tr('submitVote')),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Election code: the poll card blurred, the notice on top, and a way out
  /// (voting is not possible, so the popup must not trap the visitor).
  Widget _paused(BuildContext context, bool te, DailyPoll poll) => Stack(children: [
        IgnorePointer(
          child: ExcludeSemantics(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7, tileMode: TileMode.decal),
              child: _question(context, te, poll),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: 0.3),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: ElectionCodeNotice(
                action: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('ok'))),
              ),
            ),
          ),
        ),
      ]);

  Widget _thanks(BuildContext context, bool te) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 34, 28, 34),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, color: AppColors.green, size: 44),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('dailyThanks'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('yourChoice', {'x': widget.poll.options[_selected!].label(te)}),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}

/// Dashboard section: today's poll with its date and results once answered,
/// and the results of earlier days.
class DailyPollSection extends StatelessWidget {
  const DailyPollSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final today = state.todaysPoll;
    final past = state.pastDailyPolls(max: 3);
    if (today == null && past.isEmpty) return const SizedBox.shrink();
    final earlier = [
      Text(
        context.tr('earlierDailyPolls'),
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 6),
      for (final p in past)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DailyPollCard(poll: p),
        ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 900 && today != null && past.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(context.tr('todaysPoll')),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: DailyPollCard(poll: today, highlight: true)),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: earlier),
                  ),
                ],
              )
            else ...[
              if (today != null) DailyPollCard(poll: today, highlight: true),
              if (past.isNotEmpty) ...[const SizedBox(height: 10), ...earlier],
            ],
          ],
        );
      },
    );
  }
}

class DailyPollCard extends StatelessWidget {
  const DailyPollCard({super.key, required this.poll, this.highlight = false});

  final DailyPoll poll;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final mine = state.dailyChoice(poll);
    final open = poll.isToday && mine == null;
    final votes = open ? const <int>[] : state.dailyVotes(poll);
    final total = votes.fold(0, (a, b) => a + b);
    return AppCard(
      borderColor: highlight ? AppColors.orange.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded, size: 16, color: highlight ? AppColors.orange : AppColors.muted),
              const SizedBox(width: 6),
              Text(
                poll.dateLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: highlight ? AppColors.orange : AppColors.muted,
                ),
              ),
              const Spacer(),
              if (!open) Text(votesText(context, total), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            poll.question(te),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: highlight ? 17 : 15, height: 1.3),
          ),
          const SizedBox(height: 12),
          if (open)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: state.user == null ? null : () => showDailyPollPopup(context, poll),
                child: Text(context.tr('voteNow')),
              ),
            )
          else ...[
            for (var i = 0; i < poll.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (mine == i) ...[
                          Icon(Icons.check_circle, size: 15, color: AppColors.green),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            poll.options[i].label(te),
                            style: TextStyle(fontWeight: mine == i ? FontWeight.w800 : FontWeight.w500),
                          ),
                        ),
                        Text(
                          total == 0 ? '0%' : '${(votes[i] * 100 / total).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : votes[i] / total,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDEFF2),
                        color: dailyColor(i),
                      ),
                    ),
                  ],
                ),
              ),
            if (mine != null)
              Text(
                context.tr('yourChoice', {'x': poll.options[mine].label(te)}),
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
          ],
        ],
      ),
    );
  }
}
