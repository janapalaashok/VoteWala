import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/featured_polls.dart';
import '../data/poll_repository.dart';
import '../screens/featured_poll_screen.dart';
import '../screens/home_screen.dart';
import '../screens/live_results_screen.dart';
import '../screens/candidate_detail_screen.dart';
import '../screens/constituency_list_screen.dart';
import '../widgets/daily_poll.dart';
import 'app_state.dart';
import 'url_sync.dart';

/// Page addresses opened directly (typed, refreshed, bookmarked or shared):
/// `/c/<constituency id>`, `/f/<featured poll id>`, `/results`, `/map`, ...
/// Older `#/c/...` links work too. The page opens once the voter is signed
/// in and the main screen is shown; tabs (`/mla`, `/results`, ...) select
/// the tab.
class DeepLink {
  static String? _pending;

  @visibleForTesting
  static String? get pending => _pending;

  @visibleForTesting
  static void clear() => _pending = null;

  /// Policy page opened from its web address (`/legal/privacy`), shown
  /// without signing in.
  static final legal = ValueNotifier<String?>(null);

  static final _constituency = RegExp(r'^/c/((?:mla|mp)-\d{1,3})(/results|/candidate/[0-2])?$');
  static final _featured = RegExp(r'^/f/([A-Za-z0-9-]+)$');
  static final _district = RegExp(r'^/(mla|mp)/district/([a-z0-9_-]+)$');
  static final _daily = RegExp(r'^/poll/([a-z0-9-]{1,60})$');

  static void parse(String path) {
    final l = RegExp(r'^/legal/([a-z]+)$').firstMatch(path);
    if (l != null) legal.value = l.group(1);
    if (_constituency.hasMatch(path) ||
        _featured.hasMatch(path) ||
        _district.hasMatch(path) ||
        _daily.hasMatch(path) ||
        UrlSync.tabPaths.contains(path) ||
        UrlSync.simplePages.containsKey(path)) {
      _pending = path;
    }
  }

  /// The shell tab a pending tab address asks for (and clears it).
  static int? takeTab() {
    final i = _pending == null ? -1 : UrlSync.tabPaths.indexOf(_pending!);
    if (i < 0) return null;
    _pending = null;
    return i;
  }

  /// A shared poll link: today's unanswered poll pops up by itself (the main
  /// screen does that); otherwise its page opens with the results. A first
  /// visit may still be loading the published polls, so wait a little.
  static Future<void> _openDaily(BuildContext context, String name, [int tries = 0]) async {
    final state = AppScope.read(context);
    final poll = state.dailyByLink(name);
    if (poll == null) {
      if (tries >= 10) return;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (context.mounted) await _openDaily(context, name, tries + 1);
      return;
    }
    if (poll.isToday) {
      // Wait for the voter's record: unanswered -> the popup asks it.
      if (!state.recordLoaded && tries < 10) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (context.mounted) await _openDaily(context, name, tries + 1);
        return;
      }
      if (state.dailyChoice(poll) == null && !state.blocked) return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DailyPollScreen(poll: poll)));
  }

  /// Opens the pending page, if any. Unknown ids are ignored.
  static void openPending(BuildContext context) {
    final path = _pending;
    _pending = null;
    if (path == null) return;
    void push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    try {
      if (_constituency.firstMatch(path) case final m?) {
        final c = ApData.byId(m.group(1)!);
        final extra = m.group(2);
        if (extra == null) {
          openConstituency(context, c);
        } else if (extra == '/results') {
          push(LiveResultsScreen(constituency: c));
        } else {
          push(CandidateDetailScreen(candidate: Candidate(c, int.parse(extra.split('/').last))));
        }
      } else if (_featured.firstMatch(path) case final m?) {
        push(FeaturedPollScreen(poll: featuredById(m.group(1)!)));
      } else if (_district.firstMatch(path) case final m?) {
        ApData.district(m.group(2)!); // throws for an unknown district
        push(ConstituencyListScreen(
            type: m.group(1) == 'mp' ? ElectionType.mp : ElectionType.mla, districtId: m.group(2)));
      } else if (_daily.firstMatch(path) case final m?) {
        _openDaily(context, m.group(1)!);
      } else if (UrlSync.simplePages[path] case final page?) {
        push(page());
      }
    } catch (_) {
      // Bad or outdated link: just show the home page.
    }
  }
}
