import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../../core/network/resilient_client.dart';
import '../domain/context_advisor.dart';

/// Clima actual y probabilidad de lluvia desde Open-Meteo (datos abiertos, sin
/// clave). Usa el cliente tolerante a fallos: si el servicio no responde,
/// devuelve `null` y la app sigue sin la sugerencia de clima.
class WeatherService {
  WeatherService({ResilientClient? client, DateTime Function()? now})
    : _client = client ?? ResilientClient.shared,
      _now = now ?? DateTime.now;

  static final WeatherService shared = WeatherService();

  final ResilientClient _client;
  final DateTime Function() _now;
  final Map<String, ({DateTime at, WeatherContext? value})> _cache = {};

  static const _cacheFor = Duration(minutes: 10);

  Future<WeatherContext?> currentFor(LatLng point) async {
    // Se agrupa por celdas de ~1 km para no repetir consultas.
    final key =
        '${point.latitude.toStringAsFixed(2)},${point.longitude.toStringAsFixed(2)}';
    final cached = _cache[key];
    if (cached != null && _now().difference(cached.at) < _cacheFor) {
      return cached.value;
    }
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': point.latitude.toStringAsFixed(4),
      'longitude': point.longitude.toStringAsFixed(4),
      'current': 'precipitation,weather_code',
      'hourly': 'precipitation_probability',
      'forecast_hours': '3',
      'timezone': 'America/Lima',
    });
    final response = await _client.get(uri);
    if (response == null || response.statusCode != 200) return null;
    try {
      final value = parse(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
      _cache[key] = (at: _now(), value: value);
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Interpreta la respuesta de Open-Meteo. Pública para poder probarla.
  static WeatherContext? parse(Map<String, dynamic> json) {
    final current = json['current'];
    if (current is! Map) return null;
    final precipitation = (current['precipitation'] as num?)?.toDouble();
    if (precipitation == null) return null;

    int? chance;
    final hourly = json['hourly'];
    if (hourly is Map && hourly['precipitation_probability'] is List) {
      final values = (hourly['precipitation_probability'] as List)
          .whereType<num>()
          .map((value) => value.round())
          .toList();
      if (values.isNotEmpty) {
        chance = values.reduce((a, b) => a > b ? a : b);
      }
    }
    return WeatherContext(
      precipitationMm: precipitation,
      rainChancePercent: chance,
      description: _describe((current['weather_code'] as num?)?.toInt()),
    );
  }

  /// Códigos WMO de Open-Meteo, resumidos en lenguaje llano.
  static String? _describe(int? code) {
    if (code == null) return null;
    if (code == 0) return 'Despejado';
    if (code <= 3) return 'Nublado';
    if (code == 45 || code == 48) return 'Neblina';
    if (code >= 51 && code <= 57) return 'Llovizna';
    if (code >= 61 && code <= 67) return 'Lluvia';
    if (code >= 80 && code <= 82) return 'Chubascos';
    if (code >= 95) return 'Tormenta';
    return null;
  }
}
