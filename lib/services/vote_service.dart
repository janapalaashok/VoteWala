import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/firebase_rest.dart';
import '../data/poll_month.dart';
import 'firestore_client.dart';

/// Poll ids as stored in Firestore (see firestore.rules).
abstract final class PollIds {
  static String mla(PollMonth m) => 'mla-${m.key}';
  static String mp(PollMonth m) => 'mp-${m.key}';
  static String issues(PollMonth m) => 'issues-${m.key}';
  static String priority(PollMonth m) => 'priority-${m.key}';
  static String featured(String id) => 'f-$id';

  /// Today's poll for the IST date yyyy-mm-dd; buckets s0..s9.
  static String daily(String date) => 'd-$date';

  /// Featured polls spread votes over 10 counters per month (shards), so many
  /// people can vote at the same moment.
  static String featuredShard(PollMonth m, Random rnd) => '${m.key}-s${rnd.nextInt(10)}';
}

/// Why a vote was not recorded.
enum VoteError { notSignedIn, alreadyVoted, closed, rejected, network, blocked }

class VoteException implements Exception {
  const VoteException(this.error, [this.detail = '']);

  final VoteError error;
  final String detail;

  /// Message key in l10n/strings.dart.
  String get messageKey => switch (error) {
        VoteError.notSignedIn => 'signInToVote',
        VoteError.alreadyVoted => 'alreadyVotedMonth',
        VoteError.closed => 'pollClosedMsg',
        VoteError.rejected => 'voteRejected',
        VoteError.network => 'networkError',
        VoteError.blocked => 'accountBlocked',
      };

  @override
  String toString() => 'VoteException(${error.name}) $detail';
}

/// What the app knows about the signed-in voter.
class VoterRecord {
  VoterRecord({this.voteCount = 0, Set<String>? badges, Map<String, Map<String, Object?>>? ballots})
      : badges = badges ?? {},
        ballots = ballots ?? {};

  int voteCount;
  final Set<String> badges;

  /// Ballots by poll id.
  final Map<String, Map<String, Object?>> ballots;
}

/// Uploads voters' evidence photos to Firebase Storage.
abstract class PhotoStore {
  Future<void> upload(String path, Uint8List bytes, String contentType);
}

class FirebasePhotoStore implements PhotoStore {
  FirebasePhotoStore(this.settings, this.idToken, {http.Client? client}) : _http = client ?? http.Client();

  final FirebaseSettings settings;
  final Future<String?> Function() idToken;
  final http.Client _http;

  @override
  Future<void> upload(String path, Uint8List bytes, String contentType) async {
    final token = await idToken();
    final http.Response r;
    try {
      r = await _http.post(
        Uri.parse('https://firebasestorage.googleapis.com/v0/b/${settings.storageBucket}/o'
            '?uploadType=media&name=${Uri.encodeQueryComponent(path)}'),
        headers: {if (token != null) 'Authorization': 'Firebase $token', 'Content-Type': contentType},
        body: bytes,
      );
    } catch (e) {
      throw VoteException(VoteError.network, '$e');
    }
    if (r.statusCode != 200) throw VoteException(VoteError.rejected, 'upload ${r.statusCode} ${r.body}');
  }
}

class MemoryPhotoStore implements PhotoStore {
  final files = <String, Uint8List>{};

  @override
  Future<void> upload(String path, Uint8List bytes, String contentType) async => files[path] = bytes;
}

/// Builds the write batches that firestore.rules accept: a ballot, the
/// matching tally +1, the voter's counter and any badge reached.
class VoteService {
  VoteService(this.store, this.photos, {Random? random, this.minGap = const Duration(milliseconds: 2200)})
      : _rnd = random ?? Random();

  final DocStore store;
  final PhotoStore photos;
  final Random _rnd;

  /// The rules allow one vote-related write per user every 2 seconds.
  final Duration minGap;
  DateTime? _lastWrite;

  Future<void> _paced(Future<void> Function() write) async {
    final last = _lastWrite;
    if (last != null) {
      final wait = minGap - DateTime.now().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    try {
      await write();
    } on StoreException catch (e) {
      throw VoteException(switch (e.error) {
        StoreError.exists => VoteError.alreadyVoted,
        StoreError.network => VoteError.network,
        _ => VoteError.rejected,
      }, e.detail);
    } finally {
      _lastWrite = DateTime.now();
    }
  }

  static String ballotPath(String pollId, String uid) => 'votes/$pollId/ballots/$uid';
  static String tallyPath(String pollId, String bucket) => 'tallies/$pollId/buckets/$bucket';

  List<Write> _counted(String uid, String pollId, List<String> badges) => [
        Write.merge('users/$uid', {'lastBallot': ballotPath(pollId, uid)}, const {
          'voteCount': FieldTransform.increment(),
          'lastActionAt': FieldTransform.serverTime(),
        }),
        for (final b in badges) Write.create('users/$uid/badges/$b', const {}, const {'at': FieldTransform.serverTime()}),
      ];

  /// Loads the voter's count, badges and ballots in [pollIds].
  Future<VoterRecord> load(String uid, List<String> pollIds) async {
    final (user, badges, ballots) = await (
      store.get('users/$uid'),
      store.list('users/$uid/badges'),
      store.getAll([for (final p in pollIds) ballotPath(p, uid)]),
    ).wait;
    return VoterRecord(
      voteCount: (user?['voteCount'] as int?) ?? 0,
      badges: badges.keys.toSet(),
      ballots: {for (final e in ballots.entries) e.key.split('/')[1]: e.value},
    );
  }

  /// One option in a constituency (MLA/MP/priority) or featured poll.
  /// Returns the stored ballot.
  Future<Map<String, Object?>> castOption({
    required String uid,
    required String pollId,
    required String bucket,
    required int option,
    List<String> badges = const [],
  }) async {
    final ballot = {'bucket': bucket, 'option': option};
    await _paced(() => store.commit([
          Write.create(ballotPath(pollId, uid), ballot, const {'at': FieldTransform.serverTime()}),
          Write.merge(tallyPath(pollId, bucket), const {}, {
            'o$option': const FieldTransform.increment(),
            'total': const FieldTransform.increment(),
          }),
          ..._counted(uid, pollId, badges),
        ]));
    return ballot;
  }

  String featuredBucket(PollMonth month) => PollIds.featuredShard(month, _rnd);

  /// Today's poll counts are spread over ten buckets (s0..s9).
  String dailyBucket() => 's${_rnd.nextInt(10)}';

  /// GOOD (0) / BAD (1) per category slot for the voter's constituency.
  Future<Map<String, Object?>> castIssues({
    required String uid,
    required PollMonth month,
    required String constituencyId,
    required Map<String, int> choices,
    String? otherText,
    List<String> badges = const [],
  }) async {
    final pollId = PollIds.issues(month);
    final ballot = {'bucket': constituencyId, 'choices': choices};
    final text = otherText?.trim() ?? '';
    await _paced(() => store.commit([
          Write.create(ballotPath(pollId, uid), ballot, const {'at': FieldTransform.serverTime()}),
          for (final e in choices.entries)
            Write.merge(tallyPath(pollId, '${constituencyId}_${e.key}'), const {}, {
              'o${e.value}': const FieldTransform.increment(),
              'total': const FieldTransform.increment(),
            }),
          if (text.isNotEmpty)
            Write.create('otherIssues/${pollId}_$uid', {
              'pollId': pollId,
              'bucket': constituencyId,
              'text': text.length > 80 ? text.substring(0, 80) : text,
            }),
          ..._counted(uid, pollId, badges),
        ]));
    return ballot;
  }

  /// Attaches an evidence photo to the voter's GOOD/BAD vote for [slot].
  /// The photo stays private until an admin reviews it.
  Future<void> addPhoto({
    required String uid,
    required PollMonth month,
    required String constituencyId,
    required String slot,
    required int choice,
    required Uint8List jpeg,
    String caption = '',
  }) async {
    final pollId = PollIds.issues(month);
    final file = 'issue-photos/$uid/${pollId}_${slot}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await photos.upload(file, jpeg, 'image/jpeg');
    final id = '${pollId}_${uid}_$slot';
    final text = caption.trim();
    await _paced(() => store.commit([
          Write.create('photos/$id', {
            'pollId': pollId,
            'bucket': constituencyId,
            'slot': slot,
            'choice': choice,
            'uid': uid,
            'file': file,
            'caption': text.length > 140 ? text.substring(0, 140) : text,
            'status': 'pending',
          }, const {'at': FieldTransform.serverTime()}),
          Write.merge(tallyPath(pollId, '${constituencyId}_$slot'), const {}, {'p$choice': const FieldTransform.increment()}),
          Write.merge('users/$uid', {'lastPhoto': id}, const {'lastActionAt': FieldTransform.serverTime()}),
        ]));
  }

  /// Raises an admin alert for each [badSlots] category whose BAD votes have
  /// reached the threshold. Each threshold event is created once; the rules
  /// refuse duplicates, which is fine to ignore.
  Future<void> raiseAlerts({required PollMonth month, required String constituencyId, required Iterable<String> badSlots}) async {
    final pollId = PollIds.issues(month);
    final settings = await store.get('settings/thresholds') ?? const {};
    final fallback = (settings['default'] as int?) ?? 100;
    final bySlot = (settings['bySlot'] as Map?) ?? const {};
    for (final slot in badSlots) {
      final limit = (bySlot[slot] as int?) ?? fallback;
      final tally = await store.get(tallyPath(pollId, '${constituencyId}_$slot'));
      if (((tally?['o1'] as int?) ?? 0) < limit) continue;
      try {
        await store.commit([
          Write.create('alerts/${pollId}_${constituencyId}_${slot}_$limit', {
            'pollId': pollId,
            'bucket': constituencyId,
            'slot': slot,
            'threshold': limit,
            'seen': false,
          }, const {'at': FieldTransform.serverTime()}),
        ]);
      } on StoreException {
        // Already raised for this threshold.
      }
    }
  }

  /// Keeps the voter's account details for admins (Users page).
  Future<void> saveProfile({required String uid, required String email, required String name, required String provider}) =>
      store.commit([
        Write.merge('profiles/$uid', {
          'email': email,
          'name': name.length > 100 ? name.substring(0, 100) : name,
          'provider': provider,
        }, const {'lastSeen': FieldTransform.serverTime()}),
      ]);

  /// True when an admin blocked this account from voting.
  Future<bool> isBlocked(String uid) async => await store.get('blocked/$uid') != null;

  /// Awards badges reached earlier but not stored (e.g. after a lost connection).
  Future<void> awardBadges(String uid, List<String> badges) async {
    if (badges.isEmpty) return;
    await _paced(() => store.commit([
          for (final b in badges) Write.create('users/$uid/badges/$b', const {}, const {'at': FieldTransform.serverTime()}),
        ]));
  }

  /// Public counts: bucket id -> counter fields.
  Future<Map<String, Map<String, int>>> tallies(String pollId) async {
    final docs = await store.list('tallies/$pollId/buckets');
    return {for (final e in docs.entries) e.key: _ints(e.value)};
  }

  Future<Map<String, int>> tally(String pollId, String bucket) async =>
      _ints(await store.get(tallyPath(pollId, bucket)) ?? const {});

  static Map<String, int> _ints(Map<String, Object?> m) => {
        for (final e in m.entries)
          if (e.value is int) e.key: e.value as int,
      };
}
