import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'trip_conditions.dart';

/// El servicio de memoria no respondió, rechazó la operación o no se pudo
/// confirmar el resultado. Nunca se informa éxito en ese caso.
final class MemoryUnavailable implements Exception {
  const MemoryUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'MemoryUnavailable($reason)';
}

/// Valida la URL base de Atomic Memory antes de mandarle la clave: HTTPS (HTTP
/// solo hacia la propia máquina), sin usuario/contraseña, consulta ni
/// fragmento. Devuelve `null` si no sirve, y entonces la memoria queda
/// apagada.
Uri? parseMemoryBaseUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.isAbsolute || uri.host.isEmpty) return null;
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) return null;
  final loopback = const {
    'localhost',
    '127.0.0.1',
    '::1',
  }.contains(uri.host.toLowerCase());
  final secure = uri.scheme == 'https' || (uri.scheme == 'http' && loopback);
  if (!secure) return null;
  final path = uri.path.endsWith('/')
      ? uri.path.substring(0, uri.path.length - 1)
      : uri.path;
  return uri.replace(path: path);
}

final class StoredConditions {
  const StoredConditions({
    required this.memoryId,
    required this.conditions,
    this.updatedAt,
  });

  final String memoryId;
  final TripConditions conditions;
  final String? updatedAt;
}

/// Registro de memoria ya validado.
final class _Record {
  const _Record(this.id, this.conditions, this.updatedAt);

  final String id;

  /// `null` si el registro existe pero sus condiciones no son legibles.
  final TripConditions? conditions;
  final String? updatedAt;
}

/// Guarda un único recuerdo por cuenta con las condiciones de viaje, usando
/// rutas documentadas de la API HTTP de Atomic Memory:
///
/// * `POST /v1/memories/ingest/quick` con `skip_extraction: true` y
///   `metadata.externalId`.
/// * `GET /v1/memories/by-external-id/{externalId}?user_id=…`.
/// * `GET /v1/memories/{id}?user_id=…` y `DELETE /v1/memories/{id}?user_id=…`.
///
/// Nada se da por hecho por un código 2xx:
///
/// * Guardar exige ids confirmados, relee el registro nuevo por id y compara
///   sus condiciones; recién entonces borra el anterior, comprueba por id que
///   ya no existe y vuelve a buscar por `externalId`.
/// * Olvidar borra y comprueba por id que el registro ya no existe.
///
/// Si cualquier paso no se confirma, se lanza [MemoryUnavailable] sin borrar
/// nada más. Las solicitudes nunca siguen redirecciones, para que la clave no
/// viaje a otro destino.
///
/// `user_id` es siempre el sujeto derivado en el servidor de la cuenta
/// verificada; no hay thread, namespace ni agent.
final class AtomicMemoryStore {
  AtomicMemoryStore({
    required this.baseUrl,
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 2),
  }) : _client = client ?? http.Client();

  /// Lee `ATOMICMEMORY_API_URL` y `ATOMICMEMORY_API_KEY`. Si faltan las dos,
  /// la memoria queda apagada sin aviso; si falta una o la URL no pasa
  /// [parseMemoryBaseUrl], queda apagada y se llama a [warn]. Nunca impide
  /// arrancar el servidor.
  static AtomicMemoryStore? fromEnvironment(
    Map<String, String> env, {
    required void Function(String message) warn,
  }) {
    final rawUrl = (env['ATOMICMEMORY_API_URL'] ?? '').trim();
    final key = (env['ATOMICMEMORY_API_KEY'] ?? '').trim();
    if (rawUrl.isEmpty && key.isEmpty) return null;
    final url = parseMemoryBaseUrl(rawUrl);
    if (url == null || key.isEmpty) {
      warn(
        'ATOMICMEMORY_API_URL/ATOMICMEMORY_API_KEY incompletas o inválidas '
        '(se exige HTTPS, o HTTP solo hacia 127.0.0.1/localhost, sin usuario, '
        'consulta ni fragmento); la memoria queda apagada (MEMORY_DISABLED).',
      );
      return null;
    }
    return AtomicMemoryStore(baseUrl: url, apiKey: key);
  }

  static const externalId = 'rutealo-trip-conditions-v1';
  static const sourceSite = 'rutealo';

  /// Debe venir de [parseMemoryBaseUrl].
  final Uri baseUrl;
  final String apiKey;

  /// Tiempo máximo de cada llamada; el handler impone además un plazo total.
  final Duration timeout;
  final http.Client _client;

  /// Condiciones guardadas, `null` si no hay. Un registro ilegible es un
  /// fallo, no "vacío": así nunca se ofrecen valores a medias.
  Future<StoredConditions?> recall(String subject) async {
    final record = await _byExternalId(subject);
    if (record == null) return null;
    final conditions = record.conditions;
    if (conditions == null) throw const MemoryUnavailable('invalid_record');
    return StoredConditions(
      memoryId: record.id,
      conditions: conditions,
      updatedAt: record.updatedAt,
    );
  }

  Future<void> save(String subject, TripConditions conditions) async {
    final previous = await _byExternalId(subject);

    final response = await _send('POST', '/v1/memories/ingest/quick', {
      'user_id': subject,
      'conversation': conditions.toMemoryText(),
      'source_site': sourceSite,
      'skip_extraction': true,
      'content_class': 'summary',
      'metadata': {
        'externalId': externalId,
        'rutealoConditions': conditions.toJson(),
      },
    });
    _expectSuccess(response);
    final confirmed = _confirmedIds(response.body);
    // Sin ids confirmados no se sabe qué quedó guardado: no se toca el
    // recuerdo anterior.
    if (confirmed.isEmpty) throw const MemoryUnavailable('not_confirmed');

    // El registro nuevo debe existir y decir lo que se pidió guardar.
    String? newId;
    for (final id in confirmed) {
      final record = await _byId(subject, id);
      if (record != null && _same(record.conditions, conditions)) {
        newId = id;
        break;
      }
    }
    if (newId == null) throw const MemoryUnavailable('readback_mismatch');

    if (previous != null && previous.id != newId) {
      await _deleteConfirmed(subject, previous.id);
    }

    final current = await _byExternalId(subject);
    if (current == null || current.id != newId) {
      throw const MemoryUnavailable('readback_mismatch');
    }
  }

  /// Borra el recuerdo. Devuelve `false` si no había nada guardado y `true`
  /// solo cuando se comprobó que ya no existe.
  Future<bool> forget(String subject) async {
    var deleted = false;
    // Si quedaran copias de un intento anterior, se borran todas (hasta 3).
    for (var attempt = 0; ; attempt++) {
      final record = await _byExternalId(subject);
      if (record == null) return deleted;
      if (attempt == 3) throw const MemoryUnavailable('not_confirmed');
      await _deleteConfirmed(subject, record.id);
      deleted = true;
    }
  }

  Future<_Record?> _byExternalId(String subject) => _read(
    subject,
    '/v1/memories/by-external-id/${Uri.encodeComponent(externalId)}',
  );

  Future<_Record?> _byId(String subject, String id) =>
      _read(subject, '/v1/memories/${Uri.encodeComponent(id)}');

  /// Un 404 es "no existe"; cualquier otra respuesta que no sea un registro
  /// válido de este sujeto es un fallo.
  Future<_Record?> _read(String subject, String path) async {
    final response = await _send('GET', path, null, subject);
    if (response.statusCode == 404) return null;
    _expectSuccess(response);
    return _parseRecord(response.body, subject);
  }

  /// Borra un id y lo confirma con una lectura: un 2xx (o un 404) del borrado
  /// no basta si el registro sigue ahí.
  Future<void> _deleteConfirmed(String subject, String id) async {
    final response = await _send(
      'DELETE',
      '/v1/memories/${Uri.encodeComponent(id)}',
      null,
      subject,
    );
    if (response.statusCode != 404) _expectSuccess(response);
    if (await _byId(subject, id) != null) {
      throw const MemoryUnavailable('delete_not_applied');
    }
  }

  static _Record _parseRecord(String body, String subject) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const MemoryUnavailable('invalid_response');
    }
    // Algunas respuestas envuelven el registro en `memory`.
    final record = switch (decoded) {
      {'memory': final Map<String, Object?> inner} => inner,
      final Map<String, Object?> plain => plain,
      _ => throw const MemoryUnavailable('invalid_response'),
    };
    final id = switch (record['id']) {
      final String value when value.isNotEmpty => value,
      _ => throw const MemoryUnavailable('invalid_response'),
    };
    // Defensa adicional: el registro debe pertenecer a este sujeto.
    final owner = record['user_id'];
    if (owner != null && owner != subject) {
      throw const MemoryUnavailable('foreign_record');
    }
    final conditions = switch (record['metadata']) {
      {'rutealoConditions': final Object? raw} => TripConditions.tryParse(raw),
      _ => null,
    };
    final updatedAt = switch (record['observed_at'] ?? record['created_at']) {
      final String value => value,
      _ => null,
    };
    return _Record(id, conditions, updatedAt);
  }

  static Set<String> _confirmedIds(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const MemoryUnavailable('invalid_response');
    }
    if (decoded is! Map<String, Object?>) {
      throw const MemoryUnavailable('invalid_response');
    }
    return {
      for (final key in const ['stored_memory_ids', 'updated_memory_ids'])
        if (decoded[key] case final List<Object?> ids)
          for (final id in ids)
            if (id case final String value when value.isNotEmpty) value,
    };
  }

  static bool _same(TripConditions? a, TripConditions b) =>
      a != null && jsonEncode(a.toJson()) == jsonEncode(b.toJson());

  Future<http.Response> _send(
    String method,
    String path, [
    Map<String, Object?>? body,
    String? subject,
  ]) async {
    final uri = baseUrl.replace(
      path: '${baseUrl.path}$path',
      queryParameters: subject == null ? null : {'user_id': subject},
    );
    final request = http.Request(method, uri)
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer $apiKey';
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw const MemoryUnavailable('timeout');
    } catch (_) {
      throw const MemoryUnavailable('network');
    }
    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw const MemoryUnavailable('redirect_refused');
    }
    return response;
  }

  static void _expectSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MemoryUnavailable('http_${response.statusCode}');
    }
  }
}
