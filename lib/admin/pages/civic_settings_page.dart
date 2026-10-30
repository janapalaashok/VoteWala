import 'package:flutter/material.dart';

import '../../data/civic.dart';
import '../admin_widgets.dart';

/// Categories, MLA priorities, badges, share card and thresholds.
class CivicSettingsPage extends StatefulWidget {
  const CivicSettingsPage({super.key});

  @override
  State<CivicSettingsPage> createState() => _CivicSettingsPageState();
}

class _CivicSettingsPageState extends State<CivicSettingsPage> {
  final _default = TextEditingController();
  final _bySlot = <String, TextEditingController>{};
  bool _loaded = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final data = AdminScope.read(context).data;
    data?.setting('thresholds').then((t) {
      if (!mounted) return;
      setState(() {
        _default.text = '${t['default'] ?? 100}';
        final by = (t['bySlot'] as Map?) ?? const {};
        for (final e in by.entries) {
          _slot('${e.key}').text = '${e.value}';
        }
      });
    }).catchError((Object e) {
      if (mounted) showAdminSnack(context, 'Could not load thresholds: $e', error: true);
    });
  }

  TextEditingController _slot(String slot) => _bySlot.putIfAbsent(slot, TextEditingController.new);

  @override
  void dispose() {
    _default.dispose();
    for (final c in _bySlot.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Thresholds and badge milestones live in Firestore settings/*, which the
  /// security rules read, so they are saved directly.
  Future<void> _saveLimits() async {
    final admin = AdminScope.read(context);
    final data = admin.data;
    if (data == null) return;
    final fallback = int.tryParse(_default.text.trim());
    if (fallback == null || fallback < 1) {
      showAdminSnack(context, 'Default threshold must be a positive number', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await data.saveSetting('thresholds', {
        'default': fallback,
        'bySlot': {
          for (final e in _bySlot.entries)
            if (int.tryParse(e.value.text.trim()) case final n? when n > 0) e.key: n,
        },
      });
      await data.saveSetting('badges', {
        'milestones': {for (final b in admin.draft.civic.badges) b.id: b.milestone},
      });
      if (mounted) showAdminSnack(context, 'Thresholds and badge milestones saved');
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final c = admin.draft.civic;
    void set(CivicConfig v) => admin.update((cfg) => cfg.copyWith(civic: v));

    return AdminPage(
      title: 'Local issues, badges & sharing',
      subtitle: 'Names and lists here are published with "Publish". Thresholds and milestones are saved directly.',
      children: [
        AdminCard(
          title: 'Thresholds',
          subtitle: 'An admin alert is raised once when BAD votes for a category in one constituency reach this '
              'number in a month. Changing a threshold allows a new alert.',
          trailing: FilledButton(
            onPressed: _saving || admin.data == null ? null : _saveLimits,
            child: const Text('Save thresholds & milestones'),
          ),
          child: Wrap(spacing: 18, runSpacing: 14, children: [
            SizedBox(
              width: 180,
              child: TextField(controller: _default, decoration: const InputDecoration(labelText: 'Default')),
            ),
            for (final cat in c.categories)
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _slot(cat.slot),
                  decoration: InputDecoration(labelText: cat.en, hintText: 'Default'),
                ),
              ),
          ]),
        ),
        AdminCard(
          title: 'Local issue categories',
          subtitle: 'Up to 12. Renaming keeps the votes; a switched-off category is hidden from voters.',
          trailing: c.categories.length >= 12
              ? null
              : OutlinedButton.icon(
                  onPressed: () {
                    final used = {for (final x in c.categories) x.slot};
                    final slot = [for (var i = 0; i < 12; i++) 'c$i'].firstWhere((s) => !used.contains(s));
                    set(c.copyWith(categories: [...c.categories, CivicCategory(slot, 'New category', 'కొత్త విభాగం', 'other')]));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add category'),
                ),
          child: Column(children: [
            for (var i = 0; i < c.categories.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Icon(c.categories[i].iconData),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DraftField(
                      key: ValueKey('cat-en-${c.categories[i].slot}'),
                      label: 'English',
                      value: c.categories[i].en,
                      onChanged: (v) => set(c.copyWith(categories: [...c.categories]..[i] = c.categories[i].copyWith(en: v))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DraftField(
                      key: ValueKey('cat-te-${c.categories[i].slot}'),
                      label: 'Telugu',
                      value: c.categories[i].te,
                      onChanged: (v) => set(c.copyWith(categories: [...c.categories]..[i] = c.categories[i].copyWith(te: v))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: civicIcons.containsKey(c.categories[i].icon) ? c.categories[i].icon : 'other',
                    items: [for (final k in civicIcons.keys) DropdownMenuItem(value: k, child: Icon(civicIcons[k]))],
                    onChanged: (v) => set(c.copyWith(categories: [...c.categories]..[i] = c.categories[i].copyWith(icon: v))),
                  ),
                  Switch(
                    value: c.categories[i].enabled,
                    onChanged: (v) =>
                        set(c.copyWith(categories: [...c.categories]..[i] = c.categories[i].copyWith(enabled: v))),
                  ),
                ]),
              ),
          ]),
        ),
        AdminCard(
          title: '"If you were the MLA" options',
          subtitle: 'Options can be renamed or added. Their order is fixed because votes are stored by position.',
          trailing: OutlinedButton.icon(
            onPressed: () => set(c.copyWith(priorities: [...c.priorities, const PriorityOption('New option', 'కొత్త ఎంపిక', 'other')])),
            icon: const Icon(Icons.add),
            label: const Text('Add option'),
          ),
          child: Column(children: [
            for (var i = 0; i < c.priorities.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  SizedBox(width: 28, child: Text('${i + 1}.')),
                  Expanded(
                    child: DraftField(
                      key: ValueKey('pri-en-$i'),
                      label: 'English',
                      value: c.priorities[i].en,
                      onChanged: (v) => set(c.copyWith(
                          priorities: [...c.priorities]..[i] = PriorityOption(v, c.priorities[i].te, c.priorities[i].icon))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DraftField(
                      key: ValueKey('pri-te-$i'),
                      label: 'Telugu',
                      value: c.priorities[i].te,
                      onChanged: (v) => set(c.copyWith(
                          priorities: [...c.priorities]..[i] = PriorityOption(c.priorities[i].en, v, c.priorities[i].icon))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: civicIcons.containsKey(c.priorities[i].icon) ? c.priorities[i].icon : 'other',
                    items: [for (final k in civicIcons.keys) DropdownMenuItem(value: k, child: Icon(civicIcons[k]))],
                    onChanged: (v) => set(c.copyWith(
                        priorities: [...c.priorities]..[i] = PriorityOption(c.priorities[i].en, c.priorities[i].te, v!))),
                  ),
                ]),
              ),
          ]),
        ),
        AdminCard(
          title: 'Badges',
          subtitle: 'Milestone = accepted votes needed. After changing milestones, publish and press '
              '"Save thresholds & milestones" so the database accepts the new values.',
          child: Column(children: [
            for (var i = 0; i < c.badges.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  CircleAvatar(backgroundColor: c.badges[i].colorValue, child: Icon(c.badges[i].iconData, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DraftField(
                      key: ValueKey('badge-en-${c.badges[i].id}'),
                      label: 'English',
                      value: c.badges[i].en,
                      onChanged: (v) => set(c.copyWith(badges: [...c.badges]..[i] = c.badges[i].copyWith(en: v))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DraftField(
                      key: ValueKey('badge-te-${c.badges[i].id}'),
                      label: 'Telugu',
                      value: c.badges[i].te,
                      onChanged: (v) => set(c.copyWith(badges: [...c.badges]..[i] = c.badges[i].copyWith(te: v))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: DraftField(
                      key: ValueKey('badge-n-${c.badges[i].id}'),
                      label: 'Milestone',
                      value: '${c.badges[i].milestone}',
                      onChanged: (v) {
                        final n = int.tryParse(v.trim());
                        if (n != null && n > 0) set(c.copyWith(badges: [...c.badges]..[i] = c.badges[i].copyWith(milestone: n)));
                      },
                    ),
                  ),
                ]),
              ),
          ]),
        ),
        AdminCard(
          title: 'Share card',
          subtitle: 'Message on the card after voting. Voters decide whether their own choice is shown.',
          child: Column(children: [
            DraftField(
              key: const ValueKey('share-en'),
              label: 'Message (English)',
              value: c.shareMessageEn,
              onChanged: (v) => set(c.copyWith(shareMessageEn: v)),
            ),
            const SizedBox(height: 12),
            DraftField(
              key: const ValueKey('share-te'),
              label: 'Message (Telugu)',
              value: c.shareMessageTe,
              onChanged: (v) => set(c.copyWith(shareMessageTe: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: c.shareShowChoiceDefault,
              onChanged: (v) => set(c.copyWith(shareShowChoiceDefault: v)),
              title: const Text('"Show my choice" starts switched on'),
              subtitle: const Text('Recommended off: political opinions are sensitive personal data.'),
            ),
          ]),
        ),
      ],
    );
  }
}
