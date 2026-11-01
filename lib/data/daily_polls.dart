import '../utils.dart';

/// One answer of a daily poll.
class DailyOption {
  const DailyOption(this.en, this.te);

  final String en;
  final String te;

  String label(bool telugu) => telugu && te.isNotEmpty ? te : en;

  Map<String, dynamic> toJson() => {'en': en, 'te': te};

  factory DailyOption.fromJson(Map<String, dynamic> j) =>
      DailyOption(j['en'] as String? ?? '', j['te'] as String? ?? '');
}

/// "Today's poll": one question per day (India time), scheduled by admins.
/// Every voter answers it once, in a popup when the site opens.
class DailyPoll {
  const DailyPoll({required this.date, required this.questionEn, required this.questionTe, required this.options});

  /// yyyy-mm-dd (IST).
  final String date;
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
  };

  factory DailyPoll.fromJson(Map<String, dynamic> j) => DailyPoll(
    date: j['date'] as String? ?? '',
    questionEn: j['questionEn'] as String? ?? '',
    questionTe: j['questionTe'] as String? ?? '',
    options: [
      for (final o in (j['options'] as List? ?? const []))
        if (o is Map) DailyOption.fromJson(Map<String, dynamic>.from(o)),
    ],
  );

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
