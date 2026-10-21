import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'src/atomic_memory_store.dart';
import 'src/firebase_identity.dart';
import 'src/trip_conditions.dart';

export 'src/atomic_memory_store.dart';
export 'src/firebase_identity.dart';
export 'src/trip_conditions.dart';

/// Sujeto de memoria de una cuenta. Sale solo del `uid` verificado.
String memorySubjectFor(String uid) => 'rutealo-firebase-$uid';

/// API de condiciones recordadas (RF-26):
///
/// * `GET    /v1/trip-conditions` → `{status: found|empty, conditions?}`
/// * `PUT    /v1/trip-conditions` con `{consent: true, conditions}` → guarda
///   o corrige.
/// * `DELETE /v1/trip-conditions` → olvida.
///
/// Todas exigen `Authorization: Bearer <token de Firebase Auth>`. Sin
/// [store] (Atomic Memory sin configurar) responden `503 MEMORY_DISABLED` y
/// la app sigue con sus valores por defecto.
///
/// [deadline] acota la solicitud completa (verificar la cuenta más todas las
/// llamadas a la memoria); vencido, responde `503 MEMORY_UNAVAILABLE` y la
/// app lo muestra como "no confirmado". Es menor que el plazo de la app.
Handler createPreferencesHandler({
  required IdentityVerifier identity,
  AtomicMemoryStore? store,
  Set<String> allowedOrigins = const {},
  Duration deadline = const Duration(seconds: 5),
}) {
  Future<Response> route(Request request) async {
    final path = request.url.path;
    if (path == 'health' && request.method == 'GET') {
      return _json(200, {'status': 'ok', 'memory': store != null});
    }
    if (path != 'v1/trip-conditions') {
      return _json(404, {'error': 'NOT_FOUND'});
    }
    if (!const {'GET', 'PUT', 'DELETE'}.contains(request.method)) {
      return _json(405, {'error': 'METHOD_NOT_ALLOWED'});
    }

    final header = request.headers['authorization'] ?? '';
    final token = header.startsWith('Bearer ') ? header.substring(7) : '';
    final String? uid;
    try {
      uid = token.isEmpty ? null : await identity.verify(token);
    } on IdentityUnavailable {
      return _json(503, {'error': 'IDENTITY_UNAVAILABLE'});
    }
    if (uid == null) return _json(401, {'error': 'UNAUTHENTICATED'});
    if (store == null) return _json(503, {'error': 'MEMORY_DISABLED'});
    final subject = memorySubjectFor(uid);

    try {
      switch (request.method) {
        case 'GET':
          final stored = await store.recall(subject);
          if (stored == null) return _json(200, {'status': 'empty'});
          return _json(200, {
            'status': 'found',
            'conditions': stored.conditions.toJson(),
            'updatedAt': ?stored.updatedAt,
          });
        case 'PUT':
          final body = await _readBody(request);
          if (body == null) return _json(400, {'error': 'INVALID_BODY'});
          if (body['consent'] != true) {
            return _json(400, {'error': 'CONSENT_REQUIRED'});
          }
          final conditions = TripConditions.tryParse(body['conditions']);
          if (conditions == null) {
            return _json(400, {'error': 'INVALID_CONDITIONS'});
          }
          await store.save(subject, conditions);
          return _json(200, {
            'status': 'saved',
            'conditions': conditions.toJson(),
          });
        default:
          final deleted = await store.forget(subject);
          return _json(200, {'status': deleted ? 'deleted' : 'empty'});
      }
    } on MemoryUnavailable {
      return _json(503, {'error': 'MEMORY_UNAVAILABLE'});
    }
  }

  return (request) async {
    final origin = request.headers['origin'];
    final cors = origin != null && allowedOrigins.contains(origin)
        ? {
            'Access-Control-Allow-Origin': origin,
            'Access-Control-Allow-Methods': 'GET, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Authorization, Content-Type',
            'Access-Control-Max-Age': '600',
            'Vary': 'Origin',
          }
        : const <String, String>{};
    if (request.method == 'OPTIONS') {
      return Response(cors.isEmpty ? 403 : 204, headers: cors);
    }
    Response response;
    try {
      response = await route(request).timeout(deadline);
    } on TimeoutException {
      response = _json(503, {'error': 'MEMORY_UNAVAILABLE'});
    }
    return response.change(headers: cors);
  };
}

const _maxBodyBytes = 4096;

Future<Map<String, Object?>?> _readBody(Request request) async {
  final length = request.contentLength;
  if (length != null && length > _maxBodyBytes) return null;
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    bytes.addAll(chunk);
    if (bytes.length > _maxBodyBytes) return null;
  }
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    return decoded is Map<String, Object?> ? decoded : null;
  } catch (_) {
    return null;
  }
}

Response _json(int status, Map<String, Object?> body) => Response(
  status,
  body: jsonEncode(body),
  headers: {'Content-Type': 'application/json; charset=utf-8'},
);
