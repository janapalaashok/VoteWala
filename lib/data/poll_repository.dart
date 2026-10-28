import 'dart:math';

import '../utils.dart';
import 'ap_data.dart';

/// A contesting candidate. Profile details are generated sample data until a
/// real backend (ECI affidavit data) is wired in.
class Candidate {
  const Candidate(this.constituency, this.index);

  final Constituency constituency;
  final int index;

  Party get party => parties[index];
  String get id => '${constituency.id}-${party.id}';
  String name(bool telugu) => telugu ? 'అభ్యర్థి ${index + 1}' : 'Candidate ${index + 1}';

  int get _seed => constituency.no * 101 + index * 17 + (constituency.isMla ? 0 : 5003);

  static const _education = ['B.Tech', 'M.A.', 'B.Com', 'LL.B', 'MBBS', 'M.B.A.', 'Intermediate', 'B.Sc'];
  String get education => _education[_seed % _education.length];
  double get assetsCrore => ((_seed * 37) % 400) / 10 + 0.4;
  int get criminalCases => (_seed * 13) % 7 < 4 ? 0 : _seed % 4 + 1;

  static Candidate byId(String id) {
    final cut = id.lastIndexOf('-');
    final c = ApData.byId(id.substring(0, cut));
    return Candidate(c, parties.indexWhere((p) => p.id == id.substring(cut + 1)));
  }
}

class PollSnapshot {
  PollSnapshot(this.constituency, this.votes, {required this.closed, required this.day});

  final Constituency constituency;
  final List<int> votes;
  final bool closed;
  final DateTime day;

  List<Candidate> get candidates => PollRepository.candidates(constituency);
  int get total => votes.fold(0, (a, b) => a + b);
  double share(int i) => total == 0 ? 0 : votes[i] / total;

  /// Candidate indices ordered by votes, highest first.
  List<int> get ranking => List.generate(votes.length, (i) => i)..sort((a, b) => votes[b].compareTo(votes[a]));
  int get leader => ranking.first;
  double get margin => share(ranking[0]) - share(ranking[1]);
}

enum RaceStatus { clearLead, close, tight, noData }

RaceStatus raceStatusFor(int total, double margin) {
  if (total == 0) return RaceStatus.noData;
  if (margin >= 0.10) return RaceStatus.clearLead;
  if (margin >= 0.03) return RaceStatus.close;
  return RaceStatus.tight;
}

class DistrictSummary {
  DistrictSummary(this.district, this.partyVotes, this.polls);

  final District district;
  final List<int> partyVotes;
  final List<PollSnapshot> polls;

  int get total => partyVotes.fold(0, (a, b) => a + b);
  List<int> get ranking => List.generate(partyVotes.length, (i) => i)..sort((a, b) => partyVotes[b].compareTo(partyVotes[a]));
  Party get leadingParty => parties[ranking.first];
  double get margin => total == 0 ? 0 : (partyVotes[ranking[0]] - partyVotes[ranking[1]]) / total;
  RaceStatus get status => raceStatusFor(total, margin);
}

/// Generates deterministic sample poll data per constituency per day.
/// Replace with API calls when a backend is available.
class PollRepository {
  static final _epoch = DateTime.utc(2026, 1, 1);
  static final _candidates = <String, List<Candidate>>{};

  static List<Candidate> candidates(Constituency c) =>
      _candidates.putIfAbsent(c.id, () => List.generate(parties.length, (i) => Candidate(c, i), growable: false));

  static int _dayIndex(DateTime day) => day.difference(_epoch).inDays;

  static PollSnapshot snapshot(Constituency c, {DateTime? day, int? userChoice}) {
    final d = day ?? istToday();
    final today = istToday();
    final seed = c.no * 7919 + (c.isMla ? 0 : 104729) + _dayIndex(d) * 31337;
    final rnd = Random(seed);
    final weights = <double>[
      26 + rnd.nextDouble() * 20,
      26 + rnd.nextDouble() * 20,
      8 + rnd.nextDouble() * 14,
      3 + rnd.nextDouble() * 8,
      1 + rnd.nextDouble() * 3,
    ];
    // Regional swing so districts differ from each other.
    final districtIndex = ApData.districts.indexWhere((x) => x.id == c.districtIds.first);
    final swing = Random(districtIndex * 97 + _dayIndex(d)).nextDouble() * 24 - 12;
    weights[0] = max(1, weights[0] + swing);
    weights[1] = max(1, weights[1] - swing);
    final sum = weights.reduce((a, b) => a + b);

    var total = c.isMla ? 4000 + rnd.nextInt(14000) : 40000 + rnd.nextInt(90000);
    final closed = d.isBefore(today) || Random(seed + 1).nextInt(100) < 19;
    if (!closed && !d.isAfter(today)) {
      // Live polls fill up through the day.
      final elapsed = 1 - timeUntilPollClose().inMinutes / (24 * 60);
      total = (total * (0.35 + 0.65 * elapsed)).round();
    }
    final votes = [for (final w in weights) (total * w / sum).round()];
    if (userChoice != null) votes[userChoice] += 1;
    return PollSnapshot(c, votes, closed: closed, day: d);
  }

  static DistrictSummary districtSummary(
    District district,
    ElectionType type, {
    DateTime? day,
    int? Function(Constituency c)? choiceOf,
  }) {
    final polls = [
      for (final c in ApData.of(type))
        if (c.districtIds.contains(district.id)) snapshot(c, day: day, userChoice: choiceOf?.call(c)),
    ];
    final partyVotes = List.filled(parties.length, 0);
    for (final p in polls) {
      for (var i = 0; i < parties.length; i++) {
        partyVotes[i] += p.votes[i];
      }
    }
    return DistrictSummary(district, partyVotes, polls);
  }
}
