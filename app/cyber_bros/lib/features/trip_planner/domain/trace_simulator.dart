/// Generador de trazas GPS sintéticas para probar y demostrar la inferencia
/// de paraderos de facto (RF-19). Todo lo que produce es **simulado** y la
/// interfaz debe rotularlo así; nunca se mezcla con datos de personas reales.
///
/// Es determinista: la misma semilla produce la misma traza.
library;

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'stop_inference.dart';

abstract final class TraceSimulator {
  static const _step = Duration(seconds: 3);

  /// Punto a [metres] metros de [from] en dirección [bearingDeg].
  static LatLng offset(LatLng from, double bearingDeg, double metres) {
    final rad = bearingDeg * math.pi / 180;
    final dLat = metres * math.cos(rad) / 110540;
    final dLng =
        metres * math.sin(rad) / (111320 * math.cos(from.latitude * math.pi / 180));
    return LatLng(from.latitude + dLat, from.longitude + dLng);
  }

  /// Ruta recta que sale de [from] hacia [bearingDeg], útil como "ruta conocida".
  static List<LatLng> straightRoute(
    LatLng from,
    double bearingDeg, {
    double lengthMetres = 2000,
    double backMetres = 300,
  }) => [
    offset(from, (bearingDeg + 180) % 360, backMetres),
    offset(from, bearingDeg, lengthMetres),
  ];

  static GpsPing _ping(
    math.Random random,
    DateTime time,
    LatLng truth,
    double speed, {
    double noiseMetres = 2,
    double? heading,
  }) {
    final jitter = offset(
      offset(truth, 90, (random.nextDouble() - 0.5) * 2 * noiseMetres),
      0,
      (random.nextDouble() - 0.5) * 2 * noiseMetres,
    );
    return GpsPing(
      time: time,
      point: jitter,
      speedMps: speed,
      // Precisión realista y variable (una constante perfecta delataría un bot).
      accuracyM: 6 + random.nextDouble() * 8,
      headingDeg: heading,
    );
  }

  /// Persona real: camina hasta el paradero, espera y aborda un vehículo que
  /// avanza hacia [headingDeg] por la ruta.
  static List<GpsPing> rider({
    required LatLng stop,
    required DateTime arrival,
    double headingDeg = 90,
    double approachBearingDeg = 200,
    double approachFromMetres = 60,
    int waitSeconds = 75,
    int rideSeconds = 90,
    int seed = 1,
  }) {
    final random = math.Random(seed);
    final pings = <GpsPing>[];
    var t = arrival.subtract(
      Duration(seconds: (approachFromMetres / 1.3).round()),
    );
    // Aproximación a pie, a ~1.3 m/s.
    final walkSteps = (approachFromMetres / 1.3 / 3).round();
    for (var i = 0; i < walkSteps; i++) {
      final remaining = approachFromMetres * (1 - i / walkSteps);
      pings.add(
        _ping(random, t, offset(stop, approachBearingDeg, remaining), 1.3),
      );
      t = t.add(_step);
    }
    // Espera quieta con jitter de GPS.
    final waitSteps = waitSeconds ~/ 3;
    for (var i = 0; i < waitSteps; i++) {
      pings.add(_ping(random, t, stop, 0.1, noiseMetres: 2.5));
      t = t.add(_step);
    }
    // El vehículo arranca: acelera y sigue la ruta.
    var travelled = 0.0;
    final rideSteps = rideSeconds ~/ 3;
    for (var i = 0; i < rideSteps; i++) {
      final speed = math.min(2.0 + i * 1.5, 9.0);
      travelled += speed * 3;
      pings.add(
        _ping(
          random,
          t,
          offset(stop, headingDeg, travelled),
          speed,
          noiseMetres: 3,
          heading: headingDeg,
        ),
      );
      t = t.add(_step);
    }
    return pings;
  }

  /// El "carrito de teléfonos": una nube que camina a ~1.2 m/s sin parar.
  static List<GpsPing> cartWalker({
    required LatLng start,
    required DateTime from,
    double headingDeg = 0,
    int minutes = 10,
    int seed = 1,
  }) {
    final random = math.Random(seed);
    final pings = <GpsPing>[];
    final steps = minutes * 60 ~/ 3;
    for (var i = 0; i < steps; i++) {
      pings.add(
        _ping(
          random,
          from.add(_step * i),
          offset(start, headingDeg, 1.2 * 3 * i),
          1.2,
          noiseMetres: 1,
        ),
      );
    }
    return pings;
  }

  /// Nube de teléfonos quietos ~3 minutos y luego trasladados en un vehículo
  /// que NO sigue ninguna ruta (un auto cualquiera).
  static List<GpsPing> cartThenCar({
    required LatLng spot,
    required DateTime from,
    double carHeadingDeg = 0,
    int seed = 1,
  }) {
    final random = math.Random(seed);
    final pings = <GpsPing>[];
    var t = from;
    for (var i = 0; i < 60; i++) {
      pings.add(_ping(random, t, spot, 0.05, noiseMetres: 1));
      t = t.add(_step);
    }
    var travelled = 0.0;
    for (var i = 0; i < 30; i++) {
      final speed = math.min(2.0 + i * 1.5, 9.0);
      travelled += speed * 3;
      pings.add(
        _ping(
          random,
          t,
          offset(spot, carHeadingDeg, travelled),
          speed,
          noiseMetres: 1,
          heading: carHeadingDeg,
        ),
      );
      t = t.add(_step);
    }
    return pings;
  }

  /// Peatón que espera 20 s un semáforo y sigue caminando: no abordó nada.
  static List<GpsPing> pedestrianAtTrafficLight({
    required LatLng spot,
    required DateTime from,
    double headingDeg = 90,
    int seed = 1,
  }) {
    final random = math.Random(seed);
    final pings = <GpsPing>[];
    var t = from;
    for (var i = 0; i < 8; i++) {
      pings.add(
        _ping(random, t, offset(spot, headingDeg, -1.3 * 3 * (8 - i)), 1.3),
      );
      t = t.add(_step);
    }
    for (var i = 0; i < 7; i++) {
      pings.add(_ping(random, t, spot, 0.1, noiseMetres: 1.5));
      t = t.add(_step);
    }
    for (var i = 0; i < 10; i++) {
      pings.add(
        _ping(random, t, offset(spot, headingDeg, 1.3 * 3 * (i + 1)), 1.3),
      );
      t = t.add(_step);
    }
    return pings;
  }
}
