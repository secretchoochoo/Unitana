NEXT CHAT PROMPT — XL-D: Pack V Emergency Weather System + Marquee Alert States

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
4) `app/unitana/lib/features/dashboard/models/dashboard_live_data.dart`
5) `app/unitana/lib/features/dashboard/models/weather_backend.dart`
6) `app/unitana/lib/features/dashboard/widgets/hero_alive_marquee.dart`
7) `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
8) `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
9) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
10) `app/unitana/lib/l10n/localization_seed.dart`
11) `app/unitana/test/dashboard_places_hero_v2_test.dart`
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
Execute XL-D by starting Pack V end-to-end:
1) define deterministic emergency-weather taxonomy for hero/weather surfaces.
2) map alert severity to marquee scene behavior and high-visibility UI cues.
3) keep graceful fallback behavior when alert metadata is missing.

## Required outcomes
1) Emergency taxonomy contract
- Define explicit severity bands and source mapping for emergency conditions.
- Keep deterministic precedence when multiple signals exist.
- Document the mapping contract in code comments and tests.

2) Marquee + hero behavior
- Add alert-aware marquee state variants without breaking existing scene taxonomy.
- Ensure alert states remain readable in both light/dark themes.
- Avoid alarm-fatigue: urgent but non-chaotic visual behavior.

3) Weather sheet/readout integration
- Surface emergency state in weather summary where relevant.
- Keep interaction and layout stable on narrow devices.
- Preserve existing weather/time correctness and chart contracts.

4) Fallback behavior
- If provider alert fields are unavailable, maintain current behavior with no blank/erratic states.
- Add deterministic fallback tests.

5) Preserve existing contracts
- No regressions to:
  - Pack Q locale/persistence/runtime fallback
  - Pack U theme readability and naming
  - Pack R/S matrix behavior and widget sync
  - weather forecast interaction and mini-hero layout stability

6) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) taxonomy and precedence design in model layer
2) marquee/hero alert rendering integration
3) weather-sheet alert readout integration
4) regression tests for precedence/fallback/readability
5) full gates + docs refresh

## Definition of done
- Emergency weather taxonomy is deterministic and test-covered.
- Marquee + weather surfaces react coherently to alert severity.
- Fallback behavior remains stable when alert data is absent.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-E (Pack T world time map widget reimagination).
- Following slice: XL-F (Pack P licenses IA/readability modernization).
