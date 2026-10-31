import 'package:flutter/material.dart';

import '../config/config_service.dart';
import '../l10n/legal.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../widgets/common.dart';

void openLegal(BuildContext context, String id) {
  final doc = legalById(id);
  if (doc != null) Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LegalScreen(doc: doc)));
}

void openLegalIndex(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LegalIndexScreen()));

String _withContact(String text) {
  final email = appConfig.branding.contactEmail;
  return text.replaceAll('{contact}', email ?? 'the VoteWala team (contact email will be published here)');
}

/// One policy page. [standalone] is used when it is opened from its web
/// address (`#/legal/<id>`) without signing in.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc, this.standalone = false});

  final LegalDoc doc;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PageBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: !standalone,
        title: Text(doc.title(te)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        PageBody(
          maxWidth: 760,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (standalone && !desktopLayout(context)) ...[
              const VoteWalaLogo(markSize: 40, horizontal: true),
              const SizedBox(height: 20),
            ],
            Text(doc.titleEn, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text(context.tr('lastUpdatedOn', {'date': legalUpdated}), style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${doc.titleTe} · సారాంశం', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(_withContact(doc.summaryTe), style: const TextStyle(height: 1.6)),
              ]),
            ),
            const SizedBox(height: 8),
            for (final (heading, body) in doc.sections) ...[
              const SizedBox(height: 22),
              Text(heading, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SelectableText(_withContact(body), style: const TextStyle(height: 1.65, fontSize: 15)),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(spacing: 4, runSpacing: 4, children: [
              for (final d in legalDocs)
                if (d.id != doc.id)
                  TextButton(
                    onPressed: () => standalone
                        ? Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LegalScreen(doc: d)))
                        : Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => LegalScreen(doc: d))),
                    child: Text(d.title(te)),
                  ),
            ]),
            if (standalone) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => appLinkHome(),
                child: Text(context.tr('openVoteWala')),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Set by main.dart: leaves a standalone policy page for the app.
void Function() appLinkHome = () {};

/// All policies (Profile → Legal & policies).
class LegalIndexScreen extends StatelessWidget {
  const LegalIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final te = context.isTelugu;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PageBar(backgroundColor: Colors.white, title: Text(context.tr('legalPolicies'))),
      body: ListView(children: [
        PageBody(
          maxWidth: 640,
          child: Column(children: [
            for (final d in legalDocs)
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(d.title(te), style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openLegal(context, d.id),
              ),
          ]),
        ),
      ]),
    );
  }
}
