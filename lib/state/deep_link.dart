import 'package:flutter/material.dart';

import '../data/ap_data.dart';
import '../data/featured_polls.dart';
import '../screens/featured_poll_screen.dart';
import '../screens/home_screen.dart';

/// Links shared from the share card: `#/c/<constituency id>` opens a
/// constituency poll, `#/f/<featured poll id>` a featured poll. The link is
/// kept until the user is signed in and the main screen is shown.
class DeepLink {
  static String? _pending;

  @visibleForTesting
  static String? get pending => _pending;

  @visibleForTesting
  static void clear() => _pending = null;

  /// Policy page opened from its web address (`#/legal/privacy`), shown
  /// without signing in.
  static final legal = ValueNotifier<String?>(null);

  static void parse(String fragment) {
    final l = RegExp(r'^/legal/([a-z]+)$').firstMatch(fragment);
    if (l != null) legal.value = l.group(1);
    final m = RegExp(r'^/(c|f)/([A-Za-z0-9-]+)$').firstMatch(fragment);
    if (m != null) _pending = '${m.group(1)}:${m.group(2)}';
  }

  /// Opens the pending link, if any. Unknown ids are ignored.
  static void openPending(BuildContext context) {
    final link = _pending;
    _pending = null;
    if (link == null) return;
    final id = link.substring(2);
    try {
      if (link.startsWith('c:')) {
        openConstituency(context, ApData.byId(id));
      } else {
        final poll = featuredById(id);
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FeaturedPollScreen(poll: poll)));
      }
    } catch (_) {
      // Bad or outdated link: just show the home page.
    }
  }
}
