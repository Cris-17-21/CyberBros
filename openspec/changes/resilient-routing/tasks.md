# Tasks: Resilient Multimodal Routing & Trip Flow Experience

## Workload Forecast
- Estimated changed lines: ~180 lines (within 400-line budget, no PR split required).
- Chained PRs recommended: No.
- Decision needed before apply: No.

## Task Breakdown

### Batch 1: Domain & Engine Enhancements
- [ ] 1.1 Update `TravelEdge` validation rules in `routing_engine.dart` to allow access/egress taxi bridges originating at `trip:origin` or ending at `trip:destination`.
- [ ] 1.2 In `pilot_planner.dart`, add dynamic access/egress taxi bridges connecting `trip:origin` and `trip:destination` to nearest transit stops when allowed.
- [ ] 1.3 In `pilot_planner.dart`, add guaranteed fallback regional estimate when transit corridors cannot connect origin and destination.

### Batch 2: Presentation & UI Cost Transparency
- [ ] 2.1 Update `pilot_options_screen.dart` to present detailed cost breakdown (taxi fare + transit fare).
- [ ] 2.2 Update infeasible/empty state in `pilot_options_screen.dart` with actionable tips (e.g. increase walking tolerance, enable taxi bridge).
- [ ] 2.3 Verify `flutter analyze lib` and test plan generation with disparate coordinates across Lima.
