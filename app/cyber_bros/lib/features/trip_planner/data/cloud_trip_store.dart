import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/firebase_config.dart';
import '../../auth/data/auth_service.dart';
import 'guest_history.dart';

/// Historial de viajes en Cloud Firestore (RF-34), por la API REST y con el
/// token del usuario, de modo que las reglas de `firebase/firestore.rules`
/// limitan cada cuenta a sus propios viajes.
///
/// Ruta: `users/{uid}/trips/{tripId}`. Ante cualquier fallo (sin red, sesión
/// vencida) devuelve vacío o `false` y la app sigue usando el respaldo local.
final class CloudTripStore {
  CloudTripStore._();

  static final CloudTripStore instance = CloudTripStore._();

  static const _timeout = Duration(seconds: 12);
  static const _base =
      'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}'
      '/databases/(default)/documents';

  bool get available => AuthService.instance.isSignedIn;

  /// Detalle de la última operación fallida (código HTTP), para diagnóstico.
  String? lastError;

  Future<List<GuestTripSnapshot>> list() async {
    final uid = AuthService.instance.session?.userId;
    final token = await AuthService.instance.validIdToken();
    if (uid == null || token == null) return const [];
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_base/users/$uid/trips?pageSize=100&orderBy=createdAt%20desc',
            ),
            headers: _headers(token),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final documents = body['documents'] as List<dynamic>? ?? const [];
      final trips = <GuestTripSnapshot>[];
      for (final document in documents) {
        try {
          final fields = (document as Map<String, dynamic>)['fields']
              as Map<String, dynamic>;
          final raw = (fields['snapshot'] as Map<String, dynamic>)['stringValue']
              as String;
          trips.add(
            GuestTripSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>),
          );
        } catch (_) {
          // Un documento dañado no impide ver el resto.
        }
      }
      return trips;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> save(GuestTripSnapshot trip) async {
    final uid = AuthService.instance.session?.userId;
    final token = await AuthService.instance.validIdToken();
    if (uid == null || token == null) return false;
    try {
      final response = await http
          .patch(
            Uri.parse('$_base/users/$uid/trips/${trip.id}'),
            headers: _headers(token),
            body: jsonEncode({
              'fields': {
                'status': _string(trip.status.name.toUpperCase()),
                'spentCents': _integer(trip.spentCents),
                'replanCount': _integer(trip.replanCount),
                'createdAt': {
                  'timestampValue': trip.createdAtUtc.toIso8601String(),
                },
                'dataVersion': _string(trip.dataVersion),
                // Copia fija del recorrido elegido: no cambia aunque las rutas
                // se actualicen después.
                'snapshot': _string(jsonEncode(trip.toJson())),
              },
            }),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String tripId) async {
    final uid = AuthService.instance.session?.userId;
    final token = await AuthService.instance.validIdToken();
    if (uid == null || token == null) {
      lastError = 'sesión no válida';
      return false;
    }
    try {
      final response = await http
          .delete(
            Uri.parse('$_base/users/$uid/trips/$tripId'),
            headers: _headers(token),
          )
          .timeout(_timeout);
      final ok = response.statusCode == 200 || response.statusCode == 404;
      lastError = ok ? null : 'HTTP ${response.statusCode}';
      return ok;
    } catch (error) {
      lastError = 'sin conexión';
      return false;
    }
  }

  /// Crea el perfil `users/{uid}` la primera vez (RF-31). No toca uno
  /// existente, para no pisar banderas que solo el equipo puede cambiar.
  Future<void> ensureProfile() async {
    final session = AuthService.instance.session;
    final token = await AuthService.instance.validIdToken();
    if (session == null || token == null) return;
    final uri = Uri.parse('$_base/users/${session.userId}');
    try {
      final existing = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);
      if (existing.statusCode != 404) return;
      await http
          .patch(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'fields': {
                'email': _string(session.email),
                if (session.displayName != null)
                  'displayName': _string(session.displayName!),
                'isAnonymous': {'booleanValue': false},
                'isTeamMember': {'booleanValue': false},
                'privacyVersion': _string('1'),
                'createdAt': {
                  'timestampValue': DateTime.now().toUtc().toIso8601String(),
                },
              },
            }),
          )
          .timeout(_timeout);
    } catch (_) {
      // El perfil se reintenta en la próxima sesión.
    }
  }

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static Map<String, Object> _string(String value) => {'stringValue': value};

  static Map<String, Object> _integer(int value) => {'integerValue': '$value'};
}
