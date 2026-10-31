/// Totals for the admin Traffic dashboard, from traffic/{day}/visits and
/// traffic/{day}/logins documents.
class TrafficStats {
  TrafficStats(this.days, Map<String, Map<String, Map<String, Object?>>> visits,
      Map<String, Map<String, Map<String, Object?>>> logins) {
    for (final day in days) {
      final v = visits[day] ?? const {};
      final l = logins[day] ?? const {};
      visitorsByDay[day] = v.length;
      loginsByDay[day] = l.length;
      for (final doc in v.values) {
        _add(countries, doc['country']);
        _add(devices, doc['device']);
        _add(os, doc['os']);
        _add(browsers, doc['browser']);
        _add(sources, doc['source']);
        _add(platforms, doc['platform']);
        _add(landings, doc['landing']);
        if (doc['signedIn'] == true) signedInVisitors++;
      }
      for (final doc in l.values) {
        _add(loginMethods, doc['method']);
        if (doc['kind'] == 'signup') {
          signups++;
        } else {
          signIns++;
        }
      }
    }
  }

  /// Days covered, oldest first (yyyy-mm-dd, IST).
  final List<String> days;
  final visitorsByDay = <String, int>{};
  final loginsByDay = <String, int>{};
  final countries = <String, int>{};
  final devices = <String, int>{};
  final os = <String, int>{};
  final browsers = <String, int>{};
  final sources = <String, int>{};
  final platforms = <String, int>{};
  final landings = <String, int>{};
  final loginMethods = <String, int>{};
  int signups = 0, signIns = 0, signedInVisitors = 0;

  /// Visitors summed over the days (a person visiting on 3 days counts 3).
  int get visits => visitorsByDay.values.fold(0, (a, b) => a + b);
  int get today => days.isEmpty ? 0 : visitorsByDay[days.last] ?? 0;
  double get dailyAverage => days.isEmpty ? 0 : visits / days.length;
  String? get busiestDay {
    if (visits == 0) return null;
    return (visitorsByDay.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  static void _add(Map<String, int> m, Object? key) {
    final k = key is String && key.isNotEmpty ? key : 'unknown';
    m[k] = (m[k] ?? 0) + 1;
  }

  /// [m] sorted by count, largest first.
  static List<MapEntry<String, int>> ranked(Map<String, int> m) =>
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  /// The [n] days ending at [last] (inclusive), oldest first.
  static List<String> lastDays(DateTime last, int n) => [
        for (var i = n - 1; i >= 0; i--)
          () {
            final d = DateTime.utc(last.year, last.month, last.day - i);
            return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          }(),
      ];
}

/// Country names for the codes the site records.
const countryNames = {
  'IN': 'India', 'US': 'United States', 'GB': 'United Kingdom', 'CA': 'Canada', 'AU': 'Australia',
  'AE': 'UAE', 'SA': 'Saudi Arabia', 'QA': 'Qatar', 'KW': 'Kuwait', 'OM': 'Oman', 'BH': 'Bahrain',
  'SG': 'Singapore', 'MY': 'Malaysia', 'DE': 'Germany', 'FR': 'France', 'NL': 'Netherlands', 'IE': 'Ireland',
  'NZ': 'New Zealand', 'JP': 'Japan', 'HK': 'Hong Kong', 'CN': 'China', 'BD': 'Bangladesh', 'NP': 'Nepal',
  'LK': 'Sri Lanka', 'PK': 'Pakistan', 'TH': 'Thailand', 'ID': 'Indonesia', 'PH': 'Philippines',
  'KR': 'South Korea', 'VN': 'Vietnam', 'ZA': 'South Africa', 'KE': 'Kenya', 'NG': 'Nigeria', 'EG': 'Egypt',
  'BR': 'Brazil', 'MX': 'Mexico', 'BE': 'Belgium', 'CH': 'Switzerland', 'IT': 'Italy', 'ES': 'Spain',
  'SE': 'Sweden', 'NO': 'Norway', 'DK': 'Denmark', 'FI': 'Finland', 'PL': 'Poland', 'AT': 'Austria',
  'PT': 'Portugal', 'CZ': 'Czechia', 'RU': 'Russia', 'TR': 'Turkey', 'ZZ': 'Unknown',
};
