NEXT CHAT PROMPT — XL Unit 4: Pack E Final Readability Closure + Pack K Discovery Kickoff

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/PACK_G_RELEASE_CHECKLIST_XL3.md`
4) `app/unitana/lib/features/dashboard/widgets/hero_alive_marquee.dart`
5) `app/unitana/lib/features/dashboard/widgets/places_hero_collapsing_header.dart`
6) `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
7) `app/unitana/test/dashboard_places_hero_v2_test.dart`
8) `app/unitana/test/weather_summary_tile_open_smoke_test.dart`
9) `app/unitana/lib/app/app_state.dart`
10) `docs/ai/reference/DEFERRED_TOOLS_EXECUTION_MATRIX.md`

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
Execute XL Unit 4 as a combined slice: close Pack E readability/facelift residuals and start Pack K with deterministic discovery artifacts (no risky rollout).

## Required outcomes
1) Pack E final readability closure
- Audit marquee/hero and weather-card readability on narrow phones.
- Apply targeted typography/spacing/contrast fixes where contracts are weak.
- Add or adjust deterministic tests only where they lock correctness/readability-critical behavior.

2) Pack K discovery kickoff (safe scope)
- Produce concrete, implementation-ready Pack K discovery artifact(s):
  - scoring policy
  - opt-in/permission UX contract
  - safety boundaries (no silent switching during edits)
  - deterministic tie-breakers and explainability copy
- Do not ship autonomous profile switching behavior yet unless fully test-guarded and explicitly scoped.

3) Preserve behavior contracts
- No regressions to:
  - weather sheet open/close + forecast interaction keys
  - Pack N timezone correctness
  - Pack H locale fallback/runtime copy
  - Pack F defer lock (`clothing_sizes`) and activated tools
  - city-picker perf budget

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) readability audit and targeted implementation
2) Pack K discovery artifact drafting
3) deterministic regression/perf checks
4) full gates
5) handoff/context/prompt refresh

## Definition of done
- Pack E readability residual risk is materially reduced with deterministic guardrails.
- Pack K discovery is concrete enough for a low-risk implementation slice.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: Pack K implementation phase 1 (opt-in controls + non-invasive ranking path).
- Following slice: Pack L dual-theme discovery/prototype.
