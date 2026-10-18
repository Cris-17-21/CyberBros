# Technical Design: Resilient Multimodal Routing & Trip Flow Experience

## Architecture & Data Flow

```
[Origin / Destination Stops]
           │
           ▼
[PilotPlanner.plan] ──► 1. Evaluate Direct Walking Edge (if <= maxTotalWalkMetres)
           │        ──► 2. Evaluate Access Edges (Walk to nearest stops)
           │        ──► 3. Evaluate First-Mile Taxi Bridges (Origin -> Nearest Stops if allowed)
           │        ──► 4. Evaluate Last-Mile Taxi Bridges (Nearest Stops -> Destination if allowed)
           │        ──► 5. Inter-corridor Taxi Bridges (Transfer points)
           │        ──► 6. Fallback Off-Grid Route generation if corridor network unconnected
           ▼
[RoutingGraph & LocalPlanner (Pareto Multi-Objective)]
           │
           ▼
[FeasiblePlan Alternatives (Walk, Public Transit + Taxi Bridge, Regional Estimate)]
           │
           ▼
[PilotOptionsScreen / Route Detail Views]
```

## Detailed Component Changes

### 1. `PilotPlanner` (`lib/features/trip_planner/data/pilot_planner.dart`)
- **Dynamic First/Last Mile Bridges**:
  - If direct walk from origin to a corridor stop exceeds `maxContinuousWalkMetres`, and `limits.allowTaxiBridge` is true, attach a `taxiBridge` edge from `trip:origin` to the closest stop candidates (up to 3 closest stops within 5 km).
  - Similarly, attach terminal `taxiBridge` edges from corridor stops to `trip:destination`.
- **Guaranteed Fallback Generation**:
  - If no transit path is feasible due to coverage gaps, create a regional estimated multimodal option:
    - Base taxi fare: $S/ 5.00$ base + $S/ 1.30/km$
    - Labeled as `DataCertainty.estimated` with informative source `'estimate:regional-off-grid'`.

### 2. `RoutingEngine` (`lib/features/trip_planner/domain/routing_engine.dart`)
- Support composite routes that start or end with a `taxiBridge` edge without requiring a prior boarding edge when explicitly originating from `trip:origin`.
- Ensure multi-alternative extraction preserves both pure walk itineraries and transit/taxi combinations.

### 3. Presentation Layer (`pilot_options_screen.dart` & `planner_home_screen.dart`)
- In `pilot_options_screen.dart`, improve the empty/infeasible view: instead of a dead error message, render a suggested card to increase walking distance or toggle taxi bridge.
- Detail the exact cost breakdown: e.g. "S/ 7.50 (Taxi puente S/ 5.00 + Corredor Morado S/ 2.50)".
