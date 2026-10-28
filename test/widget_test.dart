import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votewala/data/ap_data.dart';
import 'package:votewala/data/poll_repository.dart';
import 'package:votewala/main.dart';
import 'package:votewala/state/app_state.dart';
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
      expect(Candidate.byId(cand.id).party.id, 'jsp');
    });
  });

  group('polls', () {
    test('snapshots are deterministic and count the user vote', () {
      final c = ApData.byId('mla-37');
      final day = DateTime.utc(2026, 3, 1);
      final a = PollRepository.snapshot(c, day: day);
      final b = PollRepository.snapshot(c, day: day, userChoice: 1);
      expect(a.closed, isTrue); // past days are closed
      expect(b.votes[1], a.votes[1] + 1);
      expect(a.ranking.first, a.leader);
    });
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
    expect(find.text("Today's Featured Polls"), findsOneWidget);

    final c = ApData.byId('mla-21');
    state.castVote(Candidate(c, 0));
    expect(state.choiceIndex(c), 0);
    expect(state.voteHistory, hasLength(1));
    expect(prefs.getString('votes'), contains('mla-21'));
  });
}
