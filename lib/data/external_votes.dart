import 'external_data.dart';
import 'featured_polls.dart';
import 'poll_month.dart';

/// Months of [poll] that include external (Facebook) data, oldest first.
List<PollMonth> externalMonths(FeaturedPoll poll) => [
  for (final k in (ExternalData.featured[poll.id]?.keys.toList() ?? <String>[])..sort()) PollMonth.parse(k),
];

bool hasExternalFeatured(FeaturedPoll poll, [PollMonth? month]) {
  final months = ExternalData.featured[poll.id];
  return months != null && (month == null || months.containsKey(month.key));
}

/// External votes per option of [poll] in [month] (zeros when none).
List<int> externalFeaturedVotes(FeaturedPoll poll, String monthKey) {
  final byName = ExternalData.featured[poll.id]?[monthKey] ?? const <String, int>{};
  return [for (final o in poll.options) byName[o.en] ?? 0];
}
