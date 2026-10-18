/// Inferencia de paraderos de facto a partir de trazas GPS (RF-17, RF-18) con
/// defensa contra manipulación de datos colaborativos (RF-36).
///
/// En Lima los buses y cústers paran donde la gente espera, no siempre donde
/// dice el mapa. Si varias personas esperan quietas en un punto y luego
/// salen a velocidad de vehículo, ahí hay un paradero "de facto". El módulo:
///
///  1. **Detecta abordajes** en la traza de cada sesión ([BoardingDetector]):
///     espera quieta + salto a velocidad vehicular + (opcional) alineación con
///     una ruta conocida. Rechaza datos físicamente imposibles.
///  2. **Agrupa** los abordajes con DBSCAN ([Dbscan]) en metros.
///  3. **Cuenta fuentes independientes** (`nEff`), no sesiones: 99 teléfonos en
///     un carrito cuentan como 1, y una misma fuente no suma sin tope.
///  4. **Promueve** un grupo a paradero visible solo si cumple varias
///     condiciones a la vez (cuarentena) y **decae** sin evidencia nueva.
///  5. **Permite revertir** un lote de eventos (por sesión, fuente o tiempo).
///
/// Es Dart puro y determinista: no usa red, reloj ni azar, así que se prueba
/// con trazas sintéticas ("ataque del carrito", bots, control positivo).
///
/// Garantía honesta: reduce y acota el daño de ataques baratos, no promete
/// invulnerabilidad. Un atacante con muchos dispositivos reales y paciencia
/// aún podría aportar evidencia plausible (ver docs/THREAT_MODEL.md).
library;

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

// ------------------------------------------------------------- configuración

/// Umbrales configurables (RF-17, RNF-30): ninguno está fijo en el código.
final class InferenceConfig {
  const InferenceConfig({
    this.maxAccuracyM = 40,
    this.dwellSeconds = 40,
    this.dwellRadiusM = 25,
    this.waitSpeedMps = 1.2,
    this.vehicleSpeedMps = 4.5,
    this.vehicleSustainSeconds = 8,
    this.vehicleWithinSeconds = 60,
    this.maxPlausibleSpeedMps = 70,
    this.minDistanceFromOfficialStopM = 50,
    this.alignmentToleranceM = 25,
    this.alignmentMinMetres = 300,
    this.dbscanEpsM = 28,
    this.dbscanMinPoints = 3,
    this.minEffectiveSources = 3,
    this.minArrivalSpreadSeconds = 120,
    this.minWindows = 2,
    this.windowMinutes = 30,
    this.syncArrivalSeconds = 20,
    this.coMoveMetres = 10,
    this.coMoveShare = 0.8,
    this.maxPerSource = 2,
    this.halfLifeDays = 14,
    this.minConfidence = 0.05,
  });

  final double maxAccuracyM;
  final int dwellSeconds;
  final double dwellRadiusM;
  final double waitSpeedMps;
  final double vehicleSpeedMps;
  final int vehicleSustainSeconds;
  final int vehicleWithinSeconds;
  final double maxPlausibleSpeedMps;
  final double minDistanceFromOfficialStopM;
  final double alignmentToleranceM;
  final double alignmentMinMetres;

  /// Radio del agrupamiento DBSCAN, en metros.
  final double dbscanEpsM;
  final int dbscanMinPoints;

  /// Fuentes independientes mínimas (`nEff`) para que un paradero sea visible.
  final int minEffectiveSources;

  /// Las llegadas de un paradero real están escalonadas: al menos este rango.
  final int minArrivalSpreadSeconds;

  /// Ventanas de tiempo distintas en que debe observarse (persistencia).
  final int minWindows;
  final int windowMinutes;

  /// Dos llegadas con menos de esta diferencia se tratan como la misma fuente.
  final int syncArrivalSeconds;

  /// Dos trayectorias a menos de [coMoveMetres] durante [coMoveShare] del
  /// tiempo se tratan como una sola fuente (viajan juntas).
  final double coMoveMetres;
  final double coMoveShare;

  /// Máximo de fuentes independientes que puede aportar un mismo origen
  /// (dispositivo, cuenta o IP).
  final int maxPerSource;

  /// Vida media de la confianza sin evidencia nueva (RNF-10).
  final int halfLifeDays;
  final double minConfidence;
}

// ---------------------------------------------------------------------- datos

final class GpsPing {
  const GpsPing({
    required this.time,
    required this.point,
    required this.speedMps,
    required this.accuracyM,
    this.headingDeg,
  });

  final DateTime time;
  final LatLng point;
  final double speedMps;
  final double accuracyM;
  final double? headingDeg;
}

/// Por qué se descartó un dato (auditoría sin datos personales, RNF-30).
enum RejectReason {
  tooFewPings,
  outOfOrder,
  impossibleSpeed,
  constantAccuracy,
  walkingMovement,
  noDwell,
  noVehicleSpeed,
  nearOfficialStop,
  offRoute,
  duplicateToday,
  blockedSource,
}

final class BoardingEvent {
  const BoardingEvent({
    required this.sessionId,
    required this.sourceId,
    required this.point,
    required this.arrivalTime,
    required this.boardingTime,
    required this.headingDeg,
    required this.approach,
    this.isSimulated = false,
  });

  final String sessionId;

  /// Origen del dato (dispositivo, cuenta o IP), para limitar el aporte.
  final String sourceId;
  final LatLng point;

  /// Cuándo empezó a esperar.
  final DateTime arrivalTime;
  final DateTime boardingTime;
  final double headingDeg;

  /// Trayectoria previa (para detectar quienes viajan juntos).
  final List<GpsPing> approach;
  final bool isSimulated;
}

final class DetectionResult {
  const DetectionResult.accepted(this.event) : rejected = null;
  const DetectionResult.rejected(this.rejected) : event = null;

  final BoardingEvent? event;
  final RejectReason? rejected;
}

enum StopStatus { candidate, visible }

final class InferredStop {
  const InferredStop({
    required this.id,
    required this.center,
    required this.status,
    required this.confidence,
    required this.rawEvents,
    required this.effectiveSources,
    required this.arrivalSpreadSeconds,
    required this.windows,
    required this.lastEvidence,
    required this.blockers,
    required this.isSimulated,
  });

  final String id;
  final LatLng center;
  final StopStatus status;

  /// Puntaje heurístico (no es una probabilidad bayesiana): ver
  /// [StopInferenceEngine.confidenceOf].
  final double confidence;
  final int rawEvents;

  /// Fuentes independientes tras fusionar las que viajan juntas.
  final int effectiveSources;
  final int arrivalSpreadSeconds;
  final int windows;
  final DateTime lastEvidence;

  /// Condiciones que aún faltan para ser visible (vacío si ya lo es).
  final List<String> blockers;
  final bool isSimulated;
}

// ------------------------------------------------------------------ geometría

const _distance = Distance();

double _metres(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

/// Distancia de un punto a una polilínea, en metros (aprox. plana local).
double distanceToPolyline(LatLng p, List<LatLng> line) {
  if (line.length < 2) return double.infinity;
  final cosLat = math.cos(p.latitude * math.pi / 180);
  double x(LatLng q) => (q.longitude - p.longitude) * cosLat * 111320;
  double y(LatLng q) => (q.latitude - p.latitude) * 110540;
  var best = double.infinity;
  for (var i = 0; i < line.length - 1; i++) {
    final ax = x(line[i]), ay = y(line[i]);
    final bx = x(line[i + 1]), by = y(line[i + 1]);
    final dx = bx - ax, dy = by - ay;
    final lengthSq = dx * dx + dy * dy;
    final t = lengthSq == 0
        ? 0.0
        : ((-ax * dx - ay * dy) / lengthSq).clamp(0.0, 1.0);
    final px = ax + t * dx, py = ay + t * dy;
    best = math.min(best, math.sqrt(px * px + py * py));
  }
  return best;
}

double bearingDeg(LatLng a, LatLng b) {
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

// --------------------------------------------------------------------- DBSCAN

/// Agrupamiento por densidad (DBSCAN) en metros.
///
/// A diferencia de k-means no necesita saber cuántos paraderos hay y deja los
/// puntos aislados como ruido, que es justo lo que se quiere aquí.
abstract final class Dbscan {
  /// Devuelve los clústeres como listas de índices. Los puntos que no
  /// pertenecen a ninguno (ruido) no aparecen.
  static List<List<int>> cluster(
    List<LatLng> points, {
    required double epsMetres,
    required int minPoints,
  }) {
    if (points.isEmpty) return const [];
    // Proyección plana local en metros (válida en un área pequeña como Lima).
    final lat0 = points.map((p) => p.latitude).reduce((a, b) => a + b) /
        points.length;
    final lng0 = points.map((p) => p.longitude).reduce((a, b) => a + b) /
        points.length;
    final cosLat = math.cos(lat0 * math.pi / 180);
    final xs = [for (final p in points) (p.longitude - lng0) * cosLat * 111320];
    final ys = [for (final p in points) (p.latitude - lat0) * 110540];

    List<int> neighbours(int i) {
      final result = <int>[];
      for (var j = 0; j < points.length; j++) {
        final dx = xs[i] - xs[j], dy = ys[i] - ys[j];
        if (math.sqrt(dx * dx + dy * dy) <= epsMetres) result.add(j);
      }
      return result;
    }

    const unvisited = -2, noise = -1;
    final labels = List<int>.filled(points.length, unvisited);
    var clusterId = 0;
    for (var i = 0; i < points.length; i++) {
      if (labels[i] != unvisited) continue;
      final around = neighbours(i);
      if (around.length < minPoints) {
        labels[i] = noise;
        continue;
      }
      labels[i] = clusterId;
      final queue = [...around]..remove(i);
      for (var q = 0; q < queue.length; q++) {
        final j = queue[q];
        if (labels[j] == noise) labels[j] = clusterId; // borde del clúster
        if (labels[j] != unvisited) continue;
        labels[j] = clusterId;
        final next = neighbours(j);
        if (next.length >= minPoints) {
          for (final n in next) {
            if (!queue.contains(n)) queue.add(n);
          }
        }
      }
      clusterId++;
    }
    return [
      for (var c = 0; c < clusterId; c++)
        [
          for (var i = 0; i < labels.length; i++)
            if (labels[i] == c) i,
        ],
    ];
  }
}

// ------------------------------------------------------------------- detector

/// Detecta el abordaje en la traza de UNA sesión: espera quieta y luego
/// velocidad vehicular. Rechaza trazas físicamente imposibles.
class BoardingDetector {
  const BoardingDetector({
    this.config = const InferenceConfig(),
    this.officialStops = const [],
    this.routes = const [],
  });

  final InferenceConfig config;

  /// Paraderos oficiales: un abordaje cerca de uno no es "de facto".
  final List<LatLng> officialStops;

  /// Polilíneas de rutas conocidas. Si hay, el trayecto posterior debe
  /// seguir alguna; si no, el vehículo "cualquiera" no cuenta como bus.
  final List<List<LatLng>> routes;

  DetectionResult detect({
    required String sessionId,
    required String sourceId,
    required List<GpsPing> pings,
    bool isSimulated = false,
  }) {
    // 1. Orden temporal: una traza con marcas fuera de orden se rechaza.
    for (var i = 1; i < pings.length; i++) {
      if (pings[i].time.isBefore(pings[i - 1].time)) {
        return const DetectionResult.rejected(RejectReason.outOfOrder);
      }
    }
    // 2. Precisión: se descartan los pings poco fiables (RF-16).
    final clean = [
      for (final p in pings)
        if (p.accuracyM <= config.maxAccuracyM) p,
    ];
    if (clean.length < 6) {
      return const DetectionResult.rejected(RejectReason.tooFewPings);
    }
    // 3. Física: velocidades y saltos imposibles invalidan la traza.
    for (var i = 0; i < clean.length; i++) {
      if (clean[i].speedMps > config.maxPlausibleSpeedMps) {
        return const DetectionResult.rejected(RejectReason.impossibleSpeed);
      }
      if (i > 0) {
        final dt = clean[i].time.difference(clean[i - 1].time).inMilliseconds /
            1000;
        if (dt > 0 &&
            _metres(clean[i - 1].point, clean[i].point) / dt >
                config.maxPlausibleSpeedMps) {
          return const DetectionResult.rejected(RejectReason.impossibleSpeed);
        }
      }
    }
    // 4. Precisión sospechosamente perfecta y constante (señal de falsificación).
    if (clean.length >= 10 &&
        clean.every((p) => p.accuracyM < 3) &&
        clean.every((p) => p.accuracyM == clean.first.accuracyM)) {
      return const DetectionResult.rejected(RejectReason.constantAccuracy);
    }

    final speeds = _speeds(clean);

    // 5. Espera quieta: al menos `dwellSeconds` dentro de `dwellRadiusM`.
    final dwell = _findDwell(clean, speeds);
    if (dwell == null) {
      // Si hubo una pausa real pero corta (un semáforo), la causa es "no
      // esperó lo suficiente". Si nunca se detuvo y va a paso de peatón, es
      // una nube que camina sin parar (el "carrito").
      if (_longestStillSeconds(clean, speeds) >= 10) {
        return const DetectionResult.rejected(RejectReason.noDwell);
      }
      final sorted = [...speeds]..sort();
      final median = sorted[sorted.length ~/ 2];
      return DetectionResult.rejected(
        median >= 0.6 && median <= 2.2
            ? RejectReason.walkingMovement
            : RejectReason.noDwell,
      );
    }
    final (:start, :end, :center) = dwell;

    // 6. Salto a velocidad de vehículo poco después de esperar.
    final boarding = _findVehicle(clean, speeds, end);
    if (boarding == null) {
      return const DetectionResult.rejected(RejectReason.noVehicleSpeed);
    }

    // 7. Un abordaje junto a un paradero oficial no es "de facto".
    for (final stop in officialStops) {
      if (_metres(center, stop) < config.minDistanceFromOfficialStopM) {
        return const DetectionResult.rejected(RejectReason.nearOfficialStop);
      }
    }

    // 8. Con rutas conocidas, el trayecto posterior debe seguir alguna.
    if (routes.isNotEmpty && !_followsRoute(clean, boarding)) {
      return const DetectionResult.rejected(RejectReason.offRoute);
    }

    final heading =
        clean[boarding].headingDeg ?? bearingDeg(center, clean[boarding].point);
    final cutoff = clean[start].time.subtract(const Duration(minutes: 3));
    final approach = [
      for (var i = 0; i <= end; i++)
        if (!clean[i].time.isBefore(cutoff)) clean[i],
    ];
    return DetectionResult.accepted(
      BoardingEvent(
        sessionId: sessionId,
        sourceId: sourceId,
        point: center,
        arrivalTime: clean[start].time,
        boardingTime: clean[boarding].time,
        headingDeg: heading,
        approach: approach,
        isSimulated: isSimulated,
      ),
    );
  }

  /// Velocidad de cada ping: la reportada o, si es 0, la derivada de la posición.
  List<double> _speeds(List<GpsPing> pings) {
    final result = <double>[];
    for (var i = 0; i < pings.length; i++) {
      var speed = pings[i].speedMps;
      if (speed <= 0 && i > 0) {
        final dt =
            pings[i].time.difference(pings[i - 1].time).inMilliseconds / 1000;
        if (dt > 0) speed = _metres(pings[i - 1].point, pings[i].point) / dt;
      }
      result.add(speed);
    }
    return result;
  }

  /// Duración, en segundos, de la pausa más larga (velocidad baja).
  int _longestStillSeconds(List<GpsPing> pings, List<double> speeds) {
    var best = 0;
    var i = 0;
    while (i < pings.length) {
      if (speeds[i] >= config.waitSpeedMps) {
        i++;
        continue;
      }
      var j = i;
      while (j + 1 < pings.length && speeds[j + 1] < config.waitSpeedMps) {
        j++;
      }
      best = math.max(best, pings[j].time.difference(pings[i].time).inSeconds);
      i = j + 1;
    }
    return best;
  }

  ({int start, int end, LatLng center})? _findDwell(
    List<GpsPing> pings,
    List<double> speeds,
  ) {
    for (var i = 0; i < pings.length; i++) {
      if (speeds[i] >= config.waitSpeedMps) continue;
      var j = i;
      while (j + 1 < pings.length &&
          speeds[j + 1] < config.waitSpeedMps &&
          _metres(pings[i].point, pings[j + 1].point) <= config.dwellRadiusM) {
        j++;
      }
      final seconds = pings[j].time.difference(pings[i].time).inSeconds;
      if (seconds >= config.dwellSeconds) {
        var lat = 0.0, lng = 0.0;
        for (var k = i; k <= j; k++) {
          lat += pings[k].point.latitude;
          lng += pings[k].point.longitude;
        }
        final n = j - i + 1;
        return (start: i, end: j, center: LatLng(lat / n, lng / n));
      }
      i = j; // no vuelve a probar dentro del mismo tramo quieto
    }
    return null;
  }

  /// Índice del primer ping de un tramo sostenido a velocidad vehicular que
  /// empieza poco después de la espera.
  int? _findVehicle(List<GpsPing> pings, List<double> speeds, int dwellEnd) {
    final limit = pings[dwellEnd].time.add(
      Duration(seconds: config.vehicleWithinSeconds),
    );
    for (var k = dwellEnd + 1; k < pings.length; k++) {
      if (pings[k].time.isAfter(limit)) break;
      if (speeds[k] < config.vehicleSpeedMps) continue;
      var m = k;
      while (m + 1 < pings.length && speeds[m + 1] >= config.vehicleSpeedMps) {
        m++;
      }
      if (pings[m].time.difference(pings[k].time).inSeconds >=
          config.vehicleSustainSeconds) {
        return k;
      }
      k = m;
    }
    return null;
  }

  bool _followsRoute(List<GpsPing> pings, int boarding) {
    var travelled = 0.0;
    for (var i = boarding; i < pings.length; i++) {
      if (i > boarding) {
        travelled += _metres(pings[i - 1].point, pings[i].point);
      }
      final onRoute = routes.any(
        (line) =>
            distanceToPolyline(pings[i].point, line) <=
            config.alignmentToleranceM,
      );
      if (!onRoute) return false;
      if (travelled >= config.alignmentMinMetres) return true;
    }
    return false; // la traza posterior es demasiado corta para comprobarlo
  }
}

// --------------------------------------------------------------------- motor

/// Registro de una decisión de descarte o cuarentena, sin datos personales.
final class DecisionLog {
  const DecisionLog(this.reason, this.detail);

  final String reason;
  final String detail;
}

class StopInferenceEngine {
  StopInferenceEngine({
    this.config = const InferenceConfig(),
    List<LatLng> officialStops = const [],
    List<List<LatLng>> routes = const [],
  }) : detector = BoardingDetector(
         config: config,
         officialStops: officialStops,
         routes: routes,
       );

  final InferenceConfig config;
  final BoardingDetector detector;

  final List<BoardingEvent> _events = [];
  final Set<String> _blockedSources = {};
  final Set<String> _seenToday = {};

  /// Auditoría: por qué un dato no contó (RNF-30).
  final List<DecisionLog> log = [];

  int get eventCount => _events.length;

  /// Posiciones de los abordajes aceptados (para visualizarlos).
  List<LatLng> get eventPoints => [for (final e in _events) e.point];

  /// Procesa la traza de una sesión. Devuelve el motivo si se descartó.
  RejectReason? ingest({
    required String sessionId,
    required String sourceId,
    required List<GpsPing> pings,
    bool isSimulated = false,
  }) {
    if (_blockedSources.contains(sourceId)) {
      log.add(DecisionLog('blockedSource', sourceId));
      return RejectReason.blockedSource;
    }
    final result = detector.detect(
      sessionId: sessionId,
      sourceId: sourceId,
      pings: pings,
      isSimulated: isSimulated,
    );
    final rejected = result.rejected;
    if (rejected != null) {
      log.add(DecisionLog(rejected.name, 'sesión $sessionId'));
      return rejected;
    }
    final event = result.event!;
    // Tope por fuente: 1 evento por sesión, por celda de ~25 m y por día.
    final cell =
        '${(event.point.latitude * 4000).round()}:${(event.point.longitude * 4000).round()}';
    final day = event.boardingTime.toUtc().toIso8601String().substring(0, 10);
    if (!_seenToday.add('${event.sessionId}|$cell|$day')) {
      log.add(DecisionLog('duplicateToday', 'sesión ${event.sessionId}'));
      return RejectReason.duplicateToday;
    }
    _events.add(event);
    return null;
  }

  /// Revierte un lote: quita los eventos que cumplan la condición (por
  /// sesión, fuente o ventana de tiempo). Tras [inferStops] el paradero que
  /// originaron desaparece o baja de estado.
  int invalidate(bool Function(BoardingEvent event) test) {
    final before = _events.length;
    _events.removeWhere(test);
    final removed = before - _events.length;
    if (removed > 0) log.add(DecisionLog('invalidated', '$removed eventos'));
    return removed;
  }

  /// Bloquea una fuente: sus eventos actuales se invalidan y los futuros se
  /// rechazan.
  void blockSource(String sourceId) {
    _blockedSources.add(sourceId);
    invalidate((event) => event.sourceId == sourceId);
  }

  /// Recalcula los paraderos inferidos a partir de los eventos válidos.
  List<InferredStop> inferStops(DateTime now) {
    if (_events.isEmpty) return const [];
    final clusters = Dbscan.cluster(
      [for (final e in _events) e.point],
      epsMetres: config.dbscanEpsM,
      minPoints: config.dbscanMinPoints,
    );
    final stops = <InferredStop>[];
    for (final indices in clusters) {
      final events = [for (final i in indices) _events[i]];
      final stop = _buildStop(events, now);
      if (stop != null) stops.add(stop);
    }
    stops.sort((a, b) => b.confidence.compareTo(a.confidence));
    return stops;
  }

  InferredStop? _buildStop(List<BoardingEvent> events, DateTime now) {
    final groups = _independentGroups(events);
    // n_eff: grupos independientes, con tope por fuente.
    final perSource = <String, int>{};
    for (final group in groups) {
      final source = group.first.sourceId;
      perSource[source] = (perSource[source] ?? 0) + 1;
    }
    final nEff = perSource.values
        .map((count) => math.min(count, config.maxPerSource))
        .fold(0, (sum, value) => sum + value);

    final arrivals = [
      for (final group in groups)
        group
            .map((e) => e.arrivalTime)
            .reduce((a, b) => a.isBefore(b) ? a : b),
    ]..sort();
    final spread = arrivals.last.difference(arrivals.first).inSeconds;

    final windowMillis = config.windowMinutes * 60 * 1000;
    final windows = {
      for (final e in events)
        e.boardingTime.millisecondsSinceEpoch ~/ windowMillis,
    }.length;

    final last = events
        .map((e) => e.boardingTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final blockers = <String>[
      if (nEff < config.minEffectiveSources)
        'Faltan fuentes independientes ($nEff de ${config.minEffectiveSources})',
      if (spread < config.minArrivalSpreadSeconds)
        'Las llegadas son casi simultáneas (${spread}s de dispersión)',
      if (windows < config.minWindows)
        'Aún no se observa en ${config.minWindows} ventanas de tiempo distintas',
    ];

    final confidence = confidenceOf(
      effectiveSources: nEff,
      arrivalSpreadSeconds: spread,
      windows: windows,
      lastEvidence: last,
      now: now,
    );
    if (confidence < config.minConfidence) return null; // expiró

    var lat = 0.0, lng = 0.0;
    for (final e in events) {
      lat += e.point.latitude;
      lng += e.point.longitude;
    }
    final center = LatLng(lat / events.length, lng / events.length);
    if (blockers.isNotEmpty) {
      log.add(DecisionLog('quarantine', blockers.join('; ')));
    }
    return InferredStop(
      id: 'stop:${(center.latitude * 10000).round()}:${(center.longitude * 10000).round()}',
      center: center,
      status: blockers.isEmpty ? StopStatus.visible : StopStatus.candidate,
      confidence: confidence,
      rawEvents: events.length,
      effectiveSources: nEff,
      arrivalSpreadSeconds: spread,
      windows: windows,
      lastEvidence: last,
      blockers: blockers,
      isSimulated: events.every((e) => e.isSimulated),
    );
  }

  /// Fusiona las sesiones que no son independientes: las que viajan juntas
  /// (trayectorias casi idénticas) o llegan al mismo instante.
  List<List<BoardingEvent>> _independentGroups(List<BoardingEvent> events) {
    final parent = List<int>.generate(events.length, (i) => i);
    int find(int i) {
      while (parent[i] != i) {
        parent[i] = parent[parent[i]];
        i = parent[i];
      }
      return i;
    }

    for (var i = 0; i < events.length; i++) {
      for (var j = i + 1; j < events.length; j++) {
        if (find(i) == find(j)) continue;
        final syncArrival =
            events[i].arrivalTime.difference(events[j].arrivalTime).inSeconds
                .abs() <
            config.syncArrivalSeconds;
        if (syncArrival || _coMove(events[i], events[j])) {
          parent[find(i)] = find(j);
        }
      }
    }
    final groups = <int, List<BoardingEvent>>{};
    for (var i = 0; i < events.length; i++) {
      groups.putIfAbsent(find(i), () => []).add(events[i]);
    }
    return groups.values.toList();
  }

  /// ¿Dos sesiones se movieron juntas antes de abordar?
  bool _coMove(BoardingEvent a, BoardingEvent b) {
    var compared = 0, close = 0;
    for (final p in a.approach) {
      GpsPing? match;
      for (final q in b.approach) {
        if (q.time.difference(p.time).inSeconds.abs() <= 5) {
          match = q;
          break;
        }
      }
      if (match == null) continue;
      compared++;
      if (_metres(p.point, match.point) <= config.coMoveMetres) close++;
    }
    return compared >= 5 && close / compared >= config.coMoveShare;
  }

  /// Puntaje heurístico de confianza (0 a 1). **No** es una probabilidad
  /// bayesiana: combina con pesos fijos la cantidad de fuentes independientes
  /// (60 %), la dispersión de llegadas (20 %) y la persistencia (20 %), y
  /// decae a la mitad cada [InferenceConfig.halfLifeDays] días sin evidencia.
  double confidenceOf({
    required int effectiveSources,
    required int arrivalSpreadSeconds,
    required int windows,
    required DateTime lastEvidence,
    required DateTime now,
  }) {
    final sources = math.min(effectiveSources, 10) / 10;
    final spread = math.min(arrivalSpreadSeconds / 600, 1.0);
    final persistence = math.min(windows / 4, 1.0);
    final base = 0.6 * sources + 0.2 * spread + 0.2 * persistence;
    final ageDays = math.max(0, now.difference(lastEvidence).inHours) / 24;
    final decay = math.pow(0.5, ageDays / config.halfLifeDays).toDouble();
    return base * decay;
  }
}
