import 'dart:math';

import 'package:flutter/material.dart';

import '../utils.dart';
import 'ap_data.dart';
import 'poll_month.dart';

enum FeaturedKind { cm, issues, activity }

class FeaturedOption {
  const FeaturedOption(this.en, this.te, {this.partyId, this.photoUrl, this.icon, this.weight = 10});

  final String en;
  final String te;
  final String? partyId;
  final String? photoUrl;
  final IconData? icon;

  /// Relative weight for generated sample results.
  final double weight;

  String label(bool telugu) => telugu ? te : en;
  Party? get party => partyId == null ? null : partyById(partyId!);
}

/// Statewide polls shown on the dashboard. One vote per verified user for the
/// whole poll. Yearly polls show month-by-month updates.
class FeaturedPoll {
  const FeaturedPoll({
    required this.id,
    required this.kind,
    required this.titleEn,
    required this.titleTe,
    required this.questionEn,
    required this.questionTe,
    required this.options,
    required this.start,
    required this.end,
    this.detailEn,
    this.detailTe,
    this.sourceUrl,
    this.monthlyVotes = 30000,
  });

  final String id;
  final FeaturedKind kind;
  final String titleEn, titleTe, questionEn, questionTe;
  final String? detailEn, detailTe;
  final List<FeaturedOption> options;

  /// IST wall-clock start (inclusive) and end (exclusive).
  final DateTime start, end;
  final String? sourceUrl;
  final int monthlyVotes;

  String title(bool te) => te ? titleTe : titleEn;
  String question(bool te) => te ? questionTe : questionEn;
  String? detail(bool te) => te ? detailTe : detailEn;

  bool get isOpen {
    final n = istNow();
    return !n.isBefore(start) && n.isBefore(end);
  }

  bool get hasMonthlyUpdates => kind != FeaturedKind.activity;

  /// Months the poll has run so far, oldest first.
  List<PollMonth> get months {
    final last = PollMonth.of(isOpen ? istNow() : end.subtract(const Duration(minutes: 1)));
    return [for (var m = PollMonth.of(start); m.compareTo(last) <= 0; m = m.next) m];
  }

  /// Expected share of a month's votes cast so far in [month]: the part of
  /// the month inside the poll window that has already elapsed.
  double _elapsed(PollMonth month) {
    final from = start.isAfter(month.start) ? start : month.start;
    final to = end.isBefore(month.end) ? end : month.end;
    final now = istNow();
    final until = now.isBefore(to) ? now : to;
    if (!until.isAfter(from)) return 0;
    return until.difference(from).inMinutes / month.end.difference(month.start).inMinutes;
  }

  /// Votes cast in [month] per option (sample data).
  List<int> votesIn(PollMonth month) {
    final rnd = Random(stableHash(id) + month.index * 7907);
    final weights = [for (final o in options) o.weight * (0.8 + rnd.nextDouble() * 0.4)];
    final sum = weights.reduce((a, b) => a + b);
    final total = (monthlyVotes * (0.8 + rnd.nextDouble() * 0.4) * _elapsed(month)).round();
    return [for (final w in weights) (total * w / sum).round()];
  }
}

final featuredPolls = <FeaturedPoll>[
  FeaturedPoll(
    id: 'cm-2026',
    kind: FeaturedKind.cm,
    titleEn: 'Vote for CM',
    titleTe: 'CM కి ఓటు',
    questionEn: 'Who do you want as the Chief Minister of Andhra Pradesh?',
    questionTe: 'ఆంధ్రప్రదేశ్ ముఖ్యమంత్రిగా మీరు ఎవరిని కోరుకుంటున్నారు?',
    start: DateTime.utc(2026, 1, 1),
    end: DateTime.utc(2027, 1, 1),
    options: const [
      FeaturedOption('N. Chandrababu Naidu', 'నారా చంద్రబాబు నాయుడు', partyId: 'tdp', weight: 38,
          photoUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a8/The_portrait_of_CM_Shri_Nara_Chandrababu_Naidu.jpg/250px-The_portrait_of_CM_Shri_Nara_Chandrababu_Naidu.jpg'),
      FeaturedOption('Y. S. Jagan Mohan Reddy', 'వై. ఎస్. జగన్ మోహన్ రెడ్డి', partyId: 'ysrcp', weight: 31,
          photoUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a8/The_Chief_Minister_of_Andhra_Pradesh%2C_Shri_Y.S._Jagan_Mohan_Reddy.jpg/250px-The_Chief_Minister_of_Andhra_Pradesh%2C_Shri_Y.S._Jagan_Mohan_Reddy.jpg'),
      FeaturedOption('Pawan Kalyan', 'పవన్ కళ్యాణ్', partyId: 'jsp', weight: 17,
          photoUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/16/Shri_Konidela_Pawan_Kalyan.jpg/250px-Shri_Konidela_Pawan_Kalyan.jpg'),
      FeaturedOption('Nara Lokesh', 'నారా లోకేష్', partyId: 'tdp', weight: 9,
          photoUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0a/Nara_Lokesh_at_CII_Partnership_Summit_2025%2C_Visakhapatnam.jpg/250px-Nara_Lokesh_at_CII_Partnership_Summit_2025%2C_Visakhapatnam.jpg'),
      FeaturedOption('Y. S. Sharmila', 'వై. ఎస్. షర్మిల', partyId: 'inc', weight: 5,
          photoUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/33/YS_Sharmila_at_Sitaram_Yechury_remembrance_meet.jpg/250px-YS_Sharmila_at_Sitaram_Yechury_remembrance_meet.jpg'),
    ],
  ),
  FeaturedPoll(
    id: 'ap-priority-2026',
    kind: FeaturedKind.issues,
    titleEn: 'Vote for AP',
    titleTe: 'AP కి ఓటు',
    questionEn: 'What should be the top priority for Andhra Pradesh?',
    questionTe: 'ఆంధ్రప్రదేశ్‌కు అత్యంత ప్రాధాన్యం దేనికి ఇవ్వాలి?',
    start: DateTime.utc(2026, 1, 1),
    end: DateTime.utc(2027, 1, 1),
    options: const [
      FeaturedOption('Better roads', 'మెరుగైన రోడ్లు', icon: Icons.add_road, weight: 16),
      FeaturedOption('Poverty removal', 'పేదరిక నిర్మూలన', icon: Icons.volunteer_activism, weight: 14),
      FeaturedOption('Welfare schemes', 'సంక్షేమ పథకాలు', icon: Icons.family_restroom, weight: 13),
      FeaturedOption('Reservation removal', 'రిజర్వేషన్ల తొలగింపు', icon: Icons.balance, weight: 6),
      FeaturedOption('Better education', 'మెరుగైన విద్య', icon: Icons.school, weight: 15),
      FeaturedOption('Better hospitals', 'మెరుగైన ఆసుపత్రులు', icon: Icons.local_hospital, weight: 14),
      FeaturedOption('Jobs & industries', 'ఉద్యోగాలు & పరిశ్రమలు', icon: Icons.factory, weight: 15),
      FeaturedOption('Farmers & irrigation', 'రైతులు & సాగునీరు', icon: Icons.agriculture, weight: 9),
    ],
  ),
  FeaturedPoll(
    id: 'artificial-paneer-ban-2026',
    kind: FeaturedKind.activity,
    titleEn: 'Recent activity',
    titleTe: 'ఇటీవలి పరిణామం',
    questionEn: 'The AP government has banned artificial paneer for one year. Do you support this decision?',
    questionTe: 'ఏపీ ప్రభుత్వం కృత్రిమ పనీర్‌పై ఒక సంవత్సరం నిషేధం విధించింది. ఈ నిర్ణయాన్ని మీరు సమర్థిస్తారా?',
    detailEn: 'Manufacture, storage, transport, sale and use of artificial paneer banned for one year to protect '
        'public health (reported 28 Oct 2026).',
    detailTe: 'ప్రజారోగ్య పరిరక్షణ కోసం కృత్రిమ పనీర్ తయారీ, నిల్వ, రవాణా, అమ్మకం, వినియోగంపై ఒక సంవత్సరం నిషేధం '
        '(28 అక్టోబర్ 2026 వార్త).',
    sourceUrl: 'https://ntvtelugu.com/andhra-pradesh-news/amaravathi/andhra-pradesh-bans-artificial-paneer-for-one-year-1030135.html',
    start: DateTime.utc(2026, 10, 28),
    end: DateTime.utc(2026, 11, 7), // 10 days
    monthlyVotes: 36000,
    options: const [
      FeaturedOption('Support', 'సమర్థిస్తాను', icon: Icons.thumb_up_alt, weight: 64),
      FeaturedOption('Do not support', 'సమర్థించను', icon: Icons.thumb_down_alt, weight: 36),
    ],
  ),
];

FeaturedPoll featuredById(String id) => featuredPolls.firstWhere((p) => p.id == id);
