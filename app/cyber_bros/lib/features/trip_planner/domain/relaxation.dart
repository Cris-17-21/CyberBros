/// Relajación mínima de restricciones (RF-10).
///
/// Cuando ningún recorrido cumple los límites de la persona, en lugar de
/// responder "sin resultados" se calcula qué condición, relajada **sola**,
/// haría posible el viaje y en cuánto. Es un problema de factibilidad: se
/// buscan itinerarios candidatos y, para cada uno, se mira qué restricciones
/// viola. Si viola exactamente una, ese itinerario define el cambio mínimo
/// necesario en esa restricción.
///
/// Nunca modifica los límites por su cuenta: solo propone.
library;

import 'routing_engine.dart';

/// Qué restricciones viola un itinerario frente a unos límites.
final class Violations {
  const Violations({
    required this.budget,
    required this.walk,
    required this.taxi,
  });

  final bool budget;
  final bool walk;
  final bool taxi;

  int get count => (budget ? 1 : 0) + (walk ? 1 : 0) + (taxi ? 1 : 0);
}

/// Cuánto cuesta el tramo de taxi de un itinerario (0 si no usa taxi).
int taxiCentsOf(PlanAlternative alternative) => alternative.edges
    .where((edge) => edge.kind == EdgeKind.taxiBridge)
    .fold(0, (sum, edge) => sum + edge.costCents);

bool usesTaxi(PlanAlternative alternative) =>
    alternative.edges.any((edge) => edge.kind == EdgeKind.taxiBridge);

Violations violationsOf(
  PlanAlternative alternative,
  PlanLimits limits, {
  int spentCents = 0,
}) => Violations(
  budget: alternative.costCents + spentCents > limits.budgetCents,
  walk:
      alternative.longestWalkMetres > limits.maxContinuousWalkMetres ||
      alternative.walkMetres > limits.maxTotalWalkMetres,
  taxi: usesTaxi(alternative) && !limits.allowTaxiBridge,
);

abstract final class RelaxationAdvisor {
  /// Presupuesto y caminata "sin tope" para explorar qué haría falta.
  static const _unboundedBudgetCents = 1000000;
  static const _unboundedWalkMetres = 50000;

  /// Dado un conjunto de itinerarios candidatos, devuelve los cambios
  /// mínimos de una sola restricción, uno por tipo, del menos al más costoso
  /// para la persona.
  static List<Relaxation> fromCandidates({
    required PlanLimits limits,
    required Iterable<PlanAlternative> candidates,
    int spentCents = 0,
    int max = 2,
  }) {
    final best = <RelaxationKind, Relaxation>{};
    for (final alternative in candidates) {
      final violations = violationsOf(
        alternative,
        limits,
        spentCents: spentCents,
      );
      if (violations.count != 1) continue; // dos o más cambios: no es mínimo
      final relaxation = _relaxationFor(alternative, limits, spentCents, violations);
      final current = best[relaxation.kind];
      if (current == null || relaxation.effort < current.effort) {
        best[relaxation.kind] = relaxation;
      }
    }
    final ranked = best.values.toList()
      ..sort((a, b) => a.effort.compareTo(b.effort));
    return ranked.take(max).toList(growable: false);
  }

  static Relaxation _relaxationFor(
    PlanAlternative alternative,
    PlanLimits limits,
    int spentCents,
    Violations violations,
  ) {
    if (violations.budget) {
      final needed = alternative.costCents + spentCents;
      return Relaxation(
        kind: RelaxationKind.budget,
        deltaCents: needed - limits.budgetCents,
        limits: PlanLimits(
          budgetCents: needed,
          maxContinuousWalkMetres: limits.maxContinuousWalkMetres,
          maxTotalWalkMetres: limits.maxTotalWalkMetres,
          allowTaxiBridge: limits.allowTaxiBridge,
          priority: limits.priority,
        ),
        preview: alternative,
      );
    }
    if (violations.walk) {
      final continuous = alternative.longestWalkMetres >
              limits.maxContinuousWalkMetres
          ? alternative.longestWalkMetres
          : limits.maxContinuousWalkMetres;
      final totalNeeded = alternative.walkMetres > limits.maxTotalWalkMetres
          ? alternative.walkMetres
          : limits.maxTotalWalkMetres;
      final total = totalNeeded < continuous ? continuous : totalNeeded;
      final delta = [
        continuous - limits.maxContinuousWalkMetres,
        total - limits.maxTotalWalkMetres,
      ].reduce((a, b) => a > b ? a : b);
      return Relaxation(
        kind: RelaxationKind.walk,
        deltaWalkMetres: delta,
        limits: PlanLimits(
          budgetCents: limits.budgetCents,
          maxContinuousWalkMetres: continuous,
          maxTotalWalkMetres: total,
          allowTaxiBridge: limits.allowTaxiBridge,
          priority: limits.priority,
        ),
        preview: alternative,
      );
    }
    return Relaxation(
      kind: RelaxationKind.taxi,
      taxiCents: taxiCentsOf(alternative),
      limits: PlanLimits(
        budgetCents: limits.budgetCents,
        maxContinuousWalkMetres: limits.maxContinuousWalkMetres,
        maxTotalWalkMetres: limits.maxTotalWalkMetres,
        allowTaxiBridge: true,
        priority: limits.priority,
      ),
      preview: alternative,
    );
  }

  /// Explora el grafo relajando cada restricción por separado (presupuesto,
  /// caminata y taxi) y combina los hallazgos con [extraCandidates] (por
  /// ejemplo, ir a pie o en taxi directo).
  static Future<List<Relaxation>> suggest({
    required LocalPlanner planner,
    required PlanRequest request,
    Iterable<PlanAlternative> extraCandidates = const [],
    int max = 2,
  }) async {
    final limits = request.limits;
    final candidates = <PlanAlternative>[...extraCandidates];

    Future<void> explore(PlanLimits relaxed) async {
      if (relaxed.maxTotalWalkMetres < relaxed.maxContinuousWalkMetres) return;
      final result = await planner.plan(
        PlanRequest(
          originNodeId: request.originNodeId,
          destinationNodeId: request.destinationNodeId,
          limits: relaxed,
          spentCents: request.spentCents,
          onboardRouteId: request.onboardRouteId,
        ),
      );
      if (result is FeasiblePlan) candidates.addAll(result.alternatives);
    }

    // Solo el presupuesto, sin tope.
    await explore(
      PlanLimits(
        budgetCents: _unboundedBudgetCents,
        maxContinuousWalkMetres: limits.maxContinuousWalkMetres,
        maxTotalWalkMetres: limits.maxTotalWalkMetres,
        allowTaxiBridge: limits.allowTaxiBridge,
        priority: PlanPriority.savings,
      ),
    );
    // Solo la caminata, sin tope.
    await explore(
      PlanLimits(
        budgetCents: limits.budgetCents,
        maxContinuousWalkMetres: _unboundedWalkMetres,
        maxTotalWalkMetres: _unboundedWalkMetres,
        allowTaxiBridge: limits.allowTaxiBridge,
        priority: PlanPriority.lessWalking,
      ),
    );
    // Solo el taxi, permitido.
    if (!limits.allowTaxiBridge) {
      await explore(
        PlanLimits(
          budgetCents: limits.budgetCents,
          maxContinuousWalkMetres: limits.maxContinuousWalkMetres,
          maxTotalWalkMetres: limits.maxTotalWalkMetres,
          allowTaxiBridge: true,
          priority: PlanPriority.savings,
        ),
      );
    }
    return fromCandidates(
      limits: limits,
      candidates: candidates,
      spentCents: request.spentCents,
      max: max,
    );
  }
}
