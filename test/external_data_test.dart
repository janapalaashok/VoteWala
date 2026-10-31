import 'package:flutter_test/flutter_test.dart';
import 'package:votewala/data/external_data.dart';
import 'package:votewala/data/external_votes.dart';
import 'package:votewala/data/featured_polls.dart';
import 'package:votewala/data/poll_month.dart';

void main() {
  final cm = defaultFeaturedPolls.firstWhere((p) => p.id == 'cm-2026');

  test('Facebook CM votes map to the poll options by name', () {
    expect(externalFeaturedVotes(cm, '2026-01'), [298, 72, 52, 8, 3]);
    expect(externalFeaturedVotes(cm, '2026-10'), [82, 65, 32, 3, 2]);
    expect(externalFeaturedVotes(cm, '2026-11'), [0, 0, 0, 0, 0]);
    expect(externalMonths(cm).length, 10);
  });

  test('labelled only for January to October 2026', () {
    expect(hasExternalFeatured(cm, const PollMonth(2026, 1)), isTrue);
    expect(hasExternalFeatured(cm, const PollMonth(2026, 10)), isTrue);
    expect(hasExternalFeatured(cm, const PollMonth(2026, 11)), isFalse);
    expect(ExternalData.assembly.containsKey('2026-11'), isFalse);
  });

  test('constituency totals match the workbook monthly summary', () {
    const summary = {
      '2026-01': 683, '2026-02': 847, '2026-03': 726, '2026-04': 958, '2026-05': 1087,
      '2026-06': 1193, '2026-07': 1327, '2026-08': 1469, '2026-09': 1673, '2026-10': 1841,
    };
    for (final e in summary.entries) {
      expect(ExternalData.assembly[e.key]!.values.fold(0, (a, b) => a + b), e.value, reason: e.key);
      expect(ExternalData.assembly[e.key]!.keys.every((no) => no >= 1 && no <= 175), isTrue);
    }
  });
}
