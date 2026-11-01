import '../widgets/election_lock.dart';
import 'package:flutter/material.dart';

import '../data/featured_polls.dart';
import '../data/poll_month.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'featured_poll_screen.dart';
import 'results_screen.dart';

void openClosedPolls(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ClosedPollsScreen()));

/// Featured polls that have ended, with their final results, and a way to
/// see earlier months' MLA / MP results.
class ClosedPollsScreen extends StatelessWidget {
  const ClosedPollsScreen({super.key});

  @override
  Widget build(BuildContext context) => ElectionLock(page: true, child: _unlockedBuild(context));

  Widget _unlockedBuild(BuildContext context) {
    final polls = closedFeaturedPolls;
    final te = context.isTelugu;
    final previous = PollMonth.current().previous;
    return Scaffold(
      appBar: PageBar(title: Text(context.tr('closedPolls'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        PageBody(
          maxWidth: 1200,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.tr('closedPollsSub'), style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 16),
            if (polls.isEmpty)
              EmptyState(icon: Icons.inventory_2_outlined, message: context.tr('noClosedPolls'))
            else
              LayoutBuilder(builder: (context, box) {
                final columns = box.maxWidth >= 1000 ? 3 : (box.maxWidth >= 640 ? 2 : 1);
                final w = (box.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(spacing: 16, runSpacing: 16, children: [
                  for (final p in polls) SizedBox(width: w, child: FeaturedPollCard(poll: p)),
                ]);
              }),
            const SizedBox(height: 24),
            AppCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ResultsScreen())),
              child: Row(children: [
                Icon(Icons.history, color: AppColors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr('pastMonthResults'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(context.tr('pastMonthResultsSub', {'month': previous.label(te)}),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
