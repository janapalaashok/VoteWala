import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/firebase_rest.dart';
import '../data/grievance.dart';
import '../services/firestore_client.dart';

/// Admin-only reads and writes: alerts, photos, grievances, settings.
/// Every request carries the admin's token; firestore.rules check the
/// admins collection.
class AdminData {
  AdminData(this._rest, this.settings, {http.Client? client})
      : _http = client ?? http.Client(),
        db = FirestoreClient(settings, idToken: () async => _rest.idToken);

  final FirebaseRest _rest;
  final FirebaseSettings settings;
  final http.Client _http;
  final FirestoreClient db;

  final _photoCache = <String, Uint8List>{};

  /// A private evidence photo (admins only, see storage.rules).
  Future<Uint8List> photoBytes(String file) async {
    final cached = _photoCache[file];
    if (cached != null) return cached;
    final r = await _http.get(
      Uri.parse('https://firebasestorage.googleapis.com/v0/b/${settings.storageBucket}/o/${Uri.encodeComponent(file)}?alt=media'),
      headers: {'Authorization': 'Firebase ${_rest.idToken}'},
    );
    if (r.statusCode != 200) throw FirebaseException('Photo could not be loaded (${r.statusCode})');
    return _photoCache[file] = r.bodyBytes;
  }

  /// Number of documents in [collection] where [field] >= [atLeast].
  Future<int> countAtLeast(String collection, String field, int atLeast) async {
    final docs = 'https://firestore.googleapis.com/v1/projects/${settings.projectId}/databases/(default)/documents';
    final r = await _http.post(
      Uri.parse('$docs:runAggregationQuery'),
      headers: {'Authorization': 'Bearer ${_rest.idToken}', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'structuredAggregationQuery': {
          'structuredQuery': {
            'from': [{'collectionId': collection}],
            'where': {
              'fieldFilter': {
                'field': {'fieldPath': field},
                'op': 'GREATER_THAN_OR_EQUAL',
                'value': {'integerValue': '$atLeast'},
              },
            },
          },
          'aggregations': [{'alias': 'n', 'count': {}}],
        },
      }),
    );
    if (r.statusCode != 200) throw FirebaseException('Count failed (${r.statusCode})');
    final rows = jsonDecode(r.body) as List;
    final value = ((rows.first as Map)['result'] as Map?)?['aggregateFields']?['n']?['integerValue'];
    return int.tryParse('$value') ?? 0;
  }

  Future<Map<String, Map<String, Object?>>> alerts() => db.list('alerts');

  Future<void> markAlertSeen(String id) => db.commit([Write.merge('alerts/$id', {'seen': true})]);

  Future<Map<String, Map<String, Object?>>> photos() => db.list('photos');

  Future<void> reviewPhoto(String id, String status) => db.commit([
        Write.merge('photos/$id', {'status': status}, const {'reviewedAt': FieldTransform.serverTime()}),
      ]);

  Future<Map<String, Map<String, Object?>>> otherIssues() => db.list('otherIssues');

  Future<List<Grievance>> grievances() async =>
      [for (final e in (await db.list('grievances')).entries) Grievance.fromFields(e.key, e.value)];

  Future<void> saveGrievance(Grievance g) => db.commit([Write.merge('grievances/${g.id}', g.toFields())]);

  Future<Map<String, Object?>> setting(String doc) async => await db.get('settings/$doc') ?? {};

  Future<void> saveSetting(String doc, Map<String, Object?> fields) => db.commit([Write.merge('settings/$doc', fields)]);
}
