import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';
import 'info_screens.dart';
import 'main_shell.dart';

class ConstituencyListScreen extends StatefulWidget {
  const ConstituencyListScreen({super.key, required this.type, this.embedded = false, this.districtId});

  final ElectionType type;
  final bool embedded;
  final String? districtId;

  @override
  State<ConstituencyListScreen> createState() => _ConstituencyListScreenState();
}

class _ConstituencyListScreenState extends State<ConstituencyListScreen> {
  bool _byDistrict = false;
  String _query = '';
  late String? _districtId = widget.districtId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final te = context.isTelugu;
    final all = ApData.of(widget.type);
    final filtered = [
      for (final c in all)
        if (c.matches(_query) && (_byDistrict || _districtId == null || c.districtIds.contains(_districtId))) c,
    ];

    Widget tile(Constituency c) => ConstituencyTile(
          snapshot: state.snapshot(c),
          voted: state.choiceIndex(c) != null,
          onTap: () => openConstituency(context, c),
        );

    return Scaffold(
      appBar: AppBar(
        leading: shellBackButton(context, embedded: widget.embedded),
        title: Text(context.tr(widget.type == ElectionType.mla ? 'mlaConstituencies' : 'mpConstituencies')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen())),
          ),
        ],
      ),
      body: PageBody(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: PillToggle(
              labels: ['${context.tr('all')} (${all.length})', context.tr('byDistrict')],
              selected: _byDistrict ? 1 : 0,
              onChanged: (i) => setState(() => _byDistrict = i == 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchField(hint: context.tr('searchConstituency'), onChanged: (v) => setState(() => _query = v)),
          ),
          if (!_byDistrict)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  _DistrictChip(
                    label: context.tr('all'),
                    selected: _districtId == null,
                    onTap: () => setState(() => _districtId = null),
                  ),
                  for (final d in ApData.districts)
                    if (all.any((c) => c.districtIds.contains(d.id)))
                      _DistrictChip(
                        label: d.name(te),
                        selected: _districtId == d.id,
                        onTap: () => setState(() => _districtId = d.id),
                      ),
                ],
              ),
            )
          else
            const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(icon: Icons.search_off, message: context.tr('noMatches'))
                : _byDistrict
                    ? ListView(
                        key: ValueKey('grouped-$_query'),
                        children: [
                          for (final d in ApData.districts)
                            if (filtered.any((c) => c.districtIds.contains(d.id)))
                              ExpansionTile(
                                initiallyExpanded: _query.isNotEmpty,
                                leading: Blob(
                                  color: AppColors.race(state.districtSummary(d, widget.type).status),
                                  seed: d.firstAc * 3,
                                  size: 30,
                                ),
                                title: Text(d.name(te), style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(context.tr('nConstituencies', {
                                  'n': '${filtered.where((c) => c.districtIds.contains(d.id)).length}',
                                })),
                                children: [
                                  for (final c in filtered)
                                    if (c.districtIds.contains(d.id)) tile(c),
                                ],
                              ),
                        ],
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(indent: 64),
                        itemBuilder: (_, i) => tile(filtered[i]),
                      ),
          ),
        ]),
      ),
    );
  }
}

class _DistrictChip extends StatelessWidget {
  const _DistrictChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? AppColors.orange : AppColors.border),
            ),
            child: Text(label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink,
                )),
          ),
        ),
      );
}
