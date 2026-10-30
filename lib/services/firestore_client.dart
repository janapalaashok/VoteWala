import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/firebase_rest.dart';

/// A field change applied by the server: `+n` or the request time.
class FieldTransform {
  const FieldTransform.increment([this.by = 1]) : serverTime = false;
  const FieldTransform.serverTime()
      : by = 0,
        serverTime = true;

  final int by;
  final bool serverTime;
}

/// One write in an atomic batch.
class Write {
  /// Creates [path]; fails if it already exists.
  const Write.create(this.path, [this.fields = const {}, this.transforms = const {}]) : merge = false;

  /// Sets [fields] and applies [transforms], creating the document if needed
  /// and leaving its other fields untouched.
  const Write.merge(this.path, [this.fields = const {}, this.transforms = const {}]) : merge = true;

  /// Path relative to the database root, e.g. `votes/mla-2026-10/ballots/uid`.
  final String path;
  final Map<String, Object?> fields;
  final Map<String, FieldTransform> transforms;
  final bool merge;
}

/// Why the database refused a request.
enum StoreError { denied, exists, network, unknown }

class StoreException implements Exception {
  StoreException(this.error, [this.detail = '']);

  final StoreError error;
  final String detail;

  @override
  String toString() => 'StoreException(${error.name}) $detail';
}

/// The few database operations the app needs. [FirestoreClient] talks to
/// Firestore; [MemoryStore] backs tests.
abstract class DocStore {
  /// Fields of the document, or null when it does not exist.
  Future<Map<String, Object?>?> get(String path);

  /// Documents that exist among [paths], keyed by path.
  Future<Map<String, Map<String, Object?>>> getAll(List<String> paths);

  /// Every document directly in [collection], keyed by document id.
  Future<Map<String, Map<String, Object?>>> list(String collection);

  /// Applies [writes] atomically.
  Future<void> commit(List<Write> writes);
}

/// Firestore over its REST API. Requests carry the signed-in user's ID token,
/// so firestore.rules see who is writing.
class FirestoreClient implements DocStore {
  FirestoreClient(
    this.settings, {
    required this.idToken,
    http.Client? client,
    String? host,
  })  : _http = client ?? http.Client(),
        _root = '${host ?? 'https://firestore.googleapis.com'}/v1/projects/${settings.projectId}/databases/(default)/documents';

  final FirebaseSettings settings;
  final Future<String?> Function() idToken;
  final http.Client _http;
  final String _root;

  String get _name => _root.substring(_root.indexOf('/projects/') + 1);

  Future<Map<String, String>> _headers() async {
    final token = await idToken();
    return {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future<http.Response> _send(Future<http.Response> Function(Map<String, String> headers) send) async {
    try {
      return await send(await _headers());
    } catch (e) {
      throw StoreException(StoreError.network, '$e');
    }
  }

  StoreException _error(http.Response r) => StoreException(
        switch (r.statusCode) {
          403 || 401 => StoreError.denied,
          409 => StoreError.exists,
          400 when r.body.contains('FAILED_PRECONDITION') || r.body.contains('ALREADY_EXISTS') => StoreError.exists,
          _ => StoreError.unknown,
        },
        '${r.statusCode} ${r.body.length > 300 ? r.body.substring(0, 300) : r.body}',
      );

  @override
  Future<Map<String, Object?>?> get(String path) async {
    final r = await _send((h) => _http.get(Uri.parse('$_root/$path?key=${settings.apiKey}'), headers: h));
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw _error(r);
    return decodeFields(jsonDecode(r.body) as Map<String, dynamic>);
  }

  @override
  Future<Map<String, Map<String, Object?>>> getAll(List<String> paths) async {
    if (paths.isEmpty) return {};
    final r = await _send((h) => _http.post(
          Uri.parse('$_root:batchGet?key=${settings.apiKey}'),
          headers: h,
          body: jsonEncode({'documents': [for (final p in paths) '$_name/$p']}),
        ));
    if (r.statusCode != 200) throw _error(r);
    final prefix = '$_name/';
    return {
      for (final item in jsonDecode(r.body) as List)
        if ((item as Map<String, dynamic>)['found'] case final Map<String, dynamic> doc)
          (doc['name'] as String).substring(prefix.length): decodeFields(doc),
    };
  }

  @override
  Future<Map<String, Map<String, Object?>>> list(String collection) async {
    final out = <String, Map<String, Object?>>{};
    String? page;
    do {
      final url = '$_root/$collection?pageSize=300&key=${settings.apiKey}'
          '${page == null ? '' : '&pageToken=${Uri.encodeQueryComponent(page)}'}';
      final r = await _send((h) => _http.get(Uri.parse(url), headers: h));
      if (r.statusCode != 200) throw _error(r);
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      for (final d in (body['documents'] as List? ?? const [])) {
        final doc = d as Map<String, dynamic>;
        out[(doc['name'] as String).split('/').last] = decodeFields(doc);
      }
      page = body['nextPageToken'] as String?;
    } while (page != null);
    return out;
  }

  @override
  Future<void> commit(List<Write> writes) async {
    final r = await _send((h) => _http.post(
          Uri.parse('$_root:commit?key=${settings.apiKey}'),
          headers: h,
          body: jsonEncode({'writes': [for (final w in writes) _encodeWrite(w)]}),
        ));
    if (r.statusCode != 200) throw _error(r);
  }

  Map<String, Object?> _encodeWrite(Write w) => {
        'update': {
          'name': '$_name/${w.path}',
          'fields': {for (final e in w.fields.entries) e.key: encodeValue(e.value)},
        },
        if (w.merge) 'updateMask': {'fieldPaths': w.fields.keys.toList()},
        if (!w.merge) 'currentDocument': {'exists': false},
        if (w.transforms.isNotEmpty)
          'updateTransforms': [
            for (final e in w.transforms.entries)
              {
                'fieldPath': e.key,
                if (e.value.serverTime) 'setToServerValue': 'REQUEST_TIME' else 'increment': {'integerValue': '${e.value.by}'},
              },
          ],
      };
}

Map<String, Object?> encodeValue(Object? v) => switch (v) {
      null => {'nullValue': null},
      final bool b => {'booleanValue': b},
      final int i => {'integerValue': '$i'},
      final double d => {'doubleValue': d},
      final String s => {'stringValue': s},
      final DateTime t => {'timestampValue': t.toUtc().toIso8601String()},
      final List<Object?> l => {
          'arrayValue': {'values': [for (final x in l) encodeValue(x)]},
        },
      final Map<String, Object?> m => {
          'mapValue': {'fields': {for (final e in m.entries) e.key: encodeValue(e.value)}},
        },
      _ => throw ArgumentError('Cannot store $v'),
    };

Object? decodeValue(Map<String, dynamic> v) {
  final MapEntry(:key, :value) = v.entries.first;
  return switch (key) {
    'integerValue' => int.parse(value as String),
    'doubleValue' => (value as num).toDouble(),
    'booleanValue' => value as bool,
    'stringValue' => value as String,
    'timestampValue' => DateTime.parse(value as String),
    'arrayValue' => [for (final x in ((value as Map)['values'] as List? ?? const [])) decodeValue(x as Map<String, dynamic>)],
    'mapValue' => decodeFields(value as Map<String, dynamic>),
    _ => null,
  };
}

Map<String, Object?> decodeFields(Map<String, dynamic> doc) => {
      for (final e in ((doc['fields'] as Map<String, dynamic>?) ?? const {}).entries)
        e.key: decodeValue(e.value as Map<String, dynamic>),
    };

/// In-memory [DocStore] for tests. Enforces create-once like Firestore; the
/// security rules themselves are tested against the emulator (test/rules).
class MemoryStore implements DocStore {
  final docs = <String, Map<String, Object?>>{};

  @override
  Future<Map<String, Object?>?> get(String path) async => docs[path] == null ? null : {...docs[path]!};

  @override
  Future<Map<String, Map<String, Object?>>> getAll(List<String> paths) async => {
        for (final p in paths)
          if (docs[p] != null) p: {...docs[p]!},
      };

  @override
  Future<Map<String, Map<String, Object?>>> list(String collection) async {
    final depth = collection.split('/').length + 1;
    return {
      for (final e in docs.entries)
        if (e.key.startsWith('$collection/') && e.key.split('/').length == depth) e.key.split('/').last: {...e.value},
    };
  }

  @override
  Future<void> commit(List<Write> writes) async {
    for (final w in writes) {
      if (!w.merge && docs.containsKey(w.path)) throw StoreException(StoreError.exists, w.path);
    }
    final now = DateTime.now().toUtc();
    for (final w in writes) {
      final doc = w.merge ? {...?docs[w.path], ...w.fields} : {...w.fields};
      for (final e in w.transforms.entries) {
        doc[e.key] = e.value.serverTime ? now : ((doc[e.key] as int?) ?? 0) + e.value.by;
      }
      docs[w.path] = doc;
    }
  }
}
