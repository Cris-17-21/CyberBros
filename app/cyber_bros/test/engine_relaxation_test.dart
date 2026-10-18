import 'package:cyber_bros/features/trip_planner/domain/relaxation.dart';
import 'package:cyber_bros/features/trip_planner/domain/routing_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Grafo de juguete con un recorrido conocido, para verificar el motor con
/// resultados exactos ("viajes de oro", RNF-21).
///
///   O --camina 200 m--> A --bus R1 (S/ 2.50)--> B --camina 150 m--> D
///   Costo S/ 2.50 · caminata total 350 m · tramo a pie más largo 200 m.
TravelEdge _walk(String id, String from, String to, int metres) => TravelEdge(
  id: id,
  fromNodeId: from,
  toNodeId: to,
  kind: EdgeKind.walk,
  distanceMetres: metres,
  durationMinutes: (metres / 75).ceil(),
  costCents: 0,
  certainty: DataCertainty.estimated,
  source: 'test',
);

TravelEdge _board(String from, int cents) => TravelEdge(
  id: 'board:$from',
  fromNodeId: from,
  toNodeId: from,
  kind: EdgeKind.board,
  routeId: 'R1',
  distanceMetres: 0,
  durationMinutes: 4,
  costCents: cents,
  certainty: DataCertainty.community,
  source: 'test',
);

TravelEdge _ride(String from, String to) => TravelEdge(
  id: 'ride:$from$to',
  fromNodeId: from,
  toNodeId: to,
  kind: EdgeKind.ride,
  routeId: 'R1',
  distanceMetres: 1500,
  durationMinutes: 6,
  costCents: 0,
  certainty: DataCertainty.community,
  source: 'test',
);

TravelEdge _alight(String at) => TravelEdge(
  id: 'alight:$at',
  fromNodeId: at,
  toNodeId: at,
  kind: EdgeKind.alight,
  routeId: 'R1',
  distanceMetres: 0,
  durationMinutes: 0,
  costCents: 0,
  certainty: DataCertainty.community,
  source: 'test',
);

TravelEdge _taxi(String id, String from, String to, int cents) => TravelEdge(
  id: id,
  fromNodeId: from,
  toNodeId: to,
  kind: EdgeKind.taxiBridge,
  distanceMetres: 900,
  durationMinutes: 4,
  costCents: cents,
  certainty: DataCertainty.estimated,
  source: 'test',
);

RoutingGraph _graph({
  int firstWalk = 200,
  bool withTaxi = false,
}) => RoutingGraph(
  nodeIds: const {'O', 'A', 'B', 'D'},
  planningReady: true,
  edges: [
    _walk('walk:OA', 'O', 'A', firstWalk),
    _board('A', 250),
    _ride('A', 'B'),
    _alight('B'),
    _walk('walk:BD', 'B', 'D', 150),
    if (withTaxi) _taxi('taxi:OA', 'O', 'A', 600),
  ],
);

PlanRequest _request(
  PlanLimits limits, {
  int spentCents = 0,
}) => PlanRequest(
  originNodeId: 'O',
  destinationNodeId: 'D',
  limits: limits,
  spentCents: spentCents,
);

PlanLimits _limits({
  int budget = 800,
  int continuous = 300,
  int total = 800,
  bool taxi = false,
}) => PlanLimits(
  budgetCents: budget,
  maxContinuousWalkMetres: continuous,
  maxTotalWalkMetres: total,
  allowTaxiBridge: taxi,
);

void main() {
  group('Motor: viajes de oro', () {
    test('1. solución única: respeta costo y caminata exactos', () async {
      final result = await LocalPlanner(_graph()).plan(_request(_limits()));
      expect(result, isA<FeasiblePlan>());
      final alt = (result as FeasiblePlan).alternatives.single;
      expect(alt.costCents, 250);
      expect(alt.walkMetres, 350);
      expect(alt.longestWalkMetres, 200);
    });

    test('2. ninguna alternativa devuelta viola los límites', () async {
      final limits = _limits(budget: 300, continuous: 250, total: 400);
      final result = await LocalPlanner(_graph()).plan(_request(limits));
      for (final alt in (result as FeasiblePlan).alternatives) {
        expect(alt.costCents, lessThanOrEqualTo(limits.budgetCents));
        expect(alt.longestWalkMetres,
            lessThanOrEqualTo(limits.maxContinuousWalkMetres));
        expect(alt.walkMetres, lessThanOrEqualTo(limits.maxTotalWalkMetres));
      }
    });

    test('3. el taxi NO aparece si la persona no lo permite', () async {
      final result = await LocalPlanner(_graph(withTaxi: true))
          .plan(_request(_limits(taxi: false)));
      for (final alt in (result as FeasiblePlan).alternatives) {
        expect(usesTaxi(alt), isFalse);
      }
    });

    test('4. recálculo con saldo reducido usa el dinero restante', () async {
      // Presupuesto S/ 3.00; ya gastó S/ 1.00: quedan S/ 2.00 < tarifa S/ 2.50.
      final planner = LocalPlanner(_graph());
      final limits = _limits(budget: 300);
      expect(await planner.plan(_request(limits)), isA<FeasiblePlan>());
      expect(
        await planner.plan(_request(limits, spentCents: 100)),
        isA<InfeasiblePlan>(),
      );
    });

    test('5. caminata seguida mayor al límite: sin recorrido', () async {
      final result = await LocalPlanner(_graph(firstWalk: 700))
          .plan(_request(_limits(continuous: 300)));
      expect(result, isA<InfeasiblePlan>());
    });

    test('6. presupuesto menor que cualquier tarifa: sin recorrido', () async {
      final result =
          await LocalPlanner(_graph()).plan(_request(_limits(budget: 200)));
      expect(result, isA<InfeasiblePlan>());
    });
  });

  group('Relajación mínima (RF-10)', () {
    test('presupuesto insuficiente: dice cuánto falta, exacto', () async {
      final planner = LocalPlanner(_graph());
      final request = _request(_limits(budget: 200));
      final relaxations =
          await RelaxationAdvisor.suggest(planner: planner, request: request);
      final budget = relaxations.firstWhere(
        (r) => r.kind == RelaxationKind.budget,
      );
      expect(budget.deltaCents, 50); // S/ 2.50 - S/ 2.00
      expect(budget.limits.budgetCents, 250);
      expect(budget.message, contains('S/ 0.50'));
    });

    test('caminata demasiado larga: propone el mínimo de metros', () async {
      final planner = LocalPlanner(_graph(firstWalk: 450));
      final request = _request(_limits(continuous: 300, total: 800));
      final relaxations =
          await RelaxationAdvisor.suggest(planner: planner, request: request);
      final walk = relaxations.firstWhere((r) => r.kind == RelaxationKind.walk);
      expect(walk.limits.maxContinuousWalkMetres, 450);
      expect(walk.deltaWalkMetres, 150);
      // Solo cambia la caminata: el resto de los límites queda igual.
      expect(walk.limits.budgetCents, 800);
      expect(walk.limits.allowTaxiBridge, isFalse);
    });

    test('permitir taxi puede ser el cambio mínimo', () async {
      // Caminar 700 m seguidos no entra; con taxi (S/ 6.00) + bus (S/ 2.50)
      // el total S/ 8.50 cabe en S/ 10.00.
      final planner = LocalPlanner(_graph(firstWalk: 700, withTaxi: true));
      final request = _request(_limits(budget: 1000, taxi: false));
      final relaxations =
          await RelaxationAdvisor.suggest(planner: planner, request: request);
      expect(relaxations.first.kind, RelaxationKind.taxi);
      expect(relaxations.first.limits.allowTaxiBridge, isTrue);
      expect(relaxations.first.taxiCents, 600);
    });

    test('nunca cambia los límites por su cuenta ni más de una condición', () async {
      final limits = _limits(budget: 200);
      final relaxations = await RelaxationAdvisor.suggest(
        planner: LocalPlanner(_graph()),
        request: _request(limits),
      );
      for (final r in relaxations) {
        final changed = [
          r.limits.budgetCents != limits.budgetCents,
          r.limits.maxContinuousWalkMetres != limits.maxContinuousWalkMetres ||
              r.limits.maxTotalWalkMetres != limits.maxTotalWalkMetres,
          r.limits.allowTaxiBridge != limits.allowTaxiBridge,
        ].where((x) => x).length;
        expect(changed, 1, reason: '${r.kind} debe cambiar una sola condición');
      }
    });

    test('un itinerario que viola dos condiciones no es un cambio mínimo', () {
      final alt = PlanAlternative(
        label: 'caro y largo',
        edges: [_walk('w', 'O', 'D', 900)],
        costCents: 2000,
        walkMetres: 900,
        longestWalkMetres: 900,
        durationMinutes: 12,
        transfers: 0,
        hasEstimatedData: true,
        hasCommunityData: false,
      );
      expect(
        RelaxationAdvisor.fromCandidates(
          limits: _limits(budget: 500, continuous: 300),
          candidates: [alt],
        ),
        isEmpty,
      );
    });

    test('ordena del cambio menos costoso al más costoso', () {
      PlanAlternative alt(int cost, int walk) => PlanAlternative(
        label: 'x',
        edges: [_walk('w$cost$walk', 'O', 'D', walk)],
        costCents: cost,
        walkMetres: walk,
        longestWalkMetres: walk,
        durationMinutes: 10,
        transfers: 0,
        hasEstimatedData: true,
        hasCommunityData: false,
      );
      final limits = _limits(budget: 500, continuous: 300, total: 300);
      final relaxations = RelaxationAdvisor.fromCandidates(
        limits: limits,
        candidates: [
          alt(650, 200), // viola solo el presupuesto: +S/ 1.50 -> esfuerzo 150
          alt(400, 800), // viola solo la caminata: +500 m -> esfuerzo 400
        ],
      );
      expect(relaxations.map((r) => r.kind), [
        RelaxationKind.budget,
        RelaxationKind.walk,
      ]);
      expect(relaxations.first.effort, lessThan(relaxations.last.effort));
    });
  });
}
