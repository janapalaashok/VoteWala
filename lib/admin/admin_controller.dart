import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/config_service.dart';
import '../config/firebase_rest.dart';
import 'admin_data.dart';
import 'file_pick.dart';

/// Admin session: sign-in, the working draft, uploads and publishing.
///
/// Edits go to a draft (kept in this browser so a refresh doesn't lose them)
/// and reach users only when published.
class AdminController extends ChangeNotifier {
  AdminController(this._prefs) {
    final saved = _prefs.getString(_draftKey);
    if (saved != null) {
      try {
        _draft = AppConfig.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      } catch (_) {
        _draft = _service.config;
      }
    } else {
      _draft = _service.config;
    }
    _recomputeDirty();
  }

  static const _draftKey = 'admin_draft_config';

  final SharedPreferences _prefs;
  final ConfigService _service = ConfigService.instance;
  late final FirebaseRest? _rest = _service.isRemote ? FirebaseRest(_service.settings) : null;

  /// No Firebase project configured: publish only affects this browser.
  bool get demo => _rest == null;

  /// Votes, issues, photos and grievances (null in demo mode).
  late final AdminData? data = _rest == null ? null : AdminData(_rest, _service.settings);

  bool signedIn = false;
  String? email;

  /// From admins/{uid}.
  String role = 'admin';
  String? displayName;

  /// The first sign-in with the starting password must set a new one.
  bool mustChangePassword = false;

  String get username => FirebaseRest.usernameOf(email);
  bool busy = false;
  String? error;

  late AppConfig _draft;
  bool _dirty = false;

  AppConfig get draft => _draft;
  AppConfig get published => _service.config;
  bool get dirty => _dirty;

  void _recomputeDirty() {
    _dirty = jsonEncode(_draft.toJson()..remove('updatedAt')..remove('updatedBy')) !=
        jsonEncode(published.toJson()..remove('updatedAt')..remove('updatedBy'));
  }

  Future<void> signIn(String username, String password) async {
    final rest = _rest;
    if (rest == null) return;
    _setBusy(true);
    try {
      await rest.signIn(username, password);
      final profile = await rest.adminProfile();
      if (profile == null) {
        rest.signOut();
        throw FirebaseException('This account is not an admin.');
      }
      role = (profile['role'] as String?) ?? 'admin';
      displayName = profile['displayName'] as String?;
      mustChangePassword = profile['mustChangePassword'] == true;
      await _service.refresh();
      if (_prefs.getString(_draftKey) == null) _draft = _service.config;
      email = rest.email;
      signedIn = true;
      error = null;
      _recomputeDirty();
    } catch (e) {
      error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  void enterDemo() {
    signedIn = true;
    email = 'demo-admin';
    notifyListeners();
  }

  void signOut() {
    _rest?.signOut();
    signedIn = false;
    email = null;
    mustChangePassword = false;
    notifyListeners();
  }

  /// Runs an account change; returns an error message or null.
  Future<String?> _account(Future<void> Function(FirebaseRest rest) change) async {
    final rest = _rest;
    if (rest == null) return 'Not available in demo mode';
    _setBusy(true);
    try {
      await change(rest);
      email = rest.email;
      return null;
    } catch (e) {
      return '$e';
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> changePassword(String current, String next) => _account((rest) async {
        await rest.changePassword(current, next);
        if (mustChangePassword) {
          await rest.updateAdminProfile({'mustChangePassword': false});
          mustChangePassword = false;
        }
      });

  Future<String?> changeUsername(String next) => _account((rest) async {
        final clean = next.trim().toLowerCase();
        if (!RegExp(r'^[a-z0-9._-]{3,30}$').hasMatch(clean) && !clean.contains('@')) {
          throw FirebaseException('Use 3–30 letters, numbers, dots, dashes or underscores.');
        }
        await rest.changeUsername(clean);
        await rest.updateAdminProfile({'username': FirebaseRest.usernameOf(rest.email)});
      });

  Future<String?> changeDisplayName(String name) => _account((rest) async {
        await rest.updateAdminProfile({'displayName': name.trim()});
        displayName = name.trim();
      });

  /// Applies an edit to the draft.
  void update(AppConfig Function(AppConfig c) edit) {
    _draft = edit(_draft);
    _prefs.setString(_draftKey, jsonEncode(_draft.toJson()));
    _recomputeDirty();
    notifyListeners();
  }

  void replaceDraft(AppConfig config) => update((_) => config);

  void discardDraft() {
    _draft = published;
    _prefs.remove(_draftKey);
    _recomputeDirty();
    notifyListeners();
  }

  Future<bool> publish() async {
    _setBusy(true);
    try {
      final rest = _rest;
      if (rest == null) {
        await _service.publishLocally(_draft);
      } else {
        await rest.publishConfig(_draft);
        _service.apply(_draft.copyWith(updatedAt: DateTime.now().toUtc(), updatedBy: email));
      }
      _draft = _service.config;
      _prefs.remove(_draftKey);
      error = null;
      _recomputeDirty();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Uploads an image and returns its URL (a data URL in demo mode).
  Future<String?> uploadImage(String folder) async {
    final file = await pickImageFile();
    if (file == null) return null;
    final rest = _rest;
    if (rest == null) {
      if (file.bytes.length > 400 * 1024) {
        error = 'Demo mode keeps images in this browser: use files under 400 KB, or connect Firebase.';
        notifyListeners();
        return null;
      }
      return 'data:${file.contentType};base64,${base64Encode(file.bytes)}';
    }
    _setBusy(true);
    try {
      final safe = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      return await rest.upload('$folder/${DateTime.now().millisecondsSinceEpoch}_$safe', file.bytes, file.contentType);
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      _setBusy(false);
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void _setBusy(bool v) {
    busy = v;
    notifyListeners();
  }
}
