NEXT CHAT PROMPT — XL-J: Pack E + Pack J Closure Artifacts

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/PACK_X_RETRO_BASELINE_XL_H2.md`
4) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
5) `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
6) `app/unitana/lib/features/dashboard/widgets/hero_alive_marquee.dart`
7) `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
8) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
9) `app/unitana/test/weather_summary_narrow_layout_smoke_test.dart`
10) `app/unitana/test/hero_alive_marquee_paint_extremes_test.dart`
11) `app/unitana/test/dashboard_places_hero_v2_test.dart`

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
Close remaining artifact debt for Pack E and Pack J:
1) Pack E: document and lock marquee V2 readability/spec decisions.
2) Pack J: document and lock weather product-positioning closure decisions.

## Required outcomes
1) Pack E closure artifact
- Add a concise reference doc defining:
  - scene readability principles
  - spacing/token rules
  - animation/perf constraints
  - acceptance checks for small screens

2) Pack J closure artifact
- Add a concise product-positioning doc defining:
  - weather cockpit intent and scope
  - what is in/out of scope for this app phase
  - required contracts and tests
  - unresolved follow-up ideas with priorities

3) Code follow-through (only if needed)
- Apply only minimal code/copy/test updates required to align runtime behavior with the closure docs.

4) Preserve existing contracts
- No regressions to:
  - profile board behavior
  - matrix interactions/sync
  - world time map readouts
  - localization and emergency weather surfaces

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) Pack E closure artifact
2) Pack J closure artifact
3) minimal alignment edits/tests
4) full gates
5) docs/handoff refresh

## Definition of done
- Pack E and Pack J closure artifacts exist and are actionable.
- Runtime behavior remains consistent with closure contracts.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-K (Pack L + Pack K closure pass).
- Following slice: XL-L (Pack D docs architecture consolidation).
