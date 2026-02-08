NEXT CHAT PROMPT — Core Track: Pack J Phase 4 IA Lock + Pack G Readiness Kickoff

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
4) `app/unitana/lib/features/dashboard/models/dashboard_live_data.dart`
5) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
6) `app/unitana/test/weather_summary_tile_open_smoke_test.dart`
7) `app/unitana/test/weather_summary_close_button_smoke_test.dart`
8) `app/unitana/lib/l10n/localization_seed.dart`
9) `app/unitana/test/dashboard_localizations_runtime_test.dart`
10) `app/unitana/test/toolpicker_activation_bundle_test.dart`

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
Execute a combined large slice:
1) Pack J phase 4 final information architecture/positioning lock for Weather Summary cockpit interactions.
2) Pack G kickoff for release-readiness hardening on weather cockpit accessibility/consistency/compliance edges.

## Required outcomes
1) Weather cockpit IA lock
- Validate and lock final weather-card content hierarchy:
  - header summary + high/low badge
  - sunrise/sunset, wind/gust, AQI/pollen rows
  - interactive forecast panel toggle behavior (Hourly <-> 7-day)
- Ensure non-scrolling forecast panel remains readable across narrow phone widths.

2) Accessibility/legibility readiness (Pack G kickoff)
- Improve chart/label readability and contrast where needed while preserving Dracula direction.
- Ensure swap affordance and forecast mode state are discoverable and testable.
- Keep touch targets and no-overflow behavior stable on small screens.

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

5) Perf/reliability guardrails
- Keep `city_picker_perf_budget_test.dart` passing under current thresholds.
- Add tests only for correctness-critical contracts.

6) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) IA/accessibility audit
2) targeted implementation updates
3) regression/perf guardrail tests
4) full gates
5) docs/handoff refresh

## Definition of done
- Weather Summary cockpit is interaction-locked with readable, test-backed forecast behavior and stable small-screen layout.
- No regressions to timezone/live-data/localization/city-picker or deferred-tool contracts.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: Pack G expanded pass (accessibility, legal/about copy, release checklist artifacts).
- Following slice: Pack K discovery/prototyping (context-aware profile auto-select) if reprioritized.
