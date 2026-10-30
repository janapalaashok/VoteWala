import 'package:flutter/material.dart';

import '../data/civic.dart';
import '../l10n/strings.dart';
import '../services/vote_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Sends a vote with a progress overlay. On success shows "vote recorded"
/// and celebrates newly unlocked badges; on failure explains why. Returns
/// null when the vote was not recorded.
Future<VoteOutcome?> submitVote(BuildContext context, Future<VoteOutcome> Function() send) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
  );
  VoteOutcome? outcome;
  String? error;
  try {
    outcome = await send();
  } on VoteException catch (e) {
    debugPrint('Vote failed: $e');
    error = e.messageKey;
  } catch (e) {
    debugPrint('Vote failed: $e');
    error = 'voteRejected';
  }
  navigator.pop();
  if (!context.mounted) return null;
  if (error != null) {
    messenger.showSnackBar(SnackBar(backgroundColor: AppColors.red, content: Text(context.tr(error))));
    return null;
  }
  messenger.showSnackBar(SnackBar(backgroundColor: AppColors.green, content: Text(context.tr('voteRecorded'))));
  for (final badge in outcome!.newBadges) {
    if (!context.mounted) break;
    await showBadgeUnlocked(context, badge);
  }
  return outcome;
}

/// A short, friendly celebration for a newly earned badge.
Future<void> showBadgeUnlocked(BuildContext context, BadgeDef badge) => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'badge',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (ctx, _, _) => _BadgeDialog(badge: badge),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut, reverseCurve: Curves.easeIn),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );

class _BadgeDialog extends StatelessWidget {
  const _BadgeDialog({required this.badge});

  final BadgeDef badge;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            BadgeMedal(badge, size: 96),
            const SizedBox(height: 16),
            Text(context.tr('badgeUnlocked'),
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(badge.label(te),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(context.tr('badgeMilestone', {'n': '${badge.milestone}'}),
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('great'))),
          ]),
        ),
      ),
    );
  }
}

/// Round badge medal; greyed out while locked.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal(this.badge, {super.key, this.size = 56, this.locked = false});

  final BadgeDef badge;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppColors.grey : badge.colorValue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.35)!, color],
        ),
        boxShadow: locked ? null : [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: size / 5, offset: Offset(0, size / 16))],
        border: Border.all(color: Colors.white, width: size / 18),
      ),
      child: Icon(locked ? Icons.lock_outline : badge.iconData, color: Colors.white, size: size * 0.48),
    );
  }
}
