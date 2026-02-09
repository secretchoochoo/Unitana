NEXT CHAT PROMPT — XL-E: Pack T World Time Map Widget Reimagination

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
4) `app/unitana/lib/features/dashboard/models/tool_definitions.dart`
5) `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart`
6) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
7) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
8) `app/unitana/lib/features/dashboard/models/dashboard_live_data.dart`
9) `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
10) `app/unitana/test/toolpicker_activation_bundle_test.dart`
11) `app/unitana/test/dashboard_tool_insertion_persistence_test.dart`
12) `app/unitana/test/dashboard_places_hero_v2_test.dart`

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
Execute XL-E by closing Pack T in a user-visible way:
1) redesign World Time Map widget naming/readout density for small-card legibility.
2) surface actionable timezone delta/readout data from the map context.
3) keep modal and widget semantics aligned without regressions.

## Required outcomes
1) Widget naming + fit contract
- Shorten/adjust display naming so the widget title does not truncate on compact cards.
- Preserve canonical tool ID behavior (`world_clock_delta`) and activation contracts.

2) Glance-value data model
- Add concise, high-value readout lines in the widget (delta + UTC lane context).
- Ensure values are deterministic for both home and destination reality modes.

3) Modal/widget parity
- Keep lane semantics and city/UTC identity consistent between widget and map modal.
- Avoid introducing duplicate/conflicting terminology.

4) Readability + overflow safety
- Validate compact card rendering on small widths.
- Ensure no regressions in light/dark contrast.

5) Preserve existing contracts
- No regressions to:
  - Pack V emergency taxonomy + hero/weather alert states
  - Pack U theme readability + naming simplification
  - Pack Q locale persistence/runtime fallback
  - matrix tools/widget last-selection sync behavior

6) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) widget contract audit (naming + current data payload)
2) implementation for compact glance readouts
3) regression tests for card visibility/overflow + activation parity
4) full gates
5) docs/handoff refresh

## Definition of done
- World Time Map widget presents concise, useful timezone context without truncation.
- Widget and modal semantics stay coherent and test-covered.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-F (Pack P licenses IA/readability modernization).
- Following slice: XL-G (Pack R/S matrix standards follow-through: semantics and remaining dataset expansion).
