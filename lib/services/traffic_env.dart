/// What the visitor's browser or phone reports about itself.
class TrafficEnv {
  const TrafficEnv({
    required this.platform,
    this.userAgent = '',
    this.referrer = '',
    this.timeZone = '',
    this.language = '',
    this.landing = '',
    this.query = const {},
    this.osName,
  });

  /// web or android / ios.
  final String platform;
  final String userAgent, referrer, timeZone, language, landing;
  final Map<String, String> query;

  /// Set by the app build (Android/iOS), where there is no user agent.
  final String? osName;
}
