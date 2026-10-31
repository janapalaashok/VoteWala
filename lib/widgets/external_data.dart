import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/external_data.dart';
import '../data/external_votes.dart';
import '../data/featured_polls.dart';
import '../data/poll_month.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../utils.dart';
import 'common.dart';

String externalLabel(BuildContext context) => context.isTelugu ? ExternalData.labelTe : ExternalData.label;

/// "Jan–Oct 2026" style range of the months in [months].
String externalRange(BuildContext context, List<PollMonth> months) {
  if (months.isEmpty) return '';
  final te = context.isTelugu;
  final a = months.first, b = months.last;
  return a == b ? a.label(te) : '${a.shortLabel(te)}–${b.shortLabel(te)} ${b.year}';
}

/// Small label shown wherever external data is part of the numbers.
class ExternalDataLabel extends StatelessWidget {
  const ExternalDataLabel({super.key, this.suffix});

  /// Extra text after the label, e.g. the months it covers.
  final String? suffix;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.blue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.blue),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            suffix == null ? externalLabel(context) : '${externalLabel(context)} · $suffix',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.blue),
          ),
        ),
      ],
    ),
  );
}

/// Note under featured results that include external months.
class ExternalFeaturedNote extends StatelessWidget {
  const ExternalFeaturedNote({super.key, required this.poll});

  final FeaturedPoll poll;

  @override
  Widget build(BuildContext context) {
    final months = externalMonths(poll);
    if (months.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: ExternalDataLabel(suffix: context.tr('externalIncludes', {'months': externalRange(context, months)})),
    );
  }
}

/// Assembly-constituency votes collected on Facebook in [month]: totals and
/// the constituencies with the most votes (no candidate split in the data).
class ExternalAssemblyCard extends StatefulWidget {
  const ExternalAssemblyCard({super.key, required this.month});

  final PollMonth month;

  @override
  State<ExternalAssemblyCard> createState() => _ExternalAssemblyCardState();
}

class _ExternalAssemblyCardState extends State<ExternalAssemblyCard> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final data = ExternalData.assembly[widget.month.key];
    if (data == null || data.isEmpty) return const SizedBox.shrink();
    final te = context.isTelugu;
    final total = data.values.fold(0, (a, b) => a + b);
    final ranked = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final shown = _all ? ranked : ranked.take(10).toList();
    final top = ranked.first.value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('externalAssemblyTitle'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const ExternalDataLabel(),
          const SizedBox(height: 8),
          Row(
            children: [
              _Figure(value: formatIndian(total), label: context.tr('votes')),
              const SizedBox(width: 24),
              _Figure(value: '${data.length}', label: context.tr('constituenciesTakingPart')),
            ],
          ),
          const SizedBox(height: 12),
          for (final e in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(ApData.mla[e.key - 1].name(te), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / top,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDEFF2),
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: Text(
                      formatIndian(e.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          if (ranked.length > 10)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _all = !_all),
                child: Text(_all ? context.tr('showLess') : context.tr('showAllN', {'n': '${ranked.length}'})),
              ),
            ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value, label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ],
  );
}
