import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config_service.dart';
import '../data/ap_data.dart';
import '../data/civic.dart';
import '../data/featured_polls.dart';
import '../data/poll_month.dart';
import '../data/poll_repository.dart';
import '../services/auth_service.dart';
import '../services/vote_service.dart';

class AppUser {
  const AppUser({required this.uid, required this.name, this.email, this.phone, required this.provider});

  /// Firebase user id: votes are counted against it (one vote per account).
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final String provider;
}

/// A constituency vote the user cast in a monthly poll.
class VoteRecord {
  const VoteRecord(this.month, this.candidate);

  final PollMonth month;
  final Candidate candidate;
}

/// Result of a successful vote.
class VoteOutcome {
  const VoteOutcome({this.newBadges = const []});

  /// Badges unlocked by this vote (shown with a small celebration).
  final List<BadgeDef> newBadges;
}

/// GOOD/BAD counts for one category in one constituency (or statewide).
class IssueStat {
  const IssueStat({this.good = 0, this.bad = 0, this.goodPhoto = 0, this.badPhoto = 0});

  final int good, bad, goodPhoto, badPhoto;

  int get total => good + bad;
  int get withPhoto => goodPhoto + badPhoto;
  double get badShare => total == 0 ? 0 : bad / total;
  double get goodShare => total == 0 ? 0 : good / total;

  IssueStat operator +(IssueStat o) =>
      IssueStat(good: good + o.good, bad: bad + o.bad, goodPhoto: goodPhoto + o.goodPhoto, badPhoto: badPhoto + o.badPhoto);

  factory IssueStat.of(Map<String, int> t) =>
      IssueStat(good: t['o0'] ?? 0, bad: t['o1'] ?? 0, goodPhoto: t['p0'] ?? 0, badPhoto: t['p1'] ?? 0);
}

class _PollTallies {
  final buckets = <String, Map<String, int>>{};
  final fetchedAt = <String, DateTime>{};
  DateTime? allAt;
  bool loadingAll = false;
  final loading = <String>{};
}

class AppState extends ChangeNotifier {
  AppState(this._prefs, {AuthService? auth, required this.votes}) : auth = auth ?? authService {
    _lang = _prefs.getString('lang') ?? 'en';
    _saved = (_prefs.getStringList(_savedKey) ?? const []).toSet();
    _homeMla = _prefs.getString('home_mla');
    final notif = _prefs.getString('notif');
    if (notif != null) _notif.addAll(Map<String, bool>.from(jsonDecode(notif) as Map));
    // Admin config changes (names, photos, colours, polls) rebuild the UI.
    ConfigService.instance.addListener(notifyListeners);
  }

  static const _savedKey = 'saved_v2';

  /// Counts of the current month are refreshed after this long.
  static const tallyTtl = Duration(minutes: 2);

  final SharedPreferences _prefs;
  final AuthService auth;
  final VoteService votes;

  late String _lang;
  AppUser? _user;
  VoterRecord _record = VoterRecord();
  bool _recordLoaded = false;
  String? _homeMla;
  Set<String> _saved = {};
  final Map<String, bool> _notif = {'daily': true, 'results': true, 'featured': false};
  final _tallies = <String, _PollTallies>{};

  bool get isTelugu => _lang == 'te';
  String get language => _lang;

  void setLanguage(String lang) {
    _lang = lang;
    _prefs.setString('lang', lang);
    notifyListeners();
  }

  // --- Account. ---

  AppUser? get user => _user;

  /// True once the voter's previous votes are known (voting waits for it).
  bool get recordLoaded => _recordLoaded;
  int get voteCount => _record.voteCount;
  Set<String> get earnedBadges => _record.badges;

  /// Restores the previous session (call once at start-up).
  Future<void> restoreSession() async {
    try {
      final u = await auth.restore();
      if (u != null) await signIn(u);
    } catch (e) {
      debugPrint('Session restore failed: $e');
    }
  }

  Future<void> signIn(AppUser user) async {
    _user = user;
    _record = VoterRecord();
    _recordLoaded = false;
    notifyListeners();
    await reloadRecord();
  }

  Future<void> signOut() async {
    await auth.signOut();
    _user = null;
    _record = VoterRecord();
    _recordLoaded = false;
    notifyListeners();
  }

  List<String> get _myPollIds => [
        for (final m in PollMonth.available()) ...[PollIds.mla(m), PollIds.mp(m)],
        PollIds.issues(PollMonth.current()),
        PollIds.priority(PollMonth.current()),
        for (final p in appConfig.featured) PollIds.featured(p.id),
      ];

  Future<void> reloadRecord() async {
    final u = _user;
    if (u == null) return;
    try {
      final record = await votes.load(u.uid, _myPollIds);
      if (_user?.uid != u.uid) return;
      _record = record;
      _recordLoaded = true;
      notifyListeners();
      // Catch up on badges reached while a badge write failed.
      final missing = _badgesReached(record.voteCount);
      if (missing.isNotEmpty) {
        await votes.awardBadges(u.uid, [for (final b in missing) b.id]);
        record.badges.addAll([for (final b in missing) b.id]);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Loading votes failed: $e');
    }
  }

  List<BadgeDef> _badgesReached(int count) =>
      [for (final b in civic.badges) if (count >= b.milestone && !_record.badges.contains(b.id)) b];

  void _checkCanVote() {
    if (_user == null) throw const VoteException(VoteError.notSignedIn);
    if (!_recordLoaded) throw const VoteException(VoteError.network, 'record not loaded');
  }

  /// Records a ballot locally after the database accepted it.
  VoteOutcome _counted(String pollId, Map<String, Object?> ballot, List<BadgeDef> badges) {
    _record.ballots[pollId] = ballot;
    _record.voteCount += 1;
    _record.badges.addAll([for (final b in badges) b.id]);
    _tallies.remove(pollId);
    notifyListeners();
    return VoteOutcome(newBadges: badges);
  }

  Future<VoteOutcome> _castOption(String pollId, String bucket, int option) async {
    _checkCanVote();
    if (_record.ballots.containsKey(pollId)) throw const VoteException(VoteError.alreadyVoted);
    final badges = _badgesReached(_record.voteCount + 1);
    final ballot = await votes.castOption(
      uid: _user!.uid,
      pollId: pollId,
      bucket: bucket,
      option: option,
      badges: [for (final b in badges) b.id],
    );
    return _counted(pollId, ballot, badges);
  }

  // --- Tallies (public counts), cached per poll. ---

  _PollTallies _poll(String pollId) => _tallies.putIfAbsent(pollId, _PollTallies.new);

  bool _fresh(DateTime? at, PollMonth? month) =>
      at != null && (month?.isPast == true || DateTime.now().difference(at) < tallyTtl);

  /// Counts of one bucket; fetched in the background when missing or stale.
  Map<String, int> _bucket(String pollId, String bucket, {PollMonth? month}) {
    final p = _poll(pollId);
    if (!_fresh(p.allAt, month) && !_fresh(p.fetchedAt[bucket], month) && p.loading.add(bucket)) {
      unawaited(votes.tally(pollId, bucket).then((t) {
        p.buckets[bucket] = t;
        p.fetchedAt[bucket] = DateTime.now();
      }).catchError((Object e) => debugPrint('Tally $pollId/$bucket failed: $e')).whenComplete(() {
        p.loading.remove(bucket);
        notifyListeners();
      }));
    }
    return p.buckets[bucket] ?? const {};
  }

  /// All buckets of a poll; fetched in the background when missing or stale.
  Map<String, Map<String, int>> _all(String pollId, {PollMonth? month}) {
    final p = _poll(pollId);
    if (!_fresh(p.allAt, month) && !p.loadingAll) {
      p.loadingAll = true;
      unawaited(votes.tallies(pollId).then((t) {
        p.buckets
          ..clear()
          ..addAll(t);
        p.allAt = DateTime.now();
      }).catchError((Object e) => debugPrint('Tallies $pollId failed: $e')).whenComplete(() {
        p.loadingAll = false;
        notifyListeners();
      }));
    }
    return p.buckets;
  }

  // --- Monthly constituency votes: 1 MLA + 1 MP per user per month. ---

  static String _pollOf(ElectionType type, PollMonth m) =>
      type == ElectionType.mla ? PollIds.mla(m) : PollIds.mp(m);

  /// The candidate this user voted for in [type] polls during [month].
  Candidate? monthlyVote(ElectionType type, [PollMonth? month]) {
    final b = _record.ballots[_pollOf(type, month ?? PollMonth.current())];
    return b == null ? null : Candidate(ApData.byId(b['bucket'] as String), b['option'] as int);
  }

  int? choiceIndex(Constituency c, [PollMonth? month]) {
    final v = monthlyVote(c.type, month);
    return v != null && v.constituency.id == c.id ? v.index : null;
  }

  bool canVote(Constituency c) => _user != null && _recordLoaded && monthlyVote(c.type) == null;

  /// Records this month's MLA or MP vote. Throws [VoteException].
  Future<VoteOutcome> castVote(Candidate candidate) async {
    final c = candidate.constituency;
    if (monthlyVote(c.type) != null) throw const VoteException(VoteError.alreadyVoted);
    return _castOption(_pollOf(c.type, PollMonth.current()), c.id, candidate.index);
  }

  PollSnapshot snapshot(Constituency c, {PollMonth? month}) {
    final m = month ?? PollMonth.current();
    final t = _bucket(_pollOf(c.type, m), c.id, month: m);
    return PollSnapshot(c, [for (var i = 0; i < CandidateRole.values.length; i++) t['o$i'] ?? 0], month: m);
  }

  List<PollSnapshot> snapshots(ElectionType type, {PollMonth? month}) {
    final m = month ?? PollMonth.current();
    final all = _all(_pollOf(type, m), month: m);
    return [
      for (final c in ApData.of(type))
        PollSnapshot(c, [for (var i = 0; i < CandidateRole.values.length; i++) all[c.id]?['o$i'] ?? 0], month: m),
    ];
  }

  DistrictSummary districtSummary(District d, ElectionType type, {PollMonth? month}) {
    final all = snapshots(type, month: month);
    return DistrictSummary(d, [for (final s in all) if (s.constituency.districtIds.contains(d.id)) s]);
  }

  List<VoteRecord> get voteHistory {
    final list = <VoteRecord>[];
    for (final m in PollMonth.available()) {
      for (final type in ElectionType.values) {
        final v = monthlyVote(type, m);
        if (v != null) list.add(VoteRecord(m, v));
      }
    }
    return list;
  }

  // --- Featured polls: one vote per user for the whole poll. ---

  int? featuredChoice(FeaturedPoll p) => _record.ballots[PollIds.featured(p.id)]?['option'] as int?;

  PollMonth? featuredVoteMonth(FeaturedPoll p) {
    final bucket = _record.ballots[PollIds.featured(p.id)]?['bucket'] as String?;
    return bucket == null ? null : PollMonth.parse(bucket.substring(0, 7));
  }

  Future<VoteOutcome> castFeaturedVote(FeaturedPoll p, int option) async {
    if (!p.isOpen) throw const VoteException(VoteError.closed);
    return _castOption(PollIds.featured(p.id), votes.featuredBucket(PollMonth.current()), option);
  }

  List<int> _sum(FeaturedPoll p, bool Function(String bucket) include) {
    final votes = List.filled(p.options.length, 0);
    for (final e in _all(PollIds.featured(p.id)).entries) {
      if (!include(e.key)) continue;
      for (var i = 0; i < votes.length; i++) {
        votes[i] += e.value['o$i'] ?? 0;
      }
    }
    return votes;
  }

  /// Votes per option cast in [month].
  List<int> featuredVotesIn(FeaturedPoll p, PollMonth month) => _sum(p, (b) => b.startsWith(month.key));

  /// Cumulative votes per option over the poll so far.
  List<int> featuredTotals(FeaturedPoll p) => _sum(p, (_) => true);

  // --- Your constituency: local issues and "If you were the MLA". ---

  /// The assembly constituency the voter gives feedback for.
  Constituency? get homeConstituency => _homeMla == null ? null : ApData.byIdOrNull(_homeMla!);

  void setHomeConstituency(Constituency c) {
    _homeMla = c.id;
    _prefs.setString('home_mla', c.id);
    notifyListeners();
  }

  /// This month's GOOD (0) / BAD (1) answers by category slot, if submitted.
  Map<String, int>? get myIssueChoices {
    final b = _record.ballots[PollIds.issues(PollMonth.current())];
    return b == null ? null : {for (final e in (b['choices'] as Map).entries) e.key as String: e.value as int};
  }

  /// Constituency the voter gave this month's feedback for.
  String? get myIssueConstituency => _record.ballots[PollIds.issues(PollMonth.current())]?['bucket'] as String?;

  Future<VoteOutcome> castIssues(Constituency c, Map<String, int> choices, {String? otherText}) async {
    _checkCanVote();
    final pollId = PollIds.issues(PollMonth.current());
    if (_record.ballots.containsKey(pollId)) throw const VoteException(VoteError.alreadyVoted);
    final badges = _badgesReached(_record.voteCount + 1);
    final ballot = await votes.castIssues(
      uid: _user!.uid,
      month: PollMonth.current(),
      constituencyId: c.id,
      choices: choices,
      otherText: otherText,
      badges: [for (final b in badges) b.id],
    );
    final outcome = _counted(pollId, ballot, badges);
    unawaited(votes
        .raiseAlerts(
          month: PollMonth.current(),
          constituencyId: c.id,
          badSlots: [for (final e in choices.entries) if (e.value == 1) e.key],
        )
        .catchError((Object e) => debugPrint('Alert check failed: $e')));
    return outcome;
  }

  /// Slots this month that already have the voter's photo.
  final Set<String> _photoSlots = {};
  bool hasPhoto(String slot) => _photoSlots.contains(slot);

  Future<void> addIssuePhoto(String slot, Uint8List jpeg, String caption) async {
    _checkCanVote();
    final choice = myIssueChoices?[slot];
    final bucket = myIssueConstituency;
    if (choice == null || bucket == null) throw const VoteException(VoteError.rejected, 'vote first');
    await votes.addPhoto(
      uid: _user!.uid,
      month: PollMonth.current(),
      constituencyId: bucket,
      slot: slot,
      choice: choice,
      jpeg: jpeg,
      caption: caption,
    );
    _photoSlots.add(slot);
    _tallies.remove(PollIds.issues(PollMonth.current()));
    notifyListeners();
  }

  /// Category stats for one constituency in [month].
  Map<String, IssueStat> issueStats(String constituencyId, {PollMonth? month}) {
    final m = month ?? PollMonth.current();
    final all = _all(PollIds.issues(m), month: m);
    return {
      for (final c in civic.categories) c.slot: IssueStat.of(all['${constituencyId}_${c.slot}'] ?? const {}),
    };
  }

  /// Category stats summed over all constituencies in [month].
  Map<String, IssueStat> issueStatsStatewide({PollMonth? month}) {
    final m = month ?? PollMonth.current();
    final out = {for (final c in civic.categories) c.slot: const IssueStat()};
    for (final e in _all(PollIds.issues(m), month: m).entries) {
      final slot = e.key.split('_').last;
      if (out.containsKey(slot)) out[slot] = out[slot]! + IssueStat.of(e.value);
    }
    return out;
  }

  int? get myPriority => _record.ballots[PollIds.priority(PollMonth.current())]?['option'] as int?;

  Future<VoteOutcome> castPriority(Constituency c, int option) =>
      _castOption(PollIds.priority(PollMonth.current()), c.id, option);

  /// Votes per priority option for one constituency, or statewide when null.
  List<int> priorityVotes({String? constituencyId, PollMonth? month}) {
    final m = month ?? PollMonth.current();
    final out = List.filled(civic.priorities.length, 0);
    for (final e in _all(PollIds.priority(m), month: m).entries) {
      if (constituencyId != null && e.key != constituencyId) continue;
      for (var i = 0; i < out.length; i++) {
        out[i] += e.value['o$i'] ?? 0;
      }
    }
    return out;
  }

  /// Priority votes per constituency (for rankings).
  Map<String, List<int>> priorityByConstituency({PollMonth? month}) {
    final m = month ?? PollMonth.current();
    return {
      for (final e in _all(PollIds.priority(m), month: m).entries)
        e.key: [for (var i = 0; i < civic.priorities.length; i++) e.value['o$i'] ?? 0],
    };
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
