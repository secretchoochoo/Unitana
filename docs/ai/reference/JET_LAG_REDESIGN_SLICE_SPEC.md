# Jet Lag Redesign Slice Spec (Design -> Build Contract)

## Objective
Turn Jet Lag from a timezone readout into an actionable travel-planning tool with clear, non-technical language.

## Product positioning
- `Time` tool: clock math and timezone conversion utility.
- `Jet Lag` tool: adaptation planning utility using timezone offset + direction + optional travel duration estimate.

## UX principles
1. Separate facts from heuristics.
2. Never present estimates as medical certainty.
3. Keep zero-shift state explicit and short.
4. Tile and modal must always use the same underlying calculations.

## Information architecture

### A) Travel Facts card (objective)
- `Time zone offset: +7h` (or `same zone (0h)`)
- `Direction: Eastbound / Westbound`
- `Date impact: Arrive next day / same day / previous day`
- `Estimated flight time: ~10h 40m` (if available)

### B) Adaptation Plan card (heuristic)
- `Adjustment band: Minimal / Mild / Moderate / High / Extreme`
- `Adjustment estimate: 0 days / 2-3 days / 4-6 days ...`
- `Plan guidance`:
  - bedtime shift guidance
  - wake shift guidance
  - light exposure window
  - low-friction summary sentence

### C) Zero-shift contract
- Always show:
  - `Time zone offset: same zone (0h)`
  - `Adjustment estimate: no adjustment needed`
  - no overlap hints
  - optional fatigue/travel comfort tips only

## Input model (MVP)
- From city/timezone (default: Home)
- To city/timezone (default: Destination)
- Typical bedtime
- Typical wake time
- Optional departure date/time (defaults to now)

## Heuristic policy (clearly labeled estimate)
- Offset bands:
  - `0-1h` -> Minimal
  - `2-3h` -> Mild
  - `4-6h` -> Moderate
  - `7-9h` -> High
  - `10h+` -> Extreme
- Direction weighting:
  - eastbound can be treated as one-half to one band harder than westbound.
- Copy requirement:
  - use `estimate`, `likely`, `typical`; avoid deterministic/clinical phrasing.

## Flight-time data strategy

### Phase 1 (free + fast)
- Compute great-circle distance from existing city `lat/lon`.
- Convert to estimated block time with simple model:
  - cruise speed baseline + fixed overhead for climb/descent/taxi.
- This avoids paid APIs and still improves plan realism.

### Phase 2 (optional enhancement)
- Add route-aware averages from free/low-cost sources where licensing allows.
- Keep fallback to Phase 1 deterministic estimator.

## Existing data fit
- No new city database required.
- Use existing `assets/data/cities_v1.json` fields:
  - `lat`, `lon`, `timeZoneId`, `cityName`, `countryCode`

## Technical constraints to resolve
1. Expand timezone resolution beyond current limited ruleset so offsets are globally correct.
2. Keep planner logic deterministic for tests.
3. Prevent tile/modal drift by centralizing jet-lag calculations in one shared service.

## Widget contract
- Title: `Jet Lag`
- Primary line:
  - `+7h Eastbound` OR `Same zone`
- Secondary line:
  - `~10h flight • 4-6 day adapt` OR `No adjustment needed`
- Footer CTA remains `Convert` until Settings introduces a renamed action pattern.

## Copy contract (ELI12 style)
- Prefer:
  - `Time zone offset`
  - `Adjustment estimate`
  - `Destination is ahead/behind`
- Avoid:
  - `delta` as primary user copy
  - unexplained abbreviations
  - contradictory defaults (`~1 day` vs `4 days`)

## Acceptance criteria
1. Jet Lag tile and modal show consistent offset/estimate values for same city pair.
2. Zero-shift case never shows non-zero adaptation text.
3. Tool works with any city pair in canonical dataset (after timezone service expansion).
4. Widget remains readable on phone width without truncating key meaning.
5. Full gates green: `dart format .`, `flutter analyze`, `flutter test`.

## Suggested execution slices
1. `J1`: Centralize jet-lag calculation engine + deterministic tests.
2. `J2`: Replace modal labels/cards with facts vs plan structure.
3. `J3`: Move tile preview to shared engine output.
4. `J4`: Add distance/flight-time estimator from city coordinates.
5. `J5`: Add optional bedtime/wake inputs and refine action plan copy.
