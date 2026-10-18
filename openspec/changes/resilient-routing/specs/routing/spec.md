# Specification: Resilient Multimodal Routing & Trip Flow Experience

## Capability: Multimodal Access and Egress
The planner must connect trip origins and destinations to transit corridors even when direct walking exceeds strict walking limits, provided that taxi bridge is permitted and affordable.

### Scenario: First-mile connection via taxi bridge
- **Given** an origin point located 2.5 km away from the nearest corridor stop
- **And** the user has allowed taxi bridge with adequate budget
- **When** the trip options are calculated
- **Then** the engine generates a valid itinerary starting with a taxi bridge to the nearest stop
- **And** follows with the corridor bus ride and egress walk
- **And** the estimated cost includes the taxi fare plus the bus fare.

### Scenario: Alternative presentation with walking and transit
- **Given** an origin and destination within walking distance (e.g. 1.2 km)
- **When** the trip options are calculated
- **Then** the engine returns both the direct walk option (cost S/ 0, duration based on distance)
- **And** at least one public transit alternative if a transit route exists nearby
- **And** allows the user to compare cost vs effort.

### Scenario: Off-corridor fallback estimate
- **Given** an origin and destination where no validated corridor route is accessible within reasonable distance
- **When** the trip options are calculated
- **Then** the planner does not emit a raw blocking failure
- **Instead** it produces an estimated regional route with estimated taxi/standard fare
- **And** clearly labels the alternative as `estimated:off-corridor` with guidance.

## Interface and Contract Requirements
1. `PilotPlanner.plan(...)` must return feasible plans for peripheral stops by dynamically attaching access/egress edges.
2. `PilotOptionsScreen` must render clear step breakdowns showing:
   - Walk distance and duration.
   - Taxi bridge cost and duration.
   - Corridor route name, code, and official fare.
3. Infeasible results should only occur when limits are strictly impossible (e.g., negative budget or distance > 100km).
