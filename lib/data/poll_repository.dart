import 'dart:math';

import '../config/app_config.dart';
import '../config/config_service.dart';
import 'ap_data.dart';
import 'poll_month.dart';
import 'results_2024.dart';

enum CandidateRole { won2024, runnerUp2024, other }

/// A poll option for a constituency: the 2024 winner, the 2024 runner-up, or
/// "Others / NOTA".
class Candidate {
  const Candidate(this.constituency, this.index);

  final Constituency constituency;
  final int index;

  Result2024 get result2024 => (constituency.isMla ? assembly2024 : loksabha2024)[constituency.no - 1];
  CandidateRole get role => CandidateRole.values[index];

  Contestant2024? get contestant => switch (role) {
        CandidateRole.won2024 => result2024.winner,
        CandidateRole.runnerUp2024 => result2024.runnerUp,
        CandidateRole.other => null,
      };

  bool get isPerson => contestant != null;
  String get id => '${constituency.id}-$index';
  CandidateOverride? get _override => appConfig.candidates[id];

  Party get party => partyById(_override?.partyId ?? contestant?.partyId ?? 'oth');
  String? get photoUrl => _override?.photoUrl ?? contestant?.photoUrl;

  String name(bool telugu) {
    final o = _override;
    if (contestant == null) return telugu ? 'ఇతరులు / నోటా' : 'Others / NOTA';
    return (telugu ? o?.nameTe : null) ?? o?.name ?? contestant!.name;
  }

  static Candidate byId(String id) {
    final cut = id.lastIndexOf('-');
    return Candidate(ApData.byId(id.substring(0, cut)), int.parse(id.substring(cut + 1)));
  }
}

class PollSnapshot {
  PollSnapshot(this.constituency, this.votes, {required this.month});

  final Constituency constituency;
  final List<int> votes;
  final PollMonth month;

  bool get closed => month.isPast;
  List<Candidate> get candidates => PollRepository.candidates(constituency);
  int get total => votes.fold(0, (a, b) => a + b);
  double share(int i) => total == 0 ? 0 : votes[i] / total;

  /// Candidate indices ordered by votes, highest first.
  List<int> get ranking => List.generate(votes.length, (i) => i)..sort((a, b) => votes[b].compareTo(votes[a]));
  int get leader => ranking.first;
  Party get leadingParty => candidates[leader].party;
}

/// Seats led per party group (TDP, YSRCP, JSP, BJP, Others).
class SeatTally {
  SeatTally(Iterable<PollSnapshot> polls)
      : seats = {for (final g in seatGroups) g: 0},
        votes = polls.fold(0, (a, p) => a + p.total) {
    for (final p in polls) {
      seats[p.leadingParty.group] = seats[p.leadingParty.group]! + 1;
    }
  }

  final Map<String, int> seats;
  final int votes;

  int get total => seats.values.fold(0, (a, b) => a + b);

  /// Group with the most seats, or null when tied at the top.
  String? get leader {
    final sorted = seatGroups.toList()..sort((a, b) => seats[b]!.compareTo(seats[a]!));
    if (seats[sorted[0]] == 0 || seats[sorted[0]] == seats[sorted[1]]) return null;
    return sorted[0];
  }
}

class DistrictSummary {
  DistrictSummary(this.district, this.polls) : tally = SeatTally(polls);

  final District district;
  final List<PollSnapshot> polls;
  final SeatTally tally;
}

/// Generates deterministic sample opinion-poll counts per constituency per
/// month. Replace with API calls when the backend is available.
class PollRepository {
  static final _candidates = <String, List<Candidate>>{};

  static List<Candidate> candidates(Constituency c) => _candidates.putIfAbsent(
      c.id, () => List.generate(CandidateRole.values.length, (i) => Candidate(c, i), growable: false));

  static bool _isNda(String partyId) => partyId == 'tdp' || partyId == 'jsp' || partyId == 'bjp';

  static PollSnapshot snapshot(Constituency c, {PollMonth? month, int? userChoice}) {
    final m = month ?? PollMonth.current();
    final rnd = Random(c.no * 7919 + (c.isMla ? 0 : 104729) + m.index * 31337);
    final weights = <double>[36 + rnd.nextDouble() * 20, 28 + rnd.nextDouble() * 20, 3 + rnd.nextDouble() * 7];

    // Regional NDA-vs-opposition swing that varies by district and month.
    final districtIndex = ApData.districts.indexWhere((x) => x.id == c.districtIds.first);
    final swing = Random(districtIndex * 97 + m.index * 13).nextDouble() * 24 - 12;
    final result = PollRepository.candidates(c).first.result2024;
    final winnerIsNda = _isNda(result.winner.partyId);
    final runnerIsNda = _isNda(result.runnerUp.partyId);
    if (winnerIsNda != runnerIsNda) {
      weights[0] = max(1, weights[0] + (winnerIsNda ? swing : -swing));
      weights[1] = max(1, weights[1] + (runnerIsNda ? swing : -swing));
    }
    final sum = weights.reduce((a, b) => a + b);

    final full = c.isMla ? 4000 + rnd.nextInt(14000) : 40000 + rnd.nextInt(90000);
    final total = (full * (0.1 + 0.9 * m.elapsed)).round();
    final votes = [for (final w in weights) (total * w / sum).round()];
    if (userChoice != null) votes[userChoice] += 1;
    return PollSnapshot(c, votes, month: m);
  }
}
