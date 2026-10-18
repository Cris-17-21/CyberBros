import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';
import '../data/osm_stops.dart';
import '../data/guest_history.dart';
import '../data/pilot_planner.dart';
import '../data/mapbox_road_service.dart';
import '../domain/routing_engine.dart';
import 'trip_follow_screen.dart';
import 'widgets/journey_map_leg.dart';
import 'widgets/lima_map.dart';

class PilotOptionsScreen extends StatefulWidget {
  const PilotOptionsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.limits,
  });

  final OsmStop origin;
  final OsmStop destination;
  final PlanLimits limits;

  @override
  State<PilotOptionsScreen> createState() => _PilotOptionsScreenState();
}

class _PilotOptionsScreenState extends State<PilotOptionsScreen> {
  bool _savingSelection = false;
  late final Future<PilotPlanningResult> _planning = PilotPlanner.plan(
    origin: widget.origin,
    destination: widget.destination,
    limits: widget.limits,
  );

  Future<void> _select(
    PlanAlternative alternative,
    PilotPlanningResult pilot,
  ) async {
    if (_savingSelection) return;
    setState(() => _savingSelection = true);
    final trip = GuestTripSnapshot.fromPlan(
      origin: widget.origin,
      destination: widget.destination,
      limits: widget.limits,
      alternative: alternative,
      pilot: pilot,
    );
    final saved = await GuestHistoryRepository.instance.save(trip);
    if (!mounted) return;
    setState(() => _savingSelection = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El historial solo estará disponible durante esta visita.',
          ),
        ),
      );
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PilotDetailScreen(
          alternative: alternative,
          pilot: pilot,
          origin: widget.origin.displayName,
          destination: widget.destination.displayName,
          trip: trip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(title: const Text('Opciones estimadas')),
      body: FutureBuilder<PilotPlanningResult>(
        future: _planning,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              context,
              'No se pudo cargar el catálogo de corredores.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pilot = snapshot.data!;
          final result = pilot.result;
          if (result is InfeasiblePlan) {
            return _message(
              context,
              result.reason == InfeasibleReason.noConnection
                  ? 'No encontramos una conexión en las rutas piloto que cumpla tus límites. El catálogo aún no cubre toda Lima.'
                  : 'No se puede calcular este viaje con los datos disponibles.',
            );
          }
          final alternatives = (result as FeasiblePlan).alternatives;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${alternatives.length} ${alternatives.length == 1 ? 'opción' : 'opciones'} disponibles',
                    style: const TextStyle(
                      color: Palette.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 15, color: Palette.inkMuted),
                      SizedBox(width: 6),
                      Text(
                        'Tarifas oficiales ATU · Precios de taxi estimados',
                        style: TextStyle(
                          color: Palette.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (pilot.isRushHour) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.traffic_rounded,
                            color: Color(0xFFD97706),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hora punta en Lima (Tráfico alto)',
                                  style: TextStyle(
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tiempos de viaje y tarifas de taxi calibrados por congestión vehicular.',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  for (final alternative in alternatives)
                    Card(
                      child: InkWell(
                        onTap: _savingSelection
                            ? null
                            : () => _select(alternative, pilot),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alternative.label.toUpperCase(),
                                style: const TextStyle(
                                  color: Palette.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'S/ ${(alternative.costCents / 100).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Palette.ink,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${alternative.walkMetres} m a pie · ~${alternative.durationMinutes} min · ${alternative.transfers} transbordos',
                                style: const TextStyle(
                                  color: Palette.inkMuted,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              if (alternative.edges.any(
                                (edge) => edge.kind == EdgeKind.taxiBridge,
                              )) ...[
                                Builder(
                                  builder: (context) {
                                    final taxiCents = alternative.edges
                                        .where((e) => e.kind == EdgeKind.taxiBridge)
                                        .fold<int>(0, (acc, e) => acc + e.costCents);
                                    final busCents = alternative.costCents - taxiCents;
                                    return Text(
                                      'Incluye enlace UberX (~S/ ${(taxiCents / 100).toStringAsFixed(2)})'
                                      '${busCents > 0 ? ' + corredor (S/ ${(busCents / 100).toStringAsFixed(2)})' : ''}',
                                      style: const TextStyle(
                                        color: Palette.taxi,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                              const SizedBox(height: 5),
                              Text(
                                _routeSummary(alternative, pilot.routeNames),
                                style: const TextStyle(color: Palette.inkMuted),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                alternative.hasCommunityData
                                    ? 'Estimada · paraderos comunitarios'
                                    : 'Estimada · cálculo referencial',
                                style: const TextStyle(
                                  color: Palette.estimated,
                                  fontSize: 12,
                                ),
                              ),
                              if (alternative.tradeoffText != null &&
                                  alternative.tradeoffText!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                        color: Color(0xFF16A34A),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          alternative.tradeoffText!,
                                          style: const TextStyle(
                                            color: Color(0xFF15803D),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _message(BuildContext context, String text) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, size: 48, color: Palette.primary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ajustar condiciones'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _routeSummary(PlanAlternative alternative, Map<String, String> names) {
  final routeIds = alternative.edges
      .where((edge) => edge.kind == EdgeKind.board)
      .map((edge) => edge.routeId!)
      .toSet();
  if (routeIds.isEmpty) return 'Solo caminata estimada';
  return routeIds.map((id) => names[id] ?? id).join(' → ');
}

class _PilotDetailScreen extends StatefulWidget {
  const _PilotDetailScreen({
    required this.alternative,
    required this.pilot,
    required this.origin,
    required this.destination,
    required this.trip,
  });

  final PlanAlternative alternative;
  final PilotPlanningResult pilot;
  final String origin;
  final String destination;
  final GuestTripSnapshot trip;

  @override
  State<_PilotDetailScreen> createState() => _PilotDetailScreenState();
}

class _PilotDetailScreenState extends State<_PilotDetailScreen> {
  late List<JourneyMapLeg> _legs = _journeyLegs(widget.alternative, widget.pilot);

  @override
  void initState() {
    super.initState();
    _loadRoadGeometries();
  }

  Future<void> _loadRoadGeometries() async {
    // Ejecutar todas las llamadas de geometría en paralelo con Future.wait
    final futures = _legs.map((leg) async {
      final mode = switch (leg.kind) {
        JourneyLegKind.walk => 'walking',
        JourneyLegKind.taxi || JourneyLegKind.bus => 'driving',
      };

      try {
        final roadPoints = await MapboxRoadService.getRoadRoute(
          origin: leg.from,
          destination: leg.to,
          mode: mode,
        );
        if (roadPoints.length > 2) {
          return JourneyMapLeg(
            leg.from,
            leg.to,
            leg.kind,
            points: roadPoints,
          );
        }
      } catch (_) {}

      return leg;
    });

    final updatedLegs = await Future.wait(futures);

    if (mounted) {
      setState(() {
        _legs = updatedLegs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _summarizeSteps(widget.alternative, widget.pilot);
    final legs = _legs;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('Tu Trayecto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. Mapa interactivo en vivo con el recorrido trazado por calles reales
          Positioned.fill(
            child: LimaMap(
              height: double.infinity,
              borderRadius: 0,
              journeyLegs: legs,
              originPoint: legs.isNotEmpty ? legs.first.from : null,
              destinationPoint: legs.isNotEmpty ? legs.last.to : null,
            ),
          ),

          // 2. Leyenda flotante de colores arriba a la izquierda
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegDot(color: Palette.inkMuted, label: 'Caminar'),
                  SizedBox(width: 10),
                  _LegDot(color: Palette.primaryDark, label: 'Corredor'),
                  SizedBox(width: 10),
                  _LegDot(color: Palette.taxi, label: 'Taxi'),
                ],
              ),
            ),
          ),

          // 3. Panel deslizable hacia arriba / abajo (DraggableScrollableSheet)
          DraggableScrollableSheet(
            initialChildSize: 0.40,
            minChildSize: 0.16,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.16, 0.40, 0.88],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    // Asa / handle deslizable
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Encabezado rápido con precio y duración
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.alternative.label.toUpperCase(),
                                style: const TextStyle(
                                  color: Palette.primaryDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.origin} → ${widget.destination}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'S/ ${(widget.alternative.costCents / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Palette.ink,
                                letterSpacing: -0.8,
                              ),
                            ),
                            Text(
                              '~${widget.alternative.durationMinutes} min',
                              style: const TextStyle(
                                color: Palette.inkMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.alternative.tradeoffText != null &&
                        widget.alternative.tradeoffText!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.alternative.tradeoffText!,
                                style: const TextStyle(
                                  color: Color(0xFF15803D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Botón de acción principal
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TripFollowScreen(
                            trip: widget.trip,
                            journeyLegs: _legs,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text(
                        'Empezar viaje',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Palette.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    const Text(
                      'Tramos del recorrido',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lista de etapas con íconos e identificadores de color
                    for (final step in steps)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Palette.surfaceAlt.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(step.icon, color: Palette.primaryDark, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step.subtitle,
                                    style: const TextStyle(
                                      color: Palette.inkMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegDot extends StatelessWidget {
  const _LegDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

List<JourneyMapLeg> _journeyLegs(
  PlanAlternative alternative,
  PilotPlanningResult pilot,
) {
  final legs = <JourneyMapLeg>[];
  for (final edge in alternative.edges) {
    final kind = switch (edge.kind) {
      EdgeKind.walk => JourneyLegKind.walk,
      EdgeKind.ride => JourneyLegKind.bus,
      EdgeKind.taxiBridge => JourneyLegKind.taxi,
      _ => null,
    };
    if (kind == null) continue;
    final from = pilot.stopPoints[edge.fromNodeId];
    final to = pilot.stopPoints[edge.toNodeId];
    if (from != null && to != null && from != to) {
      legs.add(JourneyMapLeg(from, to, kind));
    }
  }
  return legs;
}

final class _JourneyStep {
  const _JourneyStep(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

List<_JourneyStep> _summarizeSteps(
  PlanAlternative alternative,
  PilotPlanningResult pilot,
) {
  final steps = <_JourneyStep>[];
  final edges = alternative.edges;
  for (var i = 0; i < edges.length; i++) {
    final edge = edges[i];
    switch (edge.kind) {
      case EdgeKind.walk:
        steps.add(
          _JourneyStep(
            Icons.directions_walk_rounded,
            'Camina ~${edge.distanceMetres} m',
            'Hasta ${pilot.stopNames[edge.toNodeId] ?? 'el destino'} · distancia estimada',
          ),
        );
      case EdgeKind.board:
        steps.add(
          _JourneyStep(
            Icons.directions_bus_rounded,
            'Aborda ${pilot.routeNames[edge.routeId] ?? edge.routeId}',
            'Paradero OSM no verificado · tarifa general S/ ${(edge.costCents / 100).toStringAsFixed(2)}',
          ),
        );
      case EdgeKind.ride:
        var last = edge;
        var count = 1;
        var minutes = edge.durationMinutes;
        while (i + 1 < edges.length &&
            edges[i + 1].kind == EdgeKind.ride &&
            edges[i + 1].routeId == edge.routeId) {
          last = edges[++i];
          minutes += last.durationMinutes;
          count++;
        }
        steps.add(
          _JourneyStep(
            Icons.route_rounded,
            'Viaja hasta ${pilot.stopNames[last.toNodeId] ?? 'el siguiente paradero'}',
            '$count tramos entre paraderos · ~$minutes min estimados',
          ),
        );
      case EdgeKind.alight:
        steps.add(
          _JourneyStep(
            Icons.pin_drop_outlined,
            'Baja en ${pilot.stopNames[edge.toNodeId] ?? 'el paradero'}',
            'Paradero y descenso por confirmar',
          ),
        );
      case EdgeKind.taxiBridge:
        steps.add(
          _JourneyStep(
            Icons.local_taxi_rounded,
            'Taxi puente estimado',
            'S/ ${(edge.costCents / 100).toStringAsFixed(2)} · confirma el precio antes de subir',
          ),
        );
    }
  }
  return steps;
}

