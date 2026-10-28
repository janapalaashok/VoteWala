import 'package:flutter/material.dart';

import '../../data/ap_data.dart';
import '../../utils.dart';
import '../admin_app.dart';
import '../admin_widgets.dart';
import 'common.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    final d = admin.draft;
    final withPhoto = allCandidates.where((c) => draftPhoto(d, c) != null).length;
    final edited = d.candidates.values.where((o) => !o.isEmpty).length;
    final polls = d.featured.where((p) => p.enabled).length;
    final nav = AdminNav.of(context);

    Widget action(IconData icon, String title, String body, String target) => InkWell(
          onTap: () => nav.go(target),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(children: [
              Icon(icon, color: AdminColors.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(color: AdminColors.muted, fontSize: 12.5)),
                ]),
              ),
              const Icon(Icons.arrow_forward, size: 18, color: AdminColors.muted),
            ]),
          ),
        );

    return AdminPage(
      title: 'Welcome back',
      subtitle: 'One place to manage the VoteWala app and website.',
      children: [
        AdminGrid(children: [
          StatTile(
            label: 'Constituencies',
            value: '${ApData.mla.length + ApData.mp.length}',
            footer: '${ApData.mla.length} assembly · ${ApData.mp.length} parliament',
            icon: Icons.map_outlined,
            color: const Color(0xFF2563EB),
          ),
          StatTile(
            label: 'Candidate photos',
            value: '$withPhoto / ${allCandidates.length}',
            footer: '${(withPhoto * 100 / allCandidates.length).round()}% coverage',
            icon: Icons.photo_camera_outlined,
            color: AdminColors.accent,
          ),
          StatTile(
            label: 'Featured polls live',
            value: '$polls',
            footer: '${d.featured.length} configured',
            icon: Icons.how_to_vote_outlined,
            color: AdminColors.success,
          ),
          StatTile(
            label: 'Candidate edits',
            value: '$edited',
            footer: 'names, photos or parties changed',
            icon: Icons.edit_outlined,
            color: const Color(0xFF7C3AED),
          ),
        ]),
        const SizedBox(height: 20),
        AdminCard(
          title: 'Status',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row(Icons.cloud_outlined, 'Storage',
                admin.demo ? 'Demo mode: changes stay in this browser (connect Firebase to go live)' : 'Firebase'),
            _row(Icons.schedule, 'Last published',
                admin.published.updatedAt == null
                    ? 'Never: the app uses built-in defaults'
                    : '${formatDate(admin.published.updatedAt!.toLocal())} ${formatTime(admin.published.updatedAt!.toLocal())}'
                        '${admin.published.updatedBy == null ? '' : ' by ${admin.published.updatedBy}'}'),
            _row(Icons.edit_note, 'Draft', admin.dirty ? 'You have unpublished changes' : 'Nothing to publish'),
          ]),
        ),
        AdminCard(
          title: 'Quick actions',
          child: AdminGrid(minWidth: 300, spacing: 14, children: [
            action(Icons.photo_camera_outlined, 'Add missing photos',
                '${allCandidates.length - withPhoto} candidates use the party symbol', 'Candidates'),
            action(Icons.palette_outlined, 'Logo & colours', 'Update branding across app and website', 'Branding'),
            action(Icons.how_to_vote_outlined, 'Featured polls', 'CM, AP priorities and recent activity polls',
                'Featured polls'),
            action(Icons.web_outlined, 'Home page', 'Top seats, sections and hero text', 'Home & website'),
          ]),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: AdminColors.muted),
          const SizedBox(width: 10),
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(color: AdminColors.muted))),
        ]),
      );
}
