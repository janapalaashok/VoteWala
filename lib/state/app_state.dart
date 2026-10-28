import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ap_data.dart';
import '../data/poll_repository.dart';
import '../utils.dart';

class AppUser {
  const AppUser({required this.name, this.email, this.phone, required this.provider});

  final String name;
  final String? email;
  final String? phone;
  final String provider;

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone, 'provider': provider};

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        name: j['name'] as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        provider: j['provider'] as String,
      );
}

/// A vote the user cast: which candidate, in which poll, on which day.
class VoteRecord {
  const VoteRecord(this.pollId, this.day, this.candidateId);

  final String pollId;
  final DateTime day;
  final String candidateId;
}

class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _lang = _prefs.getString('lang') ?? 'en';
    final user = _prefs.getString('user');
    if (user != null) _user = AppUser.fromJson(jsonDecode(user) as Map<String, dynamic>);
    final votes = _prefs.getString('votes');
    if (votes != null) _votes = Map<String, String>.from(jsonDecode(votes) as Map);
    _saved = (_prefs.getStringList('saved') ?? const []).toSet();
    final notif = _prefs.getString('notif');
    if (notif != null) _notif.addAll(Map<String, bool>.from(jsonDecode(notif) as Map));
  }

  final SharedPreferences _prefs;

  late String _lang;
  AppUser? _user;
  Map<String, String> _votes = {}; // "<pollId>|<day>" -> candidateId
  Set<String> _saved = {};
  final Map<String, bool> _notif = {'daily': true, 'results': true, 'featured': false};

  bool get isTelugu => _lang == 'te';
  String get language => _lang;

  void setLanguage(String lang) {
    _lang = lang;
    _prefs.setString('lang', lang);
    notifyListeners();
  }

  AppUser? get user => _user;

  void signIn(AppUser user) {
    _user = user;
    _prefs.setString('user', jsonEncode(user.toJson()));
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _prefs.remove('user');
    notifyListeners();
  }

  int? choiceIndex(Constituency c, [DateTime? day]) {
    final id = _votes['${c.id}|${dayKey(day ?? istToday())}'];
    return id == null ? null : Candidate.byId(id).index;
  }

  PollSnapshot snapshot(Constituency c, {DateTime? day}) =>
      PollRepository.snapshot(c, day: day, userChoice: choiceIndex(c, day));

  DistrictSummary districtSummary(District d, ElectionType type, {DateTime? day}) =>
      PollRepository.districtSummary(d, type, day: day, choiceOf: (c) => choiceIndex(c, day));

  void castVote(Candidate candidate) {
    _votes['${candidate.constituency.id}|${dayKey(istToday())}'] = candidate.id;
    _prefs.setString('votes', jsonEncode(_votes));
    notifyListeners();
  }

  List<VoteRecord> get voteHistory {
    final list = [
      for (final e in _votes.entries)
        VoteRecord(e.key.split('|').first, parseDayKey(e.key.split('|').last), e.value),
    ];
    list.sort((a, b) => b.day.compareTo(a.day));
    return list;
  }

  bool isSaved(String candidateId) => _saved.contains(candidateId);
  List<String> get savedCandidates => _saved.toList();

  void toggleSaved(String candidateId) {
    if (!_saved.remove(candidateId)) _saved.add(candidateId);
    _prefs.setStringList('saved', _saved.toList());
    notifyListeners();
  }

  bool notification(String key) => _notif[key] ?? false;

  void setNotification(String key, bool value) {
    _notif[key] = value;
    _prefs.setString('notif', jsonEncode(_notif));
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Access without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
