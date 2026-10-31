import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'constituency_detail_screen.dart';
import 'home_screen.dart';

const _eciResultsUrl = 'https://results.eci.gov.in/';
const _eciAffidavitUrl = 'https://affidavit.eci.gov.in/';

class CandidateDetailScreen extends StatelessWidget {
  const CandidateDetailScreen({super.key, required this.candidate});

  final Candidate candidate;

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final cand = candidate;
    final c = cand.constituency;
    final te = context.isTelugu;
    final state = AppScope.of(context);
    final saved = state.isSaved(cand.id);
    final r = cand.result2024;
    final won = cand.role == CandidateRole.won2024;
    final opponent = Candidate(c, won ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PageBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(context.tr('candidateDetails')),
        actions: [
          IconButton(
            tooltip: context.tr(saved ? 'saved' : 'save'),
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? AppColors.orange : null),
            onPressed: () => state.toggleSaved(cand.id),
          ),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => sharePoll(context, c)),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        PageBody(
          maxWidth: 640,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PersonAvatar(photoUrl: cand.photoUrl, party: cand.party, size: 112, square: true),
              const SizedBox(width: 20),
              PartySymbolBadge(cand.party, size: 64),
            ]),
            const SizedBox(height: 16),
            Text(cand.name(te), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${cand.party.name(te)} (${cand.party.short})', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (won ? AppColors.green : AppColors.muted).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                won ? '${context.tr('won2024')} · ${roleLabel(context, cand)}' : context.tr('runnerUp2024'),
                style: TextStyle(
                  color: won ? AppColors.green : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: InfoField(label: context.tr('constituency'), value: Text(c.name(te)))),
              Expanded(
                child: InfoField(
                  label: context.tr('electionType'),
                  value: Text(context.tr(c.isMla ? 'assemblyMla' : 'parliamentMp')),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: InfoField(
                  label: context.tr('votes2024', {'n': ''}).trim(),
                  value: Text(formatIndian(cand.contestant!.votes)),
                ),
              ),
              Expanded(
                child: InfoField(
                  label: context.tr('result2024'),
                  value: Text(
                    context.tr(won ? 'wonBy' : 'lostBy', {'n': formatIndian(r.margin)}),
                    style: TextStyle(color: won ? AppColors.green : AppColors.red),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            AppCard(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => CandidateDetailScreen(candidate: opponent))),
              child: Row(children: [
                CandidateAvatar(opponent, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${context.tr(won ? 'runnerUp2024' : 'won2024')}: ${opponent.name(te)} (${opponent.party.short})',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _LinkButton(
                    icon: Icons.open_in_new, label: context.tr('eciResults'), onTap: () => _open(_eciResultsUrl)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LinkButton(
                    icon: Icons.description_outlined,
                    label: context.tr('affidavits'),
                    onTap: () => _open(_eciAffidavitUrl)),
              ),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openConstituency(context, c),
              icon: const Icon(Icons.how_to_vote_outlined),
              label: Text('${c.name(te)} ${context.tr('pollType')}'),
            ),
            const SizedBox(height: 16),
            Text(context.tr('dataCredit'), style: const TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: AppColors.blue),
        label: Text(label, style: const TextStyle(color: AppColors.blue, fontSize: 12.5)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(42),
          side: const BorderSide(color: AppColors.blue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
}
