// Runs the app's Firestore client against the emulator with firestore.rules,
// so the batches the app builds are the ones the rules accept. Skipped unless
// FIRESTORE_EMULATOR_HOST is set (test/rules: npm run test:app).
@Tags(['emulator'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:votewala/widgets/election_lock.dart';
import 'package:votewala/config/firebase_rest.dart';
import 'package:votewala/data/poll_month.dart';
import 'package:votewala/services/firestore_client.dart';
import 'package:votewala/services/vote_service.dart';

const project = 'demo-votewala';
final host = Platform.environment['FIRESTORE_EMULATOR_HOST'];

/// Unsigned ID token, which the emulator accepts.
String token(String uid) {
  String b64(Map<String, Object> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'none', 'typ': 'JWT'})}.${b64({
        'iss': 'https://securetoken.google.com/$project',
        'aud': project,
        'sub': uid,
        'user_id': uid,
        'iat': now,
        'exp': now + 3600,
        'auth_time': now,
        'email_verified': true,
        'firebase': {'sign_in_provider': 'google.com'},
      })}.';
}

VoteService service(String uid) => VoteService(
      FirestoreClient(
        const FirebaseSettings(apiKey: 'fake', projectId: project, storageBucket: ''),
        idToken: () async => token(uid),
        host: 'http://$host',
      ),
      MemoryPhotoStore(),
      minGap: const Duration(milliseconds: 2100),
    );

void main() {
  electionCodeForceOff = true; // voting screens are tested as after the election code
  setUpAll(() async {
    if (host == null) return;
    final rules = await File('firestore.rules').readAsString();
    final r = await http.put(
      Uri.parse('http://$host/emulator/v1/projects/$project:securityRules'),
      body: jsonEncode({'rules': {'files': [{'name': 'firestore.rules', 'content': rules}]}}),
    );
    expect(r.statusCode, 200, reason: r.body);
    await http.delete(Uri.parse('http://$host/emulator/v1/projects/$project/databases/(default)/documents'));
  });

  test('the app\'s vote batches pass the security rules', () async {
    final m = PollMonth.current();
    final alice = service('alice');

    await alice.castOption(uid: 'alice', pollId: PollIds.mla(m), bucket: 'mla-37', option: 1, badges: ['first-voice']);
    final record = await alice.load('alice', [PollIds.mla(m), PollIds.mp(m)]);
    expect(record.voteCount, 1);
    expect(record.badges, {'first-voice'});
    expect(record.ballots[PollIds.mla(m)], containsPair('option', 1));
    expect(await alice.tally(PollIds.mla(m), 'mla-37'), {'o1': 1, 'total': 1});

    await expectLater(
      alice.castOption(uid: 'alice', pollId: PollIds.mla(m), bucket: 'mla-38', option: 0),
      throwsA(isA<VoteException>()),
    );

    await alice.castOption(uid: 'alice', pollId: PollIds.featured('cm-2026'), bucket: alice.featuredBucket(m), option: 2);
    await alice.castIssues(uid: 'alice', month: m, constituencyId: 'mla-21', choices: {'c0': 1, 'c4': 0}, otherText: 'Bus stand');
    await alice.addPhoto(
        uid: 'alice', month: m, constituencyId: 'mla-21', slot: 'c0', choice: 1, jpeg: Uint8List(4), caption: 'Potholes');
    await alice.castOption(uid: 'alice', pollId: PollIds.priority(m), bucket: 'mla-21', option: 3);

    final bob = service('bob');
    await bob.castIssues(uid: 'bob', month: m, constituencyId: 'mla-21', choices: {'c0': 1});
    await bob.raiseAlerts(month: m, constituencyId: 'mla-21', badSlots: ['c0']);

    final tallies = await bob.tallies(PollIds.issues(m));
    expect(tallies['mla-21_c0'], {'o1': 2, 'total': 2, 'p1': 1});
    expect(tallies['mla-21_c4'], {'o0': 1, 'total': 1});
    expect((await alice.load('alice', [])).voteCount, 4);
  }, skip: host == null ? 'Set FIRESTORE_EMULATOR_HOST to run' : false, timeout: const Timeout(Duration(minutes: 2)));
}
