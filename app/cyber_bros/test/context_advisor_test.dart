import 'package:cyber_bros/core/network/resilient_client.dart';
import 'package:cyber_bros/features/trip_planner/data/weather_service.dart';
import 'package:cyber_bros/features/trip_planner/domain/context_advisor.dart';
import 'package:cyber_bros/features/trip_planner/domain/routing_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const _limits = PlanLimits(
  budgetCents: 800,
  maxContinuousWalkMetres: 400,
  maxTotalWalkMetres: 1000,
  allowTaxiBridge: true,
);

// 12:00 en Lima = 17:00 UTC; 21:00 en Lima = 02:00 UTC del día siguiente.
final _midday = DateTime.utc(2026, 10, 21, 17);
final _night = DateTime.utc(2026, 10, 22, 2);

void main() {
  group('Hora de Lima', () {
    test('Lima es UTC-5', () {
      expect(ContextAdvisor.limaTime(_midday).hour, 12);
      expect(ContextAdvisor.limaTime(_night).hour, 21);
    });

    test('de noche es de 19:30 a 05:00', () {
      expect(ContextAdvisor.isNight(DateTime.utc(2026, 10, 21, 17)), isFalse); // 12:00
      expect(ContextAdvisor.isNight(DateTime.utc(2026, 10, 22, 0, 29)), isFalse); // 19:29
      expect(ContextAdvisor.isNight(DateTime.utc(2026, 10, 22, 0, 30)), isTrue); // 19:30
      expect(ContextAdvisor.isNight(DateTime.utc(2026, 10, 21, 9, 59)), isTrue); // 04:59
      expect(ContextAdvisor.isNight(DateTime.utc(2026, 10, 21, 10, 0)), isFalse); // 05:00
    });
  });

  group('Sugerencias de contexto', () {
    test('de día y sin lluvia no sugiere nada', () {
      expect(
        ContextAdvisor.suggest(
          limits: _limits,
          nowUtc: _midday,
          weather: const WeatherContext(precipitationMm: 0, rainChancePercent: 10),
        ),
        isEmpty,
      );
    });

    test('con lluvia reduce la caminata seguida y nunca la total por debajo', () {
      final s = ContextAdvisor.suggest(
        limits: _limits,
        nowUtc: _midday,
        weather: const WeatherContext(precipitationMm: 1.2),
      );
      expect(s.single.kind, ContextKind.rain);
      expect(s.single.limits.maxContinuousWalkMetres, 250); // 400 × 0.6 = 240 -> 250
      expect(
        s.single.limits.maxTotalWalkMetres,
        greaterThanOrEqualTo(s.single.limits.maxContinuousWalkMetres),
      );
    });

    test('una alta probabilidad de lluvia también cuenta', () {
      final s = ContextAdvisor.suggest(
        limits: _limits,
        nowUtc: _midday,
        weather: const WeatherContext(precipitationMm: 0, rainChancePercent: 80),
      );
      expect(s.single.kind, ContextKind.rain);
      expect(s.single.title, 'Puede llover pronto');
    });

    test('de noche sugiere menos caminata, aun sin datos de clima', () {
      final s = ContextAdvisor.suggest(limits: _limits, nowUtc: _night);
      expect(s.single.kind, ContextKind.night);
      expect(s.single.limits.maxContinuousWalkMetres, 300); // 400 × 0.7 = 280 -> 300
    });

    test('lluvia y noche dan dos sugerencias independientes', () {
      final s = ContextAdvisor.suggest(
        limits: _limits,
        nowUtc: _night,
        weather: const WeatherContext(precipitationMm: 2),
      );
      expect(s.map((x) => x.kind), [ContextKind.rain, ContextKind.night]);
    });

    test('solo propone: no toca el presupuesto ni el taxi', () {
      final s = ContextAdvisor.suggest(
        limits: _limits,
        nowUtc: _night,
        weather: const WeatherContext(precipitationMm: 2),
      );
      for (final suggestion in s) {
        expect(suggestion.limits.budgetCents, _limits.budgetCents);
        expect(suggestion.limits.allowTaxiBridge, _limits.allowTaxiBridge);
      }
    });

    test('si la caminata ya es mínima no sugiere nada', () {
      const tiny = PlanLimits(
        budgetCents: 800,
        maxContinuousWalkMetres: 100,
        maxTotalWalkMetres: 100,
        allowTaxiBridge: true,
      );
      expect(
        ContextAdvisor.suggest(
          limits: tiny,
          nowUtc: _night,
          weather: const WeatherContext(precipitationMm: 5),
        ),
        isEmpty,
      );
    });
  });

  group('WeatherService (Open-Meteo)', () {
    const body =
        '{"current":{"precipitation":0.6,"weather_code":61},'
        '"hourly":{"precipitation_probability":[20,70,40]}}';

    test('interpreta la respuesta', () {
      final w = WeatherService.parse({
        'current': {'precipitation': 0.6, 'weather_code': 61},
        'hourly': {
          'precipitation_probability': [20, 70, 40],
        },
      })!;
      expect(w.precipitationMm, 0.6);
      expect(w.rainChancePercent, 70); // la mayor de las próximas horas
      expect(w.isRaining, isTrue);
      expect(w.description, 'Lluvia');
    });

    test('una respuesta inesperada no rompe nada', () {
      expect(WeatherService.parse({}), isNull);
      expect(WeatherService.parse({'current': 5}), isNull);
    });

    test('consulta una vez y reutiliza la respuesta (caché)', () async {
      var calls = 0;
      final service = WeatherService(
        client: ResilientClient(
          client: MockClient((request) async {
            calls++;
            expect(request.url.host, 'api.open-meteo.com');
            return http.Response(body, 200);
          }),
          retryDelay: Duration.zero,
        ),
      );
      const point = LatLng(-12.07, -77.04);
      final first = await service.currentFor(point);
      final second = await service.currentFor(point);
      expect(first?.isRaining, isTrue);
      expect(second?.isRaining, isTrue);
      expect(calls, 1);
    });

    test('si el servicio falla, devuelve null y la app sigue', () async {
      final service = WeatherService(
        client: ResilientClient(
          client: MockClient((_) async => throw http.ClientException('caído')),
          retryDelay: Duration.zero,
        ),
      );
      expect(await service.currentFor(const LatLng(-12.07, -77.04)), isNull);
    });
  });
}
