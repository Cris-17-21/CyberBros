/// Pure Dart routing core. Graph edges must come from a separately validated
/// dataset; a nearby point alone is never turned into a boarding connection.
library;

enum EdgeKind { walk, board, ride, alight, taxiBridge }

enum DataCertainty { confirmed, estimated, community }

enum PlanPriority { savings, lessWalking, time, fewerTransfers, balanced }

final class PlanLimits {
  const PlanLimits({
    required this.budgetCents,
    required this.maxContinuousWalkMetres,
    required this.maxTotalWalkMetres,
    required this.allowTaxiBridge,
    this.priority = PlanPriority.balanced,
  });

  final int budgetCents;
  final int maxContinuousWalkMetres;
  final int maxTotalWalkMetres;
  final bool allowTaxiBridge;
  final PlanPriority priority;

  bool get isValid =>
      budgetCents > 0 &&
      maxContinuousWalkMetres >= 0 &&
      maxTotalWalkMetres >= maxContinuousWalkMetres;
}

final class PlanRequest {
  const PlanRequest({
    required this.originNodeId,
    required this.destinationNodeId,
    required this.limits,
    this.spentCents = 0,
    this.onboardRouteId,
  });

  final String originNodeId;
  final String destinationNodeId;
  final PlanLimits limits;
  final int spentCents;
  final String? onboardRouteId;
}

final class TravelEdge {
  const TravelEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.kind,
    required this.distanceMetres,
    required this.durationMinutes,
    required this.costCents,
    required this.certainty,
    required this.source,
    this.routeId,
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final EdgeKind kind;
  final int distanceMetres;
  final int durationMinutes;
  final int costCents;
  final DataCertainty certainty;
  final String source;
  final String? routeId;

  bool get isValid =>
      id.isNotEmpty &&
      fromNodeId.isNotEmpty &&
      toNodeId.isNotEmpty &&
      distanceMetres >= 0 &&
      durationMinutes >= 0 &&
      costCents >= 0 &&
      source.isNotEmpty &&
      ((kind == EdgeKind.board ||
              kind == EdgeKind.ride ||
              kind == EdgeKind.alight)
          ? routeId != null && routeId!.isNotEmpty
          : routeId == null) &&
      (kind == EdgeKind.board ||
          kind == EdgeKind.taxiBridge ||
          costCents == 0) &&
      (kind == EdgeKind.walk ||
          kind == EdgeKind.ride ||
          kind == EdgeKind.taxiBridge ||
          distanceMetres == 0);
}

final class RoutingGraph {
  RoutingGraph({
    required Iterable<String> nodeIds,
    required Iterable<TravelEdge> edges,
    required this.planningReady,
  }) : nodes = Set.unmodifiable(nodeIds),
       edges = List.unmodifiable(edges) {
    if (nodes.isEmpty) throw ArgumentError('The graph needs nodes');
    final seen = <String>{};
    final adjacency = <String, List<TravelEdge>>{};
    for (final edge in this.edges) {
      if (!edge.isValid ||
          !nodes.contains(edge.fromNodeId) ||
          !nodes.contains(edge.toNodeId) ||
          !seen.add(edge.id)) {
        throw ArgumentError('Invalid or duplicate edge: ${edge.id}');
      }
      adjacency.putIfAbsent(edge.fromNodeId, () => []).add(edge);
    }
    outgoing = Map.unmodifiable({
      for (final entry in adjacency.entries)
        entry.key: List<TravelEdge>.unmodifiable(
          entry.value..sort((a, b) => a.id.compareTo(b.id)),
        ),
    });
  }

  final Set<String> nodes;
  final List<TravelEdge> edges;
  final bool planningReady;
  late final Map<String, List<TravelEdge>> outgoing;
}

sealed class PlanResult {
  const PlanResult();
}

final class FeasiblePlan extends PlanResult {
  const FeasiblePlan(this.alternatives, {required this.degraded});

  final List<PlanAlternative> alternatives;
  final bool degraded;
}

enum InfeasibleReason {
  invalidRequest,
  unavailableData,
  unknownPoint,
  noConnection,
  limitsExceeded,
}

final class InfeasiblePlan extends PlanResult {
  const InfeasiblePlan(this.reason);

  final InfeasibleReason reason;
}

final class PlanAlternative {
  const PlanAlternative({
    required this.label,
    required this.edges,
    required this.costCents,
    required this.walkMetres,
    required this.longestWalkMetres,
    required this.durationMinutes,
    required this.transfers,
    required this.hasEstimatedData,
    required this.hasCommunityData,
  });

  final String label;
  final List<TravelEdge> edges;
  final int costCents;
  final int walkMetres;
  final int longestWalkMetres;
  final int durationMinutes;
  final int transfers;
  final bool hasEstimatedData;
  final bool hasCommunityData;
}

abstract interface class PlannerGateway {
  Future<PlanResult> plan(PlanRequest request);
}

/// Bounded multi-label search. Each state includes the current onboard route,
/// so a fare is charged once on boarding rather than on every ride edge.
final class LocalPlanner implements PlannerGateway {
  const LocalPlanner(
    this.graph, {
    this.maxExpandedLabels = 50000,
    this.maxLabelsPerState = 24,
  }) : assert(maxExpandedLabels > 0),
       assert(maxLabelsPerState > 0);

  final RoutingGraph graph;
  final int maxExpandedLabels;
  final int maxLabelsPerState;

  @override
  Future<PlanResult> plan(PlanRequest request) async {
    if (!request.limits.isValid ||
        request.spentCents < 0 ||
        request.spentCents > request.limits.budgetCents) {
      return const InfeasiblePlan(InfeasibleReason.invalidRequest);
    }
    if (!graph.planningReady) {
      return const InfeasiblePlan(InfeasibleReason.unavailableData);
    }
    if (!graph.nodes.contains(request.originNodeId) ||
        !graph.nodes.contains(request.destinationNodeId)) {
      return const InfeasiblePlan(InfeasibleReason.unknownPoint);
    }
    if (request.originNodeId == request.destinationNodeId) {
      return const InfeasiblePlan(InfeasibleReason.invalidRequest);
    }
    final initial = _Label(
      nodeId: request.originNodeId,
      onboardRouteId: request.onboardRouteId,
      boardings: request.onboardRouteId == null ? 0 : 1,
      costCents: 0,
      walkMetres: 0,
      continuousWalkMetres: 0,
      longestWalkMetres: 0,
      durationMinutes: 0,
      taxiPending: false,
      taxiBridges: 0,
      previous: null,
      edge: null,
    );
    final frontier = <_Label>[initial];
    final labels = <String, List<_Label>>{};
    final completed = <_Label>[];
    var expanded = 0;
    var degraded = false;
    while (frontier.isNotEmpty) {
      frontier.sort(_compareLabels);
      final current = frontier.removeAt(0);
      if (!current.active) continue;
      if (current.nodeId == request.destinationNodeId &&
          current.onboardRouteId == null &&
          !current.taxiPending) {
        completed.add(current);
        continue;
      }
      if (++expanded > maxExpandedLabels) {
        degraded = true;
        break;
      }
      if (expanded % 128 == 0) await Future<void>.delayed(Duration.zero);
      for (final edge
          in graph.outgoing[current.nodeId] ?? const <TravelEdge>[]) {
        final next = _advance(
          current,
          edge,
          request.limits,
          request.spentCents,
        );
        if (next == null) continue;
        final key =
            '${next.nodeId}|${next.onboardRouteId ?? ''}|${next.taxiPending}|${next.taxiBridges}';
        final atState = labels.putIfAbsent(key, () => []);
        if (atState.any(
          (other) =>
              other.active &&
              (_dominates(other, next) || _sameMetrics(other, next)),
        )) {
          continue;
        }
        for (final other in atState) {
          if (other.active && _dominates(next, other)) other.active = false;
        }
        atState.removeWhere((item) => !item.active);
        atState.add(next);
        atState.sort(_compareLabels);
        if (atState.length > maxLabelsPerState) {
          for (final removed in atState.sublist(maxLabelsPerState)) {
            removed.active = false;
          }
          atState.removeRange(maxLabelsPerState, atState.length);
        }
        if (next.active) frontier.add(next);
      }
    }
    if (completed.isEmpty) {
      return InfeasiblePlan(
        degraded
            ? InfeasibleReason.limitsExceeded
            : InfeasibleReason.noConnection,
      );
    }
    final pareto = completed
        .where(
          (candidate) => !completed.any(
            (other) =>
                !identical(other, candidate) && _dominates(other, candidate),
          ),
        )
        .toList();
    final selected = <_Label>[];
    final names = <_Label, String>{};
    void take(String label, int Function(_Label, _Label) compare) {
      if (selected.length >= 3) return;
      final ranked = [...pareto]..sort(compare);
      for (final item in ranked) {
        if (selected.contains(item)) continue;
        selected.add(item);
        names[item] = label;
        return;
      }
    }

    int cheapest(_Label a, _Label b) =>
        _compareIntThenTie(a.costCents, b.costCents, a, b);
    int leastWalk(_Label a, _Label b) =>
        _compareIntThenTie(a.walkMetres, b.walkMetres, a, b);
    int fastest(_Label a, _Label b) =>
        _compareIntThenTie(a.durationMinutes, b.durationMinutes, a, b);
    int fewestTransfers(_Label a, _Label b) =>
        _compareIntThenTie(a.boardings, b.boardings, a, b);
    switch (request.limits.priority) {
      case PlanPriority.savings:
        take('Más barata', cheapest);
      case PlanPriority.lessWalking:
        take('Menos caminata', leastWalk);
      case PlanPriority.time:
        take('Más rápida', fastest);
      case PlanPriority.fewerTransfers:
        take('Menos transbordos', fewestTransfers);
      case PlanPriority.balanced:
        take('Equilibrada', _compareLabels);
    }
    take('Más barata', cheapest);
    take('Menos caminata', leastWalk);
    take('Más rápida', fastest);
    take('Menos transbordos', fewestTransfers);
    return FeasiblePlan([
      for (final item in selected) _alternative(item, names[item]!),
    ], degraded: degraded);
  }

  _Label? _advance(
    _Label current,
    TravelEdge edge,
    PlanLimits limits,
    int spentCents,
  ) {
    String? onboard = current.onboardRouteId;
    var boardings = current.boardings;
    var continuous = current.continuousWalkMetres;
    var taxiPending = current.taxiPending;
    var taxiBridges = current.taxiBridges;
    switch (edge.kind) {
      case EdgeKind.walk:
        if (onboard != null) return null;
        continuous += edge.distanceMetres;
      case EdgeKind.taxiBridge:
        if (onboard != null ||
            !limits.allowTaxiBridge ||
            taxiPending ||
            taxiBridges >= 2) {
          return null;
        }
        continuous = 0;
        taxiPending = false;
        taxiBridges++;
      case EdgeKind.board:
        if (onboard != null) return null;
        onboard = edge.routeId;
        boardings++;
        continuous = 0;
        taxiPending = false;
      case EdgeKind.ride:
        if (onboard != edge.routeId) return null;
      case EdgeKind.alight:
        if (onboard != edge.routeId) return null;
        onboard = null;
    }
    final walk =
        current.walkMetres +
        (edge.kind == EdgeKind.walk ? edge.distanceMetres : 0);
    final cost = current.costCents + edge.costCents;
    if (cost + spentCents > limits.budgetCents ||
        walk > limits.maxTotalWalkMetres ||
        continuous > limits.maxContinuousWalkMetres) {
      return null;
    }
    return _Label(
      nodeId: edge.toNodeId,
      onboardRouteId: onboard,
      boardings: boardings,
      costCents: cost,
      walkMetres: walk,
      continuousWalkMetres: continuous,
      longestWalkMetres: continuous > current.longestWalkMetres
          ? continuous
          : current.longestWalkMetres,
      durationMinutes: current.durationMinutes + edge.durationMinutes,
      taxiPending: taxiPending,
      taxiBridges: taxiBridges,
      previous: current,
      edge: edge,
    );
  }

  static bool _dominates(_Label a, _Label b) {
    final aTransfers = a.boardings > 0 ? a.boardings - 1 : 0;
    final bTransfers = b.boardings > 0 ? b.boardings - 1 : 0;
    return a.costCents <= b.costCents &&
        a.walkMetres <= b.walkMetres &&
        a.continuousWalkMetres <= b.continuousWalkMetres &&
        a.longestWalkMetres <= b.longestWalkMetres &&
        a.durationMinutes <= b.durationMinutes &&
        a.taxiBridges <= b.taxiBridges &&
        aTransfers <= bTransfers &&
        (a.costCents < b.costCents ||
            a.walkMetres < b.walkMetres ||
            a.continuousWalkMetres < b.continuousWalkMetres ||
            a.longestWalkMetres < b.longestWalkMetres ||
            a.durationMinutes < b.durationMinutes ||
            a.taxiBridges < b.taxiBridges ||
            aTransfers < bTransfers);
  }

  static bool _sameMetrics(_Label a, _Label b) =>
      a.costCents == b.costCents &&
      a.walkMetres == b.walkMetres &&
      a.continuousWalkMetres == b.continuousWalkMetres &&
      a.longestWalkMetres == b.longestWalkMetres &&
      a.durationMinutes == b.durationMinutes &&
      a.taxiPending == b.taxiPending &&
      a.taxiBridges == b.taxiBridges &&
      a.boardings == b.boardings;

  static int _compareLabels(_Label a, _Label b) {
    final weightedA = a.durationMinutes * 100 + a.costCents + a.walkMetres;
    final weightedB = b.durationMinutes * 100 + b.costCents + b.walkMetres;
    final order = weightedA.compareTo(weightedB);
    if (order != 0) return order;
    return a.nodeId.compareTo(b.nodeId);
  }

  static int _compareIntThenTie(int aValue, int bValue, _Label a, _Label b) {
    final order = aValue.compareTo(bValue);
    return order != 0 ? order : _compareLabels(a, b);
  }

  static PlanAlternative _alternative(_Label label, String name) {
    final path = <TravelEdge>[];
    for (
      _Label? cursor = label;
      cursor?.edge != null;
      cursor = cursor.previous
    ) {
      path.add(cursor!.edge!);
    }
    final edges = path.reversed.toList(growable: false);
    return PlanAlternative(
      label: name,
      edges: edges,
      costCents: label.costCents,
      walkMetres: label.walkMetres,
      longestWalkMetres: label.longestWalkMetres,
      durationMinutes: label.durationMinutes,
      transfers: label.boardings > 0 ? label.boardings - 1 : 0,
      hasEstimatedData: edges.any(
        (edge) => edge.certainty == DataCertainty.estimated,
      ),
      hasCommunityData: edges.any(
        (edge) => edge.certainty == DataCertainty.community,
      ),
    );
  }
}

final class _Label {
  _Label({
    required this.nodeId,
    required this.onboardRouteId,
    required this.boardings,
    required this.costCents,
    required this.walkMetres,
    required this.continuousWalkMetres,
    required this.longestWalkMetres,
    required this.durationMinutes,
    required this.taxiPending,
    required this.taxiBridges,
    required this.previous,
    required this.edge,
  });

  final String nodeId;
  final String? onboardRouteId;
  final int boardings;
  final int costCents;
  final int walkMetres;
  final int continuousWalkMetres;
  final int longestWalkMetres;
  final int durationMinutes;
  final bool taxiPending;
  final int taxiBridges;
  final _Label? previous;
  final TravelEdge? edge;
  bool active = true;
}
