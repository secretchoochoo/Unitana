NEXT CHAT PROMPT — XL-K: Pack L + Pack K Closure Pass

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/PACK_E_MARQUEE_V2_CLOSURE_SPEC_XL_J.md`
4) `docs/ai/reference/PACK_J_WEATHER_POSITIONING_CLOSURE_XL_J.md`
5) `app/unitana/lib/features/dashboard/widgets/profiles_board_screen.dart`
6) `app/unitana/lib/theme/app_theme.dart`
7) `app/unitana/lib/features/dashboard/models/lens_accents.dart`
8) `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart`
9) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
10) `app/unitana/test/profile_switcher_switch_profile_flow_test.dart`
11) `app/unitana/test/lens_accents_contract_test.dart`

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
Close remaining Pack L + Pack K reliability/readability debt by finishing theme-token consistency and profile auto-suggest UX contracts.

## Required outcomes
1) Pack L closure pass
- Audit light/dark token usage in profile/dashboard/tool entry surfaces.
- Remove remaining hardcoded color outliers where semantic tokens should be used.
- Ensure readability parity for key text chips and statuses in both themes.

2) Pack K closure pass
- Validate profile auto-suggest explainability copy and settings behavior.
- Lock deterministic behavior for edge cases (no permission, stale/no location, low confidence ties).
- Add/update tests only where contracts are still under-specified.

3) Preserve existing contracts
- No regressions to:
  - weather cockpit + emergency taxonomy
  - matrix interactions/widget selection sync
  - world time map widget compact readouts
  - localization/runtime fallback behavior

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) theme/profile audit
2) minimal targeted hardening
3) regression additions (only if contract-critical)
4) full gates
5) docs/handoff refresh

## Definition of done
- Pack L and Pack K closure debt is materially reduced with explicit contract lock.
- Runtime behavior remains stable across core surfaces.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-L (Pack D docs architecture consolidation).
- Following slice: XL-M (Pack W optional lofi audio spike, off by default).
