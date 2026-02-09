NEXT CHAT PROMPT — XL-H Phase 2: Pack X Retro Baseline + Price/Baking Productization

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
4) `app/unitana/lib/features/dashboard/widgets/profiles_board_screen.dart`
5) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
6) `app/unitana/lib/features/dashboard/models/tool_definitions.dart`
7) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
8) `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart`
9) `app/unitana/test/baking_tool_modal_fraction_units_test.dart`
10) `app/unitana/test/unit_price_helper_modal_interaction_test.dart`
11) `app/unitana/test/profile_switcher_switch_profile_flow_test.dart`

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
Execute XL-H phase 2 by combining:
1) Pack X retro baseline artifact (prioritized, actionable).
2) productization direction for Price Compare and Baking/Cups tools.

## Required outcomes
1) Pack X retro artifact
- Add a concise retro document with:
  - strongest app UX patterns to preserve
  - highest-priority UX/readability/perf debt
  - consistency/haptics/interaction gaps
  - recommended execution sequence for XL-I onward

2) Price Compare product direction
- Define and implement/prepare next-step contracts for dual-reality shopping:
  - home vs destination currency context clarity
  - normalized basket comparisons
  - unit-family guardrails and copy clarity

3) Baking/Cups direction
- Clarify tool split responsibilities:
  - Baking converter (unit conversion workflow)
  - Cups↔Grams matrix (ingredient density lookup workflow)
- Add/adjust copy and interaction cues to reduce confusion.

4) Preserve existing contracts
- No regressions to:
  - profile board edit/reorder/add behavior
  - matrix tool selection/copy behavior
  - world time map widget contracts
  - localization and emergency weather contracts

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) retro findings capture
2) copy/UX polish for Price Compare and Baking/Cups roles
3) targeted regression tests
4) full gates
5) docs/handoff refresh

## Definition of done
- Pack X retro baseline exists and is actionable.
- Price Compare and Baking/Cups direction is materially clearer in-product.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-I (Pack E marquee V2 continuation + weather/time visual harmonization).
- Following slice: XL-J (Pack W opt-in lofi audio foundation, off by default).
