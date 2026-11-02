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

  test('poster, link name and icons survive the round trip', () {
    const withPoster = DailyPoll(
      date: '2026-11-03',
      questionEn: 'Which sector first?',
      questionTe: '',
      options: [DailyOption('Jobs', 'ఉద్యోగాలు', icon: 'jobs'), DailyOption('Education', 'విద్య', icon: 'school')],
      imageUrl: 'https://example.com/poster.png',
      slug: 'ap-development-priority',
    );
    final back = DailyPoll.fromJson(withPoster.toJson());
    expect(back.imageUrl, 'https://example.com/poster.png');
    expect(back.linkName, 'ap-development-priority');
    expect(back.options.first.iconData, isNotNull);
    expect(poll.linkName, '2026-11-02');
    expect(DailyPoll.slugify('AP Development Priority!'), 'ap-development-priority');
    expect(DailyPoll.slugify('  ఏ రంగం? '), '');
  });
}
