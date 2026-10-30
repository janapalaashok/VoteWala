
import 'package:flutter/material.dart';

import '../utils.dart';
import '../config/config_service.dart';
import 'ap_data.dart';
import 'poll_month.dart';

enum FeaturedKind { cm, issues, activity }

/// Icons an admin can pick for poll options.
const featuredIcons = <String, IconData>{
  'road': Icons.add_road,
  'poverty': Icons.volunteer_activism,
  'welfare': Icons.family_restroom,
  'balance': Icons.balance,
  'school': Icons.school,
  'hospital': Icons.local_hospital,
  'factory': Icons.factory,
  'farm': Icons.agriculture,
  'water': Icons.water_drop,
  'power': Icons.bolt,
  'home': Icons.home_work,
  'women': Icons.woman,
  'youth': Icons.groups,
  'law': Icons.gavel,
  'up': Icons.thumb_up_alt,
  'down': Icons.thumb_down_alt,
  'neutral': Icons.remove_circle_outline,
  'star': Icons.star,
};

class FeaturedOption {
  const FeaturedOption(this.en, this.te, {this.partyId, this.photoUrl, this.iconName, this.weight = 10});

  final String en;
  final String te;
  final String? partyId;
  final String? photoUrl;
  final String? iconName;

  /// Relative weight for generated sample results.
  final double weight;

  IconData? get icon => featuredIcons[iconName];
  String label(bool telugu) => telugu ? te : en;
  Party? get party => partyId == null ? null : partyById(partyId!);

  Map<String, dynamic> toJson() => {
        'en': en,
        'te': te,
        if (partyId != null) 'partyId': partyId,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (iconName != null) 'icon': iconName,
        'weight': weight,
      };

  factory FeaturedOption.fromJson(Map<String, dynamic> j) => FeaturedOption(
        j['en'] as String? ?? '',
        j['te'] as String? ?? '',
        partyId: _blank(j['partyId']),
        photoUrl: _blank(j['photoUrl']),
        iconName: _blank(j['icon']),
        weight: (j['weight'] as num?)?.toDouble() ?? 10,
      );
}

String? _blank(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

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
    this.enabled = true,
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

  /// Hidden from the app when false (admin switch).
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'titleEn': titleEn,
        'titleTe': titleTe,
        'questionEn': questionEn,
        'questionTe': questionTe,
        if (detailEn != null) 'detailEn': detailEn,
        if (detailTe != null) 'detailTe': detailTe,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'monthlyVotes': monthlyVotes,
        'enabled': enabled,
        'options': [for (final o in options) o.toJson()],
      };

  factory FeaturedPoll.fromJson(Map<String, dynamic> j) => FeaturedPoll(
        id: j['id'] as String,
        kind: FeaturedKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => FeaturedKind.issues),
        titleEn: j['titleEn'] as String? ?? '',
        titleTe: j['titleTe'] as String? ?? '',
        questionEn: j['questionEn'] as String? ?? '',
        questionTe: j['questionTe'] as String? ?? '',
        detailEn: _blank(j['detailEn']),
        detailTe: _blank(j['detailTe']),
        sourceUrl: _blank(j['sourceUrl']),
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        monthlyVotes: (j['monthlyVotes'] as num?)?.toInt() ?? 30000,
        enabled: j['enabled'] as bool? ?? true,
        options: [for (final o in (j['options'] as List? ?? const [])) FeaturedOption.fromJson(o as Map<String, dynamic>)],
      );

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
}

/// Built-in featured polls; the admin panel can replace them.
final defaultFeaturedPolls = <FeaturedPoll>[
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
      FeaturedOption('Better roads', 'మెరుగైన రోడ్లు', iconName: 'road', weight: 16),
      FeaturedOption('Poverty removal', 'పేదరిక నిర్మూలన', iconName: 'poverty', weight: 14),
      FeaturedOption('Welfare schemes', 'సంక్షేమ పథకాలు', iconName: 'welfare', weight: 13),
      FeaturedOption('Reservation removal', 'రిజర్వేషన్ల తొలగింపు', iconName: 'balance', weight: 6),
      FeaturedOption('Better education', 'మెరుగైన విద్య', iconName: 'school', weight: 15),
      FeaturedOption('Better hospitals', 'మెరుగైన ఆసుపత్రులు', iconName: 'hospital', weight: 14),
      FeaturedOption('Jobs & industries', 'ఉద్యోగాలు & పరిశ్రమలు', iconName: 'factory', weight: 15),
      FeaturedOption('Farmers & irrigation', 'రైతులు & సాగునీరు', iconName: 'farm', weight: 9),
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
      FeaturedOption('Support', 'సమర్థిస్తాను', iconName: 'up', weight: 64),
      FeaturedOption('Do not support', 'సమర్థించను', iconName: 'down', weight: 36),
    ],
  ),
];

/// Featured polls currently enabled by the admin.
/// Active featured polls, at most [CivicConfig.maxFeatured] (5).
List<FeaturedPoll> get featuredPolls =>
    [for (final p in appConfig.featured) if (p.enabled) p].take(appConfig.civic.maxFeatured).toList();

FeaturedPoll featuredById(String id) =>
    appConfig.featured.firstWhere((p) => p.id == id, orElse: () => defaultFeaturedPolls.firstWhere((p) => p.id == id));
