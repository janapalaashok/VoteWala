import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../data/ap_data.dart';
import '../../data/poll_repository.dart';
import '../admin_widgets.dart';
import 'common.dart';

class CandidatesPage extends StatefulWidget {
  const CandidatesPage({super.key});

  @override
  State<CandidatesPage> createState() => _CandidatesPageState();
}

class _CandidatesPageState extends State<CandidatesPage> {
  String _query = '';
  ElectionType? _type;
  String? _district;
  String? _party;
  bool _missingPhoto = false;
  bool _editedOnly = false;
  int _page = 0;
  static const _perPage = 25;

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final d = admin.draft;
    final q = _query.toLowerCase();
    final list = [
      for (final c in allCandidates)
        if ((_type == null || c.constituency.type == _type) &&
            (_district == null || c.constituency.districtIds.contains(_district)) &&
            (_party == null || draftParty(d, c).id == _party) &&
            (!_missingPhoto || draftPhoto(d, c) == null) &&
            (!_editedOnly || !(d.candidates[c.id]?.isEmpty ?? true)) &&
            (q.isEmpty ||
                draftName(d, c).toLowerCase().contains(q) ||
                c.constituency.en.toLowerCase().contains(q)))
          c,
    ];
    final pages = (list.length / _perPage).ceil().clamp(1, 1000);
    final page = _page.clamp(0, pages - 1);
    final shown = list.skip(page * _perPage).take(_perPage).toList();

    void reset() => setState(() => _page = 0);

    return AdminPage(
      title: 'Candidates',
      subtitle: 'The 2024 winner and runner-up of every seat. Edit names, Telugu names, parties and photos.',
      children: [
        AdminCard(
          child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(
              width: 280,
              child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or constituency'),
                onChanged: (v) => setState(() {
                  _query = v.trim();
                  _page = 0;
                }),
              ),
            ),
            _drop<ElectionType?>('Type', _type, {null: 'MLA + MP', ElectionType.mla: 'MLA', ElectionType.mp: 'MP'},
                (v) => setState(() { _type = v; reset(); })),
            _drop<String?>('District', _district, {null: 'All districts', for (final x in ApData.districts) x.id: x.en},
                (v) => setState(() { _district = v; reset(); })),
            _drop<String?>('Party', _party, {null: 'All parties', for (final p in d.parties) p.id: p.short},
                (v) => setState(() { _party = v; reset(); })),
            FilterChip(
              label: const Text('Missing photo'),
              selected: _missingPhoto,
              onSelected: (v) => setState(() { _missingPhoto = v; reset(); }),
            ),
            FilterChip(
              label: const Text('Edited'),
              selected: _editedOnly,
              onSelected: (v) => setState(() { _editedOnly = v; reset(); }),
            ),
            Text('${list.length} candidates', style: const TextStyle(color: AdminColors.muted)),
          ]),
        ),
        AdminCard(
          padding: 0,
          child: Column(children: [
            for (final c in shown) _CandidateRow(candidate: c),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('Page ${page + 1} of $pages', style: const TextStyle(color: AdminColors.muted)),
                IconButton(
                  onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: page < pages - 1 ? () => setState(() => _page = page + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _drop<T>(String label, T value, Map<T, String> items, ValueChanged<T?> onChanged) => SizedBox(
        width: 190,
        child: DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: onChanged,
        ),
      );
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final d = admin.draft;
    final c = candidate;
    final party = draftParty(d, c);
    final edited = !(d.candidates[c.id]?.isEmpty ?? true);
    return InkWell(
      onTap: () => showDialog<void>(context: context, builder: (_) => CandidateEditor(candidate: c)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isAdminPhone(context) ? 14 : 22, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.border))),
        child: isAdminPhone(context) ? _phone(context, d, c, party, edited) : Row(children: [
          DraftAvatar(url: draftPhoto(d, c), color: party.color, size: 44, label: draftName(d, c)),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(draftName(d, c), style: const TextStyle(fontWeight: FontWeight.w700)),
              if (d.candidates[c.id]?.nameTe != null)
                Text(d.candidates[c.id]!.nameTe!, style: const TextStyle(color: AdminColors.muted, fontSize: 12.5)),
            ]),
          ),
          Expanded(
            flex: 2,
            child: Text('${c.constituency.en} · ${c.constituency.isMla ? 'MLA' : 'MP'}',
                style: const TextStyle(color: AdminColors.muted)),
          ),
          SizedBox(
            width: 120,
            child: Text(c.role == CandidateRole.won2024 ? 'Won 2024' : 'Runner-up',
                style: TextStyle(
                  color: c.role == CandidateRole.won2024 ? AdminColors.success : AdminColors.muted,
                  fontWeight: FontWeight.w600,
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: party.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(party.short, style: TextStyle(color: party.color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          SizedBox(
            width: 90,
            child: edited
                ? const Align(
                    alignment: Alignment.centerRight,
                    child: Chip(label: Text('Edited'), visualDensity: VisualDensity.compact),
                  )
                : null,
          ),
          const Icon(Icons.chevron_right, color: AdminColors.muted),
        ]),
      ),
    );
  }
  /// Phones: avatar, name, seat and party stacked so nothing is squeezed.
  Widget _phone(BuildContext context, AppConfig d, Candidate c, Party party, bool edited) => Row(children: [
        DraftAvatar(url: draftPhoto(d, c), color: party.color, size: 40, label: draftName(d, c)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(draftName(d, c), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              '${c.constituency.en} · ${c.constituency.isMla ? 'MLA' : 'MP'} · '
              '${c.role == CandidateRole.won2024 ? 'Won 2024' : 'Runner-up'}',
              style: const TextStyle(color: AdminColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: party.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(party.short, style: TextStyle(color: party.color, fontWeight: FontWeight.w700, fontSize: 11.5)),
              ),
              if (edited)
                const Text('Edited', style: TextStyle(color: AdminColors.accent, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AdminColors.muted),
      ]);
}

class CandidateEditor extends StatefulWidget {
  const CandidateEditor({super.key, required this.candidate});

  final Candidate candidate;

  @override
  State<CandidateEditor> createState() => _CandidateEditorState();
}

class _CandidateEditorState extends State<CandidateEditor> {
  late CandidateOverride _o = AdminScope.read(context).draft.candidates[widget.candidate.id] ?? const CandidateOverride();

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    final d = AdminScope.of(context).draft;
    final official = c.contestant!;
    return AlertDialog(
        title: Text('${official.name} · ${c.constituency.en}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Official 2024 data: ${official.name}, ${official.partyId.toUpperCase()}, ${official.votes} votes',
                  style: const TextStyle(color: AdminColors.muted, fontSize: 12.5)),
              const SizedBox(height: 18),
              ImageField(
                label: 'Photo',
                helper: 'Use an official photo you have the right to publish (e.g. from the ECI affidavit).',
                url: _o.photoUrl ?? official.photoUrl,
                folder: 'candidates',
                onChanged: (u) => setState(() => _o = CandidateOverride(
                      name: _o.name, nameTe: _o.nameTe, partyId: _o.partyId, photoUrl: u)),
              ),
              const SizedBox(height: 18),
              DraftField(
                label: 'Name (English)',
                hint: official.name,
                value: _o.name,
                onChanged: (v) => _o = CandidateOverride(
                    name: v.isEmpty ? null : v, nameTe: _o.nameTe, partyId: _o.partyId, photoUrl: _o.photoUrl),
              ),
              const SizedBox(height: 14),
              DraftField(
                label: 'Name (Telugu)',
                value: _o.nameTe,
                onChanged: (v) => _o = CandidateOverride(
                    name: _o.name, nameTe: v.isEmpty ? null : v, partyId: _o.partyId, photoUrl: _o.photoUrl),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _o.partyId ?? official.partyId,
                decoration: const InputDecoration(labelText: 'Party'),
                items: [for (final p in d.parties) DropdownMenuItem(value: p.id, child: Text('${p.short} · ${p.en}'))],
                onChanged: (v) => _o = CandidateOverride(
                    name: _o.name, nameTe: _o.nameTe, photoUrl: _o.photoUrl, partyId: v == official.partyId ? null : v),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _save(const CandidateOverride());
              Navigator.pop(context);
            },
            child: const Text('Reset to official'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _save(_o);
              Navigator.pop(context);
            },
            child: const Text('Save to draft'),
          ),
        ],
    );
  }

  void _save(CandidateOverride o) {
    final official = widget.candidate.contestant!;
    final clean = CandidateOverride(
      name: o.name == official.name ? null : o.name,
      nameTe: o.nameTe,
      photoUrl: o.photoUrl == official.photoUrl ? null : o.photoUrl,
      partyId: o.partyId,
    );
    AdminScope.read(context).update((c) => c.copyWith(candidates: {...c.candidates, widget.candidate.id: clean}));
  }
}
