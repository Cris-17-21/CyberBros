import 'dart:math' as math;

import 'package:cyber_bros/features/trip_planner/data/osm_stops.dart';
import 'package:cyber_bros/features/trip_planner/data/pilot_planner.dart';
import 'package:cyber_bros/features/trip_planner/domain/routing_engine.dart';
import 'package:cyber_bros/features/trip_planner/domain/stop_inference.dart';
import 'package:cyber_bros/features/trip_planner/domain/trace_simulator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Mide la latencia del motor sobre los datos reales de los corredores
/// (RNF-01, RNF-24). Los resultados se imprimen y se documentan en
/// docs/PERFORMANCE.md. Las aserciones usan la meta de RNF-01 (p95 ≤ 2 s).
OsmStop _point(double lat, double lng, String name) => OsmStop(
  id: 'address:$lat,$lng',
  name: name,
  point: LatLng(lat, lng),
  source: 'address',
);

double _percentile(List<int> sortedMicros, double p) {
  final index = ((sortedMicros.length - 1) * p).round();
  return sortedMicros[index] / 1000;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('latencia de planificación sobre los corredores reales', () async {
    final trips = <(OsmStop, OsmStop)>[
      (_point(-12.0712, -77.0425, 'Brasil'), _point(-12.0575, -77.0375, 'Bolognesi')),
      (_point(-12.0464, -77.0428, 'Centro'), _point(-12.1190, -77.0300, 'Miraflores')),
      (_point(-12.0770, -77.0830, 'San Miguel'), _point(-12.0464, -77.0428, 'Centro')),
      (_point(-12.0900, -77.0300, 'San Isidro'), _point(-12.1500, -77.0200, 'Barranco')),
      (_point(-12.0200, -77.0500, 'Rímac'), _point(-12.0900, -77.0300, 'San Isidro')),
    ];
    final limitSets = const [
      PlanLimits(budgetCents: 800, maxContinuousWalkMetres: 300, maxTotalWalkMetres: 800, allowTaxiBridge: true),
      PlanLimits(budgetCents: 500, maxContinuousWalkMetres: 200, maxTotalWalkMetres: 500, allowTaxiBridge: false),
      PlanLimits(budgetCents: 1500, maxContinuousWalkMetres: 600, maxTotalWalkMetres: 1500, allowTaxiBridge: true),
    ];

    // Calentamiento (carga del catálogo y JIT).
    await PilotPlanner.plan(
      origin: trips.first.$1,
      destination: trips.first.$2,
      limits: limitSets.first,
    );

    final micros = <int>[];
    var feasible = 0, infeasible = 0;
    for (var round = 0; round < 4; round++) {
      for (final trip in trips) {
        for (final limits in limitSets) {
          final watch = Stopwatch()..start();
          final res = await PilotPlanner.plan(
            origin: trip.$1,
            destination: trip.$2,
            limits: limits,
          );
          watch.stop();
          micros.add(watch.elapsedMicroseconds);
          res.result is FeasiblePlan ? feasible++ : infeasible++;
        }
      }
    }
    micros.sort();
    final p50 = _percentile(micros, 0.50);
    final p95 = _percentile(micros, 0.95);
    final p99 = _percentile(micros, 0.99);
    // ignore: avoid_print
    print(
      'BENCH plan: n=${micros.length} (factibles $feasible, sin ruta $infeasible) '
      'p50=${p50.toStringAsFixed(1)} ms · p95=${p95.toStringAsFixed(1)} ms · '
      'p99=${p99.toStringAsFixed(1)} ms · máx=${(micros.last / 1000).toStringAsFixed(1)} ms',
    );
    expect(p95, lessThan(2000), reason: 'RNF-01: p95 ≤ 2 s');
  });

  test('tamaño del grafo cargado', () async {
    final res = await PilotPlanner.plan(
      origin: _point(-12.0712, -77.0425, 'a'),
      destination: _point(-12.0575, -77.0375, 'b'),
      limits: const PlanLimits(
        budgetCents: 800,
        maxContinuousWalkMetres: 300,
        maxTotalWalkMetres: 800,
        allowTaxiBridge: true,
      ),
    );
    // ignore: avoid_print
    print(
      'BENCH grafo: ${res.stopPoints.length} nodos (paraderos + origen/destino), '
      '${res.routeNames.length} rutas',
    );
    expect(res.stopPoints.length, greaterThan(100));
  });

  test('inferencia de paraderos: DBSCAN y motor con muchos eventos', () {
    const spot = LatLng(-12.0896, -77.0305);
    final t0 = DateTime.utc(2026, 10, 18, 10);

    // DBSCAN sobre 2000 puntos repartidos en 10 zonas.
    final random = math.Random(7);
    final points = [
      for (var z = 0; z < 10; z++)
        for (var i = 0; i < 200; i++)
          TraceSimulator.offset(
            TraceSimulator.offset(spot, 36.0 * z, 600.0 * z),
            random.nextDouble() * 360,
            random.nextDouble() * 12,
          ),
    ];
    var watch = Stopwatch()..start();
    final clusters = Dbscan.cluster(points, epsMetres: 28, minPoints: 3);
    watch.stop();
    // ignore: avoid_print
    print(
      'BENCH dbscan: ${points.length} puntos -> ${clusters.length} clústeres en ${watch.elapsedMilliseconds} ms',
    );
    expect(clusters.length, 10);

    // Motor completo con 99 sesiones co-ubicadas (el ataque del carrito).
    final engine = StopInferenceEngine();
    for (var i = 0; i < 99; i++) {
      engine.ingest(
        sessionId: 's$i',
        sourceId: 'bot-$i',
        pings: TraceSimulator.cartThenCar(spot: spot, from: t0, seed: i),
      );
    }
    watch = Stopwatch()..start();
    final stops = engine.inferStops(t0.add(const Duration(hours: 1)));
    watch.stop();
    // ignore: avoid_print
    print(
      'BENCH inferencia: ${engine.eventCount} eventos -> ${stops.length} paradero(s) en ${watch.elapsedMilliseconds} ms',
    );
    expect(watch.elapsedMilliseconds, lessThan(5000));
  });
}
