import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ap_data.dart';
import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import 'painters.dart';

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

/// Centers content and caps its width on tablets and desktop browsers.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

class VoteWalaLogo extends StatelessWidget {
  const VoteWalaLogo({super.key, this.markSize = 56, this.horizontal = false, this.tagline = true});

  final double markSize;
  final bool horizontal;
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(dimension: markSize, child: const CustomPaint(painter: BallotMarkPainter()));
    final fontSize = horizontal ? markSize * 0.5 : markSize * 0.42;
    final word = Text.rich(
      TextSpan(children: const [
        TextSpan(text: 'Vote', style: TextStyle(color: AppColors.orange)),
        TextSpan(text: 'wala', style: TextStyle(color: AppColors.green)),
      ]),
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.5),
    );
    final tag = Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: fontSize * 0.5, height: 1.5, color: AppColors.orange),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('Your Voice. Your Choice.',
            style: TextStyle(fontSize: fontSize * 0.28, color: AppColors.ink, fontWeight: FontWeight.w500)),
      ),
      Container(width: fontSize * 0.5, height: 1.5, color: AppColors.green),
    ]);
    if (horizontal) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        mark,
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          word,
          if (tagline) tag,
        ]),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [mark, const SizedBox(height: 4), word, if (tagline) tag]);
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.borderColor});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor ?? AppColors.border, width: borderColor == null ? 1 : 1.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      );
}

/// Two-option toggle (orange pill for selected), e.g. "All (175) | By District".
class PillToggle extends StatelessWidget {
  const PillToggle({super.key, required this.labels, required this.selected, required this.onChanged});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFFEDEFF2), borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(labels[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: i == selected ? Colors.white : AppColors.ink,
                      )),
                ),
              ),
            ),
        ]),
      );
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, this.onChanged, this.onTap, this.autofocus = false, this.controller});

  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        readOnly: onTap != null,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: AppColors.orange)),
        ),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color = AppColors.green, this.icon = Icons.circle});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, this.closed = false, this.long = false});

  final bool closed;
  final bool long;

  @override
  Widget build(BuildContext context) => closed
      ? StatusBadge(label: context.tr('pollClosed'), color: AppColors.muted, icon: Icons.lock)
      : StatusBadge(label: context.tr(long ? 'livePoll' : 'live'));
}

class Blob extends StatelessWidget {
  const Blob({super.key, required this.color, required this.seed, this.size = 34});

  final Color color;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: BlobPainter(color, seed)));
}

class CandidateAvatar extends StatelessWidget {
  const CandidateAvatar(this.candidate, {super.key, this.size = 40});

  final Candidate candidate;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: candidate.party.color.withValues(alpha: 0.14),
          border: Border.all(color: candidate.party.color, width: 2),
        ),
        child: Icon(Icons.person, size: size * 0.62, color: const Color(0xFF59606E)),
      );
}

class PartySymbolBadge extends StatelessWidget {
  const PartySymbolBadge(this.party, {super.key, this.size = 40});

  final Party party;
  final double size;

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.62;
    final Widget symbol = switch (party.symbol) {
      PartySymbol.bicycle => Icon(Icons.pedal_bike, size: inner, color: Colors.black87),
      PartySymbol.fan => SizedBox.square(dimension: inner, child: const CustomPaint(painter: FanPainter())),
      PartySymbol.glass => SizedBox.square(dimension: inner, child: const CustomPaint(painter: GlassPainter())),
      PartySymbol.lotus => Icon(Icons.local_florist, size: inner, color: const Color(0xFFE8562A)),
      PartySymbol.independent => Icon(Icons.how_to_vote_outlined, size: inner, color: AppColors.blue),
    };
    final filled = party.symbol == PartySymbol.bicycle;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? party.color : Colors.white,
        border: filled ? null : Border.all(color: AppColors.border),
      ),
      child: symbol,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600)),
            ),
        ]),
      );
}

/// Candidate result row with a party-coloured bar and percentage.
class ResultRow extends StatelessWidget {
  const ResultRow({super.key, required this.snapshot, required this.index, this.highlight = false});

  final PollSnapshot snapshot;
  final int index;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = snapshot.candidates[index];
    final share = snapshot.share(index);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        CandidateAvatar(c, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${c.name(context.isTelugu)} - ${c.party.short}',
                    style: TextStyle(fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
              ),
              Text('${(share * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(children: [
                Container(height: 12, color: const Color(0xFFEDEFF2)),
                FractionallySizedBox(
                  widthFactor: share.clamp(0.0, 1.0),
                  child: Container(height: 12, color: c.party.color),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Thin stacked bar showing every candidate's share.
class ShareBar extends StatelessWidget {
  const ShareBar(this.snapshot, {super.key, this.height = 8});

  final PollSnapshot snapshot;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Row(children: [
            for (final i in snapshot.ranking)
              Expanded(
                flex: (snapshot.share(i) * 1000).round().clamp(1, 1000),
                child: Container(color: snapshot.candidates[i].party.color),
              ),
          ]),
        ),
      );
}

class InfoField extends StatelessWidget {
  const InfoField({super.key, required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 4),
        DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), child: value),
      ]);
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
      );
}

/// Copies a shareable description of a poll to the clipboard.
Future<void> sharePoll(BuildContext context, Constituency c) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = context.tr('copied');
  await Clipboard.setData(ClipboardData(
    text: 'VoteWala: ${c.en} (${c.te}) ${c.isMla ? 'MLA' : 'MP'} poll is live. '
        'Your Voice. Your Choice. Cast your opinion today!',
  ));
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// Leading-party blob for a constituency tile.
class ConstituencyTile extends StatelessWidget {
  const ConstituencyTile({super.key, required this.snapshot, required this.onTap, this.voted = false});

  final PollSnapshot snapshot;
  final VoidCallback onTap;
  final bool voted;

  @override
  Widget build(BuildContext context) {
    final c = snapshot.constituency;
    final te = context.isTelugu;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Blob(color: snapshot.candidates[snapshot.leader].party.color, seed: c.no + (c.isMla ? 0 : 500)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c.no}. ${c.name(te)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(c.name(!te), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ]),
          ),
          if (voted) const Icon(Icons.check_circle, color: AppColors.green, size: 20),
          if (snapshot.closed) const Icon(Icons.lock_outline, color: AppColors.muted, size: 18),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}
