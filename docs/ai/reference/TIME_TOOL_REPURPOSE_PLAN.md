# Time Tool Repurpose Plan (Timezone/Delta First)

> Status: Superseded plan.
> Current Time/World Time Map direction is reflected in shipped behavior, `CURRENT_HANDOFF.md`, and closure artifacts listed in `/Users/codypritchard/unitana/docs/ai/reference/REFERENCE_INDEX.md`.

## Problem
Current `Time` modal is primarily a `12h ↔ 24h` converter.  
That is low-value in context of a travel app and overlaps with system formatting preferences.

## Target behavior
Repurpose `Time` into timezone and delta workflows:
- Home vs destination local time
- timezone offset delta
- “what time is it there now”
- optional simple planning helper (arrival/departure local conversions)

## Scope decisions
- Keep `12h/24h` formatting as a display preference (settings/profile), not as the core time tool purpose.
- Merge conceptual overlap across:
  - `time`
  - `world_clock_delta`
  - `timezone_lookup`
- Canonical outcome: one coherent time-zone tool surface, not fragmented “coming soon” entries.

## Sequenced rollout
### Phase 1 (P1, low risk)
- Introduce a `time_zones` mode inside current Time modal shell.
- Pre-fill Home and Destination from current profile places.
- Show:
  - current local clock in both zones
  - signed offset delta (hours/minutes)
- Keep legacy `12h/24h` conversion mode behind a fallback tab only during transition.

### Phase 2 (P1)
- Route `world_clock_delta` to the new timezone mode (not legacy converter mode).
- Convert `timezone_lookup` from disabled placeholder into the same surface.
- Add tests for:
  - delta correctness across representative IANA zones
  - DST boundary sanity behavior
  - home/destination reality swaps

### Phase 3 (P1/P2)
- Remove legacy `12h/24h` conversion as primary Time workflow.
- Keep format preference controls in profile/settings only.
- Clean up tool registry labels/copy to match final behavior.

## Test/quality gates
- Deterministic timezone fixtures for widget tests.
- Explicit DST transition tests (spring/fall examples).
- No blank states when one place is missing: provide guided fallback copy.

## Dependency notes
- Reuse existing place timezone IDs from canonical city schema.
- Reuse existing dashboard reality context and time utilities.
