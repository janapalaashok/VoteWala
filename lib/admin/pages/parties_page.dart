import 'package:flutter/material.dart';

import '../../data/ap_data.dart';
import '../admin_widgets.dart';

class PartiesPage extends StatelessWidget {
  const PartiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    void set(int i, Party p) => admin.update((c) => c.copyWith(parties: [...c.parties]..[i] = p));
    final list = admin.draft.parties;

    return AdminPage(
      title: 'Parties',
      subtitle: 'Names and colours used in polls, results, seat tallies and the map. TDP, YSRCP, JSP and BJP are '
          'shown separately; all others are grouped as "Others".',
      children: [
        for (var i = 0; i < list.length; i++)
          AdminCard(
            title: '${list[i].short} · ${list[i].en}',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: list[i].color, borderRadius: BorderRadius.circular(20)),
              child: Text(list[i].short, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            child: Wrap(spacing: 24, runSpacing: 18, crossAxisAlignment: WrapCrossAlignment.start, children: [
              SizedBox(
                width: 180,
                child: DraftField(
                  key: ValueKey('short-${list[i].id}'),
                  label: 'Short name',
                  value: list[i].short,
                  onChanged: (v) => set(i, list[i].copyWith(short: v)),
                ),
              ),
              SizedBox(
                width: 300,
                child: DraftField(
                  key: ValueKey('en-${list[i].id}'),
                  label: 'Name (English)',
                  value: list[i].en,
                  onChanged: (v) => set(i, list[i].copyWith(en: v)),
                ),
              ),
              SizedBox(
                width: 300,
                child: DraftField(
                  key: ValueKey('te-${list[i].id}'),
                  label: 'Name (Telugu)',
                  value: list[i].te,
                  onChanged: (v) => set(i, list[i].copyWith(te: v)),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<PartySymbol>(
                  initialValue: list[i].symbol,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                  items: [
                    for (final s in PartySymbol.values) DropdownMenuItem(value: s, child: Text(s.name)),
                  ],
                  onChanged: (s) => set(i, list[i].copyWith(symbol: s)),
                ),
              ),
              ColorField(label: 'Colour', color: list[i].color, onChanged: (c) => set(i, list[i].copyWith(color: c))),
            ]),
          ),
      ],
    );
  }
}
