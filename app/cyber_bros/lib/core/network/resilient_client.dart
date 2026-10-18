import 'dart:async';

import 'package:http/http.dart' as http;

/// Cliente HTTP tolerante a fallos para servicios de terceros (RNF-07).
///
/// Ningún servicio externo puede ser un punto único de falla de la demo:
///  * cada intento tiene un **tiempo máximo**;
///  * se **reintenta** un número limitado de veces con espera creciente;
///  * un *circuit breaker* por servidor **corta las llamadas** tras varios
///    fallos seguidos y las retoma pasado un tiempo, para no hacer esperar a
///    la persona con un servicio caído.
///
/// Siempre devuelve `null` en lugar de lanzar, de modo que quien lo usa pueda
/// aplicar su alternativa (por ejemplo, una línea recta si no hay ruta por
/// calle). Funciona igual en Android y en web (usa `package:http`).
class ResilientClient {
  ResilientClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 4),
    this.maxRetries = 1,
    this.retryDelay = const Duration(milliseconds: 250),
    this.failureThreshold = 3,
    this.cooldown = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final http.Client _client;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;
  final int failureThreshold;
  final Duration cooldown;
  final DateTime Function() _now;

  final Map<String, _Circuit> _circuits = {};

  /// Instancia compartida de la app.
  static final ResilientClient shared = ResilientClient();

  /// `true` mientras el servidor [host] está "en pausa" por fallos seguidos.
  bool isOpen(String host) => _circuits[host]?.isOpen(_now()) ?? false;

  /// Cuántos fallos seguidos lleva [host] (para diagnóstico y pruebas).
  int failuresOf(String host) => _circuits[host]?.failures ?? 0;

  /// GET con reintentos y *circuit breaker*. `null` si falló o si el servicio
  /// está en pausa.
  Future<http.Response?> get(Uri uri, {Map<String, String>? headers}) async {
    final circuit = _circuits.putIfAbsent(uri.host, () => _Circuit(this));
    if (circuit.isOpen(_now())) return null;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: headers)
            .timeout(timeout);
        // Los 5xx y 429 son fallos del servicio; los 4xx no se reintentan.
        if (response.statusCode >= 500 || response.statusCode == 429) {
          throw http.ClientException('HTTP ${response.statusCode}', uri);
        }
        circuit.recordSuccess();
        return response;
      } catch (_) {
        if (attempt < maxRetries) {
          await Future<void>.delayed(retryDelay * (attempt + 1));
        }
      }
    }
    circuit.recordFailure(_now());
    return null;
  }

  void close() => _client.close();
}

final class _Circuit {
  _Circuit(this._owner);

  final ResilientClient _owner;
  int failures = 0;
  DateTime? _openUntil;

  bool isOpen(DateTime now) {
    final until = _openUntil;
    if (until == null) return false;
    if (now.isBefore(until)) return true;
    // Pasó el enfriamiento: se prueba de nuevo (estado "semiabierto").
    _openUntil = null;
    failures = _owner.failureThreshold - 1;
    return false;
  }

  void recordSuccess() {
    failures = 0;
    _openUntil = null;
  }

  void recordFailure(DateTime now) {
    failures++;
    if (failures >= _owner.failureThreshold) {
      _openUntil = now.add(_owner.cooldown);
    }
  }
}
