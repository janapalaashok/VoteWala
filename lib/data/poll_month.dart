import '../utils.dart';

/// A monthly poll period. Constituency polls run from the 1st of the month
/// to the end of the month (IST).
class PollMonth implements Comparable<PollMonth> {
  const PollMonth(this.year, this.month);

  factory PollMonth.of(DateTime d) => PollMonth(d.year, d.month);

  /// The month VoteWala polls started.
  static const first = PollMonth(2026, 1);

  static PollMonth current() => PollMonth.of(istNow());

  final int year;
  final int month;

  /// Start (inclusive) and end (exclusive), as IST wall-clock times.
  DateTime get start => DateTime.utc(year, month);
  DateTime get end => DateTime.utc(year, month + 1);

  int get index => year * 12 + month - 1;
  String get key => '$year-${month.toString().padLeft(2, '0')}';
  PollMonth get previous => PollMonth.of(DateTime.utc(year, month - 1));
  PollMonth get next => PollMonth.of(DateTime.utc(year, month + 1));

  bool get isCurrent => this == current();
  bool get isPast => compareTo(current()) < 0;

  /// Share of this month that has elapsed (1 for past months).
  double get elapsed {
    if (isPast) return 1;
    final n = istNow();
    return (n.difference(start).inMinutes / end.difference(start).inMinutes).clamp(0.0, 1.0);
  }

  static PollMonth parse(String key) {
    final p = key.split('-').map(int.parse).toList();
    return PollMonth(p[0], p[1]);
  }

  /// Months with polls, newest first.
  static List<PollMonth> available() {
    final list = <PollMonth>[];
    for (var m = current(); m.compareTo(first) >= 0; m = m.previous) {
      list.add(m);
    }
    return list;
  }

  static const _en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
    'October', 'November', 'December'];
  static const _te = ['జనవరి', 'ఫిబ్రవరి', 'మార్చి', 'ఏప్రిల్', 'మే', 'జూన్', 'జూలై', 'ఆగస్టు', 'సెప్టెంబర్',
    'అక్టోబర్', 'నవంబర్', 'డిసెంబర్'];

  String monthName(bool telugu) => (telugu ? _te : _en)[month - 1];
  String label(bool telugu) => '${monthName(telugu)} $year';
  String shortLabel(bool telugu) => telugu ? _te[month - 1] : _en[month - 1].substring(0, 3);

  @override
  int compareTo(PollMonth other) => index.compareTo(other.index);

  @override
  bool operator ==(Object other) => other is PollMonth && other.index == index;

  @override
  int get hashCode => index;
}
