import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../domain/routing_engine.dart';
import 'osm_stops.dart';

final class PilotPlanningResult {
  const PilotPlanningResult({
    required this.result,
    required this.routeNames,
    required this.stopNames,
    required this.stopPoints,
    required this.warning,
    required this.datasetId,
    this.isRushHour = false,
  });

  final PlanResult result;
  final Map<String, String> routeNames;
  final Map<String, String> stopNames;
  final Map<String, LatLng> stopPoints;
  final String warning;
  final String datasetId;
  final bool isRushHour;
}

/// A limited corridor pilot. Stops come from OSM and fares are ATU general
/// fares; actual operation, boarding, promotions and trip time need checking.
final class PilotPlanner {
  static Future<PilotPlanningResult> plan({
    required OsmStop origin,
    required OsmStop destination,
    required PlanLimits limits,
  }) async {
    final raw = await rootBundle.loadString(
      'assets/data/corridor_candidates.json',
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['schema_version'] != 1 || data['scope'] != 'corridor_pilot_only') {
      throw const FormatException(
        'Versión del catálogo de corredores no compatible',
      );
    }
    final routes = data['routes'] as List<dynamic>;
    final rush = isRushHour();
    final busSpeedMetresPerMin = rush ? 220 : 300;
    final taxiSpeedMetresPerMin = rush ? 240 : 350;
    final boardWaitMinutes = rush ? 7 : 4;

    final stops = <String, LatLng>{};
    final names = <String, String>{};
    final stopNames = <String, String>{};
    final stopRoutes = <String, Set<String>>{};
    final edges = <TravelEdge>[];
    final seenBoarding = <String>{};
    for (final item in routes) {
      final route = item as Map<String, dynamic>;
      final routeId = route['id'] as String;
      names[routeId] = route['name'] as String? ?? route['service'] as String;
      final sequence = route['stops'] as List<dynamic>;
      final fareCents = route['general_fare_cents'] as int;
      final source = route['stop_sequence_source'] as String;
      for (var index = 0; index < sequence.length; index++) {
        final stop = sequence[index] as Map<String, dynamic>;
        final stopId = stop['id'] as String;
        final point = LatLng(
          (stop['lat'] as num).toDouble(),
          (stop['lon'] as num).toDouble(),
        );
        stops[stopId] = point;
        stopNames[stopId] = stop['name'] as String? ?? 'Paradero OSM';
        stopRoutes.putIfAbsent(stopId, () => <String>{}).add(routeId);
        final key = '$routeId|$stopId';
        if (seenBoarding.add(key)) {
          edges.add(
            TravelEdge(
              id: 'board:$key',
              fromNodeId: stopId,
              toNodeId: stopId,
              kind: EdgeKind.board,
              routeId: routeId,
              distanceMetres: 0,
              durationMinutes: boardWaitMinutes,
              costCents: fareCents,
              certainty: DataCertainty.community,
              source: route['fare_source'] as String,
            ),
          );
          edges.add(
            TravelEdge(
              id: 'alight:$key',
              fromNodeId: stopId,
              toNodeId: stopId,
              kind: EdgeKind.alight,
              routeId: routeId,
              distanceMetres: 0,
              durationMinutes: 0,
              costCents: 0,
              certainty: DataCertainty.community,
              source: source,
            ),
          );
        }
        if (index == 0) continue;
        final previous = sequence[index - 1] as Map<String, dynamic>;
        final previousId = previous['id'] as String;
        if (previousId == stopId) continue;
        final previousPoint = stops[previousId]!;
        final metres = _estimatedRoadMetres(previousPoint, point);
        // Si dos paraderos consecutivos reportan más de 2500 m en una ruta urbana,
        // es un error de secuencia OSM (ida/vuelta mezclada o salto de terminal)
        if (metres > 2500) continue;
        edges.add(
          TravelEdge(
            id: 'ride:$routeId:$index',
            fromNodeId: previousId,
            toNodeId: stopId,
            kind: EdgeKind.ride,
            routeId: routeId,
            distanceMetres: metres,
            durationMinutes:
                math.max(1, (metres / busSpeedMetresPerMin).ceil()),
            costCents: 0,
            certainty: DataCertainty.community,
            source: source,
          ),
        );
      }
    }
    const startId = 'trip:origin';
    const finishId = 'trip:destination';
    final directWalk = _estimatedRoadMetres(origin.point, destination.point);
    if (directWalk <= limits.maxContinuousWalkMetres &&
        directWalk <= limits.maxTotalWalkMetres) {
      edges.add(
        TravelEdge(
          id: 'walk:direct',
          fromNodeId: startId,
          toNodeId: finishId,
          kind: EdgeKind.walk,
          distanceMetres: directWalk,
          durationMinutes: (directWalk / 75).ceil(),
          costCents: 0,
          certainty: DataCertainty.estimated,
          source: 'estimate:haversine-times-1.3',
        ),
      );
    }
    // Construir aristas peatonales de acceso a paraderos con un radio físico holgado
    // para que el grafo siempre contenga las rutas reales y el algoritmo pueda evaluar
    // tanto el límite estricto como el relajado en caso de condiciones mínimas.
    final maxAccessWalk = math.max(limits.maxContinuousWalkMetres, 2200);
    final maxAccessTotal = math.max(limits.maxTotalWalkMetres, 4500);

    for (final entry in stops.entries) {
      final firstWalk = _estimatedRoadMetres(origin.point, entry.value);
      if (firstWalk <= maxAccessWalk && firstWalk <= maxAccessTotal) {
        edges.add(
          TravelEdge(
            id: 'access:${entry.key}',
            fromNodeId: startId,
            toNodeId: entry.key,
            kind: EdgeKind.walk,
            distanceMetres: firstWalk,
            durationMinutes: (firstWalk / 75).ceil(),
            costCents: 0,
            certainty: DataCertainty.estimated,
            source: 'estimate:haversine-times-1.3',
          ),
        );
      }
      final finalWalk = _estimatedRoadMetres(entry.value, destination.point);
      if (finalWalk <= maxAccessWalk && finalWalk <= maxAccessTotal) {
        edges.add(
          TravelEdge(
            id: 'egress:${entry.key}',
            fromNodeId: entry.key,
            toNodeId: finishId,
            kind: EdgeKind.walk,
            distanceMetres: finalWalk,
            durationMinutes: (finalWalk / 75).ceil(),
            costCents: 0,
            certainty: DataCertainty.estimated,
            source: 'estimate:haversine-times-1.3',
          ),
        );
      }
    }
    if (limits.allowTaxiBridge) {
      _addTaxiBridges(
        stops,
        stopRoutes,
        limits,
        edges,
        taxiSpeed: taxiSpeedMetresPerMin,
      );
      _addAccessAndEgressTaxiBridges(
        startId,
        origin.point,
        finishId,
        destination.point,
        stops,
        limits,
        edges,
        taxiSpeed: taxiSpeedMetresPerMin,
      );
    }
    final graph = RoutingGraph(
      nodeIds: {...stops.keys, startId, finishId},
      edges: edges,
      planningReady: true,
    );
    var result = await LocalPlanner(graph, maxExpandedLabels: 15000).plan(
      PlanRequest(
        originNodeId: startId,
        destinationNodeId: finishId,
        limits: limits,
      ),
    );

    // Si no hubo solución factible O si la solución no incluye transporte público
    // (por ejemplo, si el usuario puso las condiciones al mínimo y solo saldría caminar todo el trayecto):
    final hasTransit = result is FeasiblePlan &&
        result.alternatives.any(
          (a) => a.edges.any(
            (e) =>
                e.kind == EdgeKind.board ||
                e.kind == EdgeKind.ride ||
                e.kind == EdgeKind.taxiBridge,
          ),
        );

    if (result is InfeasiblePlan || !hasTransit) {
      result = await _buildFallbackPlan(
        graph: graph,
        startId: startId,
        finishId: finishId,
        originPoint: origin.point,
        destinationPoint: destination.point,
        limits: limits,
        taxiSpeed: taxiSpeedMetresPerMin,
        strictPlan: result is FeasiblePlan ? result : null,
      );
    }
    return PilotPlanningResult(
      result: result,
      routeNames: names,
      stopNames: stopNames,
      stopPoints: Map.unmodifiable({
        ...stops,
        startId: origin.point,
        finishId: destination.point,
      }),
      warning: data['fare_warning'] as String,
      datasetId: data['dataset_id'] as String,
      isRushHour: rush,
    );
  }

  static int _estimatedRoadMetres(LatLng first, LatLng second) =>
      (const Distance().as(LengthUnit.Meter, first, second) * 1.3).round();

  /// Detecta hora punta en Lima (UTC-5):
  /// - Lunes a viernes de 07:00 a 09:59 y de 17:30 a 21:00
  static bool isRushHour([DateTime? customTime]) {
    final now = (customTime ?? DateTime.now()).toUtc().subtract(const Duration(hours: 5));
    final hour = now.hour;
    final minute = now.minute;
    final isWeekday = now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
    final isMorningRush = hour >= 7 && hour < 10;
    final isEveningRush = (hour == 17 && minute >= 30) || (hour >= 18 && hour <= 21);
    return isWeekday && (isMorningRush || isEveningRush);
  }

  /// Modelo oficial de tarificación UberX Lima:
  /// - Tarifa mínima de servicio: S/ 8.50 (850 centavos)
  /// - Tarifa base (pickup): S/ 3.80 (380 centavos)
  /// - Tarifa kilométrica: S/ 1.45/km (145 centavos/km)
  /// - Tarifa por tiempo: S/ 0.28/min (28 centavos/minuto)
  /// - Factor dinámico (Surge): 1.20x en hora punta de Lima
  static int estimateUberXCents({
    required int distanceMetres,
    required int durationMinutes,
    DateTime? customTime,
  }) {
    const minFareCents = 850;
    const baseFareCents = 380;
    const centsPerKm = 145;
    const centsPerMinute = 28;

    final rawCents = baseFareCents +
        (centsPerKm * distanceMetres / 1000).round() +
        (centsPerMinute * durationMinutes);

    final surge = isRushHour(customTime) ? 1.20 : 1.0;
    final finalCents = (rawCents * surge).round();
    return math.max(minFareCents, finalCents);
  }

  static void _addTaxiBridges(
    Map<String, LatLng> stops,
    Map<String, Set<String>> stopRoutes,
    PlanLimits limits,
    List<TravelEdge> edges, {
    int taxiSpeed = 350,
  }) {
    const maxTaxiMetres = 1800;
    const maxDestinationsPerStop = 4;
    for (final from in stops.entries) {
      final nearby = <({String id, int metres})>[];
      for (final to in stops.entries) {
        if (from.key == to.key ||
            stopRoutes[from.key]!
                .intersection(stopRoutes[to.key]!)
                .isNotEmpty) {
          continue;
        }
        final metres = _estimatedRoadMetres(from.value, to.value);
        if (metres <= limits.maxContinuousWalkMetres ||
            metres > maxTaxiMetres) {
          continue;
        }
        nearby.add((id: to.key, metres: metres));
      }
      nearby.sort((a, b) {
        final order = a.metres.compareTo(b.metres);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
      for (final target in nearby.take(maxDestinationsPerStop)) {
        final minutes = math.max(2, (target.metres / taxiSpeed).ceil());
        final estimatedCents = estimateUberXCents(
          distanceMetres: target.metres,
          durationMinutes: minutes,
        );
        if (estimatedCents > math.max(limits.budgetCents, 2500)) continue;
        edges.add(
          TravelEdge(
            id: 'taxi:${from.key}:${target.id}',
            fromNodeId: from.key,
            toNodeId: target.id,
            kind: EdgeKind.taxiBridge,
            distanceMetres: target.metres,
            durationMinutes: minutes,
            costCents: estimatedCents,
            certainty: DataCertainty.estimated,
            source: 'estimate:uberx-lima-formula',
          ),
        );
      }
    }
  }

  static void _addAccessAndEgressTaxiBridges(
    String startId,
    LatLng originPoint,
    String finishId,
    LatLng destinationPoint,
    Map<String, LatLng> stops,
    PlanLimits limits,
    List<TravelEdge> edges, {
    int taxiSpeed = 350,
  }) {
    const maxAccessTaxiMetres = 5000;
    final accessCandidates = <({String id, int metres})>[];
    final egressCandidates = <({String id, int metres})>[];

    for (final entry in stops.entries) {
      final accessMetres = _estimatedRoadMetres(originPoint, entry.value);
      if (accessMetres > limits.maxContinuousWalkMetres &&
          accessMetres <= maxAccessTaxiMetres) {
        accessCandidates.add((id: entry.key, metres: accessMetres));
      }

      final egressMetres = _estimatedRoadMetres(entry.value, destinationPoint);
      if (egressMetres > limits.maxContinuousWalkMetres &&
          egressMetres <= maxAccessTaxiMetres) {
        egressCandidates.add((id: entry.key, metres: egressMetres));
      }
    }

    accessCandidates.sort((a, b) => a.metres.compareTo(b.metres));
    egressCandidates.sort((a, b) => a.metres.compareTo(b.metres));

    for (final target in accessCandidates.take(3)) {
      final minutes = math.max(2, (target.metres / taxiSpeed).ceil());
      final estimatedCents = estimateUberXCents(
        distanceMetres: target.metres,
        durationMinutes: minutes,
      );
      if (estimatedCents > math.max(limits.budgetCents, 2500)) continue;
      edges.add(
        TravelEdge(
          id: 'taxi_access:$startId:${target.id}',
          fromNodeId: startId,
          toNodeId: target.id,
          kind: EdgeKind.taxiBridge,
          distanceMetres: target.metres,
          durationMinutes: minutes,
          costCents: estimatedCents,
          certainty: DataCertainty.estimated,
          source: 'estimate:uberx-lima-formula',
        ),
      );
    }

    for (final from in egressCandidates.take(3)) {
      final minutes = math.max(2, (from.metres / taxiSpeed).ceil());
      final estimatedCents = estimateUberXCents(
        distanceMetres: from.metres,
        durationMinutes: minutes,
      );
      if (estimatedCents > math.max(limits.budgetCents, 2500)) continue;
      edges.add(
        TravelEdge(
          id: 'taxi_egress:${from.id}:$finishId',
          fromNodeId: from.id,
          toNodeId: finishId,
          kind: EdgeKind.taxiBridge,
          distanceMetres: from.metres,
          durationMinutes: minutes,
          costCents: estimatedCents,
          certainty: DataCertainty.estimated,
          source: 'estimate:uberx-lima-formula',
        ),
      );
    }
  }

  static Future<PlanResult> _buildFallbackPlan({
    required RoutingGraph graph,
    required String startId,
    required String finishId,
    required LatLng originPoint,
    required LatLng destinationPoint,
    required PlanLimits limits,
    int taxiSpeed = 350,
    FeasiblePlan? strictPlan,
  }) async {
    final directDistance = _estimatedRoadMetres(originPoint, destinationPoint);
    final walkMinutes = (directDistance / 75).ceil();
    final alternatives = <PlanAlternative>[];

    // 1. Incorporar opciones de la búsqueda estricta si existían
    if (strictPlan != null) {
      alternatives.addAll(strictPlan.alternatives);
    }

    // 2. Buscar opciones de transporte público (buses / corredores oficiales ATU y enlaces)
    // relajando los límites para que SIEMPRE aparezcan las mejores opciones de transporte público
    try {
      final relaxedLimits = PlanLimits(
        budgetCents: math.max(limits.budgetCents, 2500),
        maxContinuousWalkMetres: math.max(limits.maxContinuousWalkMetres, 2200),
        maxTotalWalkMetres: math.max(limits.maxTotalWalkMetres, 4500),
        allowTaxiBridge: true,
        priority: PlanPriority.savings,
      );
      final transitPlan = await LocalPlanner(
        graph,
        maxExpandedLabels: 15000,
      ).plan(
        PlanRequest(
          originNodeId: startId,
          destinationNodeId: finishId,
          limits: relaxedLimits,
        ),
      );

      if (transitPlan is FeasiblePlan && transitPlan.alternatives.isNotEmpty) {
        for (final alt in transitPlan.alternatives) {
          // Asegurar que use transporte público o taxi puente
          final hasTransitOrBridge = alt.edges.any(
            (e) =>
                e.kind == EdgeKind.board ||
                e.kind == EdgeKind.ride ||
                e.kind == EdgeKind.taxiBridge,
          );
          if (!hasTransitOrBridge) continue;

          final exceedsBudget = alt.costCents > limits.budgetCents;
          final exceedsWalk =
              alt.longestWalkMetres > limits.maxContinuousWalkMetres;
          String label = alt.label;

          if (exceedsBudget && exceedsWalk) {
            label =
                '${alt.label} (S/ ${(alt.costCents / 100).toStringAsFixed(2)} y ${alt.longestWalkMetres}m · excede condiciones)';
          } else if (exceedsBudget) {
            label =
                '${alt.label} (S/ ${(alt.costCents / 100).toStringAsFixed(2)} · excede presupuesto de S/ ${(limits.budgetCents / 100).toStringAsFixed(2)})';
          } else if (exceedsWalk) {
            label =
                '${alt.label} (Requiere caminar ${alt.longestWalkMetres} m · excede límite de ${limits.maxContinuousWalkMetres} m)';
          }

          alternatives.add(
            PlanAlternative(
              label: label,
              edges: alt.edges,
              costCents: alt.costCents,
              walkMetres: alt.walkMetres,
              longestWalkMetres: alt.longestWalkMetres,
              durationMinutes: alt.durationMinutes,
              transfers: alt.transfers,
              hasEstimatedData: alt.hasEstimatedData,
              hasCommunityData: alt.hasCommunityData,
            ),
          );
        }
      }
    } catch (_) {}

    // 3. Alternativa estimada de taxi UberX directo
    final taxiMinutes = math.max(5, (directDistance / taxiSpeed).ceil());
    final taxiCents = estimateUberXCents(
      distanceMetres: directDistance,
      durationMinutes: taxiMinutes,
    );
    final hasDirectTaxi = alternatives.any(
      (a) => a.edges.length == 1 && a.edges.first.kind == EdgeKind.taxiBridge,
    );

    if (!hasDirectTaxi) {
      final exceedsTaxi = taxiCents > limits.budgetCents;
      final taxiLabel = exceedsTaxi
          ? 'Taxi UberX estimado (~S/ ${(taxiCents / 100).toStringAsFixed(2)} · excede presupuesto de S/ ${(limits.budgetCents / 100).toStringAsFixed(2)})'
          : 'Taxi UberX estimado';

      alternatives.add(
        PlanAlternative(
          label: taxiLabel,
          edges: [
            TravelEdge(
              id: 'taxi:fallback_direct',
              fromNodeId: startId,
              toNodeId: finishId,
              kind: EdgeKind.taxiBridge,
              distanceMetres: directDistance,
              durationMinutes: taxiMinutes,
              costCents: taxiCents,
              certainty: DataCertainty.estimated,
              source: 'estimate:uberx-lima-formula',
            ),
          ],
          costCents: taxiCents,
          walkMetres: 0,
          longestWalkMetres: 0,
          durationMinutes: taxiMinutes,
          transfers: 0,
          hasEstimatedData: true,
          hasCommunityData: false,
        ),
      );
    }

    // 4. Alternativa 100% a pie (si no estaba ya en la lista)
    final hasDirectWalk = alternatives.any(
      (a) => a.edges.length == 1 && a.edges.first.kind == EdgeKind.walk,
    );
    if (!hasDirectWalk) {
      final walkExceeds = directDistance > limits.maxTotalWalkMetres;
      final walkLabel = walkExceeds
          ? 'A pie (requiere caminar $directDistance m · excede límite de ${limits.maxTotalWalkMetres} m)'
          : 'A pie (directo)';
      alternatives.add(
        PlanAlternative(
          label: walkLabel,
          edges: [
            TravelEdge(
              id: 'walk:fallback_direct',
              fromNodeId: startId,
              toNodeId: finishId,
              kind: EdgeKind.walk,
              distanceMetres: directDistance,
              durationMinutes: walkMinutes,
              costCents: 0,
              certainty: DataCertainty.estimated,
              source: 'estimate:caminata-directa',
            ),
          ],
          costCents: 0,
          walkMetres: directDistance,
          longestWalkMetres: directDistance,
          durationMinutes: walkMinutes,
          transfers: 0,
          hasEstimatedData: true,
          hasCommunityData: false,
        ),
      );
    }

    // 5. Deduplicar opciones si difieren en muy pocos metros (<= 50m) con mismo costo y tiempo
    final deduplicated = <PlanAlternative>[];
    for (final alt in alternatives) {
      final isDup = deduplicated.any((existing) {
        final costDiff = (existing.costCents - alt.costCents).abs();
        final walkDiff = (existing.walkMetres - alt.walkMetres).abs();
        final timeDiff = (existing.durationMinutes - alt.durationMinutes).abs();
        final transfersDiff = (existing.transfers - alt.transfers).abs();
        return costDiff == 0 &&
            transfersDiff == 0 &&
            walkDiff <= 60 &&
            timeDiff <= 3;
      });
      if (!isDup) {
        deduplicated.add(alt);
      }
    }

    // 6. Ordenar con criterio inteligente:
    // Primero transporte público / corredor, luego enlaces taxi, luego taxi directo, y finalmente a pie
    int priorityOrder(PlanAlternative alt) {
      final isPureWalk = alt.edges.every((e) => e.kind == EdgeKind.walk);
      final isDirectTaxi =
          alt.edges.length == 1 && alt.edges.first.kind == EdgeKind.taxiBridge;
      final hasBus = alt.edges.any(
        (e) => e.kind == EdgeKind.board || e.kind == EdgeKind.ride,
      );

      if (hasBus && !alt.edges.any((e) => e.kind == EdgeKind.taxiBridge)) {
        return 1; // Corredores directos primero
      }
      if (hasBus && alt.edges.any((e) => e.kind == EdgeKind.taxiBridge)) {
        return 2; // Enlace multimodal taxi + corredor segundo
      }
      if (isDirectTaxi) {
        return 3; // Taxi directo tercero
      }
      if (isPureWalk) {
        return 4; // A pie al final
      }
      return 5;
    }

    deduplicated.sort((a, b) {
      final pa = priorityOrder(a);
      final pb = priorityOrder(b);
      if (pa != pb) return pa.compareTo(pb);
      return a.costCents.compareTo(b.costCents);
    });

    return FeasiblePlan(
      LocalPlanner.enrichWithTradeoffs(deduplicated),
      degraded: true,
    );
  }
}
