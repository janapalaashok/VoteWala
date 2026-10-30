import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:url_launcher/url_launcher.dart';

import '../admin/file_pick.dart';
import '../data/ap_data.dart';
import '../data/civic.dart';
import '../data/featured_polls.dart';
import '../data/poll_month.dart';
import '../l10n/strings.dart';
import '../screens/ap_map_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Public website; links open the poll directly (see main.dart deep links).
/// Builds for another host pass --dart-define=SITE_URL=https://...
const siteUrl = String.fromEnvironment('SITE_URL', defaultValue: 'https://votewala-a2dcd.web.app');
final siteHost = Uri.parse(siteUrl).host;

String constituencyLink(Constituency c) => '$siteUrl/#/c/${c.id}';
String featuredLink(FeaturedPoll p) => '$siteUrl/#/f/${p.id}';

class ShareRow {
  const ShareRow(this.label, this.share, this.color, this.avatar);

  final String label;
  final double share;
  final Color color;
  final Widget avatar;
}

class ShareCardData {
  const ShareCardData({
    required this.headline,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.hook,
    required this.link,
    required this.text,
    this.myChoice,
  });

  final String headline;
  final String title;

  /// The poll question.
  final String subtitle;
  final List<ShareRow> rows;
  final String hook;
  final String link;

  /// Message posted with the image.
  final String text;

  /// The voter's own option, only when they choose to show it.
  final String? myChoice;
}

/// Builds the card; [showChoice] adds the voter's own option.
typedef ShareCardBuilder = ShareCardData Function(bool showChoice);

/// The hook line that makes viewers want to vote.
String _hook(BuildContext context, String leader, double margin) => margin < 0.05
    ? context.tr('hookTight')
    : context.tr('hookLead', {'name': leader, 'n': (margin * 100).toStringAsFixed(0)});

ShareCardData constituencyShareData(BuildContext context, Constituency c, {bool showChoice = false}) {
  final state = AppScope.read(context);
  final te = context.isTelugu;
  final snap = state.snapshot(c);
  final order = snap.ranking;
  final top = [for (final i in order.take(2)) snap.candidates[i]];
  final margin = snap.share(order[0]) - snap.share(order[1]);
  final hook = snap.hasVotes ? _hook(context, top.first.name(te), margin) : context.tr('hookFirst');
  final mine = state.choiceIndex(c);
  final voted = mine != null;
  final type = c.isMla ? 'MLA' : 'MP';
  final link = constituencyLink(c);
  return ShareCardData(
    headline: voted ? civic.shareMessage(te) : context.tr('shareHeadlineView'),
    title: c.name(te),
    subtitle: context.tr(c.isMla ? 'questionMla' : 'questionMp', {'name': c.name(te), 'month': PollMonth.current().label(te)}),
    myChoice: showChoice && voted ? snap.candidates[mine].name(te) : null,
    rows: [
      for (var k = 0; k < top.length; k++)
        ShareRow(
          top[k].isPerson ? '${top[k].name(te)} · ${top[k].party.short}' : top[k].name(te),
          snap.share(order[k]),
          top[k].party.color,
          CandidateAvatar(top[k], size: 30),
        ),
    ],
    hook: hook,
    link: link,
    text: context.tr(voted ? 'shareText' : 'shareTextView', {'name': c.name(te), 'type': type, 'hook': hook, 'link': link}),
  );
}

ShareCardData featuredShareData(BuildContext context, FeaturedPoll p, List<int> totals, Color Function(int) colorOf,
    {bool showChoice = false}) {
  final state = AppScope.read(context);
  final te = context.isTelugu;
  final total = totals.fold(0, (a, b) => a + b);
  final order = List.generate(totals.length, (i) => i)..sort((a, b) => totals[b].compareTo(totals[a]));
  double share(int i) => total == 0 ? 0 : totals[i] / total;
  final margin = order.length < 2 ? 1.0 : share(order[0]) - share(order[1]);
  final hook = total == 0 ? context.tr('hookFirst') : _hook(context, p.options[order.first].label(te), margin);
  final mine = state.featuredChoice(p);
  final voted = mine != null;
  final link = featuredLink(p);
  Widget avatar(int i) {
    final o = p.options[i];
    if (o.party != null) return PersonAvatar(photoUrl: o.photoUrl, party: o.party!, size: 30);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: colorOf(i).withValues(alpha: 0.2), shape: BoxShape.circle),
      child: Icon(o.icon ?? Icons.circle, size: 17, color: colorOf(i)),
    );
  }

  return ShareCardData(
    headline: voted ? civic.shareMessage(te) : context.tr('shareHeadlineView'),
    title: p.title(te),
    subtitle: p.question(te),
    myChoice: showChoice && voted ? p.options[mine].label(te) : null,
    rows: [for (final i in order.take(2)) ShareRow(p.options[i].label(te), share(i), colorOf(i), avatar(i))],
    hook: hook,
    link: link,
    text: context.tr(voted ? 'shareText' : 'shareTextView', {'name': p.title(te), 'type': '', 'hook': hook, 'link': link})
        .replaceAll('  ', ' '),
  );
}

/// 4:5 social card (360×450 logical, exported at 3× = 1080×1350).
class ShareCard extends StatelessWidget {
  const ShareCard(this.data, {super.key});

  final ShareCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 450,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B1B33), Color(0xFF123A63), Color(0xFF1E5B8C)],
                ),
              ),
            ),
          ),
          Positioned(right: -90, top: -90, child: _glow(AppColors.orange, 260)),
          Positioned(left: -90, bottom: -100, child: _glow(AppColors.green, 240)),
          const Positioned(right: -30, top: 120, width: 210, height: 210 / apMapAspect, child: Opacity(opacity: 0.16, child: CustomPaint(painter: _MapPainter()))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const VoteWalaLogo(markSize: 24, horizontal: true),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF47A1F), Color(0xFFF6B21A)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('● ${context.tr('livePoll')}',
                      style: const TextStyle(color: Color(0xFF0B1B33), fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: .5)),
                ),
              ]),
              const SizedBox(height: 16),
              Text(data.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(height: 6),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFF9A3D), Color(0xFFF6B21A)]).createShader(r),
                child: Text(data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.15)),
              ),
              Text(data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFC9D6E6), fontSize: 11.5, height: 1.3)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: Column(children: [
                  if (data.myChoice != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.how_to_vote, size: 15, color: Color(0xFF86EFAC)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(context.tr('myChoiceOnCard', {'x': data.myChoice!}),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ]),
                    ),
                  for (final r in data.rows) _row(r),
                  const SizedBox(height: 2),
                  Text(data.hook,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFF6B21A), fontSize: 12.5, fontWeight: FontWeight.w800)),
                ]),
              ),
              const Spacer(),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.orange.withValues(alpha: 0.5), blurRadius: 16)],
                      ),
                      child: Text(context.tr('shareCta'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                    const SizedBox(height: 7),
                    Text(siteHost, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    Text(context.tr('shareVerified'), style: const TextStyle(color: Color(0xFF9FB2C8), fontSize: 9.5)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: QrImageView(
                    data: data.link,
                    size: 76,
                    padding: EdgeInsets.zero,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0B1B33)),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0B1B33)),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  static Widget _glow(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c.withValues(alpha: 0.5), c.withValues(alpha: 0)])),
      );

  Widget _row(ShareRow r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          r.avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(r.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
                Text('${(r.share * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Container(height: 7, color: Colors.white.withValues(alpha: 0.15)),
                  FractionallySizedBox(widthFactor: r.share.clamp(0.0, 1.0), child: Container(height: 7, color: r.color)),
                ]),
              ),
            ]),
          ),
        ]),
      );
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paths = apMapPaths(size).values.toList();
    for (var i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], Paint()..color = i.isEven ? const Color(0xFFFFB26B) : const Color(0xFF5FD08A));
      canvas.drawPath(
          paths[i],
          Paint()
            ..color = const Color(0xFF0B1B33)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom sheet with the card preview and share / WhatsApp / download /
/// copy-link actions. Voters can choose to show their own choice.
Future<void> showShareSheet(BuildContext context, ShareCardBuilder build, {bool canShowChoice = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ShareSheet(build: build, canShowChoice: canShowChoice),
  );
}

Future<void> shareConstituency(BuildContext context, Constituency c) => showShareSheet(
      context,
      (show) => constituencyShareData(context, c, showChoice: show),
      canShowChoice: AppScope.read(context).choiceIndex(c) != null,
    );

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.build, required this.canShowChoice});

  final ShareCardBuilder build;
  final bool canShowChoice;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _key = GlobalKey();
  bool _busy = false;
  late bool _showChoice = widget.canShowChoice && civic.shareShowChoiceDefault;

  ShareCardData get _data => widget.build(_showChoice);

  Future<Uint8List?> _capture() async {
    final boundary = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      debugPrint('Share failed: $e');
      await _copy();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(BuildContext buttonContext) => _run(() async {
        final box = buttonContext.findRenderObject() as RenderBox?;
        final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
        final png = await _capture();
        await SharePlus.instance.share(ShareParams(
          text: _data.text,
          files: png == null ? null : [XFile.fromData(png, mimeType: 'image/png', name: 'votewala-poll.png')],
          fileNameOverrides: png == null ? null : ['votewala-poll.png'],
          sharePositionOrigin: origin,
          downloadFallbackEnabled: true,
        ));
      });

  /// WhatsApp takes text and a link; the card image goes through Share.
  Future<void> _whatsApp() => _run(() async {
        final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_data.text)}');
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw StateError('no WhatsApp');
      });

  Future<void> _download() => _run(() async {
        final png = await _capture();
        if (png == null) return;
        if (!downloadBytes('votewala-poll.png', png, 'image/png')) {
          // Apps: the system sheet offers "Save to device" / Files / Drive.
          await SharePlus.instance.share(ShareParams(
            files: [XFile.fromData(png, mimeType: 'image/png', name: 'votewala-poll.png')],
            fileNameOverrides: const ['votewala-poll.png'],
          ));
        }
      });

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = context.tr('linkCopied');
    await Clipboard.setData(ClipboardData(text: _data.link));
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    Widget action(IconData icon, String label, VoidCallback? onTap, {Color? color}) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _busy ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: (color ?? AppColors.ink).withValues(alpha: 0.1),
                  child: Icon(icon, color: color ?? AppColors.ink),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Text(context.tr('shareTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(context.tr(_showChoice ? 'shareSubChoice' : 'shareSub'),
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5, maxWidth: 360),
            child: FittedBox(child: RepaintBoundary(key: _key, child: ShareCard(data))),
          ),
          if (widget.canShowChoice)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _showChoice,
                onChanged: (v) => setState(() => _showChoice = v),
                title: Text(context.tr('showMyChoice'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            )
          else
            const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                child: Builder(
                  builder: (b) => FilledButton.icon(
                    onPressed: _busy ? null : () => _share(b),
                    icon: _busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.ios_share),
                    label: Text(context.tr('share')),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                action(Icons.chat, 'WhatsApp', _whatsApp, color: const Color(0xFF25D366)),
                action(Icons.download, context.tr('download'), _download),
                action(Icons.link, context.tr('copyLink'), _copy),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
