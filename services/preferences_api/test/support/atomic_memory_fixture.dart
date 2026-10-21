// FIXTURE DE PRUEBA — NO es Atomic Memory.
//
// Imita, en memoria y solo en 127.0.0.1, las rutas documentadas que usa
// `AtomicMemoryStore` (https://docs.atomicstrata.ai/api-reference/http/):
// `POST /v1/memories/ingest/quick`, `GET /v1/memories/by-external-id/{id}`,
// `GET /v1/memories/{id}` y `DELETE /v1/memories/{id}`. Sirve para las pruebas
// y para la demo local sin credenciales reales; no forma parte de la app ni
// se despliega.
//
// Como la documentación no promete que repetir `metadata.externalId`
// actualice el registro, el fixture hace lo más exigente: cada ingesta crea
// un registro nuevo y la búsqueda devuelve el más reciente. Uso:
//
//   PORT=4721 dart run test/support/atomic_memory_fixture.dart
//   curl -X POST 127.0.0.1:4721/__fixture/mode -d failing   # o normal, …
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

enum FixtureMode {
  normal,

  /// Todo responde 503.
  failing,

  /// Cada solicitud tarda [AtomicMemoryFixture.hangFor].
  hanging,

  /// La ingesta responde 200 sin ids confirmados.
  noIds,

  /// La ingesta responde 201 Created (válido) en lugar de 200.
  created,

  /// Los borrados fallan con 503; el resto funciona.
  failingDeletes,

  /// Los borrados responden 200 `{}` pero el registro sigue ahí.
  deleteRetains,

  /// Todo responde 307 hacia [AtomicMemoryFixture.redirectTo].
  redirecting,
}

final class AtomicMemoryFixture {
  AtomicMemoryFixture({this.apiKey = 'fixture-key'});

  final String apiKey;
  FixtureMode mode = FixtureMode.normal;
  Duration hangFor = const Duration(seconds: 30);
  Uri? redirectTo;

  /// Registros vivos en orden de creación: id → fila.
  final Map<String, Map<String, Object?>> rows = {};
  final List<String> requests = [];
  int _nextId = 1;

  Handler get handler => _handle;

  Future<Response> _handle(Request request) async {
    final path = request.url.path;
    if (path == '__fixture/mode' && request.method == 'POST') {
      final name = (await request.readAsString()).trim();
      mode = FixtureMode.values.firstWhere(
        (value) => value.name == name,
        orElse: () => FixtureMode.normal,
      );
      return _json(200, {'mode': mode.name});
    }
    requests.add('${request.method} /$path');
    if (request.headers['authorization'] != 'Bearer $apiKey') {
      return _json(401, {'error': 'unauthorized'});
    }
    switch (mode) {
      case FixtureMode.hanging:
        await Future<void>.delayed(hangFor);
      case FixtureMode.failing:
        return _json(503, {'error': 'fixture failure', 'retryable': true});
      case FixtureMode.redirecting:
        return Response(
          307,
          headers: {'location': '${redirectTo ?? 'http://127.0.0.1:9'}'},
        );
      default:
    }

    final segments = request.url.pathSegments;
    if (path == 'v1/memories/ingest/quick' && request.method == 'POST') {
      return _ingest(await request.readAsString());
    }

    final userId = request.url.queryParameters['user_id'];
    if (userId == null || userId.isEmpty) {
      return _json(400, {'error': 'user_id (string) is required'});
    }
    if (segments.length == 4 &&
        segments[2] == 'by-external-id' &&
        request.method == 'GET') {
      final matches = rows.values.where(
        (row) =>
            row['user_id'] == userId &&
            switch (row['metadata']) {
              {'externalId': final String id} => id == segments[3],
              _ => false,
            },
      );
      return matches.isEmpty
          ? _json(404, {'error': 'Memory not found'})
          : _json(200, matches.last);
    }
    if (segments.length == 3 && segments[1] == 'memories') {
      final row = rows[segments[2]];
      final owned = row != null && row['user_id'] == userId;
      if (request.method == 'GET') {
        return owned
            ? _json(200, row)
            : _json(404, {'error': 'Memory not found'});
      }
      if (request.method == 'DELETE') {
        if (mode == FixtureMode.failingDeletes) {
          return _json(503, {'error': 'fixture failure', 'retryable': true});
        }
        if (mode == FixtureMode.deleteRetains) return _json(200, {});
        if (!owned) return _json(404, {'error': 'Memory not found'});
        rows.remove(segments[2]);
        return _json(200, {'success': true});
      }
    }
    return _json(404, {'error': 'not implemented by fixture'});
  }

  Response _ingest(String raw) {
    final Object? body;
    try {
      body = jsonDecode(raw);
    } on FormatException {
      return _json(400, {'error': 'invalid json'});
    }
    if (body case {
      'user_id': final String userId,
      'conversation': final String conversation,
      'source_site': final String sourceSite,
      'skip_extraction': true,
      'metadata': final Map<String, Object?> metadata,
    }) {
      if (mode == FixtureMode.noIds) return _json(200, _ingestResult());
      final now = DateTime.now().toUtc().toIso8601String();
      final id =
          '00000000-0000-4000-8000-${(_nextId++).toString().padLeft(12, '0')}';
      rows[id] = {
        'id': id,
        'user_id': userId,
        'content': conversation,
        'source_site': sourceSite,
        'metadata': metadata,
        'status': 'active',
        'created_at': now,
        'observed_at': now,
      };
      return _json(
        mode == FixtureMode.created ? 201 : 200,
        _ingestResult(stored: [id]),
      );
    }
    return _json(400, {'error': 'invalid fixture request'});
  }

  static Map<String, Object?> _ingestResult({List<String> stored = const []}) =>
      {
        'episode_id': 'fixture-episode',
        'facts_extracted': 0,
        'memories_stored': stored.length,
        'memories_updated': 0,
        'memories_deleted': 0,
        'memories_skipped': 0,
        'stored_memory_ids': stored,
        'updated_memory_ids': <String>[],
        'links_created': 0,
        'composites_created': 0,
      };

  static Response _json(int status, Object body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}

Future<void> main() async {
  final fixture = AtomicMemoryFixture(
    apiKey: Platform.environment['FIXTURE_API_KEY'] ?? 'fixture-key',
  );
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 4712;
  final server = await shelf_io.serve(
    logRequests()(fixture.handler),
    InternetAddress.loopbackIPv4,
    port,
  );
  stdout.writeln(
    'FIXTURE de Atomic Memory (no es el servicio real) en '
    'http://127.0.0.1:${server.port}',
  );
}
