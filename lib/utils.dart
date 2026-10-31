const _istOffset = Duration(hours: 5, minutes: 30);

/// Current wall-clock time in India Standard Time, held in a UTC DateTime.
DateTime istNow() => DateTime.now().toUtc().add(_istOffset);

/// Today's date in IST (time set to midnight).
DateTime istToday() {
  final n = istNow();
  return DateTime.utc(n.year, n.month, n.day);
}

/// Time left until [end] (an IST wall-clock time).
Duration timeUntil(DateTime end) => end.difference(istNow());

String dayKey(DateTime day) => '${day.year}-${_two(day.month)}-${_two(day.day)}';

DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// Indian digit grouping: 124580 -> 1,24,580.
String formatIndian(int n) {
  final s = n.abs().toString();
  final sign = n < 0 ? '-' : '';
  if (s.length <= 3) return '$sign$s';
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '$sign${groups.join(',')},${s.substring(s.length - 3)}';
}

/// Compact Indian units: 72400 -> 72.4K, 120000 -> 1.2L.
String formatCompact(int n) {
  if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${_two(h)}:${_two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatCountdown(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final days = d.inDays;
  final h = d.inHours % 24;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return days > 0 ? '${days}d ${_two(h)}h ${_two(m)}m' : '${_two(h)}h ${_two(m)}m ${_two(s)}s';
}

/// Stable string hash (Dart's String.hashCode differs between platforms).
int stableHash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x3fffffff;
  }
  return h;
}

String _two(int n) => n.toString().padLeft(2, '0');
