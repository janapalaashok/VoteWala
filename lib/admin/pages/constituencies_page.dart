import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../data/ap_data.dart';
import '../admin_widgets.dart';

class ConstituenciesPage extends StatefulWidget {
  const ConstituenciesPage({super.key});

  @override
  State<ConstituenciesPage> createState() => _ConstituenciesPageState();
}

class _ConstituenciesPageState extends State<ConstituenciesPage> {
  String _query = '';
  ElectionType _type = ElectionType.mla;

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final names = admin.draft.constituencyNames;
    final q = _query.toLowerCase();
    final list = ApData.of(_type).where((c) => q.isEmpty || c.en.toLowerCase().contains(q) || c.te.contains(q)).toList();

    void set(Constituency c, {String? en, String? te}) {
      final cur = names[c.id] ?? const NamePair();
      final next = NamePair(
        en: en == null ? cur.en : (en.isEmpty || en == c.en ? null : en),
        te: te == null ? cur.te : (te.isEmpty || te == c.te ? null : te),
      );
      admin.update((cfg) => cfg.copyWith(constituencyNames: {...cfg.constituencyNames, c.id: next}));
    }

    return AdminPage(
      title: 'Constituencies',
      subtitle: 'Display names in English and Telugu. Leave a field empty to use the official name.',
      children: [
        AdminCard(
          child: Row(children: [
            SegmentedButton<ElectionType>(
              segments: const [
                ButtonSegment(value: ElectionType.mla, label: Text('Assembly (175)')),
                ButtonSegment(value: ElectionType.mp, label: Text('Parliament (25)')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
          ]),
        ),
        AdminCard(
          padding: 0,
          child: Column(children: [
            for (final c in list)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.border))),
                child: Row(children: [
                  SizedBox(width: 48, child: Text('${c.no}', style: const TextStyle(color: AdminColors.muted))),
                  Expanded(
                    child: DraftField(
                      key: ValueKey('en-${c.id}'),
                      label: 'English',
                      hint: c.en,
                      value: names[c.id]?.en ?? c.en,
                      onChanged: (v) => set(c, en: v),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DraftField(
                      key: ValueKey('te-${c.id}'),
                      label: 'Telugu',
                      hint: c.te,
                      value: names[c.id]?.te ?? c.te,
                      onChanged: (v) => set(c, te: v),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 140,
                    child: Text(c.districts.map((d) => d.en).join(', '),
                        overflow: TextOverflow.ellipsis, style: const TextStyle(color: AdminColors.muted, fontSize: 12.5)),
                  ),
                ]),
              ),
          ]),
        ),
      ],
    );
  }
}
