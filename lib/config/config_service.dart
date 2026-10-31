import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';
import 'firebase_rest.dart';

/// Holds the live [AppConfig]: built-in defaults, then the cached copy, then
/// the latest published version from Firebase.
class ConfigService extends ChangeNotifier {
  ConfigService._();

  static final instance = ConfigService._();

  static const _cacheKey = 'app_config_cache';

  /// Demo mode (no Firebase): the admin panel publishes here, in this browser.
  static const localPublishKey = 'app_config_local';

  final FirebaseSettings settings = FirebaseSettings.fromEnvironment;
  AppConfig _config = AppConfig.defaults();
  SharedPreferences? _prefs;

  AppConfig get config => _config;
  bool get isRemote => settings.isConfigured;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final cached = prefs.getString(isRemote ? _cacheKey : localPublishKey);
    if (cached != null) {
      try {
        _config = AppConfig.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        // Ignore a corrupt cache; defaults stay in place.
      }
    }
    if (isRemote) refresh();
  }

  /// Fetches the latest published config (failures keep the current one).
  Future<void> refresh() async {
    try {
      final remote = await FirebaseRest(settings).fetchConfig();
      if (remote != null) {
        apply(remote);
        _prefs?.setString(_cacheKey, jsonEncode(remote.toJson()));
      }
    } catch (e) {
      debugPrint('Config refresh failed: $e');
    }
  }

  void apply(AppConfig config) {
    _config = config;
    notifyListeners();
  }

  /// Demo mode publish: save in this browser and apply immediately.
  Future<void> publishLocally(AppConfig config) async {
    final doc = config.copyWith(updatedAt: DateTime.now().toUtc(), updatedBy: 'demo');
    await _prefs?.setString(localPublishKey, jsonEncode(doc.toJson()));
    apply(doc);
  }
}

/// The current configuration (defaults until init/refresh).
AppConfig get appConfig => ConfigService.instance.config;
