NEXT CHAT PROMPT — XL Unit 11: Pack D Consolidation + Pack J/Pace Signoff

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
4) `app/unitana/lib/features/dashboard/widgets/pinned_mini_hero_readout.dart`
5) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
6) `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
7) `app/unitana/lib/features/dashboard/models/tool_definitions.dart`
8) `app/unitana/lib/features/dashboard/models/tool_registry.dart`
9) `app/unitana/test/pace_tool_modal_interaction_test.dart`
10) `app/unitana/test/small_device_overflow_sweep_test.dart`

## Core operating rules
- Keep repo green if any code/docs are touched:
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- Work directly in-repo (Codex-first).
- Preserve non-negotiables:
  - collapsing pinned `SliverPersistentHeader` morph
  - canonical hero key uniqueness
  - wizard previews with `includeTestKeys=false`
  - goldens opt-in only

## Mission
Execute XL Unit 11 as a combined closure slice:
1) Pack D docs/text consolidation pass.
2) Pack J mini-hero readability signoff polish.
3) Pace planner usability refinement and contract hardening.

## Required outcomes
1) Pack D consolidation closure
- Audit current AI handoff/context/prompt files for stale or duplicated status notes.
- Normalize “done / in_progress / planned” language so backlog state is unambiguous.
- Keep pending work explicit and short (no handoff drift).

2) Pack J mini-hero signoff
- Keep the compact mini-hero size contract (no overflows on small screens).
- Improve spacing/legibility in both dark/light themes where needed without reintroducing extra rows.
- Preserve all existing data contracts (delta, sun, wind, AQI, pollen, temp, FX).

3) Pace planner refinement
- Improve novice readability for goal planner outputs (labels + split checkpoints).
- Keep deterministic parsing behavior for `mm:ss` and `h:mm:ss`.
- Expand regression checks only where they lock correctness/UX-critical behavior.

4) Preserve existing contracts
- No regressions to:
  - Pack N timezone conversion/search behavior
  - Pack H locale/runtime fallback
  - Pack K opt-in/no-silent-switch profile suggestion contracts
  - matrix lookup copy/tap contracts
  - city-picker perf budgets

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) docs/backlog audit + normalization
2) mini-hero polish pass + targeted overflow tests
3) pace planner UX/readability refinements + tests
4) full gates
5) handoff refresh

## Definition of done
- Backlog/docs state is auditable and current.
- Mini-hero is readable at same size in both themes with no overflow regressions.
- Pace planner is clearer for novice users while preserving deterministic behavior.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: Pack K phase-2 explainability UX and safe-switch boundary hardening.
- Following slice: Pack I + Pack O tutorial overlay planning.
