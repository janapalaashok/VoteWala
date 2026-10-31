import 'package:flutter/material.dart';

import '../../utils.dart';
import '../admin_widgets.dart';
import '../traffic_stats.dart';
import 'issues_page.dart';

/// Website and app traffic recorded by the site itself: visitors per day,
/// countries, devices, browsers, where visitors came from and sign-ins.
class TrafficPage extends StatefulWidget {
  const TrafficPage({super.key});

  @override
  State<TrafficPage> createState() => _TrafficPageState();
}

class _TrafficPageState extends State<TrafficPage> {
  int _range = 7;
  Future<TrafficStats>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  Future<TrafficStats> _fetch() async {
    final db = AdminScope.read(context).data!.db;
    final days = TrafficStats.lastDays(istNow(), _range);
    final visits = await Future.wait([for (final d in days) db.list('traffic/$d/visits')]);
    final logins = await Future.wait([for (final d in days) db.list('traffic/$d/logins')]);
    return TrafficStats(days, {for (var i = 0; i < days.length; i++) days[i]: visits[i]},
        {for (var i = 0; i < days.length; i++) days[i]: logins[i]});
  }

  void _reload() => setState(() => _load = _fetch());

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    if (admin.data == null) return const NeedsFirebase(title: 'Traffic');
    return FutureBuilder(
      future: _load,
      builder: (context, snap) => AdminPage(
        title: 'Traffic',
        subtitle: 'Real visits to votewala.in and the app, recorded by the site. Anonymous: no names, emails or IP addresses.',
        actions: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Today')),
              ButtonSegment(value: 7, label: Text('7 days')),
              ButtonSegment(value: 30, label: Text('30 days')),
              ButtonSegment(value: 90, label: Text('90 days')),
            ],
            selected: {_range},
            onSelectionChanged: (s) {
              _range = s.first;
              _reload();
            },
          ),
          IconButton(tooltip: 'Refresh', onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
        children: [
          if (snap.hasError) AdminCard(child: Text('Could not load: ${snap.error}')),
          if (snap.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator()),
          if (snap.connectionState == ConnectionState.done && snap.data != null) ..._body(snap.data!),
        ],
      ),
    );
  }

  List<Widget> _body(TrafficStats s) {
    String pct(int v, int total) => total == 0 ? '0%' : '${(v * 100 / total).round()}%';
    final busiest = s.busiestDay;
    return [
      AdminGrid(children: [
        StatTile(icon: Icons.today, label: 'Visitors today', value: formatIndian(s.today), color: AdminColors.accent,
            footer: 'Unique devices, ${formatDay(s.days.last)}'),
        StatTile(icon: Icons.groups, label: 'Visitors ($_range ${_range == 1 ? 'day' : 'days'})', value: formatIndian(s.visits),
            color: AdminColors.success, footer: 'Avg ${s.dailyAverage.toStringAsFixed(1)} a day'),
        StatTile(icon: Icons.login, label: 'Sign-ins', value: formatIndian(s.signIns), color: AdminColors.ink,
            footer: '${formatIndian(s.signups)} new accounts'),
        StatTile(icon: Icons.trending_up, label: 'Busiest day', value: busiest == null ? '—' : formatDay(busiest),
            color: const Color(0xFF8E44AD), footer: busiest == null ? 'No visits yet' : '${s.visitorsByDay[busiest]} visitors'),
      ]),
      const SizedBox(height: 20),
      if (s.days.length > 1)
        AdminCard(
          title: 'Visitors per day',
          subtitle: 'Each device counts once a day (IST)',
          child: _DailyBars(s),
        ),
      AdminGrid(minWidth: 380, children: [
        _Breakdown(
          title: 'Countries',
          subtitle: 'From the visitor\'s device time zone',
          icon: Icons.public,
          rows: [for (final e in TrafficStats.ranked(s.countries)) (countryNames[e.key] ?? e.key, e.value)],
          total: s.visits,
        ),
        _Breakdown(
          title: 'Where visitors came from',
          subtitle: 'Referring site, app (Facebook/WhatsApp/Instagram) or link tag; direct = typed or bookmarked',
          icon: Icons.alt_route,
          rows: [for (final e in TrafficStats.ranked(s.sources)) (_label(e.key), e.value)],
          total: s.visits,
        ),
        _Breakdown(
          title: 'Devices',
          icon: Icons.devices,
          rows: [for (final e in TrafficStats.ranked(s.devices)) (_label(e.key), e.value)],
          total: s.visits,
        ),
        _Breakdown(
          title: 'Website or app',
          icon: Icons.phone_android,
          rows: [
            for (final e in TrafficStats.ranked(s.platforms))
              (e.key == 'web' ? 'Website (votewala.in)' : e.key == 'android' ? 'Android app' : _label(e.key), e.value),
          ],
          total: s.visits,
        ),
        _Breakdown(
          title: 'Operating system',
          icon: Icons.memory,
          rows: [for (final e in TrafficStats.ranked(s.os)) (e.key, e.value)],
          total: s.visits,
        ),
        _Breakdown(
          title: 'Browser',
          icon: Icons.web,
          rows: [for (final e in TrafficStats.ranked(s.browsers)) (e.key, e.value)],
          total: s.visits,
        ),
        _Breakdown(
          title: 'How people signed in',
          subtitle: '${s.signIns} sign-ins, ${s.signups} new accounts',
          icon: Icons.key,
          rows: [for (final e in TrafficStats.ranked(s.loginMethods)) (_method(e.key), e.value)],
          total: s.signIns + s.signups,
        ),
        _Breakdown(
          title: 'First page opened',
          icon: Icons.open_in_browser,
          rows: [for (final e in TrafficStats.ranked(s.landings)) (_page(e.key), e.value)],
          total: s.visits,
        ),
      ]),
      const SizedBox(height: 20),
      AdminCard(
        title: 'About these numbers',
        child: Text(
          '• Recorded by votewala.in and the app from ${formatDay(s.days.first)}; '
          'tracking began with this release, so earlier days show 0.\n'
          '• A visitor is one browser or phone per day. Visitors already signed in: '
          '${pct(s.signedInVisitors, s.visits)}.\n'
          '• Country comes from the device time zone (no IP lookup), so a VPN does not change it but a '
          'traveller\'s phone may.\n'
          '• Tip: add ?src=fb, ?src=wa or ?src=yt to links you post (e.g. https://votewala.in/?src=fb) '
          'to see exactly which post brought people.',
          style: const TextStyle(height: 1.6, color: AdminColors.muted),
        ),
      ),
    ];
  }

  static String _label(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _method(String m) => switch (m) {
        'google' => 'Google',
        'password' => 'Email + password',
        'phone' => 'Mobile OTP',
        _ => _label(m),
      };

  static String _page(String p) => switch (p) {
        'home' => 'Home',
        'admin' => 'Admin',
        _ when p.startsWith('f/') => 'Featured poll (${p.substring(2)})',
        _ when p.startsWith('legal/') => 'Legal: ${p.substring(6)}',
        _ when p.startsWith('c/') => 'Constituency link',
        _ => p,
      };
}

String formatDay(String day) {
  final p = day.split('-').map(int.parse).toList();
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${p[2]} ${m[p[1] - 1]}';
}

class _DailyBars extends StatelessWidget {
  const _DailyBars(this.s);

  final TrafficStats s;

  @override
  Widget build(BuildContext context) {
    final max = s.visitorsByDay.values.fold(0, (a, b) => a > b ? a : b);
    final label = s.days.length <= 31;
    return SizedBox(
      height: 190,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final d in s.days)
          Expanded(
            child: Tooltip(
              message: '${formatDay(d)}: ${s.visitorsByDay[d]} visitors, ${s.loginsByDay[d]} sign-ins',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (label && s.days.length <= 14)
                    Text('${s.visitorsByDay[d]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    height: max == 0 ? 2 : 2 + 140 * (s.visitorsByDay[d]! / max),
                    decoration: BoxDecoration(
                      color: AdminColors.accent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 14,
                    child: label && (s.days.length <= 14 || s.days.indexOf(d) % 5 == 0)
                        ? FittedBox(child: Text(formatDay(d), style: const TextStyle(fontSize: 10, color: AdminColors.muted)))
                        : null,
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.title, this.subtitle, required this.icon, required this.rows, required this.total});

  final String title;
  final String? subtitle;
  final IconData icon;
  final List<(String, int)> rows;
  final int total;

  @override
  Widget build(BuildContext context) => AdminCard(
        title: title,
        subtitle: subtitle,
        trailing: Icon(icon, color: AdminColors.muted),
        child: rows.isEmpty
            ? const Text('No data yet', style: TextStyle(color: AdminColors.muted))
            : Column(children: [
                for (final (name, n) in rows.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(width: 150, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : n / total,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFEFF1F5),
                            color: AdminColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 86,
                        child: Text('${formatIndian(n)} · ${total == 0 ? 0 : (n * 100 / total).round()}%',
                            textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ]),
                  ),
              ]),
      );
}
