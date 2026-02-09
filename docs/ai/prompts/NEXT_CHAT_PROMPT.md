NEXT CHAT PROMPT — XL-G: Pack R/S Matrix Standards Follow-through

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
4) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
5) `app/unitana/lib/features/dashboard/models/tool_definitions.dart`
6) `app/unitana/lib/features/dashboard/models/dashboard_session_controller.dart`
7) `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart`
8) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
9) `app/unitana/test/matrix_global_standards_expansion_test.dart`
10) `app/unitana/test/dashboard_session_matrix_selection_test.dart`
11) `app/unitana/test/shoe_sizes_tool_modal_interaction_test.dart`
12) `app/unitana/test/mattress_sizes_matrix_interaction_test.dart`

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
Execute XL-G by closing outstanding matrix-tool direction debt for Shoes/Paper/Mattress:
1) finalize table semantics (no duplicate/ambiguous reference columns).
2) expand global standards coverage where reliable mappings exist.
3) lock matrix-to-widget sync behavior and readability on compact surfaces.

## Required outcomes
1) Semantics and direction
- Remove or refactor confusing matrix column semantics (`reference`-style duplication, ambiguous taxonomy labels).
- Ensure each matrix has one canonical anchor + mapped system columns.

2) Dataset follow-through
- Expand remaining practical size ranges for Shoes/Paper/Mattress where gaps remain.
- Keep mappings deterministic and documented in code comments.

3) Widget sync + compact readability
- Ensure matrix widgets consistently reflect last selected/copied value.
- Validate no truncation/overflow regressions on compact tiles.

4) Preserve existing contracts
- No regressions to:
  - Pack V emergency weather taxonomy and alert surfaces
  - Pack T world time map widget readout contracts
  - Pack U theme readability and naming
  - Pack Q localization/runtime fallback behavior

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) matrix semantic audit
2) dataset/model updates
3) matrix widget sync/readability pass
4) regression tests
5) full gates + docs refresh

## Definition of done
- Matrix tools present clear canonical mappings with no duplicate-semantics confusion.
- Widget sync behavior is deterministic and test-covered.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-H (Pack Q localization completion sweep for remaining unlocalized strings).
- Following slice: XL-I (Pack X full-app UX/UI/performance retro baseline).
