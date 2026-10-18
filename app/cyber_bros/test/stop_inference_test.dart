import 'package:cyber_bros/features/trip_planner/domain/stop_inference.dart';
import 'package:cyber_bros/features/trip_planner/domain/trace_simulator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Un paradero informal en una avenida de Lima (no oficial).
const _spot = LatLng(-12.0900, -77.0300);
final _t0 = DateTime.utc(2026, 10, 18, 10); // 05:00 en Lima, inicio de ventana
final _route = TraceSimulator.straightRoute(_spot, 90);

StopInferenceEngine _engine({bool withRoute = true}) => StopInferenceEngine(
  routes: withRoute ? [_route] : const [],
);

/// Cinco personas independientes que llegan escalonadas y abordan.
void _legitimateRiders(
  StopInferenceEngine engine, {
  List<int> minutesOffsets = const [0, 3, 6, 40, 43],
}) {
  for (var i = 0; i < minutesOffsets.length; i++) {
    engine.ingest(
      sessionId: 'persona-$i',
      sourceId: 'dispositivo-$i',
      pings: TraceSimulator.rider(
        stop: _spot,
        arrival: _t0.add(Duration(minutes: minutesOffsets[i])),
        approachBearingDeg: 30.0 * i + 100, // cada una llega desde otro lado
        approachFromMetres: 40.0 + 10 * i,
        waitSeconds: 60 + 9 * i,
        seed: 100 + i,
      ),
    );
  }
}

void main() {
  group('DBSCAN', () {
    test('agrupa puntos cercanos y deja el ruido fuera', () {
      final points = [
        _spot,
        TraceSimulator.offset(_spot, 0, 5),
        TraceSimulator.offset(_spot, 90, 8),
        TraceSimulator.offset(_spot, 180, 6),
        TraceSimulator.offset(_spot, 0, 500), // aislado: ruido
      ];
      final clusters =
          Dbscan.cluster(points, epsMetres: 28, minPoints: 3);
      expect(clusters.length, 1);
      expect(clusters.single.toSet(), {0, 1, 2, 3});
    });

    test('separa dos zonas lejanas en dos clústeres', () {
      final far = TraceSimulator.offset(_spot, 0, 400);
      final points = [
        for (var i = 0; i < 4; i++) TraceSimulator.offset(_spot, 90.0 * i, 4),
        for (var i = 0; i < 4; i++) TraceSimulator.offset(far, 90.0 * i, 4),
      ];
      expect(
        Dbscan.cluster(points, epsMetres: 28, minPoints: 3).length,
        2,
      );
    });

    test('sin suficientes puntos no hay clúster', () {
      expect(
        Dbscan.cluster([_spot, TraceSimulator.offset(_spot, 0, 5)],
            epsMetres: 28, minPoints: 3),
        isEmpty,
      );
    });
  });

  group('Detector de abordaje (RF-17)', () {
    const detector = BoardingDetector();

    test('espera quieta + salto a velocidad de vehículo = un abordaje', () {
      final result = detector.detect(
        sessionId: 's',
        sourceId: 'd',
        pings: TraceSimulator.rider(stop: _spot, arrival: _t0),
      );
      final event = result.event!;
      expect(const Distance().as(LengthUnit.Meter, event.point, _spot),
          lessThan(8));
      expect(event.headingDeg, closeTo(90, 5));
    });

    test('un peatón que espera un semáforo NO es un abordaje', () {
      final result = detector.detect(
        sessionId: 's',
        sourceId: 'd',
        pings: TraceSimulator.pedestrianAtTrafficLight(spot: _spot, from: _t0),
      );
      expect(result.event, isNull);
      expect(result.rejected, RejectReason.noDwell);
    });

    test('una nube que camina sin parar se descarta como movimiento peatonal', () {
      final result = detector.detect(
        sessionId: 's',
        sourceId: 'd',
        pings: TraceSimulator.cartWalker(start: _spot, from: _t0),
      );
      expect(result.rejected, RejectReason.walkingMovement);
    });

    test('rechaza velocidades físicamente imposibles', () {
      final pings = TraceSimulator.rider(stop: _spot, arrival: _t0);
      final bad = [
        ...pings,
        GpsPing(
          time: pings.last.time.add(const Duration(seconds: 3)),
          point: _spot,
          speedMps: 200,
          accuracyM: 8,
        ),
      ];
      expect(
        detector.detect(sessionId: 's', sourceId: 'd', pings: bad).rejected,
        RejectReason.impossibleSpeed,
      );
    });

    test('rechaza saltos de posición imposibles aunque la velocidad reportada sea normal', () {
      final pings = TraceSimulator.rider(stop: _spot, arrival: _t0);
      final jump = [
        ...pings.take(10),
        GpsPing(
          time: pings[10].time,
          point: TraceSimulator.offset(_spot, 0, 50000), // 50 km en 3 s
          speedMps: 1,
          accuracyM: 8,
        ),
        ...pings.skip(11),
      ];
      expect(
        detector.detect(sessionId: 's', sourceId: 'd', pings: jump).rejected,
        RejectReason.impossibleSpeed,
      );
    });

    test('descarta los pings poco precisos', () {
      final noisy = [
        for (final p in TraceSimulator.rider(stop: _spot, arrival: _t0))
          GpsPing(
            time: p.time,
            point: p.point,
            speedMps: p.speedMps,
            accuracyM: 120,
          ),
      ];
      expect(
        detector.detect(sessionId: 's', sourceId: 'd', pings: noisy).rejected,
        RejectReason.tooFewPings,
      );
    });

    test('rechaza una precisión perfecta y constante (señal de bot)', () {
      final fake = [
        for (final p in TraceSimulator.rider(stop: _spot, arrival: _t0))
          GpsPing(
            time: p.time,
            point: p.point,
            speedMps: p.speedMps,
            accuracyM: 1,
            headingDeg: p.headingDeg,
          ),
      ];
      expect(
        detector.detect(sessionId: 's', sourceId: 'd', pings: fake).rejected,
        RejectReason.constantAccuracy,
      );
    });

    test('rechaza marcas de tiempo fuera de orden', () {
      final pings = TraceSimulator.rider(stop: _spot, arrival: _t0);
      final shuffled = [pings[1], pings[0], ...pings.skip(2)];
      expect(
        detector.detect(sessionId: 's', sourceId: 'd', pings: shuffled).rejected,
        RejectReason.outOfOrder,
      );
    });

    test('un abordaje junto a un paradero oficial no es "de facto"', () {
      final withOfficial = BoardingDetector(officialStops: [_spot]);
      expect(
        withOfficial
            .detect(
              sessionId: 's',
              sourceId: 'd',
              pings: TraceSimulator.rider(stop: _spot, arrival: _t0),
            )
            .rejected,
        RejectReason.nearOfficialStop,
      );
    });

    test('con rutas conocidas, un auto cualquiera no cuenta como bus', () {
      final onRoute = BoardingDetector(routes: [_route]);
      // Bus que sigue la ruta (hacia el este): válido.
      expect(
        onRoute
            .detect(
              sessionId: 's',
              sourceId: 'd',
              pings: TraceSimulator.rider(stop: _spot, arrival: _t0),
            )
            .event,
        isNotNull,
      );
      // Auto que se va hacia el norte, fuera de la ruta: se descarta.
      expect(
        onRoute
            .detect(
              sessionId: 's',
              sourceId: 'd',
              pings: TraceSimulator.cartThenCar(spot: _spot, from: _t0),
            )
            .rejected,
        RejectReason.offRoute,
      );
    });
  });

  group('Defensa contra manipulación (RF-36)', () {
    test('prueba "carrito": 99 teléfonos caminando generan 0 eventos y 0 paraderos', () {
      final engine = _engine();
      for (var i = 0; i < 99; i++) {
        engine.ingest(
          sessionId: 'carrito-$i',
          sourceId: 'bot-$i',
          pings: TraceSimulator.cartWalker(start: _spot, from: _t0, seed: i),
        );
      }
      expect(engine.eventCount, 0);
      expect(engine.inferStops(_t0.add(const Duration(hours: 1))), isEmpty);
    });

    test('prueba "carrito + auto": 99 sesiones co-ubicadas cuentan como 1 y no son visibles', () {
      // Sin rutas: así los eventos se generan y se prueba la fusión por
      // independencia (n_eff), no el filtro de ruta.
      final engine = _engine(withRoute: false);
      for (var i = 0; i < 99; i++) {
        engine.ingest(
          sessionId: 'carrito-$i',
          sourceId: 'bot-$i',
          pings: TraceSimulator.cartThenCar(spot: _spot, from: _t0, seed: i),
        );
      }
      expect(engine.eventCount, 99);
      final stops = engine.inferStops(_t0.add(const Duration(hours: 1)));
      expect(stops.length, 1);
      expect(stops.single.effectiveSources, 1);
      expect(stops.single.status, StopStatus.candidate);
      expect(stops.single.blockers, isNotEmpty);
    });

    test('prueba "carrito + auto" con rutas conocidas: ni siquiera llega a ser evento', () {
      final engine = _engine(); // con ruta
      for (var i = 0; i < 20; i++) {
        engine.ingest(
          sessionId: 'carrito-$i',
          sourceId: 'bot-$i',
          pings: TraceSimulator.cartThenCar(spot: _spot, from: _t0, seed: i),
        );
      }
      expect(engine.eventCount, 0);
      expect(engine.log.where((l) => l.reason == 'offRoute').length, 20);
    });

    test('prueba "bots dispersos": 20 sesiones de una misma fuente quedan topadas', () {
      final engine = _engine();
      for (var i = 0; i < 20; i++) {
        engine.ingest(
          sessionId: 'bot-$i',
          sourceId: 'misma-ip', // una sola fuente
          pings: TraceSimulator.rider(
            stop: _spot,
            // llegadas escalonadas para parecer legítimas
            arrival: _t0.add(Duration(minutes: i * 3)),
            approachBearingDeg: 18.0 * i,
            approachFromMetres: 40 + i.toDouble(),
            seed: 300 + i,
          ),
        );
      }
      final stops = engine.inferStops(_t0.add(const Duration(hours: 3)));
      expect(stops.length, 1);
      expect(stops.single.effectiveSources, lessThanOrEqualTo(2));
      expect(stops.single.status, StopStatus.candidate);
    });

    test('control positivo: 5 personas independientes y escalonadas SÍ promueven el paradero', () {
      final engine = _engine();
      _legitimateRiders(engine);
      expect(engine.eventCount, 5);
      final stops = engine.inferStops(_t0.add(const Duration(hours: 2)));
      expect(stops.length, 1);
      final stop = stops.single;
      expect(stop.status, StopStatus.visible);
      expect(stop.effectiveSources, 5);
      expect(stop.arrivalSpreadSeconds, greaterThanOrEqualTo(120));
      expect(stop.confidence, greaterThan(0.3));
      expect(
        const Distance().as(LengthUnit.Meter, stop.center, _spot),
        lessThan(10),
      );
    });

    test('persistencia: sin ventanas de tiempo distintas queda en cuarentena', () {
      final engine = _engine();
      _legitimateRiders(engine, minutesOffsets: const [0, 3, 6, 9, 12]);
      final stop = engine.inferStops(_t0.add(const Duration(hours: 1))).single;
      expect(stop.status, StopStatus.candidate);
      expect(stop.windows, 1);
      expect(stop.blockers.join(), contains('ventanas'));
    });

    test('llegadas simultáneas de fuentes distintas se tratan como una sola', () {
      final engine = _engine();
      for (var i = 0; i < 6; i++) {
        engine.ingest(
          sessionId: 'sync-$i',
          sourceId: 'fuente-$i',
          pings: TraceSimulator.rider(
            stop: _spot,
            arrival: _t0, // todas a la vez
            approachBearingDeg: 60.0 * i,
            seed: 500 + i,
          ),
        );
      }
      final stop = engine.inferStops(_t0.add(const Duration(hours: 1))).single;
      expect(stop.effectiveSources, 1);
      expect(stop.status, StopStatus.candidate);
    });

    test('reversión: invalidar un lote elimina el paradero que originó', () {
      final engine = _engine();
      _legitimateRiders(engine);
      final now = _t0.add(const Duration(hours: 2));
      expect(engine.inferStops(now).single.status, StopStatus.visible);

      // Se invalida todo lo aportado por 3 de las 5 fuentes.
      final removed = engine.invalidate(
        (e) => const {'dispositivo-0', 'dispositivo-1', 'dispositivo-2'}
            .contains(e.sourceId),
      );
      expect(removed, 3);
      // Quedan 2 eventos: menos que el mínimo de DBSCAN, así que no hay clúster.
      expect(engine.inferStops(now), isEmpty);
    });

    test('bloquear una fuente invalida sus eventos y rechaza los siguientes', () {
      final engine = _engine();
      _legitimateRiders(engine);
      engine.blockSource('dispositivo-4');
      expect(engine.eventCount, 4);
      final reason = engine.ingest(
        sessionId: 'nuevo',
        sourceId: 'dispositivo-4',
        pings: TraceSimulator.rider(stop: _spot, arrival: _t0, seed: 9),
      );
      expect(reason, RejectReason.blockedSource);
      expect(engine.eventCount, 4);
    });

    test('una sesión no cuenta dos veces el mismo día en el mismo punto', () {
      final engine = _engine();
      final pings = TraceSimulator.rider(stop: _spot, arrival: _t0);
      expect(engine.ingest(sessionId: 'a', sourceId: 'x', pings: pings), isNull);
      expect(
        engine.ingest(sessionId: 'a', sourceId: 'x', pings: pings),
        RejectReason.duplicateToday,
      );
      expect(engine.eventCount, 1);
    });

    test('cada descarte queda registrado con su causa, sin datos personales', () {
      final engine = _engine();
      engine.ingest(
        sessionId: 'peaton',
        sourceId: 'x',
        pings: TraceSimulator.pedestrianAtTrafficLight(spot: _spot, from: _t0),
      );
      expect(engine.log.single.reason, 'noDwell');
    });
  });

  group('Decaimiento de la confianza (RNF-10)', () {
    test('baja a la mitad cada 14 días y el paradero expira sin evidencia', () {
      final engine = _engine();
      _legitimateRiders(engine);
      final last = _t0.add(const Duration(minutes: 41));
      double confidenceAt(Duration after) =>
          engine.confidenceOf(
            effectiveSources: 5,
            arrivalSpreadSeconds: 600,
            windows: 2,
            lastEvidence: last,
            now: last.add(after),
          );
      final fresh = confidenceAt(Duration.zero);
      expect(confidenceAt(const Duration(days: 14)), closeTo(fresh / 2, 0.001));
      expect(confidenceAt(const Duration(days: 28)), closeTo(fresh / 4, 0.001));
      // Mucho tiempo después: el paradero desaparece del resultado.
      expect(engine.inferStops(last.add(const Duration(days: 90))), isEmpty);
    });
  });
}
