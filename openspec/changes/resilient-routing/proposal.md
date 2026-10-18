# Change: Resilient Multimodal Routing & Trip Flow Experience

## Problem Statement
Currently, users face a frustrating experience when planning trips in Cyberon:
1. When selecting an origin or destination far from the 13 corridor pilot routes, the routing engine terminates with a hard error (`InfeasiblePlan.noConnection`) without guidance, approximate costs, or alternatives.
2. When points are close, the app only suggests walking directly (`walk:direct`) and omits public transit/taxi alternatives.
3. The UI does not provide helpful visual affordances regarding corridor coverage, nearest transit stop recommendations, or transparent breakdown of multimodal trip costs.

## Objective & Outcomes
- Transform the routing engine into a resilient multimodal system that never hits a dead end when reasonable estimates can be computed.
- Enable automatic first-mile / last-mile connection via taxi bridge or extended walking access to the nearest transit hubs.
- Always provide clear cost estimates (transit fare + taxi bridge + walking distance) and realistic transit options alongside direct walking.
- Upgrade the trip planner and options screen to clearly communicate transit proximity, data certainty, and breakdown costs.

## Scope & Boundaries
- **In Scope:**
  - `PilotPlanner` and `RoutingEngine` edge expansion: support initial/terminal taxi bridges connecting origin/destination to transit stops when walking exceeds limits.
  - Multi-option presentation: present both direct walking and transit/taxi combinations when feasible.
  - Transparent cost fallback: compute estimated trip fare and duration based on regional distance when completely off-corridor, clearly labeled as `estimated:off-grid`.
  - UI enhancements in `planner_home_screen.dart`, `trip_conditions_screen.dart`, and `pilot_options_screen.dart`.
- **Out of Scope:**
  - Real-time GPS tracking or turn-by-turn road navigation.
  - Full metropolitan network ingestion (remains focused on expanding the engine capabilities over existing SIT/OSM datasets).

## Delivery Strategy
- Strategy: `ask-on-risk` (split into staged work units if code changes exceed 400 lines).
- Artifact Store: `openspec`.
