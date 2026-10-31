import 'package:flutter/material.dart';

import '../../l10n/legal.dart';
import '../admin_widgets.dart';
import 'issues_page.dart';

String _date(Object? v) => v is DateTime ? v.toLocal().toString().substring(0, 16) : '—';

// -------------------------------------------------------------------- admins

/// The admin team. Owners add and remove admins.
class AdminsPage extends StatefulWidget {
  const AdminsPage({super.key});

  @override
  State<AdminsPage> createState() => _AdminsPageState();
}

class _AdminsPageState extends State<AdminsPage> {
  Future<Map<String, Map<String, Object?>>>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= AdminScope.read(context).data?.admins();
  }

  void _reload() => setState(() => _load = AdminScope.read(context).data?.admins());

  Future<void> _add() async {
    final data = AdminScope.read(context).data!;
    final username = TextEditingController();
    final name = TextEditingController();
    final password = TextEditingController();
    String? error;
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add admin'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('They sign in at /#/admin with this username and the temporary password, and must set '
                  'their own password on the first sign-in.',
                  style: TextStyle(color: AdminColors.muted, fontSize: 13)),
              const SizedBox(height: 14),
              TextField(controller: username, decoration: const InputDecoration(labelText: 'Username (e.g. ravi)')),
              const SizedBox(height: 10),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 10),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'Temporary password (8+ characters)')),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AdminColors.danger)),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final u = username.text.trim().toLowerCase();
                if (!RegExp(r'^[a-z0-9._-]{3,30}$').hasMatch(u)) {
                  return setLocal(() => error = 'Username: 3–30 letters, numbers, dots, dashes or underscores.');
                }
                if (password.text.length < 8) return setLocal(() => error = 'Use at least 8 characters.');
                try {
                  await data.createAdmin(username: u, displayName: name.text.trim(), tempPassword: password.text);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setLocal(() => error = '$e');
                }
              },
              child: const Text('Add admin'),
            ),
          ],
        ),
      ),
    );
    if (added == true && mounted) {
      showAdminSnack(context, 'Admin added. Share the username and temporary password privately.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final data = admin.data;
    if (data == null) return const NeedsFirebase(title: 'Admins');
    final owner = admin.role == 'owner';
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        final list = (snap.data ?? const {}).entries.toList()
          ..sort((a, b) => '${a.value['username']}'.compareTo('${b.value['username']}'));
        return AdminPage(
          title: 'Admins',
          subtitle: owner
              ? 'People who can sign in to this admin panel. Owners can add and remove admins.'
              : 'People who can sign in to this admin panel. Only owners can add or remove admins.',
          actions: [
            if (owner) FilledButton.icon(onPressed: _add, icon: const Icon(Icons.person_add), label: const Text('Add admin')),
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          ],
          children: [
            if (snap.hasError) AdminCard(child: Text('Could not load: ${snap.error}')),
            if (snap.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator()),
            AdminCard(
              padding: 8,
              child: Column(children: [
                for (final e in list)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AdminColors.accent.withValues(alpha: 0.15),
                      child: Text('${e.value['username'] ?? '?'}'[0].toUpperCase(),
                          style: const TextStyle(color: AdminColors.accent, fontWeight: FontWeight.w800)),
                    ),
                    title: Text('${e.value['displayName'] ?? e.value['username'] ?? e.key}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('@${e.value['username'] ?? '—'} · ${e.value['role'] ?? 'admin'}'
                        '${e.value['mustChangePassword'] == true ? ' · has not signed in yet' : ''}'),
                    trailing: owner && e.value['role'] != 'owner'
                        ? IconButton(
                            tooltip: 'Remove admin',
                            icon: const Icon(Icons.person_remove, color: AdminColors.danger),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Remove ${e.value['username']}?'),
                                  content: const Text('They will no longer be able to use the admin panel.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              try {
                                await data.removeAdmin(e.key);
                                _reload();
                              } catch (err) {
                                if (context.mounted) showAdminSnack(context, '$err', error: true);
                              }
                            },
                          )
                        : null,
                  ),
              ]),
            ),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------------- users

/// Voters: search, vote counts, block / unblock.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  Future<(Map<String, Map<String, Object?>>, Map<String, Map<String, Object?>>, Map<String, Map<String, Object?>>)>? _load;
  String _query = '';
  bool _blockedOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  Future<(Map<String, Map<String, Object?>>, Map<String, Map<String, Object?>>, Map<String, Map<String, Object?>>)> _fetch() {
    final data = AdminScope.read(context).data!;
    return (data.profiles(), data.voteCounts(), data.blocked()).wait;
  }

  Future<void> _block(String uid, String email) async {
    final data = AdminScope.read(context).data!;
    final reason = await promptText(context, 'Block $email from voting? Reason (shown to admins only)', '');
    if (reason == null) return;
    try {
      await data.block(uid, reason.isEmpty ? 'Community guidelines' : reason);
      setState(() => _load = _fetch());
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = AdminScope.of(context).data;
    if (data == null) return const NeedsFirebase(title: 'Users');
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        final (profiles, counts, blocked) = snap.data ?? (const {}, const {}, const {});
        final q = _query.trim().toLowerCase();
        final rows = [
          for (final e in profiles.entries)
            if ((q.isEmpty ||
                    '${e.value['email']}'.toLowerCase().contains(q) ||
                    '${e.value['name']}'.toLowerCase().contains(q) ||
                    e.key.contains(q)) &&
                (!_blockedOnly || blocked.containsKey(e.key)))
              e,
        ]..sort((a, b) => ((counts[b.key]?['voteCount'] as int?) ?? 0).compareTo((counts[a.key]?['voteCount'] as int?) ?? 0));
        return AdminPage(
          title: 'Users',
          subtitle: 'Voters who signed in (${profiles.length}). Blocked users can still browse but cannot vote. '
              'Their earlier votes stay counted.',
          actions: [
            FilterChip(
              label: Text('Blocked only (${blocked.length})'),
              selected: _blockedOnly,
              onSelected: (v) => setState(() => _blockedOnly = v),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: () => setState(() => _load = _fetch()), icon: const Icon(Icons.refresh)),
          ],
          children: [
            if (snap.hasError) AdminCard(child: Text('Could not load: ${snap.error}')),
            if (snap.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator()),
            TextField(
              decoration: const InputDecoration(hintText: 'Search email, name or user id', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            AdminCard(
              padding: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Sign-in')),
                    DataColumn(label: Text('Votes'), numeric: true),
                    DataColumn(label: Text('Last seen')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final e in rows.take(500))
                      DataRow(cells: [
                        DataCell(Text('${e.value['email'] ?? ''}')),
                        DataCell(Text('${e.value['name'] ?? ''}')),
                        DataCell(Text('${e.value['provider'] ?? ''}')),
                        DataCell(Text('${counts[e.key]?['voteCount'] ?? 0}')),
                        DataCell(Text(_date(e.value['lastSeen']))),
                        DataCell(blocked.containsKey(e.key)
                            ? Tooltip(
                                message: '${blocked[e.key]?['reason'] ?? ''}',
                                child: const Chip(label: Text('Blocked'), backgroundColor: Color(0xFFFEE2E2)),
                              )
                            : const Text('Active')),
                        DataCell(blocked.containsKey(e.key)
                            ? TextButton(
                                onPressed: () async {
                                  await data.unblock(e.key);
                                  setState(() => _load = _fetch());
                                },
                                child: const Text('Unblock'),
                              )
                            : TextButton(
                                onPressed: () => _block(e.key, '${e.value['email']}'),
                                style: TextButton.styleFrom(foregroundColor: AdminColors.danger),
                                child: const Text('Block'),
                              )),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------------- legal

/// Edit the policy pages (published with "Publish").
class LegalPagesPage extends StatefulWidget {
  const LegalPagesPage({super.key});

  @override
  State<LegalPagesPage> createState() => _LegalPagesPageState();
}

class _LegalPagesPageState extends State<LegalPagesPage> {
  String _id = defaultLegalDocs.first.id;

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final base = defaultLegalDocs.firstWhere((d) => d.id == _id);
    final doc = admin.draft.legal[_id] ?? base;
    final edited = admin.draft.legal.containsKey(_id);
    void save(LegalDoc d) => admin.update((c) => c.copyWith(legal: {...c.legal, _id: d}));

    return AdminPage(
      title: 'Legal pages',
      subtitle: 'Privacy Policy, Terms and the other policy pages. Changes go live with "Publish". '
          'Write {contact} to insert the contact email. Have a lawyer review important changes.',
      actions: [
        if (edited)
          OutlinedButton.icon(
            onPressed: () => admin.update((c) => c.copyWith(legal: {...c.legal}..remove(_id))),
            icon: const Icon(Icons.restore),
            label: const Text('Reset to default'),
          ),
      ],
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final d in defaultLegalDocs)
            ChoiceChip(
              label: Text((admin.draft.legal[d.id] ?? d).titleEn),
              selected: d.id == _id,
              onSelected: (_) => setState(() => _id = d.id),
            ),
        ]),
        const SizedBox(height: 20),
        AdminCard(
          title: 'Page',
          subtitle: 'Address: /#/legal/$_id',
          child: Column(children: [
            DraftField(
              key: ValueKey('title-en-$_id'),
              label: 'Title (English)',
              value: doc.titleEn,
              onChanged: (v) => save(doc.copyWith(titleEn: v)),
            ),
            const SizedBox(height: 12),
            DraftField(
              key: ValueKey('title-te-$_id'),
              label: 'Title (Telugu)',
              value: doc.titleTe,
              onChanged: (v) => save(doc.copyWith(titleTe: v)),
            ),
            const SizedBox(height: 12),
            DraftField(
              key: ValueKey('summary-$_id'),
              label: 'Telugu summary (top of the page)',
              value: doc.summaryTe,
              maxLines: 4,
              onChanged: (v) => save(doc.copyWith(summaryTe: v)),
            ),
          ]),
        ),
        for (var i = 0; i < doc.sections.length; i++)
          AdminCard(
            title: 'Section ${i + 1}',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Move up',
                onPressed: i == 0
                    ? null
                    : () => save(doc.copyWith(sections: [...doc.sections]..removeAt(i)..insert(i - 1, doc.sections[i]))),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Delete section',
                onPressed: () => save(doc.copyWith(sections: [...doc.sections]..removeAt(i))),
                icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
              ),
            ]),
            child: Column(children: [
              DraftField(
                key: ValueKey('h-$_id-$i-${doc.sections.length}'),
                label: 'Heading',
                value: doc.sections[i].$1,
                onChanged: (v) => save(doc.copyWith(sections: [...doc.sections]..[i] = (v, doc.sections[i].$2))),
              ),
              const SizedBox(height: 12),
              DraftField(
                key: ValueKey('b-$_id-$i-${doc.sections.length}'),
                label: 'Text',
                value: doc.sections[i].$2,
                maxLines: 8,
                onChanged: (v) => save(doc.copyWith(sections: [...doc.sections]..[i] = (doc.sections[i].$1, v))),
              ),
            ]),
          ),
        OutlinedButton.icon(
          onPressed: () => save(doc.copyWith(sections: [...doc.sections, ('New section', '')])),
          icon: const Icon(Icons.add),
          label: const Text('Add section'),
        ),
      ],
    );
  }
}
