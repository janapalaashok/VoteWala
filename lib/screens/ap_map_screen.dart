import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/poll_month.dart';
import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'constituency_list_screen.dart';
import 'results_screen.dart';

/// Simplified district outlines as (longitude, latitude) points.
const _outlines = <String, List<(double, double)>>{
  'srikakulam': [(83.6, 18.6), (83.9, 19.15), (84.75, 19.1), (84.1, 18.3), (83.6, 18.2)],
  'vizianagaram': [(83.0, 18.9), (83.9, 19.15), (83.6, 18.6), (83.6, 18.2), (83.45, 18.0), (83.0, 18.1)],
  'visakhapatnam': [(82.0, 18.4), (82.3, 18.9), (83.0, 18.9), (83.0, 18.1), (83.45, 18.0), (83.3, 17.7), (82.6, 17.25), (82.2, 17.6)],
  'east-godavari': [(81.4, 17.8), (82.0, 18.4), (82.2, 17.6), (82.6, 17.25), (82.25, 16.95), (82.3, 16.6), (81.75, 16.35), (81.7, 16.8), (81.5, 17.2)],
  'west-godavari': [(80.9, 17.5), (81.4, 17.8), (81.5, 17.2), (81.7, 16.8), (81.75, 16.35), (81.4, 16.3), (81.0, 16.6), (80.9, 17.0)],
  'krishna': [(80.0, 16.85), (80.9, 17.5), (80.9, 17.0), (81.0, 16.6), (81.4, 16.3), (81.15, 16.1), (80.9, 15.8), (80.4, 16.5)],
  'guntur': [(79.2, 16.5), (80.0, 16.85), (80.4, 16.5), (80.9, 15.8), (80.35, 15.75), (79.8, 15.9), (79.3, 16.0)],
  'prakasam': [(78.9, 16.1), (79.2, 16.5), (79.3, 16.0), (79.8, 15.9), (80.35, 15.75), (80.1, 15.4), (80.05, 15.0), (79.5, 15.0), (79.0, 15.3)],
  'nellore': [(79.05, 14.85), (79.5, 15.0), (80.05, 15.0), (80.15, 14.4), (80.2, 13.7), (79.7, 13.8), (79.2, 14.2)],
  'kadapa': [(78.2, 14.9), (79.0, 15.3), (79.5, 15.0), (79.05, 14.85), (79.2, 14.2), (78.9, 13.9), (78.4, 14.0), (78.1, 14.4)],
  'kurnool': [(77.2, 15.9), (78.2, 16.2), (78.9, 16.1), (79.0, 15.3), (78.2, 14.9), (77.4, 15.0), (77.0, 15.4)],
  'anantapur': [(77.0, 15.4), (77.4, 15.0), (78.2, 14.9), (78.1, 14.4), (78.4, 14.0), (77.9, 13.7), (77.4, 13.9), (77.0, 14.2), (76.9, 14.8)],
  'chittoor': [(77.9, 13.7), (78.4, 14.0), (78.9, 13.9), (79.2, 14.2), (79.7, 13.8), (80.2, 13.7), (80.2, 13.4), (79.6, 13.1), (79.0, 12.8), (78.5, 12.7), (78.1, 13.2)],
};

const _minLon = 76.7, _maxLon = 84.95, _minLat = 12.55, _maxLat = 19.3;
const _mapAspect = (_maxLon - _minLon) / (_maxLat - _minLat);

Map<String, Path> _buildPaths(Size size) => {
      for (final e in _outlines.entries)
        e.key: Path()
          ..addPolygon([
            for (final (lon, lat) in e.value)
              Offset((lon - _minLon) / (_maxLon - _minLon) * size.width,
                  (_maxLat - lat) / (_maxLat - _minLat) * size.height),
          ], true),
    };

class ApMapScreen extends StatefulWidget {
  const ApMapScreen({super.key});

  @override
  State<ApMapScreen> createState() => _ApMapScreenState();
}

class _ApMapScreenState extends State<ApMapScreen> {
  ElectionType _type = ElectionType.mla;
  PollMonth _month = PollMonth.current();
  String _query = '';
  String? _selected;

  void _openDistrict(District d) => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ConstituencyListScreen(type: _type, districtId: d.id),
      ));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final summaries = {for (final d in ApData.districts) d.id: state.districtSummary(d, _type, month: _month)};
    final stateTally = SeatTally(state.snapshots(_type, month: _month));
    final q = _query.trim().toLowerCase();
    final matching = ApData.districts
        .where((d) =>
            q.isEmpty ||
            d.en.toLowerCase().contains(q) ||
            d.te.contains(q) ||
            ApData.of(_type).any((c) => c.districtIds.contains(d.id) && (c.en.toLowerCase().contains(q) || c.te.contains(q))))
        .toList();
    final selected = _selected == null ? null : summaries[_selected]!;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('apMap'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        PageBody(
          maxWidth: 820,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PillToggle(
              labels: ['${context.tr('mla')} (175)', '${context.tr('mp')} (25)'],
              selected: _type.index,
              onChanged: (i) => setState(() => _type = ElectionType.values[i]),
            ),
            const SizedBox(height: 12),
            MonthSelector(month: _month, onChanged: (m) => setState(() => _month = m)),
            const SizedBox(height: 12),
            SearchField(hint: context.tr('searchConstituency'), onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: _mapAspect,
              child: LayoutBuilder(builder: (context, box) {
                final paths = _buildPaths(box.biggest);
                return GestureDetector(
                  onTapUp: (d) {
                    final hit = paths.entries.where((e) => e.value.contains(d.localPosition)).firstOrNull;
                    setState(() => _selected = hit?.key == _selected ? null : hit?.key);
                  },
                  child: CustomPaint(
                    size: box.biggest,
                    painter: _MapPainter(
                      paths: paths,
                      colors: {
                        for (final e in summaries.entries)
                          e.key: e.value.tally.leader == null ? AppColors.grey : groupColor(e.value.tally.leader!),
                      },
                      labels: {for (final d in ApData.districts) d.id: d.name(te)},
                      selected: _selected,
                      dimmed: q.isEmpty ? const {} : {
                        for (final d in ApData.districts)
                          if (!matching.contains(d)) d.id,
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            AppCard(child: SeatTallyView(stateTally, majority: ApData.of(_type).length ~/ 2 + 1)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const PartyDot(AppColors.grey, size: 12),
              const SizedBox(width: 4),
              Text(context.tr('tied'), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
            ]),
            if (selected != null) ...[
              const SizedBox(height: 14),
              _SelectedDistrictCard(summary: selected, onOpen: () => _openDistrict(selected.district)),
            ],
            SectionHeader(context.tr('districts')),
            SizedBox(
              height: 128,
              child: matching.isEmpty
                  ? EmptyState(icon: Icons.search_off, message: context.tr('noMatches'))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: matching.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final d = matching[i];
                        final s = summaries[d.id]!;
                        return SizedBox(
                          width: 118,
                          child: AppCard(
                            onTap: () => _openDistrict(d),
                            padding: const EdgeInsets.all(10),
                            child: Column(children: [
                              SeatDonut(s.tally, size: 44),
                              const SizedBox(height: 8),
                              Text(d.name(te),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(context.tr('nConstituencies', {'n': '${s.polls.length}'}),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SelectedDistrictCard extends StatelessWidget {
  const _SelectedDistrictCard({required this.summary, required this.onOpen});

  final DistrictSummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            SeatDonut(summary.tally, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(summary.district.name(context.isTelugu),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            Text('${formatCompact(summary.tally.votes)} ${context.tr('votes')}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          SeatTallyView(summary.tally),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.chevron_right),
              label: Text(context.tr('openConstituencies')),
            ),
          ),
        ]),
      );
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.paths,
    required this.colors,
    required this.labels,
    required this.selected,
    required this.dimmed,
  });

  final Map<String, Path> paths;
  final Map<String, Color> colors;
  final Map<String, String> labels;
  final String? selected;
  final Set<String> dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    for (final e in paths.entries) {
      final color = colors[e.key]!;
      canvas.drawPath(e.value, Paint()..color = dimmed.contains(e.key) ? color.withValues(alpha: 0.25) : color);
      canvas.drawPath(e.value, stroke);
    }
    if (selected != null) {
      canvas.drawPath(
        paths[selected]!,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
    }
    final fontSize = (size.width / 46).clamp(8.0, 13.0);
    for (final e in paths.entries) {
      final b = e.value.getBounds();
      final tp = TextPainter(
        text: TextSpan(
          text: labels[e.key],
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: b.width + 20);
      tp.paint(canvas, b.center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.selected != selected || old.colors != colors || old.dimmed != dimmed || old.labels != labels;
}
