import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'app_config.dart';

/// Firebase project settings. Defaults point at the VoteWala project; a build
/// can target another project with --dart-define=FIREBASE_API_KEY=... etc.
///
/// The web API key is not a secret (it ships inside every Firebase app);
/// access is controlled by firestore.rules and storage.rules.
class FirebaseSettings {
  const FirebaseSettings({required this.apiKey, required this.projectId, required this.storageBucket});

  static const fromEnvironment = FirebaseSettings(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyAimoZLqju6M4goUgfSvPxXmZaEhvBzu-I'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'votewala-a2dcd'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'votewala-a2dcd.firebasestorage.app'),
  );

  final String apiKey;
  final String projectId;
  final String storageBucket;

  bool get isConfigured => apiKey.isNotEmpty && projectId.isNotEmpty;
}

class FirebaseException implements Exception {
  FirebaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Minimal Firebase client over the public REST APIs (Auth, Firestore,
/// Storage). Works the same on Android, iOS and web with no native setup.
///
/// The config lives in Firestore at config/app as a single `json` string
/// field. Admins are users whose uid has a document in the `admins`
/// collection (see firestore.rules).
class FirebaseRest {
  FirebaseRest(this.settings, {http.Client? client}) : _http = client ?? http.Client();

  final FirebaseSettings settings;
  final http.Client _http;

  String? _idToken;
  String? uid;
  String? email;

  bool get signedIn => _idToken != null;

  /// The admin's ID token for other Firebase requests.
  String? get idToken => _idToken;

  String get _docs =>
      'https://firestore.googleapis.com/v1/projects/${settings.projectId}/databases/(default)/documents';

  Map<String, String> get _auth => {if (_idToken != null) 'Authorization': 'Bearer $_idToken'};

  /// Admins sign in with a username; it maps to a sign-in-only address.
  static const adminDomain = 'admin.votewala.in';

  static String loginEmail(String usernameOrEmail) {
    final v = usernameOrEmail.trim().toLowerCase();
    return v.contains('@') ? v : '$v@$adminDomain';
  }

  /// "admin" for admin@admin.votewala.in, the address otherwise.
  static String usernameOf(String? email) =>
      email == null ? '' : (email.endsWith('@$adminDomain') ? email.split('@').first : email);

  Future<void> signIn(String usernameOrEmail, String password) async {
    final email = loginEmail(usernameOrEmail);
    final r = await _http.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${settings.apiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200) {
      final code = (body['error'] as Map?)?['message'] as String? ?? 'SIGN_IN_FAILED';
      throw FirebaseException(switch (code) {
        'CONFIGURATION_NOT_FOUND' || 'OPERATION_NOT_ALLOWED' =>
          'Email/Password sign-in is not enabled: Firebase console → Authentication → Sign-in method.',
        'USER_DISABLED' => 'This account is disabled in Firebase Authentication.',
        _ when code.startsWith('TOO_MANY_ATTEMPTS') => 'Too many attempts. Try again in a few minutes.',
        _ when code.contains('INVALID') || code.contains('NOT_FOUND') => 'Wrong username or password',
        _ => code,
      });
    }
    _idToken = body['idToken'] as String;
    uid = body['localId'] as String;
    this.email = body['email'] as String?;
  }

  void signOut() {
    _idToken = null;
    uid = null;
    email = null;
  }

  /// True when the signed-in user is listed in the admins collection.
  Future<bool> isAdmin() async => (await adminProfile()) != null;

  /// The admins/{uid} document (role, username, displayName,
  /// mustChangePassword), or null for non-admins.
  Future<Map<String, Object?>?> adminProfile() async {
    if (uid == null) return null;
    final r = await _http.get(Uri.parse('$_docs/admins/$uid'), headers: _auth);
    if (r.statusCode != 200) return null;
    final fields = (jsonDecode(r.body) as Map<String, dynamic>)['fields'] as Map<String, dynamic>? ?? const {};
    return {
      for (final e in fields.entries) e.key: (e.value as Map).values.first,
    };
  }

  /// Updates the admin's own profile fields (see firestore.rules).
  Future<void> updateAdminProfile(Map<String, Object> fields) async {
    final mask = fields.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
    final r = await _http.patch(
      Uri.parse('$_docs/admins/$uid?$mask'),
      headers: {..._auth, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          for (final e in fields.entries)
            e.key: e.value is bool ? {'booleanValue': e.value} : {'stringValue': '${e.value}'},
        },
      }),
    );
    if (r.statusCode != 200) throw FirebaseException('Could not save profile (${r.statusCode})');
  }

  Future<void> _updateAccount(Map<String, Object> changes) async {
    final r = await _http.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:update?key=${settings.apiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': _idToken, ...changes, 'returnSecureToken': true}),
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200) {
      final code = (body['error'] as Map?)?['message'] as String? ?? 'UPDATE_FAILED';
      throw FirebaseException(switch (code) {
        _ when code.startsWith('WEAK_PASSWORD') => 'Use at least 6 characters for the password.',
        'EMAIL_EXISTS' => 'That username is already taken.',
        'CREDENTIAL_TOO_OLD_LOGIN_AGAIN' || 'TOKEN_EXPIRED' => 'Please sign in again and retry.',
        _ => code,
      });
    }
    _idToken = body['idToken'] as String? ?? _idToken;
    email = body['email'] as String? ?? email;
  }

  /// Checks [current] by signing in again, then sets [next].
  Future<void> changePassword(String current, String next) async {
    final address = email;
    if (address == null) throw FirebaseException('Not signed in');
    try {
      await signIn(address, current);
    } on FirebaseException {
      throw FirebaseException('Current password is wrong');
    }
    await _updateAccount({'password': next});
  }

  /// Changes the sign-in username (or email).
  Future<void> changeUsername(String username) => _updateAccount({'email': loginEmail(username)});

  Future<AppConfig?> fetchConfig() async {
    final r = await _http.get(Uri.parse('$_docs/config/app?key=${settings.apiKey}'));
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw FirebaseException('Could not load config (${r.statusCode})');
    final fields = (jsonDecode(r.body) as Map<String, dynamic>)['fields'] as Map<String, dynamic>?;
    final json = (fields?['json'] as Map?)?['stringValue'] as String?;
    return json == null ? null : AppConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> publishConfig(AppConfig config) async {
    final now = DateTime.now().toUtc();
    final doc = config.copyWith(updatedAt: now, updatedBy: email);
    final r = await _http.patch(
      Uri.parse('$_docs/config/app'),
      headers: {..._auth, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'json': {'stringValue': jsonEncode(doc.toJson())},
          'updatedAt': {'timestampValue': now.toIso8601String()},
          'updatedBy': {'stringValue': email ?? ''},
        },
      }),
    );
    if (r.statusCode != 200) {
      throw FirebaseException(r.statusCode == 403
          ? 'Permission denied: this account is not an admin'
          : 'Publish failed (${r.statusCode})');
    }
  }

  /// Uploads a file to Firebase Storage and returns its public download URL.
  Future<String> upload(String path, Uint8List bytes, String contentType) async {
    const notEnabled = 'Photo upload needs Firebase Storage, which is not enabled yet. '
        'Use "Paste URL" for now, or enable Storage (docs/FIREBASE_SETUP.md, step 4).';
    final bucket = settings.storageBucket;
    if (bucket.isEmpty) throw FirebaseException(notEnabled);
    final http.Response r;
    try {
      r = await _http.post(
        Uri.parse('https://firebasestorage.googleapis.com/v0/b/$bucket/o?uploadType=media&name=${Uri.encodeQueryComponent(path)}'),
        headers: {if (_idToken != null) 'Authorization': 'Firebase $_idToken', 'Content-Type': contentType},
        body: bytes,
      );
    } catch (_) {
      throw FirebaseException(notEnabled);
    }
    if (r.statusCode != 200) {
      throw FirebaseException(switch (r.statusCode) {
        403 => 'Upload blocked by Firebase Storage. The site owner must allow Storage to read the admin list once: '
            'Firebase console -> Storage -> Rules (accept the "grant access to Cloud Firestore" prompt), or '
            'Google Cloud -> IAM -> service-596383314349@gcp-sa-firebasestorage.iam.gserviceaccount.com -> add role '
            '"Firebase Rules Firestore Service Agent". Until then use "Paste URL".',
        400 || 404 || 412 => notEnabled,
        _ => 'Upload failed (${r.statusCode})',
      });
    }
    final meta = jsonDecode(r.body) as Map<String, dynamic>;
    final token = (meta['downloadTokens'] as String?)?.split(',').first;
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media'
        '${token == null ? '' : '&token=$token'}';
  }
}
