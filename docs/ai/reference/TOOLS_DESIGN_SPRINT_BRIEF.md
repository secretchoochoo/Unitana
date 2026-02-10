# Tools Design Sprint Brief (Urgent)

> Status: Superseded planning brief.
> Use `/Users/codypritchard/unitana/docs/ai/reference/REFERENCE_INDEX.md` and latest `PACK_*_CLOSURE_*` docs for current contracts.

## Why now
Recent Pack F execution exposed design drift in tool surfaces (especially Time) despite functional improvements.  
We need a single visual/interaction direction before adding more tool complexity.

## Scope
- Time tool redesign (primary)
- Weather tool polish pass (secondary)
- Tool taxonomy pass (dedicated vs configurable tools)
- Cross-tool visual consistency pass (header, controls, spacing, labels, card anatomy)

## External references (interaction patterns)
- https://www.timeanddate.com/worldclock/
- https://www.timeanddate.com/time/map/

These are interaction references only. Unitana must keep Dracula brand/system identity.

## Art direction requirements
- Maintain Dracula color system and existing type hierarchy.
- Align tool visuals with future marquee 16-bit artistic vision.
- Define one reusable “tool anatomy” spec with explicit exceptions:
  - `Converter` tools
  - `Lookup` tools
  - `Cockpit` tools (Time, Weather)

## Deliverables
1) `Tool Surface Visual Language v1`
- spacing grid
- border radius policy
- control styles (button, picker row, segmented control)
- title/metadata/header alignment rules

2) `Time Tool v2` interaction spec
- primary jobs-to-be-done
- allowed controls only
- no dead/ambiguous sections
- deterministic default states

3) `Tool taxonomy audit`
- each tool tagged:
  - `dedicated`
  - `preset`
  - `configurable`
  - `defer/remove`

4) `Golden lock plan`
- prioritized visual goldens for time/weather/tool modal primitives.

## QA/Regression integration
- Add/update golden tests (opt-in gated) for:
  - Time tool modal (default + compact phone)
  - Weather summary sheet (default + small phone)
  - Generic converter modal shell
- Add layout overflow smoke tests for all new cockpit/lookup surfaces.

## Decision constraints
- If a control does not map to a clear user job, remove it.
- If a duplicated tool entry has no distinct user value, merge or re-scope it.
- Do not ship “placeholder complexity” (controls without user-legible purpose).
