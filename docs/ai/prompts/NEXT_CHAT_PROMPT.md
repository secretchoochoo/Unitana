NEXT CHAT PROMPT — Pack E 6h/6i Completion + Pack H Residual Sweep

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/CITY_PICKER_PERF_BUDGET.md`
4) `app/unitana/lib/data/city_picker_engine.dart`
5) `app/unitana/lib/widgets/city_picker.dart`
6) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
7) `app/unitana/lib/features/dashboard/models/time_zone_catalog.dart`
8) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
9) `app/unitana/lib/l10n/localization_seed.dart`
10) `app/unitana/test/city_picker_perf_budget_test.dart`

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
Finish Pack E city-picker quality edge cases now that shared engine + perf contracts are in place, and continue Pack H residual runtime-localization migration.

## Required outcomes
1) Pack E 6h ambiguity ranking calibration
- Tune `CityPickerEngine` scoring for same-name multi-country city ambiguity.
- Keep seeded home/destination precedence stable.
- Preserve alias and short-query expectations.

2) Pack E 6i duplicate/disambiguation clarity
- Reduce duplicate-feeling rows in both wizard and Time-family pickers.
- Improve disambiguation clarity (country/region hints) without row clutter.
- Keep advanced timezone mode and timezone-id path intact.

3) Pack E regression expansion
- Add tests for:
  - same-name city ranking/disambiguation order
  - selected-row marker stability under mixed city + timezone result sets
  - no regression in Time/Jet Lag swap/seeding/history behavior
  - keep `city_picker_perf_budget_test.dart` passing under current budget thresholds

4) Pack H residual migration
- Migrate more high-traffic hardcoded strings in dashboard/weather/devtools/profile surfaces through `DashboardCopy` + runtime lookup.
- Add stable `dashboard.*` keys and keep deterministic fallback behavior.

5) Pack H test hardening
- Expand runtime localization tests for newly migrated keys/placeholders.
- Keep localization contract readability and fallback stability locked.

6) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) Pack E ambiguity/disambiguation tweaks in shared engine
2) Regression tests (including mixed-state selection and ambiguity cases)
3) Pack H residual string migration + tests
4) Full gates
5) Docs/handoff refresh

## Definition of done
- Shared picker engine remains performant and deterministic while improving ambiguity handling.
- Wizard and Time/Jet Lag picker quality stays aligned.
- Pack H runtime-localized coverage expands on high-traffic surfaces with deterministic fallback.
- Repo green (`format`, `analyze`, `test`).
