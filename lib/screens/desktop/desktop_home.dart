import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/config_service.dart';
import '../../data/ap_data.dart';
import '../../data/featured_polls.dart';
import '../../data/poll_month.dart';
import '../../data/poll_repository.dart';
import '../../l10n/legal.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../../widgets/painters.dart';
import '../ap_map_screen.dart';
import '../browse_screens.dart';
import '../main_shell.dart';
import '../closed_polls_screen.dart';
import '../legal_screens.dart';
import '../my_constituency_screen.dart';
import 'desktop_sections.dart';

const _maxWidth = 1240.0;

/// Premium home page for desktop browsers.
class DesktopHome extends StatelessWidget {
  const DesktopHome({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final home = appConfig.home;
    final month = PollMonth.current();
    final mla = state.snapshots(ElectionType.mla);
    final mp = state.snapshots(ElectionType.mp);
    final mlaTally = SeatTally(mla);
    final votes = mlaTally.votes + SeatTally(mp).votes;

    return ListView(children: [
      if (state.blocked) const _Section(top: 20, child: BlockedBanner()),
      _Section(
        top: 28,
        child: _Hero(tally: mlaTally, month: month),
      ),
      _Section(
        top: 28,
        child: Row(children: [
          _Metric(icon: Icons.account_balance, value: '175', label: context.tr('mlaConstituencies'), color: AppColors.orange),
          const SizedBox(width: 18),
          _Metric(icon: Icons.museum, value: '25', label: context.tr('mpConstituencies'), color: AppColors.green),
          const SizedBox(width: 18),
          _Metric(
            icon: Icons.how_to_vote,
            value: formatIndian(votes),
            label: context.tr('monthVotes', {'n': ''}).replaceAll('  ', ' ').trim(),
            color: AppColors.blue,
          ),
          const SizedBox(width: 18),
          _Metric(
            icon: Icons.local_fire_department,
            value: '${featuredPolls.where((p) => p.isOpen).length}',
            label: context.tr('featuredPolls'),
            color: const Color(0xFF8E44AD),
          ),
        ]),
      ),
      const _Section(top: 28, child: YourConstituencyCard()),
      if (home.showFeatured && (featuredPolls.isNotEmpty || closedFeaturedPolls.isNotEmpty))
        _Section(
          title: context.tr('featuredPolls'),
          subtitle: month.label(context.isTelugu),
          action: closedFeaturedPolls.isEmpty
              ? null
              : TextButton.icon(
                  onPressed: () => openClosedPolls(context),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text('${context.tr('closedPolls')} (${closedFeaturedPolls.length})'),
                ),
          child: DesktopFeatured(showMonthlyVotes: home.showMonthlyVotes),
        ),
      if (home.showTopSeats)
        _Section(
          title: context.tr('topSeats'),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: DesktopSeatColumn(
                  title: context.tr('topMlaSeats'), icon: Icons.account_balance, ids: home.topMla, tab: ShellTab.mla),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: DesktopSeatColumn(
                  title: context.tr('topMpSeats'), icon: Icons.museum_outlined, ids: home.topMp, tab: ShellTab.mp),
            ),
          ]),
        ),
      _Section(
        title: context.tr('districtWise'),
        subtitle: month.label(context.isTelugu),
        action: TextButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ApMapScreen())),
          icon: const Icon(Icons.map_outlined),
          label: Text(context.tr('apMap')),
        ),
        child: LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 3 * 16) / 4;
          return Wrap(spacing: 16, runSpacing: 16, children: [
            for (final d in ApData.districts)
              SizedBox(width: w, child: _DistrictTile(summary: state.districtSummary(d, ElectionType.mla))),
          ]);
        }),
      ),
      const SizedBox(height: 56),
      const _Footer(),
    ]);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.title, this.subtitle, this.action, this.top = 56});

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(32, top, 32, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (title != null) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title!,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                        ),
                    ]),
                  ),
                  ?action,
                ]),
                const SizedBox(height: 22),
              ],
              child,
            ]),
          ),
        ),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.tally, required this.month});

  final SeatTally tally;
  final PollMonth month;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    final home = appConfig.home;
    final shell = ShellScope.maybeOf(context);
    final title = (te ? home.heroTitleTe : home.heroTitleEn) ?? context.tr('heroTitle');
    final sub = (te ? home.heroSubtitleTe : home.heroSubtitleEn) ?? context.tr('heroSub');

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 520,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1B33), Color(0xFF123A63), Color(0xFF1E5B8C)],
          ),
        ),
        child: Stack(children: [
          const Positioned.fill(child: Opacity(opacity: 0.55, child: CustomPaint(painter: HeroScenePainter()))),
          Positioned(
            right: -120,
            top: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.orange.withValues(alpha: 0.35), Colors.transparent]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                flex: 6,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, size: 9, color: AppColors.green),
                      const SizedBox(width: 8),
                      Text('${month.label(te)} · ${context.tr('livePolls')}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 58, fontWeight: FontWeight.w900, height: 1.02, letterSpacing: -1.5)),
                  const SizedBox(height: 12),
                  Text(appConfig.branding.taglineTe,
                      style: const TextStyle(color: AppColors.amber, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(sub, style: const TextStyle(color: Color(0xFFD5E2F0), fontSize: 17, height: 1.5)),
                  ),
                  const SizedBox(height: 30),
                  Row(children: [
                    FilledButton.icon(
                      onPressed: () => shell?.go(ShellTab.mla),
                      style: FilledButton.styleFrom(minimumSize: const Size(200, 56)),
                      icon: const Icon(Icons.how_to_vote),
                      label: Text('${context.tr('mlaPolls')} · ${context.tr('voteNow')}'),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
                      onPressed: () => shell?.go(ShellTab.mp),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(200, 56),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54, width: 1.4),
                      ),
                      icon: const Icon(Icons.museum_outlined),
                      label: Text('${context.tr('mpPolls')} · ${context.tr('voteNow')}'),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 520,
                    child: SearchField(
                      hint: context.tr('searchHint'),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 40),
              SizedBox(width: 400, child: _ProjectionCard(tally: tally, month: month)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Glass panel with the live MLA seat projection.
class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.tally, required this.month});

  final SeatTally tally;
  final PollMonth month;

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    final max = tally.seats.values.fold(1, (a, b) => b > a ? b : a);
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 50, offset: Offset(0, 24))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: Text(context.tr('seatsLeading'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          StatusBadge(label: context.tr('live')),
        ]),
        const SizedBox(height: 4),
        Text('MLA · ${month.label(context.isTelugu)}', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 20),
        for (final g in seatGroups)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              PartyDot(groupColor(g), size: 14),
              const SizedBox(width: 10),
              SizedBox(width: 70, child: Text(groupLabel(context, g), style: const TextStyle(fontWeight: FontWeight.w700))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: tally.seats[g]! / max,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFEFF1F5),
                    color: groupColor(g),
                  ),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text('${tally.seats[g]}',
                    textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ]),
          ),
        const Divider(height: 28),
        Row(children: [
          Text(context.tr('majority', {'n': '88'}), style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          TextButton(
            onPressed: () => shell?.go(ShellTab.results),
            child: Text('${context.tr('results')} →'),
          ),
        ]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 30, offset: Offset(0, 12))],
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.06)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted)),
              ]),
            ),
          ]),
        ),
      );
}

class _DistrictTile extends StatelessWidget {
  const _DistrictTile({required this.summary});

  final DistrictSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = summary.tally;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        SeatDonut(t, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(summary.district.name(context.isTelugu), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              t.total == 0
                  ? context.tr('beFirst')
                  : [for (final g in seatGroups) if (t.seats[g]! > 0) '${groupLabel(context, g)} ${t.seats[g]}'].join(' · '),
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final b = appConfig.branding;
    final te = context.isTelugu;
    final shell = ShellScope.maybeOf(context);
    const linkStyle = TextStyle(color: Color(0xFFCBD5E1), fontSize: 14);
    const headStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.4);

    Widget link(String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(onTap: onTap, child: Text(label, style: linkStyle)),
        );

    Widget column(String title, List<Widget> links) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(), style: headStyle),
            const SizedBox(height: 16),
            ...links,
          ]),
        );

    return Container(
      color: const Color(0xFF0B1424),
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 2,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const VoteWalaLogo(markSize: 44, horizontal: true),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 380,
                    child: Text(context.tr('footerAbout'),
                        style: const TextStyle(color: Color(0xFF94A3B8), height: 1.6, fontSize: 13.5)),
                  ),
                ]),
              ),
              column(context.tr('footerPlatform'), [
                link(context.tr('mlaPollsShort'), () => shell?.go(ShellTab.mla)),
                link(context.tr('mpPollsShort'), () => shell?.go(ShellTab.mp)),
                link(context.tr('results'), () => shell?.go(ShellTab.results)),
                link(context.tr('closedPolls'), () => openClosedPolls(context)),
                link(context.tr('yourConstituency'), () => openMyConstituency(context)),
              ]),
              column(context.tr('footerLegal'), [
                for (final id in ['privacy', 'terms', 'disclaimer', 'cookies'])
                  link(legalById(id)!.title(te), () => openLegal(context, id)),
              ]),
              column(context.tr('footerHelp'), [
                for (final id in ['guidelines', 'grievance'])
                  link(legalById(id)!.title(te), () => openLegal(context, id)),
                if (b.contactEmail != null) link(b.contactEmail!, () => launchUrl(Uri.parse('mailto:${b.contactEmail}'))),
              ]),
            ]),
            const SizedBox(height: 36),
            const Divider(color: Color(0xFF1E293B)),
            const SizedBox(height: 16),
            Row(children: [
              Text('© ${istNow().year} ${b.appName}. ${context.tr('footerRights')}',
                  style: const TextStyle(color: Color(0xFF64748B))),
              const Spacer(),
              Text(b.tagline(te), style: const TextStyle(color: Color(0xFF64748B))),
            ]),
          ]),
        ),
      ),
    );
  }
}
