import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/config_service.dart';
import '../data/ap_data.dart';
import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../utils.dart';
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

/// The VoteWala logo: uploaded images from the admin config, otherwise the
/// bundled assets (generated from brand/).
class VoteWalaLogo extends StatelessWidget {
  const VoteWalaLogo({super.key, this.markSize = 56, this.horizontal = false, this.tagline = true});

  /// Height of the ballot-box mark.
  final double markSize;
  final bool horizontal;

  /// Without the tagline, the stacked logo shows the mark only (e.g. a nav rail).
  final bool tagline;

  static Widget _image(String asset, String? url, {double? height, double? width}) {
    final fallback = Image.asset(asset, height: height, width: width, semanticLabel: 'VoteWala');
    if (url == null) return fallback;
    return Image.network(url, height: height, width: width, errorBuilder: (_, _, _) => fallback);
  }

  @override
  Widget build(BuildContext context) {
    final b = appConfig.branding;
    if (horizontal) return _image('assets/brand/logo.png', b.logoUrl, height: markSize);
    final mark = _image('assets/brand/mark.png', b.markUrl, height: markSize);
    if (!tagline) return mark;
    if (b.logoUrl != null && b.markUrl == null) return _image('assets/brand/logo.png', b.logoUrl, width: markSize * 2.4);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      mark,
      SizedBox(height: markSize * 0.12),
      _image('assets/brand/wordmark.png', null, width: markSize * 1.9),
    ]);
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
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: AppColors.orange)),
        ),
      );
}

class StatusBadge extends StatelessWidget {
  // ignore: prefer_initializing_formals
  const StatusBadge({super.key, required this.label, Color? color, this.icon = Icons.circle}) : _color = color;

  final String label;
  final Color? _color;
  final IconData icon;

  /// Defaults to the brand secondary colour (live/green).
  Color get color => _color ?? AppColors.green;

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
      ? StatusBadge(label: context.tr('closed'), color: AppColors.muted, icon: Icons.lock)
      : StatusBadge(label: context.tr(long ? 'livePoll' : 'live'));
}

/// Candidate photo; falls back to the party symbol on the party colour.
class CandidateAvatar extends StatelessWidget {
  const CandidateAvatar(this.candidate, {super.key, this.size = 40});

  final Candidate candidate;
  final double size;

  @override
  Widget build(BuildContext context) =>
      PersonAvatar(photoUrl: candidate.photoUrl, party: candidate.party, size: size);
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.photoUrl, required this.party, this.size = 40, this.square = false});

  final String? photoUrl;
  final Party party;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: party.color.withValues(alpha: 0.16),
      alignment: Alignment.center,
      child: PartySymbolBadge(party, size: size * 0.78, plain: true),
    );
    final radius = square ? BorderRadius.circular(12) : BorderRadius.circular(size);
    return Container(
      width: size,
      height: square ? size * 1.18 : size,
      decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: party.color, width: 2)),
      child: ClipRRect(
        borderRadius: radius,
        child: photoUrl == null
            ? fallback
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
              ),
      ),
    );
  }
}

class PartySymbolBadge extends StatelessWidget {
  const PartySymbolBadge(this.party, {super.key, this.size = 40, this.plain = false});

  final Party party;
  final double size;

  /// Symbol only, without the round badge background.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.62;
    final Widget symbol = switch (party.symbol) {
      PartySymbol.bicycle => Icon(Icons.pedal_bike, size: inner, color: Colors.black87),
      PartySymbol.fan => SizedBox.square(dimension: inner, child: const CustomPaint(painter: FanPainter())),
      PartySymbol.glass => SizedBox.square(dimension: inner, child: const CustomPaint(painter: GlassPainter())),
      PartySymbol.lotus => Icon(Icons.local_florist, size: inner, color: const Color(0xFFE8562A)),
      PartySymbol.hand => Icon(Icons.back_hand, size: inner, color: const Color(0xFF138A5E)),
      PartySymbol.other => Icon(Icons.how_to_vote_outlined, size: inner, color: AppColors.muted),
    };
    if (plain) return SizedBox.square(dimension: size, child: Center(child: symbol));
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

/// Solid circle in a party colour.
class PartyDot extends StatelessWidget {
  const PartyDot(this.color, {super.key, this.size = 30});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 3)],
        ),
      );
}

Color groupColor(String group) => partyById(group).color;

String groupLabel(BuildContext context, String group) =>
    group == 'oth' ? context.tr('others') : partyById(group).short;

/// Circle split by seats per party (party representation of a district).
class SeatDonut extends StatelessWidget {
  const SeatDonut(this.tally, {super.key, this.size = 40});

  final SeatTally tally;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _DonutPainter([for (final g in seatGroups) (groupColor(g), tally.seats[g]!)]),
          child: Center(
            child: Text('${tally.total}',
                style: TextStyle(fontSize: size * 0.3, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.parts);

  final List<(Color, int)> parts;

  @override
  void paint(Canvas canvas, Size size) {
    final total = parts.fold(0, (a, p) => a + p.$2);
    final stroke = size.width * 0.2;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (total == 0) {
      canvas.drawArc(rect, 0, 6.2832, false, paint..color = AppColors.grey);
      return;
    }
    var start = -1.5708;
    for (final (color, n) in parts) {
      if (n == 0) continue;
      final sweep = 6.2832 * n / total;
      canvas.drawArc(rect, start, sweep, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

/// Party seat counts with a stacked bar, e.g. "TDP 98 · YSRCP 60 · ...".
class SeatTallyView extends StatelessWidget {
  const SeatTallyView(this.tally, {super.key, this.majority});

  final SeatTally tally;
  final int? majority;

  @override
  Widget build(BuildContext context) {
    final total = tally.total;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final g in seatGroups)
          Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            decoration: BoxDecoration(
              color: groupColor(g).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: groupColor(g).withValues(alpha: 0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              PartyDot(groupColor(g), size: 16),
              const SizedBox(width: 6),
              Text(groupLabel(context, g), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Text('${tally.seats[g]}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
      ]),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, box) => Stack(clipBehavior: Clip.none, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 14,
                child: Row(children: [
                  for (final g in seatGroups)
                    if (tally.seats[g]! > 0) Expanded(flex: tally.seats[g]!, child: Container(color: groupColor(g))),
                ]),
              ),
            ),
            if (majority != null && total > 0)
              Positioned(
                left: box.maxWidth * majority! / total - 1,
                top: -4,
                child: Container(width: 2, height: 22, color: AppColors.ink),
              ),
          ])),
      if (majority != null) ...[
        const SizedBox(height: 8),
        Text(context.tr('majority', {'n': '$majority'}),
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    ]);
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
                child: Text(c.isPerson ? '${c.name(context.isTelugu)} - ${c.party.short}' : c.name(context.isTelugu),
                    style: TextStyle(fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${(share * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('${formatIndian(snapshot.votes[index])} ${context.tr('votes')}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ]),
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
          PartyDot(snapshot.leadingParty.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c.no}. ${c.name(te)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(c.name(!te), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ]),
          ),
          if (voted) Icon(Icons.check_circle, color: AppColors.green, size: 20),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}
