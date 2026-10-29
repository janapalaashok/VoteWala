import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'app_config.dart';

/// Firebase project settings, passed at build time:
///   --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_PROJECT_ID=...
///   --dart-define=FIREBASE_STORAGE_BUCKET=...
class FirebaseSettings {
  const FirebaseSettings({required this.apiKey, required this.projectId, required this.storageBucket});

  static const fromEnvironment = FirebaseSettings(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
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

  String get _docs =>
      'https://firestore.googleapis.com/v1/projects/${settings.projectId}/databases/(default)/documents';

  Map<String, String> get _auth => {if (_idToken != null) 'Authorization': 'Bearer $_idToken'};

  Future<void> signIn(String email, String password) async {
    final r = await _http.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${settings.apiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200) {
      final code = (body['error'] as Map?)?['message'] as String? ?? 'SIGN_IN_FAILED';
      throw FirebaseException(code.contains('INVALID') ? 'Wrong email or password' : code);
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
  Future<bool> isAdmin() async {
    if (uid == null) return false;
    final r = await _http.get(Uri.parse('$_docs/admins/$uid'), headers: _auth);
    return r.statusCode == 200;
  }

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
        403 => 'Upload not allowed for this account (check storage.rules)',
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
