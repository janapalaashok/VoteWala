import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/civic.dart';
import '../data/daily_polls.dart';
import '../l10n/legal.dart';
import '../data/featured_polls.dart';

/// Brand settings an admin can change.
class BrandingConfig {
  const BrandingConfig({
    this.appName = 'VoteWala',
    this.taglineEn = 'Your Voice. Your Choice.',
    this.taglineTe = 'మీ అభిప్రాయం. మీ ఎంపిక.',
    this.primary = const Color(0xFFF47A1F),
    this.secondary = const Color(0xFF1E9A3F),
    this.logoUrl,
    this.markUrl,
    this.appIconUrl,
    this.contactEmail = 'contact@votewala.in',
  });

  final String appName;
  final String taglineEn;
  final String taglineTe;
  final Color primary;
  final Color secondary;

  /// Uploaded images; null means the bundled assets are used.
  final String? logoUrl;
  final String? markUrl;

  /// Used by the next app build (installed apps cannot change their icon).
  final String? appIconUrl;

  /// Shown on the legal pages for privacy requests and grievances.
  final String? contactEmail;

  String tagline(bool te) => te ? taglineTe : taglineEn;

  BrandingConfig copyWith({
    String? appName,
    String? taglineEn,
    String? taglineTe,
    Color? primary,
    Color? secondary,
    String? logoUrl,
    String? markUrl,
    String? appIconUrl,
    String? contactEmail,
    bool clearLogo = false,
    bool clearMark = false,
    bool clearAppIcon = false,
  }) =>
      BrandingConfig(
        appName: appName ?? this.appName,
        taglineEn: taglineEn ?? this.taglineEn,
        taglineTe: taglineTe ?? this.taglineTe,
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        logoUrl: clearLogo ? null : logoUrl ?? this.logoUrl,
        markUrl: clearMark ? null : markUrl ?? this.markUrl,
        appIconUrl: clearAppIcon ? null : appIconUrl ?? this.appIconUrl,
        contactEmail: contactEmail == null ? this.contactEmail : (contactEmail.isEmpty ? null : contactEmail),
      );

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'taglineEn': taglineEn,
        'taglineTe': taglineTe,
        'primary': colorToHex(primary),
        'secondary': colorToHex(secondary),
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (markUrl != null) 'markUrl': markUrl,
        if (appIconUrl != null) 'appIconUrl': appIconUrl,
        if (contactEmail != null) 'contactEmail': contactEmail,
      };

  factory BrandingConfig.fromJson(Map<String, dynamic> j) {
    const d = BrandingConfig();
    return BrandingConfig(
      appName: _str(j['appName']) ?? d.appName,
      taglineEn: _str(j['taglineEn']) ?? d.taglineEn,
      taglineTe: _str(j['taglineTe']) ?? d.taglineTe,
      primary: colorFromHex(j['primary'] as String?) ?? d.primary,
      secondary: colorFromHex(j['secondary'] as String?) ?? d.secondary,
      logoUrl: _str(j['logoUrl']),
      markUrl: _str(j['markUrl']),
      appIconUrl: _str(j['appIconUrl']),
      contactEmail: _str(j['contactEmail']) ?? d.contactEmail,
    );
  }
}

/// Admin edits to a 2024 candidate (null fields keep the official data).
class CandidateOverride {
  const CandidateOverride({this.name, this.nameTe, this.photoUrl, this.partyId});

  final String? name;
  final String? nameTe;
  final String? photoUrl;
  final String? partyId;

  bool get isEmpty => name == null && nameTe == null && photoUrl == null && partyId == null;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (nameTe != null) 'nameTe': nameTe,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (partyId != null) 'partyId': partyId,
      };

  factory CandidateOverride.fromJson(Map<String, dynamic> j) => CandidateOverride(
        name: _str(j['name']),
        nameTe: _str(j['nameTe']),
        photoUrl: _str(j['photoUrl']),
        partyId: _str(j['partyId']),
      );
}

class NamePair {
  const NamePair({this.en, this.te});

  final String? en;
  final String? te;

  bool get isEmpty => en == null && te == null;

  Map<String, dynamic> toJson() => {if (en != null) 'en': en, if (te != null) 'te': te};

  factory NamePair.fromJson(Map<String, dynamic> j) => NamePair(en: _str(j['en']), te: _str(j['te']));
}

/// Home page / website content.
class HomeConfig {
  const HomeConfig({
    this.topMla = const ['mla-129', 'mla-175', 'mla-37', 'mla-87', 'mla-157'],
    this.topMp = const ['mp-4', 'mp-23', 'mp-21', 'mp-5', 'mp-12'],
    this.showMonthlyVotes = true,
    this.showTopSeats = true,
    this.showFeatured = true,
    this.heroTitleEn,
    this.heroTitleTe,
    this.heroSubtitleEn,
    this.heroSubtitleTe,
  });

  final List<String> topMla;
  final List<String> topMp;
  final bool showMonthlyVotes;
  final bool showTopSeats;
  final bool showFeatured;

  /// Null uses the built-in text.
  final String? heroTitleEn, heroTitleTe, heroSubtitleEn, heroSubtitleTe;

  HomeConfig copyWith({
    List<String>? topMla,
    List<String>? topMp,
    bool? showMonthlyVotes,
    bool? showTopSeats,
    bool? showFeatured,
    String? heroTitleEn,
    String? heroTitleTe,
    String? heroSubtitleEn,
    String? heroSubtitleTe,
  }) =>
      HomeConfig(
        topMla: topMla ?? this.topMla,
        topMp: topMp ?? this.topMp,
        showMonthlyVotes: showMonthlyVotes ?? this.showMonthlyVotes,
        showTopSeats: showTopSeats ?? this.showTopSeats,
        showFeatured: showFeatured ?? this.showFeatured,
        heroTitleEn: _str(heroTitleEn ?? this.heroTitleEn),
        heroTitleTe: _str(heroTitleTe ?? this.heroTitleTe),
        heroSubtitleEn: _str(heroSubtitleEn ?? this.heroSubtitleEn),
        heroSubtitleTe: _str(heroSubtitleTe ?? this.heroSubtitleTe),
      );

  Map<String, dynamic> toJson() => {
        'topMla': topMla,
        'topMp': topMp,
        'showMonthlyVotes': showMonthlyVotes,
        'showTopSeats': showTopSeats,
        'showFeatured': showFeatured,
        if (heroTitleEn != null) 'heroTitleEn': heroTitleEn,
        if (heroTitleTe != null) 'heroTitleTe': heroTitleTe,
        if (heroSubtitleEn != null) 'heroSubtitleEn': heroSubtitleEn,
        if (heroSubtitleTe != null) 'heroSubtitleTe': heroSubtitleTe,
      };

  factory HomeConfig.fromJson(Map<String, dynamic> j) {
    const d = HomeConfig();
    List<String> ids(Object? v, List<String> fallback) =>
        v is List ? [for (final x in v) if (x is String) x] : fallback;
    return HomeConfig(
      topMla: ids(j['topMla'], d.topMla),
      topMp: ids(j['topMp'], d.topMp),
      showMonthlyVotes: j['showMonthlyVotes'] as bool? ?? true,
      showTopSeats: j['showTopSeats'] as bool? ?? true,
      showFeatured: j['showFeatured'] as bool? ?? true,
      heroTitleEn: _str(j['heroTitleEn']),
      heroTitleTe: _str(j['heroTitleTe']),
      heroSubtitleEn: _str(j['heroSubtitleEn']),
      heroSubtitleTe: _str(j['heroSubtitleTe']),
    );
  }
}

/// Everything the admin panel controls. Stored as one JSON document.
class AppConfig {
  const AppConfig({
    required this.branding,
    required this.parties,
    required this.candidates,
    required this.constituencyNames,
    required this.featured,
    required this.home,
    this.civic = const CivicConfig(),
    this.legal = const {},
    this.daily = const [],
    this.updatedAt,
    this.updatedBy,
  });

  factory AppConfig.defaults() => AppConfig(
        branding: const BrandingConfig(),
        parties: List.of(defaultParties),
        candidates: const {},
        constituencyNames: const {},
        featured: List.of(defaultFeaturedPolls),
        home: const HomeConfig(),
      );

  final BrandingConfig branding;
  final List<Party> parties;
  final Map<String, CandidateOverride> candidates;
  final Map<String, NamePair> constituencyNames;
  final List<FeaturedPoll> featured;
  final HomeConfig home;
  final CivicConfig civic;

  /// Edited policy pages by id (see l10n/legal.dart).
  final Map<String, LegalDoc> legal;

  /// "Today's poll" questions scheduled by date (see data/daily_polls.dart).
  final List<DailyPoll> daily;
  final DateTime? updatedAt;
  final String? updatedBy;

  AppConfig copyWith({
    BrandingConfig? branding,
    List<Party>? parties,
    Map<String, CandidateOverride>? candidates,
    Map<String, NamePair>? constituencyNames,
    List<FeaturedPoll>? featured,
    HomeConfig? home,
    CivicConfig? civic,
    Map<String, LegalDoc>? legal,
    List<DailyPoll>? daily,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      AppConfig(
        branding: branding ?? this.branding,
        parties: parties ?? this.parties,
        candidates: candidates ?? this.candidates,
        constituencyNames: constituencyNames ?? this.constituencyNames,
        featured: featured ?? this.featured,
        home: home ?? this.home,
        civic: civic ?? this.civic,
        legal: legal ?? this.legal,
        daily: daily ?? this.daily,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  Map<String, dynamic> toJson() => {
        'schema': 1,
        'branding': branding.toJson(),
        'parties': [for (final p in parties) p.toJson()],
        'candidates': {
          for (final e in candidates.entries)
            if (!e.value.isEmpty) e.key: e.value.toJson(),
        },
        'constituencyNames': {
          for (final e in constituencyNames.entries)
            if (!e.value.isEmpty) e.key: e.value.toJson(),
        },
        'featured': [for (final f in featured) f.toJson()],
        'home': home.toJson(),
        'civic': civic.toJson(),
        'legal': {for (final e in legal.entries) e.key: e.value.toJson()},
        'daily': [for (final d in daily) d.toJson()],
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (updatedBy != null) 'updatedBy': updatedBy,
      };

  /// Missing sections fall back to the defaults, so older documents keep working.
  factory AppConfig.fromJson(Map<String, dynamic> j) {
    final d = AppConfig.defaults();
    Map<String, dynamic> map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};
    final parties = j['parties'] is List
        ? [for (final p in j['parties'] as List) Party.fromJson(Map<String, dynamic>.from(p as Map))]
        : d.parties;
    // Keep every built-in party available even if the document lacks one.
    for (final p in defaultParties) {
      if (!parties.any((x) => x.id == p.id)) parties.add(p);
    }
    return AppConfig(
      branding: j['branding'] is Map ? BrandingConfig.fromJson(map(j['branding'])) : d.branding,
      parties: parties,
      candidates: {
        for (final e in map(j['candidates']).entries) e.key: CandidateOverride.fromJson(map(e.value)),
      },
      constituencyNames: {
        for (final e in map(j['constituencyNames']).entries) e.key: NamePair.fromJson(map(e.value)),
      },
      featured: j['featured'] is List
          ? [for (final f in j['featured'] as List) FeaturedPoll.fromJson(Map<String, dynamic>.from(f as Map))]
          : d.featured,
      home: j['home'] is Map ? HomeConfig.fromJson(map(j['home'])) : d.home,
      civic: j['civic'] is Map ? CivicConfig.fromJson(map(j['civic'])) : d.civic,
      legal: {
        for (final e in map(j['legal']).entries)
          if (defaultLegalDocs.where((x) => x.id == e.key).firstOrNull case final base?)
            e.key: LegalDoc.fromJson(e.key, map(e.value), base),
      },
      daily: [
        for (final d in (j['daily'] as List? ?? const []))
          if (d is Map) DailyPoll.fromJson(Map<String, dynamic>.from(d)),
      ],
      updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
      updatedBy: _str(j['updatedBy']),
    );
  }
}

String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
