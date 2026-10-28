import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../data/ap_data.dart';
import '../admin_widgets.dart';

class HomeContentPage extends StatelessWidget {
  const HomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final h = admin.draft.home;
    void set(HomeConfig Function(HomeConfig h) f) => admin.update((c) => c.copyWith(home: f(c.home)));

    return AdminPage(
      title: 'Home & website',
      subtitle: 'What the home page shows in the app and on the website.',
      children: [
        AdminCard(
          title: 'Hero text',
          subtitle: 'Leave empty to use the built-in text.',
          child: Column(children: [
            Row(children: [
              Expanded(
                child: DraftField(
                  label: 'Headline (English)',
                  hint: 'Your Voice. Your Choice.',
                  value: h.heroTitleEn,
                  onChanged: (v) => set((h) => HomeConfig.fromJson({...h.toJson(), 'heroTitleEn': v})),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DraftField(
                  label: 'Headline (Telugu)',
                  value: h.heroTitleTe,
                  onChanged: (v) => set((h) => HomeConfig.fromJson({...h.toJson(), 'heroTitleTe': v})),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: DraftField(
                  label: 'Sub-heading (English)',
                  maxLines: 3,
                  value: h.heroSubtitleEn,
                  onChanged: (v) => set((h) => HomeConfig.fromJson({...h.toJson(), 'heroSubtitleEn': v})),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DraftField(
                  label: 'Sub-heading (Telugu)',
                  maxLines: 3,
                  value: h.heroSubtitleTe,
                  onChanged: (v) => set((h) => HomeConfig.fromJson({...h.toJson(), 'heroSubtitleTe': v})),
                ),
              ),
            ]),
          ]),
        ),
        AdminCard(
          title: 'Sections',
          child: Column(children: [
            SwitchListTile(
              title: const Text('"Your votes this month" card'),
              value: h.showMonthlyVotes,
              onChanged: (v) => set((h) => h.copyWith(showMonthlyVotes: v)),
            ),
            SwitchListTile(
              title: const Text('Top 5 MLA and MP seats'),
              value: h.showTopSeats,
              onChanged: (v) => set((h) => h.copyWith(showTopSeats: v)),
            ),
            SwitchListTile(
              title: const Text('Featured polls'),
              value: h.showFeatured,
              onChanged: (v) => set((h) => h.copyWith(showFeatured: v)),
            ),
          ]),
        ),
        AdminCard(
          title: 'Top 5 MLA seats',
          child: _SeatPicker(
            type: ElectionType.mla,
            ids: h.topMla,
            onChanged: (ids) => set((h) => h.copyWith(topMla: ids)),
          ),
        ),
        AdminCard(
          title: 'Top 5 MP seats',
          child: _SeatPicker(
            type: ElectionType.mp,
            ids: h.topMp,
            onChanged: (ids) => set((h) => h.copyWith(topMp: ids)),
          ),
        ),
      ],
    );
  }
}

class _SeatPicker extends StatelessWidget {
  const _SeatPicker({required this.type, required this.ids, required this.onChanged});

  final ElectionType type;
  final List<String> ids;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final all = ApData.of(type);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < ids.length; i++)
          InputChip(
            avatar: CircleAvatar(child: Text('${i + 1}', style: const TextStyle(fontSize: 11))),
            label: Text(all.where((c) => c.id == ids[i]).firstOrNull?.en ?? ids[i]),
            onDeleted: () => onChanged([...ids]..removeAt(i)),
          ),
      ]),
      const SizedBox(height: 14),
      if (ids.length < 5)
        SizedBox(
          width: 360,
          child: Autocomplete<Constituency>(
            optionsBuilder: (v) => all.where(
                (c) => !ids.contains(c.id) && c.en.toLowerCase().contains(v.text.toLowerCase())),
            displayStringForOption: (c) => '${c.no}. ${c.en}',
            onSelected: (c) => onChanged([...ids, c.id]),
            fieldViewBuilder: (context, controller, focus, submit) => TextField(
              controller: controller,
              focusNode: focus,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.add), hintText: 'Add a constituency'),
            ),
          ),
        )
      else
        const Text('Remove one to add another (max 5).', style: TextStyle(color: AdminColors.muted)),
    ]);
  }
}
