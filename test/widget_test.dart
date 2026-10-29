import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votewala/config/app_config.dart';
import 'package:votewala/config/config_service.dart';
import 'package:votewala/data/ap_data.dart';
import 'package:votewala/data/featured_polls.dart';
import 'package:votewala/data/poll_month.dart';
import 'package:votewala/data/poll_repository.dart';
import 'package:votewala/main.dart';
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
    test('past months are closed, snapshots are deterministic and count the user vote', () {
      final c = ApData.byId('mla-37');
      const month = PollMonth(2026, 3);
      final a = PollRepository.snapshot(c, month: month);
      final b = PollRepository.snapshot(c, month: month, userChoice: 1);
      expect(a.closed, isTrue);
      expect(b.votes[1], a.votes[1] + 1);
      expect(a.ranking.first, a.leader);
      expect(SeatTally(ApData.mla.map((c) => PollRepository.snapshot(c, month: month))).total, 175);
    });

    test('one MLA and one MP vote per user per month', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState(await SharedPreferences.getInstance());
      state.signIn(const AppUser(name: 'A', email: 'a@x.com', provider: 'google'));
      expect(state.castVote(Candidate(ApData.byId('mla-21'), 0)), isTrue);
      expect(state.castVote(Candidate(ApData.byId('mla-22'), 1)), isFalse);
      expect(state.castVote(Candidate(ApData.byId('mla-21'), 1)), isFalse);
      expect(state.castVote(Candidate(ApData.byId('mp-4'), 0)), isTrue);
      expect(state.canVote(ApData.byId('mp-5')), isFalse);
      expect(state.choiceIndex(ApData.byId('mla-21')), 0);

      // A different account on the same device has its own votes.
      state.signIn(const AppUser(name: 'B', email: 'b@x.com', provider: 'google'));
      expect(state.canVote(ApData.byId('mla-22')), isTrue);
    });

    test('featured polls allow one vote per user', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState(await SharedPreferences.getInstance());
      state.signIn(const AppUser(name: 'A', email: 'a@x.com', provider: 'google'));
      final cm = featuredById('cm-2026');
      final before = state.featuredTotals(cm)[2];
      expect(state.castFeaturedVote(cm, 2), cm.isOpen);
      if (cm.isOpen) {
        expect(state.castFeaturedVote(cm, 1), isFalse);
        expect(state.featuredTotals(cm)[2], before + 1);
      }
      expect(featuredById('artificial-paneer-ban-2026').end.difference(featuredById('artificial-paneer-ban-2026').start).inDays, 10);
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

  testWidgets('language choice leads to login, and votes are recorded', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(prefs);
    await tester.pumpWidget(VoteWalaApp(state: state));

    expect(find.text('Continue in English'), findsOneWidget);
    await tester.tap(find.text('Continue in English'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to VoteWala'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(state.user, isNotNull);
    expect(find.text('MLA Polls'), findsOneWidget);
    expect(find.text('Featured Polls'), findsOneWidget);
    expect(find.text('Vote for CM'), findsOneWidget);

    final c = ApData.byId('mla-21');
    expect(state.castVote(Candidate(c, 0)), isTrue);
    expect(state.choiceIndex(c), 0);
    expect(state.voteHistory, hasLength(1));
    expect(prefs.getString('votes_v2'), contains('mla-21'));
  });
}
