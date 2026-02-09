NEXT CHAT PROMPT — XL-C: Pack U + Pack L Theme Readability Finalization

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
4) `app/unitana/lib/theme/app_theme.dart`
5) `app/unitana/lib/features/dashboard/models/tool_registry.dart`
6) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
7) `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart`
8) `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
9) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
10) `app/unitana/test/dashboard_theme_mode_persistence_test.dart`
11) `app/unitana/test/tool_modal_units_typography_consistency_test.dart`
12) `app/unitana/test/weather_summary_narrow_layout_smoke_test.dart`

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
Execute XL-C by closing Pack U + Pack L readability/naming finalization:
1) finish light/dark readability parity across high-traffic surfaces.
2) simplify user-facing theme naming to `Light` and `Dark`.
3) reduce low-contrast hotspots in tools/modals/widgets without regressing existing behavior.

## Required outcomes
1) Theme naming simplification
- Settings should present `System`, `Dark`, `Light` (user-facing labels).
- Keep internal theme/token architecture stable.

2) Readability sweep (dark + light)
- Audit and fix low-contrast text/controls in:
  - dashboard hero and mini-hero
  - tool menu + tool modal headers
  - high-traffic tool modals (weather/time/pace/unit-price)
  - widget cards (especially long-title truncation/readability zones)
- Replace oversaturated light-mode CTA pink with a contrast-safe accent.

3) Consistency contracts
- Preserve tool accent semantics while ensuring text contrast is WCAG-pragmatic on both themes.
- Avoid one-off color hacks; prefer semantic token-level adjustments.

4) Preserve existing contracts
- No regressions to:
  - Pack Q locale selection/persistence/runtime fallback
  - Pack R/S matrix behavior and widget sync
  - weather forecast panel interaction/layout contracts
  - profile suggestion and dashboard interaction tests

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) token/readability audit and targeted fixes
2) theme label simplification in settings/localization keys
3) regression updates for readability-sensitive tests
4) full gates
5) docs/handoff refresh

## Definition of done
- Theme labels are simplified to `System`/`Dark`/`Light`.
- Light and dark readability debt is materially reduced on high-traffic surfaces.
- Existing interaction/layout contracts remain intact.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-D (Pack V emergency weather system + marquee alert states).
- Following slice: XL-E (Pack T world time map widget reimagination + matrix polish follow-up).
