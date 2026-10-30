import 'package:flutter/material.dart';

import '../config/config_service.dart';

/// Icons an admin can pick for local-issue categories and priorities.
const civicIcons = <String, IconData>{
  'road': Icons.add_road,
  'drain': Icons.water_damage,
  'water': Icons.water_drop,
  'light': Icons.lightbulb,
  'garbage': Icons.delete,
  'park': Icons.park,
  'bus': Icons.directions_bus,
  'safety': Icons.local_police,
  'health': Icons.local_hospital,
  'school': Icons.school,
  'work': Icons.work,
  'power': Icons.bolt,
  'home': Icons.home_work,
  'farm': Icons.agriculture,
  'other': Icons.more_horiz,
};

/// A local development category voted GOOD / BAD per constituency. [slot]
/// (c0..c11) is the permanent key in the database, so renaming a category
/// keeps its votes; a new category needs an unused slot.
class CivicCategory {
  const CivicCategory(this.slot, this.en, this.te, this.icon, {this.enabled = true});

  final String slot;
  final String en, te, icon;
  final bool enabled;

  String label(bool telugu) => telugu ? te : en;
  IconData get iconData => civicIcons[icon] ?? Icons.label;
  bool get isOther => icon == 'other';

  CivicCategory copyWith({String? en, String? te, String? icon, bool? enabled}) =>
      CivicCategory(slot, en ?? this.en, te ?? this.te, icon ?? this.icon, enabled: enabled ?? this.enabled);

  Map<String, dynamic> toJson() => {'slot': slot, 'en': en, 'te': te, 'icon': icon, 'enabled': enabled};

  factory CivicCategory.fromJson(Map<String, dynamic> j) => CivicCategory(
        j['slot'] as String,
        j['en'] as String? ?? '',
        j['te'] as String? ?? '',
        j['icon'] as String? ?? 'other',
        enabled: j['enabled'] as bool? ?? true,
      );
}

/// An option for "If you were the MLA, what would you fix first?". The
/// position in the list is the stored option number, so options are only
/// renamed or appended, never reordered.
class PriorityOption {
  const PriorityOption(this.en, this.te, this.icon);

  final String en, te, icon;

  String label(bool telugu) => telugu ? te : en;
  IconData get iconData => civicIcons[icon] ?? Icons.label;

  Map<String, dynamic> toJson() => {'en': en, 'te': te, 'icon': icon};

  factory PriorityOption.fromJson(Map<String, dynamic> j) =>
      PriorityOption(j['en'] as String? ?? '', j['te'] as String? ?? '', j['icon'] as String? ?? 'other');
}

/// A participation badge. Milestones are mirrored in Firestore
/// settings/badges, which the security rules check.
class BadgeDef {
  const BadgeDef(this.id, this.en, this.te, this.milestone, this.icon, this.color);

  final String id;
  final String en, te;
  final int milestone;
  final String icon;
  final int color;

  String label(bool telugu) => telugu ? te : en;
  Color get colorValue => Color(color);
  IconData get iconData => _badgeIcons[icon] ?? Icons.military_tech;

  BadgeDef copyWith({String? en, String? te, int? milestone}) =>
      BadgeDef(id, en ?? this.en, te ?? this.te, milestone ?? this.milestone, icon, color);

  Map<String, dynamic> toJson() => {'id': id, 'en': en, 'te': te, 'milestone': milestone, 'icon': icon, 'color': color};

  factory BadgeDef.fromJson(Map<String, dynamic> j, BadgeDef fallback) => BadgeDef(
        fallback.id,
        j['en'] as String? ?? fallback.en,
        j['te'] as String? ?? fallback.te,
        (j['milestone'] as num?)?.toInt() ?? fallback.milestone,
        fallback.icon,
        fallback.color,
      );
}

const _badgeIcons = <String, IconData>{
  'mic': Icons.record_voice_over,
  'campaign': Icons.campaign,
  'citizen': Icons.how_to_vote,
  'people': Icons.groups,
  'trophy': Icons.emoji_events,
  'crown': Icons.workspace_premium,
};

const defaultBadges = [
  BadgeDef('first-voice', 'First Voice', 'మొదటి గళం', 1, 'mic', 0xFF2E7D32),
  BadgeDef('active-voice', 'Active Voice', 'చురుకైన గళం', 5, 'campaign', 0xFF1565C0),
  BadgeDef('active-citizen', 'Active Citizen', 'చురుకైన పౌరుడు', 10, 'citizen', 0xFF6A1B9A),
  BadgeDef('peoples-voice', "People's Voice", 'ప్రజల గళం', 25, 'people', 0xFFEF6C00),
  BadgeDef('community-champion', 'Community Champion', 'సమాజ ఛాంపియన్', 50, 'trophy', 0xFFC62828),
  BadgeDef('peoples-ambassador', "People's Ambassador", 'ప్రజా రాయబారి', 100, 'crown', 0xFFB8860B),
];

const defaultCategories = [
  CivicCategory('c0', 'Roads & Infrastructure', 'రోడ్లు & మౌలిక వసతులు', 'road'),
  CivicCategory('c1', 'Drainage & Sewage', 'డ్రైనేజీ & మురుగు', 'drain'),
  CivicCategory('c2', 'Drinking Water Supply', 'తాగునీటి సరఫరా', 'water'),
  CivicCategory('c3', 'Street Lighting', 'వీధి దీపాలు', 'light'),
  CivicCategory('c4', 'Garbage & Sanitation', 'చెత్త & పారిశుద్ధ్యం', 'garbage'),
  CivicCategory('c5', 'Parks & Greenery', 'పార్కులు & పచ్చదనం', 'park'),
  CivicCategory('c6', 'Public Transportation', 'ప్రజా రవాణా', 'bus'),
  CivicCategory('c7', 'Public Safety', 'ప్రజా భద్రత', 'safety'),
  CivicCategory('c8', 'Healthcare Facilities', 'వైద్య సదుపాయాలు', 'health'),
  CivicCategory('c9', 'Other', 'ఇతరాలు', 'other'),
];

const defaultPriorities = [
  PriorityOption('Roads & Infrastructure', 'రోడ్లు & మౌలిక వసతులు', 'road'),
  PriorityOption('Drinking Water', 'తాగునీరు', 'water'),
  PriorityOption('Drainage', 'డ్రైనేజీ', 'drain'),
  PriorityOption('Healthcare', 'వైద్యం', 'health'),
  PriorityOption('Education', 'విద్య', 'school'),
  PriorityOption('Employment', 'ఉపాధి', 'work'),
  PriorityOption('Public Transportation', 'ప్రజా రవాణా', 'bus'),
  PriorityOption('Street Lighting', 'వీధి దీపాలు', 'light'),
  PriorityOption('Garbage & Sanitation', 'చెత్త & పారిశుద్ధ్యం', 'garbage'),
  PriorityOption('Parks & Greenery', 'పార్కులు & పచ్చదనం', 'park'),
  PriorityOption('Public Safety', 'ప్రజా భద్రత', 'safety'),
  PriorityOption('Other', 'ఇతరాలు', 'other'),
];

/// Settings for local issues, MLA priorities, badges and share cards.
class CivicConfig {
  const CivicConfig({
    this.categories = defaultCategories,
    this.priorities = defaultPriorities,
    this.badges = defaultBadges,
    this.shareMessageEn = 'I just shared my voice on VoteWala!',
    this.shareMessageTe = 'నేను VoteWalaలో నా అభిప్రాయం చెప్పాను!',
    this.shareShowChoiceDefault = false,
    this.maxFeatured = 5,
  });

  final List<CivicCategory> categories;
  final List<PriorityOption> priorities;
  final List<BadgeDef> badges;
  final String shareMessageEn, shareMessageTe;

  /// Whether "Show my choice on the card" starts switched on.
  final bool shareShowChoiceDefault;

  /// Featured polls shown at once on the home page.
  final int maxFeatured;

  List<CivicCategory> get activeCategories => [for (final c in categories) if (c.enabled) c];
  String shareMessage(bool telugu) => telugu ? shareMessageTe : shareMessageEn;

  CivicConfig copyWith({
    List<CivicCategory>? categories,
    List<PriorityOption>? priorities,
    List<BadgeDef>? badges,
    String? shareMessageEn,
    String? shareMessageTe,
    bool? shareShowChoiceDefault,
  }) =>
      CivicConfig(
        categories: categories ?? this.categories,
        priorities: priorities ?? this.priorities,
        badges: badges ?? this.badges,
        shareMessageEn: shareMessageEn ?? this.shareMessageEn,
        shareMessageTe: shareMessageTe ?? this.shareMessageTe,
        shareShowChoiceDefault: shareShowChoiceDefault ?? this.shareShowChoiceDefault,
        maxFeatured: maxFeatured,
      );

  Map<String, dynamic> toJson() => {
        'categories': [for (final c in categories) c.toJson()],
        'priorities': [for (final p in priorities) p.toJson()],
        'badges': [for (final b in badges) b.toJson()],
        'shareMessageEn': shareMessageEn,
        'shareMessageTe': shareMessageTe,
        'shareShowChoiceDefault': shareShowChoiceDefault,
      };

  factory CivicConfig.fromJson(Map<String, dynamic> j) {
    const d = CivicConfig();
    List<Map<String, dynamic>> maps(Object? v) =>
        v is List ? [for (final x in v) if (x is Map) Map<String, dynamic>.from(x)] : const [];
    final badgeJson = {for (final b in maps(j['badges'])) b['id']: b};
    final categories = [
      for (final c in maps(j['categories']))
        if (RegExp(r'^c([0-9]|1[01])$').hasMatch(c['slot'] as String? ?? '')) CivicCategory.fromJson(c),
    ];
    final priorities = [for (final p in maps(j['priorities'])) PriorityOption.fromJson(p)];
    return CivicConfig(
      categories: categories.isEmpty ? d.categories : categories,
      priorities: priorities.isEmpty ? d.priorities : priorities,
      badges: [for (final b in defaultBadges) badgeJson[b.id] == null ? b : BadgeDef.fromJson(badgeJson[b.id]!, b)],
      shareMessageEn: j['shareMessageEn'] as String? ?? d.shareMessageEn,
      shareMessageTe: j['shareMessageTe'] as String? ?? d.shareMessageTe,
      shareShowChoiceDefault: j['shareShowChoiceDefault'] as bool? ?? d.shareShowChoiceDefault,
    );
  }
}

CivicConfig get civic => appConfig.civic;

CivicCategory? categoryBySlot(String slot) => civic.categories.where((c) => c.slot == slot).firstOrNull;

BadgeDef? badgeById(String id) => civic.badges.where((b) => b.id == id).firstOrNull;
