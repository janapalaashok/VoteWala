import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votewala/config/app_config.dart';
import 'package:votewala/config/config_service.dart';
import 'package:votewala/data/ap_data.dart';
import 'package:votewala/data/featured_polls.dart';
import 'package:votewala/data/poll_month.dart';
import 'package:votewala/data/poll_repository.dart';
import 'package:votewala/main.dart';
import 'package:votewala/services/auth_service.dart';
import 'package:votewala/services/firestore_client.dart';
import 'package:votewala/services/vote_service.dart';
import 'package:votewala/state/app_state.dart';
import 'package:votewala/state/deep_link.dart';
import 'package:votewala/widgets/share_card.dart';
import 'package:votewala/utils.dart';

void main() {
  group('AP data', () {
    test('has 175 assembly and 25 parliament constituencies', () {
      expect(ApData.mla, hasLength(175));
      expect(ApData.mp, hasLength(25));
    });

    test('each assembly segment belongs to exactly one parliament constituency', () {
      final segments = [for (final pc in ApData.mp) ...pc.segments]..sort();
      expect(segments, List.generate(175, (i) => i + 1));
      for (final pc in ApData.mp) {
        expect(pc.segments, hasLength(7));
      }
    });

    test('district ranges cover every assembly constituency', () {
      expect(ApData.districts.fold(0, (a, d) => a + d.mlaCount), 175);
      expect(ApData.mla.first.districtIds, ['srikakulam']);
      expect(ApData.mla.last.districtIds, ['chittoor']);
    });

    test('ids round-trip', () {
      expect(ApData.byId('mla-21').en, 'Visakhapatnam East');
      expect(ApData.byId('mp-12').en, 'Vijayawada');
      final cand = Candidate(ApData.byId('mla-87'), 2);
      expect(Candidate.byId(cand.id).index, 2);
    });
  });

  group('2024 results', () {
    test('winners match the official seat tally', () {
      int seats(ElectionType t, String party) =>
          ApData.of(t).where((c) => Candidate(c, 0).party.id == party).length;
      expect(seats(ElectionType.mla, 'tdp'), 135);
      expect(seats(ElectionType.mla, 'jsp'), 21);
      expect(seats(ElectionType.mla, 'bjp'), 8);
      expect(seats(ElectionType.mla, 'ysrcp'), 11);
      expect(seats(ElectionType.mp, 'tdp'), 16);
      expect(seats(ElectionType.mp, 'ysrcp'), 4);
      expect(Candidate(ApData.byId('mla-175'), 0).name(false), contains('Chandrababu'));
    });
  });

  group('polls', () {
    test('snapshots count real votes only; empty polls have no leader', () {
      final c = ApData.byId('mla-37');
      const month = PollMonth(2026, 3);
      final empty = PollSnapshot(c, [0, 0, 0], month: month);
      final some = PollSnapshot(c, [3, 5, 1], month: month);
      expect(empty.closed, isTrue);
      expect(empty.hasVotes, isFalse);
      expect(some.leader, 1);
      expect(SeatTally([empty, some]).total, 1);
    });

    test('one MLA and one MP vote per user per month, counted in the tallies', () async {
      final (state, store) = await newState();
      await state.signIn(alice);
      final outcome = await state.castVote(Candidate(ApData.byId('mla-21'), 0));
      expect(outcome.newBadges.map((b) => b.id), ['first-voice']);
      await expectLater(state.castVote(Candidate(ApData.byId('mla-22'), 1)), throwsA(isA<VoteException>()));
      await state.castVote(Candidate(ApData.byId('mp-4'), 0));
      expect(state.canVote(ApData.byId('mp-5')), isFalse);
      expect(state.choiceIndex(ApData.byId('mla-21')), 0);
      expect(state.voteCount, 2);

      final m = PollMonth.current().key;
      expect(store.docs['tallies/mla-$m/buckets/mla-21'], containsPair('o0', 1));
      expect(store.docs['users/alice'], containsPair('voteCount', 2));
      expect(store.docs.containsKey('users/alice/badges/first-voice'), isTrue);

      // The database refuses a second ballot even if the app thinks it can vote.
      final again = VoteService(store, MemoryPhotoStore(), minGap: Duration.zero);
      await expectLater(
        again.castOption(uid: 'alice', pollId: 'mla-$m', bucket: 'mla-22', option: 1),
        throwsA(isA<VoteException>().having((e) => e.error, 'error', VoteError.alreadyVoted)),
      );

      // Votes follow the account, not the device.
      await state.signIn(bob);
      expect(state.canVote(ApData.byId('mla-22')), isTrue);
      await state.signIn(alice);
      expect(state.canVote(ApData.byId('mla-22')), isFalse);
    });

    test('featured polls allow one vote per user', () async {
      final (state, _) = await newState();
      await state.signIn(alice);
      final cm = featuredById('cm-2026');
      if (cm.isOpen) {
        await state.castFeaturedVote(cm, 2);
        await expectLater(state.castFeaturedVote(cm, 1), throwsA(isA<VoteException>()));
        expect(state.featuredChoice(cm), 2);
        expect(state.featuredVoteMonth(cm), PollMonth.current());
      }
      expect(featuredById('artificial-paneer-ban-2026').end.difference(featuredById('artificial-paneer-ban-2026').start).inDays, 10);
    });

    test('local issues, evidence photos and threshold alerts', () async {
      final (state, store) = await newState();
      store.docs['settings/thresholds'] = {'default': 2};
      final c = ApData.byId('mla-21');
      final m = PollMonth.current().key;
      await state.signIn(alice);
      await state.castIssues(c, {'c0': 1, 'c3': 0}, otherText: 'Bus stand roof');
      await state.addIssuePhoto('c0', Uint8List.fromList([1, 2, 3]), 'Potholes');
      await state.signIn(bob);
      await state.castIssues(c, {'c0': 1});
      await Future<void>.delayed(Duration.zero);

      expect(store.docs['tallies/issues-$m/buckets/mla-21_c0'], {'o1': 2, 'total': 2, 'p1': 1});
      expect(store.docs['photos/issues-${m}_alice_c0'], containsPair('status', 'pending'));
      expect(store.docs['otherIssues/issues-${m}_alice'], containsPair('text', 'Bus stand roof'));
      expect(store.docs.keys.where((k) => k.startsWith('alerts/')), ['alerts/issues-${m}_mla-21_c0_2']);
      await expectLater(state.castIssues(c, {'c1': 0}), throwsA(isA<VoteException>()));
    });
  });

  group('admin config', () {
    tearDown(() => ConfigService.instance.apply(AppConfig.defaults()));

    test('round-trips through JSON', () {
      final c = AppConfig.defaults().copyWith(
        candidates: {'mla-175-0': const CandidateOverride(nameTe: 'చంద్రబాబు', photoUrl: 'https://x/p.png')},
        constituencyNames: {'mla-1': const NamePair(en: 'Ichchapuram (Town)')},
        home: const HomeConfig(topMla: ['mla-1']),
      );
      final back = AppConfig.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(back.toJson()), jsonEncode(c.toJson()));
      expect(back.featured.length, defaultFeaturedPolls.length);
      expect(back.parties.length, defaultParties.length);
    });

    test('overrides apply to candidates, parties, constituencies and polls', () {
      final kuppam = Candidate(ApData.byId('mla-175'), 0);
      final officialName = kuppam.name(false);
      ConfigService.instance.apply(AppConfig.defaults().copyWith(
        candidates: {kuppam.id: const CandidateOverride(name: 'New Name', nameTe: 'కొత్త పేరు', photoUrl: 'https://x/p.png')},
        constituencyNames: {'mla-175': const NamePair(te: 'కుప్పం (కొత్త)')},
        parties: [for (final p in defaultParties) p.id == 'tdp' ? p.copyWith(short: 'TDP*') : p],
        featured: [FeaturedPoll.fromJson({...defaultFeaturedPolls.first.toJson(), 'enabled': false}), ...defaultFeaturedPolls.skip(1)],
      ));
      expect(kuppam.name(false), 'New Name');
      expect(kuppam.name(true), 'కొత్త పేరు');
      expect(kuppam.photoUrl, 'https://x/p.png');
      expect(kuppam.party.short, 'TDP*');
      expect(ApData.byId('mla-175').name(true), 'కుప్పం (కొత్త)');
      expect(ApData.byId('mla-175').name(false), 'Kuppam');
      expect(featuredPolls.length, defaultFeaturedPolls.length - 1);

      ConfigService.instance.apply(AppConfig.defaults());
      expect(kuppam.name(false), officialName);
    });

    test('older documents missing sections fall back to defaults', () {
      final c = AppConfig.fromJson({'branding': {'primary': '#7C3AED'}});
      expect(colorToHex(c.branding.primary), '#7C3AED');
      expect(c.home.topMla, const HomeConfig().topMla);
      expect(c.featured.length, defaultFeaturedPolls.length);
    });
  });

  test('share links and deep links round-trip', () {
    expect(constituencyLink(ApData.byId('mla-37')), 'https://votewala-a2dcd.web.app/#/c/mla-37');
    DeepLink.parse('/c/mla-37');
    DeepLink.parse('/admin'); // not a share link: keeps the earlier one
    DeepLink.parse('/c/<script>'); // rejected
    expect(DeepLink.pending, 'c:mla-37');
    DeepLink.clear();
    expect(featuredLink(featuredById('cm-2026')), 'https://votewala-a2dcd.web.app/#/f/cm-2026');
  });

  test('formatting', () {
    expect(formatIndian(124580), '1,24,580');
    expect(formatIndian(12548), '12,548');
    expect(formatCompact(72400), '72.4K');
    expect(formatCompact(120000), '1.2L');
  });

  testWidgets('sign-in page registers or signs in, and votes are recorded', (tester) async {
    final (state, store) = await newState();
    await tester.pumpWidget(VoteWalaApp(state: state));

    // One page: language, email sign-in / register, and Google.
    expect(find.text('తెలుగు'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Re-enter password'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'voter@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.enterText(find.byType(TextField).at(2), 'secret2');
    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(state.user, isNotNull);
    expect(find.text('MLA Polls'), findsOneWidget);
    expect(find.text('Featured Polls'), findsOneWidget);
    expect(find.text('Vote for CM'), findsOneWidget);

    final c = ApData.byId('mla-21');
    await tester.runAsync(() => state.castVote(Candidate(c, 0)));
    expect(state.choiceIndex(c), 0);
    expect(state.voteHistory, hasLength(1));
    expect(store.docs.keys, contains('votes/mla-${PollMonth.current().key}/ballots/demo-google'));
  });
}

const alice = AppUser(uid: 'alice', name: 'A', phone: '+91 9000000001', provider: 'phone');
const bob = AppUser(uid: 'bob', name: 'B', phone: '+91 9000000002', provider: 'phone');

Future<(AppState, MemoryStore)> newState() async {
  SharedPreferences.setMockInitialValues({});
  final store = MemoryStore();
  final state = AppState(
    await SharedPreferences.getInstance(),
    auth: DemoAuthService(),
    votes: VoteService(store, MemoryPhotoStore(), minGap: Duration.zero),
  );
  return (state, store);
}
