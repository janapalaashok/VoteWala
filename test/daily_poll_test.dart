import 'package:flutter_test/flutter_test.dart';
import 'package:votewala/config/app_config.dart';
import 'package:votewala/data/daily_polls.dart';

void main() {
  const poll = DailyPoll(
    date: '2026-11-02',
    questionEn: 'Should Amaravati be the only capital?',
    questionTe: 'అమరావతి ఒక్కటే రాజధానిగా ఉండాలా?',
    options: [DailyOption('Yes', 'అవును'), DailyOption('No', 'కాదు')],
  );

  test('daily polls survive the published config round trip', () {
    final config = AppConfig.defaults().copyWith(daily: [poll]);
    final back = AppConfig.fromJson(config.toJson());
    expect(back.daily.single.date, '2026-11-02');
    expect(back.daily.single.options.map((o) => o.en), ['Yes', 'No']);
    expect(back.daily.single.question(true), 'అమరావతి ఒక్కటే రాజధానిగా ఉండాలా?');
    expect(AppConfig.fromJson({}).daily, isEmpty);
  });

  test('validity, labels and India date', () {
    expect(poll.isValid, isTrue);
    expect(poll.dateLabel, '2 Nov 2026');
    expect(const DailyPoll(date: '2026-11-02', questionEn: 'Q', questionTe: '', options: [DailyOption('A', '')]).isValid,
        isFalse);
    expect(todayKey(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
