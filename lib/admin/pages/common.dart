import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../data/ap_data.dart';
import '../../data/poll_repository.dart';

/// All named 2024 candidates (winner + runner-up of every seat).
final List<Candidate> allCandidates = [
  for (final c in [...ApData.mla, ...ApData.mp])
    for (final i in [0, 1]) Candidate(c, i),
];

String? draftPhoto(AppConfig d, Candidate c) => d.candidates[c.id]?.photoUrl ?? c.contestant?.photoUrl;

String draftName(AppConfig d, Candidate c) => d.candidates[c.id]?.name ?? c.contestant!.name;

Party draftParty(AppConfig d, Candidate c) {
  final id = d.candidates[c.id]?.partyId ?? c.contestant!.partyId;
  return d.parties.where((p) => p.id == id).firstOrNull ?? defaultParties.last;
}

class DraftAvatar extends StatelessWidget {
  const DraftAvatar({super.key, required this.url, required this.color, this.size = 40, this.label = ''});

  final String? url;
  final Color color;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final initials = Text(
      label.isEmpty ? '?' : label.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join(),
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size * 0.34),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url == null
          ? initials
          : Image.network(url!, fit: BoxFit.cover, width: size, height: size, errorBuilder: (_, _, _) => initials),
    );
  }
}
