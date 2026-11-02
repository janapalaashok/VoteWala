import 'package:flutter/widgets.dart';

import '../utils.dart';
import 'featured_polls.dart';

/// One answer of a daily poll.
class DailyOption {
  const DailyOption(this.en, this.te, {this.icon});

  final String en;
  final String te;

  /// Optional icon name from [featuredIcons] (jobs, school, hospital, farm...).
  final String? icon;

  IconData? get iconData => featuredIcons[icon];
  String label(bool telugu) => telugu && te.isNotEmpty ? te : en;

  Map<String, dynamic> toJson() => {'en': en, 'te': te, if (icon != null) 'icon': icon};

  factory DailyOption.fromJson(Map<String, dynamic> j) => DailyOption(
        j['en'] as String? ?? '',
        j['te'] as String? ?? '',
        icon: (j['icon'] as String?)?.isNotEmpty == true ? j['icon'] as String : null,
      );
}

/// "Today's poll": one question per day (India time), scheduled by admins.
/// Every voter answers it once, in a popup when the site opens.
class DailyPoll {
  const DailyPoll({
    required this.date,
    required this.questionEn,
    required this.questionTe,
    required this.options,
    this.imageUrl,
    this.slug,
  });

  /// yyyy-mm-dd (IST).
  final String date;

  /// Poster shown in the popup (the same picture shared on social media).
  final String? imageUrl;

  /// Short link name: `votewala.in/poll/<slug>`. Defaults to the date.
  final String? slug;

  String get linkName => slug ?? date;
  final String questionEn;
  final String questionTe;
  final List<DailyOption> options;

  String question(bool telugu) => telugu && questionTe.isNotEmpty ? questionTe : questionEn;

  bool get isToday => date == todayKey();

  /// "2 Nov 2026"
  String get dateLabel {
    final p = date.split('-').map(int.parse).toList();
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${p[2]} ${m[p[1] - 1]} ${p[0]}';
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'questionEn': questionEn,
    'questionTe': questionTe,
    'options': [for (final o in options) o.toJson()],
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (slug != null) 'slug': slug,
  };

  factory DailyPoll.fromJson(Map<String, dynamic> j) => DailyPoll(
    date: j['date'] as String? ?? '',
    questionEn: j['questionEn'] as String? ?? '',
    questionTe: j['questionTe'] as String? ?? '',
    options: [
      for (final o in (j['options'] as List? ?? const []))
        if (o is Map) DailyOption.fromJson(Map<String, dynamic>.from(o)),
    ],
    imageUrl: _text(j['imageUrl']),
    slug: _text(j['slug']),
  );

  static String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  /// Link names: lower-case letters, digits and dashes.
  static final slugPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,59}$');

  /// "AP Development Priority!" -> "ap-development-priority".
  static String slugify(String text) {
    final s = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return s.length > 60 ? s.substring(0, 60).replaceAll(RegExp(r'-+$'), '') : s;
  }

  static final _date = RegExp(r'^20\d\d-[01]\d-[0-3]\d$');

  /// Usable: a valid date, a question and 2 to 8 answers.
  bool get isValid =>
      _date.hasMatch(date) &&
      questionEn.trim().isNotEmpty &&
      options.length >= 2 &&
      options.length <= 8 &&
      options.every((o) => o.en.trim().isNotEmpty);
}

/// Today's date in India time, yyyy-mm-dd.
String todayKey([DateTime? ist]) {
  final d = ist ?? istNow();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
