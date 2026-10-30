import 'ap_data.dart';
import 'civic.dart';

/// Steps of a grievance. Only admins move a grievance forward, each step with
/// a date and a note; the public page shows exactly what was recorded.
enum GrievanceStatus { threshold, reportGenerated, sentToMla, responseReceived, actionReported, resolved }

class GrievanceStep {
  const GrievanceStep(this.status, this.at, [this.note = '']);

  final GrievanceStatus status;
  final DateTime at;

  /// Public note, e.g. "Emailed to the MLA office on 3 Nov".
  final String note;

  Map<String, Object?> toFields() => {'status': status.name, 'at': at.toUtc(), 'note': note};

  factory GrievanceStep.fromFields(Map<String, Object?> m) => GrievanceStep(
        GrievanceStatus.values.asNameMap()[m['status']] ?? GrievanceStatus.threshold,
        (m['at'] as DateTime?) ?? DateTime.fromMillisecondsSinceEpoch(0),
        (m['note'] as String?) ?? '',
      );
}

/// A collective local issue that crossed the admin threshold, stored at
/// grievances/{pollId_constituency_slot}. Holds totals only, never voters.
class Grievance {
  const Grievance({
    required this.id,
    required this.pollId,
    required this.constituencyId,
    required this.slot,
    required this.good,
    required this.bad,
    required this.badWithPhoto,
    required this.steps,
  });

  final String id;
  final String pollId;
  final String constituencyId;
  final String slot;
  final int good, bad, badWithPhoto;
  final List<GrievanceStep> steps;

  static String idFor(String pollId, String constituencyId, String slot) => '${pollId}_${constituencyId}_$slot';

  Constituency? get constituency => ApData.byIdOrNull(constituencyId);
  CivicCategory? get category => categoryBySlot(slot);
  GrievanceStatus get status => steps.isEmpty ? GrievanceStatus.threshold : steps.last.status;
  DateTime? get updatedAt => steps.isEmpty ? null : steps.last.at;

  /// "issues-2026-10" -> "2026-10".
  String get monthKey => pollId.substring(pollId.indexOf('-') + 1);

  Grievance withStep(GrievanceStep step) => Grievance(
        id: id,
        pollId: pollId,
        constituencyId: constituencyId,
        slot: slot,
        good: good,
        bad: bad,
        badWithPhoto: badWithPhoto,
        steps: [...steps, step],
      );

  Map<String, Object?> toFields() => {
        'pollId': pollId,
        'constituencyId': constituencyId,
        'slot': slot,
        'good': good,
        'bad': bad,
        'badWithPhoto': badWithPhoto,
        'status': status.name,
        'steps': [for (final s in steps) s.toFields()],
      };

  factory Grievance.fromFields(String id, Map<String, Object?> m) => Grievance(
        id: id,
        pollId: (m['pollId'] as String?) ?? '',
        constituencyId: (m['constituencyId'] as String?) ?? '',
        slot: (m['slot'] as String?) ?? '',
        good: (m['good'] as int?) ?? 0,
        bad: (m['bad'] as int?) ?? 0,
        badWithPhoto: (m['badWithPhoto'] as int?) ?? 0,
        steps: [
          for (final s in (m['steps'] as List?) ?? const [])
            if (s is Map<String, Object?>) GrievanceStep.fromFields(s),
        ],
      );
}
