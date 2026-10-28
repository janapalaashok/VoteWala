import 'dart:convert';

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../admin_widgets.dart';
import '../file_pick.dart';

class PublishPage extends StatelessWidget {
  const PublishPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final json = const JsonEncoder.withIndent('  ').convert(admin.draft.toJson());

    return AdminPage(
      title: 'Publish & backup',
      subtitle: 'Publish sends the draft to every app and website visitor. Back up before big changes.',
      children: [
        AdminCard(
          title: admin.dirty ? 'You have unpublished changes' : 'Everything is published',
          subtitle: admin.demo
              ? 'Demo mode: publishing applies to this browser only. Connect Firebase (docs/FIREBASE_SETUP.md) to go live.'
              : 'Published changes reach users the next time they open the app or website.',
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton.icon(
              onPressed: admin.dirty
                  ? () async {
                      final ok = await admin.publish();
                      if (context.mounted) showAdminSnack(context, ok ? 'Published' : admin.error ?? 'Failed', error: !ok);
                    }
                  : null,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Publish now'),
            ),
            OutlinedButton.icon(
              onPressed: admin.dirty ? admin.discardDraft : null,
              icon: const Icon(Icons.undo),
              label: const Text('Discard draft'),
            ),
          ]),
        ),
        AdminCard(
          title: 'Backup',
          subtitle: 'Export the draft as JSON, or import a backup into the draft.',
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            OutlinedButton.icon(
              onPressed: () => downloadText('votewala-config-${DateTime.now().millisecondsSinceEpoch}.json', json),
              icon: const Icon(Icons.download),
              label: const Text('Export JSON'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final text = await promptText(context, 'Paste exported JSON', '', maxLines: 12);
                if (text == null || text.isEmpty) return;
                try {
                  admin.replaceDraft(AppConfig.fromJson(jsonDecode(text) as Map<String, dynamic>));
                  if (context.mounted) showAdminSnack(context, 'Imported into the draft. Review, then publish.');
                } catch (e) {
                  if (context.mounted) showAdminSnack(context, 'Not a valid VoteWala config: $e', error: true);
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Import JSON'),
            ),
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset the draft to built-in defaults?'),
                    content: const Text('All edits (names, photos, polls, branding) are removed from the draft. '
                        'Nothing changes for users until you publish.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset draft')),
                    ],
                  ),
                );
                if (ok == true) admin.replaceDraft(AppConfig.defaults());
              },
              icon: const Icon(Icons.restart_alt, color: AdminColors.danger),
              label: const Text('Reset to defaults', style: TextStyle(color: AdminColors.danger)),
            ),
          ]),
        ),
        AdminCard(
          title: 'Draft JSON',
          subtitle: '${(json.length / 1024).toStringAsFixed(1)} KB (Firestore limit: 1024 KB)',
          child: Container(
            constraints: const BoxConstraints(maxHeight: 420),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(
              child: SelectableText(json,
                  style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.5)),
            ),
          ),
        ),
      ],
    );
  }
}
