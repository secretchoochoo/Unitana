# PACK J Weather Product Positioning Closure (XL-J)

## Product Intent
Weather in Unitana is a **travel readiness cockpit**, not a generic weather app and not a pure converter.

## In-Scope (Current Phase)
- Two-place weather comparison grounded in active reality (home vs destination).
- Dense at-a-glance context: current conditions, deltas, key environment signals.
- Forecast panel optimized for small screens with deterministic compact behavior.
- Consistent behavior across dashboard hero, weather sheet, and weather-related widget previews.
- Emergency-weather severity surfaced through deterministic taxonomy and compact alert affordances.

## Out of Scope (Current Phase)
- Full meteorological exploration feature set (radar layers, map navigation, severe-event drilldowns).
- Long-form narrative forecasting.
- High-frequency animation gimmicks that reduce readability.

## Required Contracts
- City-first labeling and reality-consistent ordering.
- Deterministic fallback behavior when live providers fail.
- Forecast readability on narrow layouts (no clipped/overflowing labels).
- Existing profile/matrix/world-time/localization contracts must not regress.

## Required Tests / Guardrails
- Narrow-layout weather smoke tests remain green.
- Existing forecast/control interaction tests remain green.
- Emergency taxonomy tests remain green.
- City picker perf budget remains green when running full test suite.

## Follow-Up Ideas (Prioritized)
1. `P1` Forecast clarity pass: optional adaptive label suppression for extremely dense hourly sets.
2. `P1` Context layering pass: optional “today summary” strip for precipitation chance/high-low confidence.
3. `P2` Visual parity pass: strengthen theme parity for edge-case weather chips in light mode.
4. `P2` Exploratory: route to deeper external weather view (opt-in) instead of in-app feature bloat.

## Decision Outcome
Pack J is considered **closed at positioning level**: the weather surface is now explicitly defined as a compact travel-readiness cockpit with deterministic UX and reliability guardrails.

