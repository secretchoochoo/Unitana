NEXT CHAT PROMPT — Core Track: Pack G Expanded Pass (Release Compliance + Artifacts)

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
4) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
5) `app/unitana/lib/features/dashboard/models/dashboard_live_data.dart`
6) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
7) `app/unitana/test/weather_summary_tile_open_smoke_test.dart`
8) `app/unitana/test/weather_summary_close_button_smoke_test.dart`
9) `app/unitana/test/dashboard_localizations_runtime_test.dart`
10) `app/unitana/test/toolpicker_activation_bundle_test.dart`
11) `docs/ai/reference/DEFERRED_TOOLS_EXECUTION_MATRIX.md`

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
Execute the Pack G expanded pass focused on release-compliance closure after weather cockpit accessibility hardening.

## Required outcomes
1) Compliance surfaces and release copy closure
- Add/verify About + Licenses visibility from Settings/dashboard entry points.
- Ensure legal/compliance copy is deterministic, localized-fallback safe, and test-covered.

2) Accessibility + interaction consistency follow-through
- Validate weather cockpit semantics/legibility contracts remain intact while adding compliance surfaces.
- Keep tap targets and tooltip/label contracts deterministic.

3) Preserve current behavior contracts
- No regressions to:
  - weather sheet open/close behavior
  - refresh semantics / stale truthfulness
  - per-place card scene rendering keys
  - picker launch path (`weather_summary` opens sheet, not converter modal)
  - Pack N timezone behavior and Pack H locale fallback behavior
  - imperial/metric high-low ordering (`°F/°C` vs `°C/°F`)
  - forecast panel interaction keys (`weather_summary_forecast_*`)

4) Keep Pack F closure intact
- Do not reopen `clothing_sizes`; deferred state and acceptance criteria stay explicit.
- No regressions to activated Pack F tools (`energy`, `pace`, `cups_grams_estimates`, `hydration`).

4) Perf/reliability guardrails
- Keep `city_picker_perf_budget_test.dart` passing under current thresholds.
- Add tests only for correctness-critical contracts.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) compliance surface audit (About/Licenses + copy contracts)
2) implementation updates + deterministic tests
3) weather/accessibility regression spot-checks
4) full gates
5) docs/handoff refresh

## Definition of done
- Pack G compliance artifacts (About/Licenses + copy/test coverage) are materially closed.
- No regressions to timezone/live-data/localization/city-picker or deferred-tool contracts.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: Pack G final checklist/signoff artifacts.
- Following slice: Pack K discovery/prototyping (context-aware profile auto-select) if reprioritized.
