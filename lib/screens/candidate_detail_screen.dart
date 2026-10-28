import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/poll_repository.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _eciAffidavitUrl = 'https://affidavit.eci.gov.in/';
const _ceoAndhraUrl = 'https://ceoandhra.nic.in/';

class CandidateDetailScreen extends StatefulWidget {
  const CandidateDetailScreen({super.key, required this.candidate});

  final Candidate candidate;

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cand = widget.candidate;
    final c = cand.constituency;
    final te = context.isTelugu;
    final state = AppScope.of(context);
    final saved = state.isSaved(cand.id);
    final name = cand.name(te);

    final tabBody = switch (_tabs.index) {
      0 => context.tr('aboutCandidateBody', {'name': name, 'constituency': c.name(te), 'party': cand.party.name(te)}),
      1 => context.tr('historyBody'),
      2 => context.tr('assetsBody', {'amount': cand.assetsCrore.toStringAsFixed(1)}),
      _ => context.tr('casesBody', {'n': '${cand.criminalCases}'}),
    };
    final tabTitle = [context.tr('aboutCandidate'), context.tr('electionHistory'), context.tr('assets'), context.tr('cases')];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
              Container(
                width: 110,
                height: 128,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.person, size: 84, color: Color(0xFF9AA1AD)),
              ),
              const SizedBox(width: 20),
              PartySymbolBadge(cand.party, size: 64),
            ]),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(cand.name(!te), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('${cand.party.name(te)} (${cand.party.short})', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            _Grid(children: [
              InfoField(label: context.tr('constituency'), value: Text(c.name(te))),
              InfoField(
                  label: context.tr('electionType'), value: Text(context.tr(c.isMla ? 'assemblyMla' : 'parliamentMp'))),
              InfoField(
                label: context.tr('nominationStatus'),
                value: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFE8F6EC), borderRadius: BorderRadius.circular(6)),
                  child: Text(context.tr('contesting'),
                      style: const TextStyle(color: AppColors.green, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
              InfoField(label: context.tr('education'), value: Text(cand.education)),
              InfoField(label: context.tr('totalAssets'), value: Text('₹ ${cand.assetsCrore.toStringAsFixed(1)} Crore')),
              InfoField(
                label: context.tr('criminalCases'),
                value: Text(
                  cand.criminalCases == 0 ? context.tr('noCases') : context.tr('nCases', {'n': '${cand.criminalCases}'}),
                  style: TextStyle(color: cand.criminalCases == 0 ? AppColors.green : AppColors.red),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: _LinkButton(
                  icon: Icons.open_in_new,
                  label: context.tr('viewAffidavit'),
                  onTap: () => _open(_eciAffidavitUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LinkButton(
                  icon: Icons.verified_outlined,
                  label: context.tr('officialSource'),
                  onTap: () => _open(_ceoAndhraUrl),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(context.tr('sampleData'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: context.tr('about')),
                Tab(text: context.tr('electionHistory')),
                Tab(text: context.tr('assets')),
                Tab(text: context.tr('cases')),
              ],
            ),
            const SizedBox(height: 16),
            Text(tabTitle[_tabs.index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(tabBody, style: const TextStyle(color: Color(0xFF4B5160), height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < children.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: children[i]),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ]),
          ),
      ]);
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
