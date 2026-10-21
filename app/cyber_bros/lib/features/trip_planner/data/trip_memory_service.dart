import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/auth_service.dart';
import '../domain/routing_engine.dart';

/// Resultado de una operación con las condiciones recordadas.
sealed class TripMemoryResult {
  const TripMemoryResult();
}

/// Hay condiciones recordadas para la cuenta.
final class TripMemoryFound extends TripMemoryResult {
  const TripMemoryFound(this.limits);

  final PlanLimits limits;
}

/// No hay nada guardado.
final class TripMemoryEmpty extends TripMemoryResult {
  const TripMemoryEmpty();
}

/// El servidor confirmó que guardó estas condiciones.
final class TripMemorySaved extends TripMemoryResult {
  const TripMemorySaved(this.limits);

  final PlanLimits limits;
}

/// El servidor confirmó que ya no hay condiciones guardadas.
final class TripMemoryDeleted extends TripMemoryResult {
  const TripMemoryDeleted();
}

/// Sin sesión: la memoria solo existe para cuentas.
final class TripMemorySignedOut extends TripMemoryResult {
  const TripMemorySignedOut();
}

/// Sin configurar, sin red, tiempo agotado o respuesta no confirmada: no se
/// puede afirmar nada.
final class TripMemoryUnavailable extends TripMemoryResult {
  const TripMemoryUnavailable();
}

/// Condiciones de viaje recordadas (RF-26) a través de
/// `services/preferences_api`, que verifica la cuenta y guarda en Atomic
/// Memory. La app nunca ve la clave del servicio de memoria.
///
/// Apagado por defecto: solo se activa con
/// `--dart-define=TRIP_MEMORY_API_URL=http://127.0.0.1:8787`.
final class TripMemoryService {
  TripMemoryService({
    String? baseUrl,
    http.Client? client,
    Future<String?> Function()? idToken,
    // Mayor que el plazo total del servidor (5 s), que responde antes.
    this.timeout = const Duration(seconds: 8),
  }) : baseUrl = baseUrl ?? _configuredUrl,
       _client = client ?? http.Client(),
       _idToken = idToken ?? AuthService.instance.validIdToken;

  static final TripMemoryService instance = TripMemoryService();

  static const _configuredUrl = String.fromEnvironment('TRIP_MEMORY_API_URL');

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;
  final Future<String?> Function() _idToken;

  bool get isEnabled => baseUrl.isNotEmpty;

  Uri get _uri => Uri.parse('$baseUrl/v1/trip-conditions');

  Future<TripMemoryResult> recall() => _call('GET');

  /// Guarda o corrige. Solo se llama cuando la persona pulsa "Guardar".
  Future<TripMemoryResult> save(PlanLimits limits) => _call('PUT', {
    'consent': true,
    'conditions': {
      'budgetCents': limits.budgetCents,
      'maxContinuousWalkMetres': limits.maxContinuousWalkMetres,
      'maxTotalWalkMetres': limits.maxTotalWalkMetres,
      'allowTaxiBridge': limits.allowTaxiBridge,
      'priority': limits.priority.name,
    },
  });

  Future<TripMemoryResult> forget() => _call('DELETE');

  Future<TripMemoryResult> _call(
    String method, [
    Map<String, Object?>? body,
  ]) async {
    if (!isEnabled) return const TripMemoryUnavailable();
    final token = await _idToken();
    if (token == null) return const TripMemorySignedOut();
    final http.Response response;
    try {
      final request = http.Request(method, _uri)
        ..followRedirects = false
        ..headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode(body);
      }
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } catch (_) {
      // Sin red o tiempo agotado: no se afirma nada.
      return const TripMemoryUnavailable();
    }
    if (response.statusCode == 401) return const TripMemorySignedOut();
    if (response.statusCode != 200) return const TripMemoryUnavailable();
    final Object? data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      return const TripMemoryUnavailable();
    }
    return switch ((method, data)) {
      ('GET', {'status': 'found', 'conditions': final Object? raw}) =>
        switch (parseLimits(raw)) {
          final PlanLimits limits => TripMemoryFound(limits),
          null => const TripMemoryUnavailable(),
        },
      ('GET', {'status': 'empty'}) => const TripMemoryEmpty(),
      ('PUT', {'status': 'saved', 'conditions': final Object? raw}) =>
        switch (parseLimits(raw)) {
          final PlanLimits limits => TripMemorySaved(limits),
          null => const TripMemoryUnavailable(),
        },
      ('DELETE', {'status': 'deleted'}) => const TripMemoryDeleted(),
      // Olvidar cuando no había nada deja el mismo estado: nada guardado.
      ('DELETE', {'status': 'empty'}) => const TripMemoryDeleted(),
      _ => const TripMemoryUnavailable(),
    };
  }

  /// Convierte las condiciones que manda el servidor; `null` si falta algo o
  /// no cumple las reglas del planificador.
  static PlanLimits? parseLimits(Object? raw) {
    if (raw case {
      'budgetCents': final int budget,
      'maxContinuousWalkMetres': final int continuous,
      'maxTotalWalkMetres': final int total,
      'allowTaxiBridge': final bool taxi,
      'priority': final String priorityName,
    }) {
      final priority = PlanPriority.values.asNameMap()[priorityName];
      if (priority == null) return null;
      final limits = PlanLimits(
        budgetCents: budget,
        maxContinuousWalkMetres: continuous,
        maxTotalWalkMetres: total,
        allowTaxiBridge: taxi,
        priority: priority,
      );
      return limits.isValid ? limits : null;
    }
    return null;
  }
}
