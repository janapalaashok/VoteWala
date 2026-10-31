import 'package:flutter_test/flutter_test.dart';
import 'package:votewala/admin/traffic_stats.dart';
import 'package:votewala/services/traffic.dart';
import 'package:votewala/services/traffic_env.dart';

const _androidChrome = 'Mozilla/5.0 (Linux; Android 14; SM-A546E) AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/130.0 Mobile Safari/537.36';
const _fbApp = 'Mozilla/5.0 (Linux; Android 13; RMX3371) AppleWebKit/537.36 Chrome/129.0 Mobile Safari/537.36 '
    '[FB_IAB/FB4A;FBAV/485.0.0.0;]';
const _windowsEdge = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/130.0 Safari/537.36 Edg/130.0';
const _iphone = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 Version/17.5 Mobile/15E148 Safari/604.1';

void main() {
  test('visit fields from a phone opened from Facebook', () {
    final v = Traffic.describe(const TrafficEnv(
      platform: 'web',
      userAgent: _fbApp,
      referrer: 'https://m.facebook.com/',
      timeZone: 'Asia/Kolkata',
      language: 'te-IN',
      landing: '/f/cm-2026',
    ));
    expect(v['device'], 'mobile');
    expect(v['os'], 'Android');
    expect(v['browser'], 'Facebook app');
    expect(v['source'], 'facebook');
    expect(v['country'], 'IN');
    expect(v['landing'], 'f/cm-2026');
  });

  test('sources', () {
    TrafficEnv web(String ua, {String ref = '', Map<String, String> q = const {}}) =>
        TrafficEnv(platform: 'web', userAgent: ua, referrer: ref, query: q);
    expect(Traffic.sourceOf(web(_windowsEdge)), 'direct');
    expect(Traffic.sourceOf(web(_windowsEdge, ref: 'https://www.google.co.in/')), 'google');
    expect(Traffic.sourceOf(web(_androidChrome, ref: 'https://t.co/abc')), 'twitter');
    expect(Traffic.sourceOf(web(_androidChrome, ref: 'https://www.reddit.com/r/andhra')), 'reddit.com');
    expect(Traffic.sourceOf(web(_androidChrome, ref: 'https://votewala.in/')), 'direct');
    expect(Traffic.sourceOf(web(_androidChrome, q: {'src': 'wa'})), 'whatsapp');
    expect(Traffic.sourceOf(web(_androidChrome, q: {'utm_source': 'Newsletter'})), 'newsletter');
    expect(Traffic.sourceOf(const TrafficEnv(platform: 'android')), 'app');
  });

  test('devices, systems and browsers', () {
    expect(Traffic.deviceOf(const TrafficEnv(platform: 'web', userAgent: _windowsEdge)), 'desktop');
    expect(Traffic.deviceOf(const TrafficEnv(platform: 'web', userAgent: _iphone)), 'mobile');
    expect(Traffic.osOf(_windowsEdge), 'Windows');
    expect(Traffic.osOf(_iphone), 'iOS');
    expect(Traffic.browserOf(_windowsEdge), 'Edge');
    expect(Traffic.browserOf(_iphone), 'Safari');
    expect(Traffic.browserOf(_androidChrome), 'Chrome');
  });

  test('countries from time zones', () {
    expect(Traffic.countryOf('Asia/Kolkata', 'en-US'), 'IN');
    expect(Traffic.countryOf('America/Chicago', 'en-US'), 'US');
    expect(Traffic.countryOf('Asia/Dubai', 'te-IN'), 'AE');
    expect(Traffic.countryOf('Australia/Perth', ''), 'AU');
    expect(Traffic.countryOf('IST', 'en_US'), 'IN');
    expect(Traffic.countryOf('Mars/Base', 'en-US'), 'ZZ');
  });

  test('dashboard totals', () {
    final days = TrafficStats.lastDays(DateTime.utc(2026, 11, 2), 3);
    expect(days, ['2026-10-31', '2026-11-01', '2026-11-02']);
    final s = TrafficStats(days, {
      '2026-11-01': {
        'a': {'country': 'IN', 'device': 'mobile', 'source': 'facebook', 'platform': 'web', 'signedIn': true},
        'b': {'country': 'US', 'device': 'desktop', 'source': 'direct', 'platform': 'web'},
      },
      '2026-11-02': {
        'a': {'country': 'IN', 'device': 'mobile', 'source': 'whatsapp', 'platform': 'android'},
      },
    }, {
      '2026-11-02': {
        'x': {'method': 'google', 'kind': 'signup'},
        'y': {'method': 'password', 'kind': 'login'},
      },
    });
    expect(s.visits, 3);
    expect(s.today, 1);
    expect(s.countries, {'IN': 2, 'US': 1});
    expect(s.signups, 1);
    expect(s.signIns, 1);
    expect(s.loginMethods, {'google': 1, 'password': 1});
    expect(s.busiestDay, '2026-11-01');
    expect(s.signedInVisitors, 1);
  });
}
