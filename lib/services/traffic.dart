import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils.dart';
import 'firestore_client.dart';
import 'traffic_env.dart';
import 'traffic_env_io.dart' if (dart.library.js_interop) 'traffic_env_web.dart';

/// Set at start-up (null in tests and the demo build).
Traffic? traffic;

/// Records anonymous visits and sign-ins for the admin Traffic dashboard.
///
/// One document per visitor per day (traffic/{day}/visits/{visitorId}) with
/// device, OS, browser, country (from the device time zone), where the
/// visitor came from and the platform; one document per sign-in
/// (traffic/{day}/logins/{id}) with the method. No names, emails or IPs.
class Traffic {
  Traffic(this.store, this.prefs, {TrafficEnv? env}) : env = env ?? readTrafficEnv();

  final DocStore store;
  final SharedPreferences prefs;
  final TrafficEnv env;
  static final _rnd = Random.secure();

  static String today() {
    final d = istNow();
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _id(int n) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes([for (var i = 0; i < n; i++) chars.codeUnitAt(_rnd.nextInt(chars.length))]);
  }

  /// Anonymous id kept on this device, so a visitor counts once a day.
  String get visitorId {
    var id = prefs.getString('visitorId');
    if (id == null || id.length < 16) {
      id = _id(20);
      prefs.setString('visitorId', id);
    }
    return id;
  }

  /// Records today's visit once per device.
  Future<void> visit({bool signedIn = false}) async {
    final day = today();
    if (prefs.getString('visitDay') == day) return;
    try {
      await store.commit([
        Write.create('traffic/$day/visits/$visitorId', describe(env, signedIn: signedIn),
            const {'at': FieldTransform.serverTime()}),
      ]);
    } on StoreException catch (e) {
      if (e.error != StoreError.exists) {
        debugPrint('Visit not recorded: $e');
        return;
      }
    } catch (e) {
      debugPrint('Visit not recorded: $e');
      return;
    }
    await prefs.setString('visitDay', day);
  }

  /// Records a sign-in. [method] google | password | phone; [isNew] for the
  /// first sign-in (account created).
  Future<void> login(String method, {required bool isNew}) async {
    try {
      await store.commit([
        Write.create('traffic/${today()}/logins/${_id(20)}', {
          'method': const {'google', 'password', 'phone'}.contains(method) ? method : 'other',
          'kind': isNew ? 'signup' : 'login',
          'platform': env.platform,
        }, const {'at': FieldTransform.serverTime()}),
      ]);
    } catch (e) {
      debugPrint('Login not recorded: $e');
    }
  }

  /// The visit fields for [env] (pure, tested).
  static Map<String, Object?> describe(TrafficEnv env, {bool signedIn = false}) {
    final ua = env.userAgent;
    final ref = _host(env.referrer);
    return {
      'platform': env.platform,
      'device': deviceOf(env),
      'os': env.osName ?? osOf(ua),
      'browser': env.platform == 'web' ? browserOf(ua) : 'App',
      'country': countryOf(env.timeZone, env.language),
      'tz': _clip(env.timeZone),
      'lang': _clip(env.language),
      'source': sourceOf(env),
      'ref': _clip(ref),
      'landing': _clip(_landing(env.landing)),
      'signedIn': signedIn,
    };
  }

  static String _clip(String s) => s.length > 60 ? s.substring(0, 60) : s;

  static String _host(String url) {
    if (url.isEmpty) return '';
    try {
      return Uri.parse(url).host.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  static String _landing(String fragment) {
    final path = fragment.split('?').first;
    if (path.isEmpty || path == '/') return 'home';
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? 'home' : parts.take(2).join('/');
  }

  static String deviceOf(TrafficEnv env) {
    if (env.platform != 'web') return 'mobile';
    final ua = env.userAgent.toLowerCase();
    if (ua.contains('ipad') || (ua.contains('android') && !ua.contains('mobile')) || ua.contains('tablet')) {
      return 'tablet';
    }
    if (ua.contains('mobi') || ua.contains('iphone') || ua.contains('android')) return 'mobile';
    return 'desktop';
  }

  static String osOf(String ua) {
    final u = ua.toLowerCase();
    if (u.contains('android')) return 'Android';
    if (u.contains('iphone') || u.contains('ipad') || u.contains('ipod')) return 'iOS';
    if (u.contains('windows')) return 'Windows';
    if (u.contains('mac os') || u.contains('macintosh')) return 'macOS';
    if (u.contains('cros')) return 'ChromeOS';
    if (u.contains('linux')) return 'Linux';
    return 'Other';
  }

  static String browserOf(String ua) {
    final u = ua.toLowerCase();
    if (u.contains('fban') || u.contains('fbav') || u.contains('fb_iab')) return 'Facebook app';
    if (u.contains('instagram')) return 'Instagram app';
    if (u.contains('whatsapp')) return 'WhatsApp';
    if (u.contains('edg/')) return 'Edge';
    if (u.contains('opr/') || u.contains('opera')) return 'Opera';
    if (u.contains('samsungbrowser')) return 'Samsung Internet';
    if (u.contains('ucbrowser')) return 'UC Browser';
    if (u.contains('firefox') || u.contains('fxios')) return 'Firefox';
    if (u.contains('chrome') || u.contains('crios')) return 'Chrome';
    if (u.contains('safari')) return 'Safari';
    return 'Other';
  }

  /// Where the visitor came from: a utm_source / ?src= tag, the referring
  /// site, the in-app browser it opened in, or "direct".
  static String sourceOf(TrafficEnv env) {
    if (env.platform != 'web') return 'app';
    final tag = (env.query['utm_source'] ?? env.query['src'] ?? '').trim().toLowerCase();
    if (tag.isNotEmpty) return _clip(_tag(tag) ?? tag);
    final ua = env.userAgent.toLowerCase();
    final host = _host(env.referrer);
    final fromHost = host.isEmpty ? null : _site(host);
    if (fromHost != null) return fromHost;
    if (ua.contains('fban') || ua.contains('fbav')) return 'facebook';
    if (ua.contains('instagram')) return 'instagram';
    if (ua.contains('whatsapp')) return 'whatsapp';
    if (host.isEmpty || host.endsWith('votewala.in') || host.contains('votewala-a2dcd')) return 'direct';
    return _clip(host.replaceFirst('www.', ''));
  }

  /// Known sites by domain (exact or subdomain match).
  static String? _site(String host) {
    const domains = {
      'google.com': 'google', 'google.co.in': 'google', 'facebook.com': 'facebook', 'fb.com': 'facebook',
      'fb.me': 'facebook', 'instagram.com': 'instagram', 'whatsapp.com': 'whatsapp', 'wa.me': 'whatsapp',
      't.co': 'twitter', 'twitter.com': 'twitter', 'x.com': 'twitter', 'youtube.com': 'youtube',
      'youtu.be': 'youtube', 'linkedin.com': 'linkedin', 'lnkd.in': 'linkedin', 't.me': 'telegram',
      'telegram.org': 'telegram', 'bing.com': 'bing', 'yahoo.com': 'yahoo', 'duckduckgo.com': 'duckduckgo',
    };
    for (final e in domains.entries) {
      if (host == e.key || host.endsWith('.${e.key}')) return e.value;
    }
    if (host.startsWith('google.') || host.contains('.google.')) return 'google';
    return null;
  }

  /// utm_source / src tags such as "fb", "wa", "whatsapp", "share".
  static String? _tag(String tag) {
    const words = {
      'fb': 'facebook', 'facebook': 'facebook', 'ig': 'instagram', 'instagram': 'instagram', 'wa': 'whatsapp',
      'whatsapp': 'whatsapp', 'tw': 'twitter', 'twitter': 'twitter', 'x': 'twitter', 'yt': 'youtube',
      'youtube': 'youtube', 'telegram': 'telegram', 'google': 'google', 'share': 'share link',
    };
    return words[tag];
  }

  /// ISO country code from the device time zone (falls back to the language
  /// region, then "ZZ" = unknown).
  static String countryOf(String timeZone, String language) {
    final byZone = _zones[timeZone];
    if (byZone != null) return byZone;
    final prefix = timeZone.split('/').first;
    if (prefix == 'Australia') return 'AU';
    if (const {'IST'}.contains(timeZone)) return 'IN';
    final region = RegExp(r'[-_]([A-Za-z]{2})$').firstMatch(language)?.group(1);
    if (region != null && timeZone.isEmpty) return region.toUpperCase();
    return 'ZZ';
  }

  static const _zones = {
    'Asia/Kolkata': 'IN', 'Asia/Calcutta': 'IN',
    'America/New_York': 'US', 'America/Chicago': 'US', 'America/Denver': 'US', 'America/Los_Angeles': 'US',
    'America/Phoenix': 'US', 'America/Anchorage': 'US', 'America/Detroit': 'US', 'Pacific/Honolulu': 'US',
    'America/Indiana/Indianapolis': 'US', 'America/Boise': 'US',
    'America/Toronto': 'CA', 'America/Vancouver': 'CA', 'America/Edmonton': 'CA', 'America/Winnipeg': 'CA',
    'America/Halifax': 'CA', 'Europe/London': 'GB', 'Europe/Dublin': 'IE', 'Europe/Berlin': 'DE',
    'Europe/Paris': 'FR', 'Europe/Amsterdam': 'NL', 'Europe/Brussels': 'BE', 'Europe/Zurich': 'CH',
    'Europe/Rome': 'IT', 'Europe/Madrid': 'ES', 'Europe/Stockholm': 'SE', 'Europe/Oslo': 'NO',
    'Europe/Copenhagen': 'DK', 'Europe/Helsinki': 'FI', 'Europe/Warsaw': 'PL', 'Europe/Vienna': 'AT',
    'Europe/Lisbon': 'PT', 'Europe/Prague': 'CZ', 'Europe/Moscow': 'RU', 'Europe/Istanbul': 'TR',
    'Asia/Dubai': 'AE', 'Asia/Riyadh': 'SA', 'Asia/Qatar': 'QA', 'Asia/Kuwait': 'KW', 'Asia/Muscat': 'OM',
    'Asia/Bahrain': 'BH', 'Asia/Singapore': 'SG', 'Asia/Kuala_Lumpur': 'MY', 'Asia/Tokyo': 'JP',
    'Asia/Hong_Kong': 'HK', 'Asia/Shanghai': 'CN', 'Asia/Dhaka': 'BD', 'Asia/Kathmandu': 'NP',
    'Asia/Katmandu': 'NP', 'Asia/Colombo': 'LK', 'Asia/Karachi': 'PK', 'Asia/Bangkok': 'TH',
    'Asia/Jakarta': 'ID', 'Asia/Manila': 'PH', 'Asia/Seoul': 'KR', 'Asia/Ho_Chi_Minh': 'VN',
    'Pacific/Auckland': 'NZ', 'Africa/Johannesburg': 'ZA', 'Africa/Nairobi': 'KE', 'Africa/Lagos': 'NG',
    'Africa/Cairo': 'EG', 'America/Sao_Paulo': 'BR', 'America/Mexico_City': 'MX',
  };
}
