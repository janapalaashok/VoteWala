import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'traffic_env.dart';

@JS('Intl.DateTimeFormat')
extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external factory _DateTimeFormat();
  external _Resolved resolvedOptions();
}

extension type _Resolved._(JSObject _) implements JSObject {
  external String? get timeZone;
}

TrafficEnv readTrafficEnv() {
  var tz = '';
  try {
    tz = _DateTimeFormat().resolvedOptions().timeZone ?? '';
  } catch (_) {}
  final uri = Uri.base;
  return TrafficEnv(
    platform: 'web',
    userAgent: web.window.navigator.userAgent,
    referrer: web.document.referrer,
    timeZone: tz,
    language: web.window.navigator.language,
    landing: uri.fragment,
    query: uri.queryParameters,
  );
}
