import 'package:flutter/material.dart';

import '../data/civic.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/vote_flow.dart';

/// Profile strip: votes so far and earned badges; opens [AchievementsScreen].
class AchievementsStrip extends StatelessWidget {
  const AchievementsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final earned = [for (final b in civic.badges) if (state.earnedBadges.contains(b.id)) b];
    final next = civic.badges.where((b) => !state.earnedBadges.contains(b.id)).firstOrNull;
    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AchievementsScreen())),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(context.tr('achievements'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          Text(context.tr('votesCast', {'n': '${state.voteCount}'}), style: const TextStyle(color: AppColors.muted)),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
        const SizedBox(height: 12),
        if (earned.isEmpty)
          Text(context.tr('firstBadgeHint'), style: const TextStyle(color: AppColors.muted))
        else
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: earned.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => BadgeMedal(earned[i], size: 44),
            ),
          ),
        if (next != null) ...[
          const SizedBox(height: 12),
          _Progress(badge: next, count: state.voteCount),
        ],
      ]),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.badge, required this.count});

  final BadgeDef badge;
  final int count;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          context.tr('nextBadge', {'name': badge.label(context.isTelugu), 'n': '${badge.milestone - count}'}),
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (count / badge.milestone).clamp(0, 1).toDouble(),
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: badge.colorValue,
          ),
        ),
      ]);
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('achievements'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        PageBody(
          maxWidth: 640,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.tr('votesCast', {'n': '${state.voteCount}'}),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(context.tr('badgesExplain'), style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 16),
            for (final b in civic.badges)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(children: [
                    BadgeMedal(b, size: 52, locked: !state.earnedBadges.contains(b.id)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.label(te), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                        const SizedBox(height: 2),
                        Text(context.tr(b.milestone == 1 ? 'badgeMilestoneOne' : 'badgeMilestone', {'n': '${b.milestone}'}),
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        if (!state.earnedBadges.contains(b.id)) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (state.voteCount / b.milestone).clamp(0, 1).toDouble(),
                              minHeight: 5,
                              backgroundColor: AppColors.border,
                              color: b.colorValue,
                            ),
                          ),
                        ],
                      ]),
                    ),
                    if (state.earnedBadges.contains(b.id)) Icon(Icons.verified, color: AppColors.green),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
