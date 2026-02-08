NEXT CHAT PROMPT — XL Unit 3: Pack G Final Checklist + Pack B/C Closure Proof

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
4) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
5) `docs/ai/reference/DEFERRED_TOOLS_EXECUTION_MATRIX.md`
6) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
7) `app/unitana/lib/features/dashboard/models/dashboard_live_data.dart`
8) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
9) `app/unitana/test/weather_summary_tile_open_smoke_test.dart`
10) `app/unitana/test/weather_summary_close_button_smoke_test.dart`
11) `app/unitana/test/dashboard_localizations_runtime_test.dart`
12) `app/unitana/test/toolpicker_activation_bundle_test.dart`

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
Execute XL Unit 3 as a combined slice: finish Pack G release-checklist artifacts and produce closure-proof contracts for Pack B/C reliability/completeness.

## Required outcomes
1) Pack G final release-checklist artifacts
- Create/refresh explicit release checklist + QA signoff artifact(s) in docs.
- Confirm About/Licenses/settings compliance path stays deterministic and test-covered.

2) Pack B closure proof pass
- Add deterministic tests/contracts that demonstrate weather/time/AQI/pollen reliability behavior across representative global cases and fallback paths.
- Ensure stale/freshness semantics remain truthful under failure scenarios.

3) Pack C closure proof pass
- Add/adjust deterministic currency coverage tests for representative global mappings and outage fallback behavior.
- Confirm stale-rate retry/cache semantics remain intact.

4) Preserve current behavior contracts
- No regressions to:
  - weather sheet open/close behavior
  - refresh semantics / stale truthfulness
  - per-place card scene rendering keys
  - picker launch path (`weather_summary` opens sheet, not converter modal)
  - Pack N timezone behavior and Pack H locale fallback behavior
  - imperial/metric high-low ordering (`°F/°C` vs `°C/°F`)
  - forecast panel interaction keys (`weather_summary_forecast_*`)

5) Keep Pack F closure intact
- Do not reopen `clothing_sizes`; deferred state and acceptance criteria stay explicit.
- No regressions to activated Pack F tools (`energy`, `pace`, `cups_grams_estimates`, `hydration`).

6) Perf/reliability guardrails
- Keep `city_picker_perf_budget_test.dart` passing under current thresholds.
- Add tests only for correctness-critical contracts.

7) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) release-checklist artifact pass
2) Pack B/C closure-proof implementation + tests
3) regression/perf guardrail tests
4) full gates
5) handoff/context/prompt refresh

## Definition of done
- Pack G final checklist/signoff artifacts are materially complete.
- Pack B/C closure proof is materially stronger with deterministic tests/contracts.
- No regressions to timezone/live-data/localization/city-picker or deferred-tool contracts.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: Pack E final readability/facelift closure or Pack K discovery (based on priority).
- Following slice: Pack L dual-theme discovery/prototype.
