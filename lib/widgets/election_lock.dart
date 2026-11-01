import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme.dart';

/// Model Code of Conduct: opinion polls and results are hidden until the
/// election code ends, 5 December 2026, 6 PM India time (12:30 UTC). The
/// voter site blurs them automatically until then; the admin console is not
/// affected.
final electionCodeEnds = DateTime.utc(2026, 12, 5, 12, 30);

/// Tests switch the pause off to exercise the voting screens.
bool electionCodeForceOff = false;

bool get electionCodeActive => !electionCodeForceOff && DateTime.now().toUtc().isBefore(electionCodeEnds);

const _blur = 8.0;

/// Shows [child] blurred and untouchable with an "election code" notice on
/// top while the code is in force; just [child] afterwards.
///
/// [page]: [child] is a whole screen; the notice offers a way back.
class ElectionLock extends StatelessWidget {
  const ElectionLock({super.key, required this.child, this.page = false});

  final Widget child;
  final bool page;

  @override
  Widget build(BuildContext context) {
    if (!electionCodeActive) return child;
    final canPop = page && (ModalRoute.of(context)?.canPop ?? false);
    return Stack(children: [
      IgnorePointer(
        child: ExcludeSemantics(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: _blur, sigmaY: _blur, tileMode: TileMode.decal),
            child: child,
          ),
        ),
      ),
      Positioned.fill(
        // Material: text styles for the notice when [child] is a whole page.
        child: Material(
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, box) => Container(
              color: Colors.white.withValues(alpha: 0.35),
              alignment: page ? Alignment.center : Alignment.topCenter,
              padding: EdgeInsets.all(box.maxHeight < 230 ? 6 : (page ? 20 : 12)),
              child: box.maxHeight < 230
                  ? const ElectionCodeChip()
                  : SingleChildScrollView(
                      child: ElectionCodeNotice(onBack: canPop ? () => Navigator.of(context).maybePop() : null),
                    ),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// "Not available: election code" card.
class ElectionCodeNotice extends StatelessWidget {
  const ElectionCodeNotice({super.key, this.onBack, this.action});

  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(Icons.gavel_rounded, color: AppColors.orange),
            ),
            const SizedBox(height: 10),
            Text(context.tr('electionCodeTitle'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(context.tr('electionCodeBody'),
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.45)),
            if (onBack != null || action != null) const SizedBox(height: 14),
            ?action,
            if (onBack != null)
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: Text(context.tr('goBack')),
              ),
          ]),
        ),
      );
}

/// One-line notice for short blocks (a row of figures).
class ElectionCodeChip extends StatelessWidget {
  const ElectionCodeChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.gavel_rounded, size: 16, color: AppColors.orange),
          const SizedBox(width: 8),
          Flexible(
            child: Text(context.tr('electionCodeShort'),
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        ]),
      );
}
