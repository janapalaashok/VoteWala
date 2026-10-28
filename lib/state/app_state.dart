import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_service.dart';
import '../data/ap_data.dart';
import '../data/featured_polls.dart';
import '../data/poll_month.dart';
import '../data/poll_repository.dart';

class AppUser {
  const AppUser({required this.name, this.email, this.phone, required this.provider});

  final String name;
  final String? email;
  final String? phone;
  final String provider;

  /// Identity that votes are counted against (one vote per account).
  String get key => email ?? phone ?? name;

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone, 'provider': provider};

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        name: j['name'] as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        provider: j['provider'] as String,
      );
}

/// A constituency vote the user cast in a monthly poll.
class VoteRecord {
  const VoteRecord(this.month, this.candidate);

  final PollMonth month;
  final Candidate candidate;
}

class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _lang = _prefs.getString('lang') ?? 'en';
    final user = _prefs.getString('user');
    if (user != null) _user = AppUser.fromJson(jsonDecode(user) as Map<String, dynamic>);
    final votes = _prefs.getString(_votesKey);
    if (votes != null) _votes = Map<String, String>.from(jsonDecode(votes) as Map);
    _saved = (_prefs.getStringList(_savedKey) ?? const []).toSet();
    final notif = _prefs.getString('notif');
    if (notif != null) _notif.addAll(Map<String, bool>.from(jsonDecode(notif) as Map));
    // Admin config changes (names, photos, colours, polls) rebuild the UI.
    ConfigService.instance.addListener(notifyListeners);
  }

  static const _votesKey = 'votes_v2';
  static const _savedKey = 'saved_v2';

  final SharedPreferences _prefs;

  late String _lang;
  AppUser? _user;

  /// `user|mla|YYYY-MM` -> candidate id,
  /// `user|featured|pollId` -> `optionIndex|YYYY-MM`.
  Map<String, String> _votes = {};
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
  String get _uk => _user?.key ?? 'guest';

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

  void _saveVotes() => _prefs.setString(_votesKey, jsonEncode(_votes));

  // --- Monthly constituency votes: 1 MLA + 1 MP per user per month. ---

  String _monthlyKey(ElectionType type, PollMonth m) => '$_uk|${type.name}|${m.key}';

  /// The candidate this user voted for in [type] polls during [month].
  Candidate? monthlyVote(ElectionType type, [PollMonth? month]) {
    final id = _votes[_monthlyKey(type, month ?? PollMonth.current())];
    return id == null ? null : Candidate.byId(id);
  }

  int? choiceIndex(Constituency c, [PollMonth? month]) {
    final v = monthlyVote(c.type, month);
    return v != null && v.constituency.id == c.id ? v.index : null;
  }

  bool canVote(Constituency c) => _user != null && monthlyVote(c.type) == null;

  /// Records a vote; returns false if this month's vote for that type is used.
  bool castVote(Candidate candidate) {
    if (!canVote(candidate.constituency)) return false;
    _votes[_monthlyKey(candidate.constituency.type, PollMonth.current())] = candidate.id;
    _saveVotes();
    notifyListeners();
    return true;
  }

  PollSnapshot snapshot(Constituency c, {PollMonth? month}) =>
      PollRepository.snapshot(c, month: month, userChoice: choiceIndex(c, month));

  List<PollSnapshot> snapshots(ElectionType type, {PollMonth? month}) =>
      [for (final c in ApData.of(type)) snapshot(c, month: month)];

  DistrictSummary districtSummary(District d, ElectionType type, {PollMonth? month}) => DistrictSummary(
        d,
        [for (final c in ApData.of(type)) if (c.districtIds.contains(d.id)) snapshot(c, month: month)],
      );

  List<VoteRecord> get voteHistory {
    final list = <VoteRecord>[];
    for (final e in _votes.entries) {
      final p = e.key.split('|');
      if (p.length == 3 && p[0] == _uk && p[1] != 'featured') {
        list.add(VoteRecord(PollMonth.parse(p[2]), Candidate.byId(e.value)));
      }
    }
    list.sort((a, b) => b.month.compareTo(a.month));
    return list;
  }

  // --- Featured polls: one vote per user for the whole poll. ---

  String _featuredKey(FeaturedPoll p) => '$_uk|featured|${p.id}';

  int? featuredChoice(FeaturedPoll p) {
    final v = _votes[_featuredKey(p)];
    return v == null ? null : int.parse(v.split('|').first);
  }

  PollMonth? featuredVoteMonth(FeaturedPoll p) {
    final v = _votes[_featuredKey(p)];
    return v == null ? null : PollMonth.parse(v.split('|').last);
  }

  bool castFeaturedVote(FeaturedPoll p, int option) {
    if (_user == null || !p.isOpen || featuredChoice(p) != null) return false;
    _votes[_featuredKey(p)] = '$option|${PollMonth.current().key}';
    _saveVotes();
    notifyListeners();
    return true;
  }

  /// Votes per option cast in [month], including this user's vote.
  List<int> featuredVotesIn(FeaturedPoll p, PollMonth month) {
    final votes = p.votesIn(month);
    final mine = featuredChoice(p);
    if (mine != null && featuredVoteMonth(p) == month) votes[mine] += 1;
    return votes;
  }

  /// Cumulative votes per option over the poll so far.
  List<int> featuredTotals(FeaturedPoll p) {
    final totals = List.filled(p.options.length, 0);
    for (final m in p.months) {
      final v = featuredVotesIn(p, m);
      for (var i = 0; i < totals.length; i++) {
        totals[i] += v[i];
      }
    }
    return totals;
  }

  // --- Saved candidates and settings. ---

  bool isSaved(String candidateId) => _saved.contains(candidateId);
  List<String> get savedCandidates => _saved.toList();

  void toggleSaved(String candidateId) {
    if (!_saved.remove(candidateId)) _saved.add(candidateId);
    _prefs.setStringList(_savedKey, _saved.toList());
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
