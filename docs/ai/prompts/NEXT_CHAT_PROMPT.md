NEXT CHAT PROMPT — Pack H Zero-Residual Audit + Pack E Ambiguity V2

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/CITY_PICKER_PERF_BUDGET.md`
4) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
5) `app/unitana/lib/l10n/localization_seed.dart`
6) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
7) `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
8) `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
9) `app/unitana/lib/data/city_picker_engine.dart`
10) `app/unitana/test/city_picker_engine_test.dart`

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
Close remaining Pack H runtime-localization residuals and run Pack E ambiguity calibration v2 on top of the shared picker engine.

## Required outcomes
1) Pack H zero-residual audit (dashboard/weather/devtools/profile)
- Run a strict literal audit for high-traffic user-visible copy.
- Migrate any remaining hardcoded strings through `DashboardCopy` + runtime lookup.
- Keep fallback behavior deterministic and readable.

2) Pack H contracts
- Add stable `dashboard.*` keys for newly migrated strings.
- Expand:
  - `dashboard_localizations_runtime_test.dart`
  - `localization_seed_contract_test.dart`
- Add or adjust focused widget tests when migrated copy appears in critical surfaces.

3) Pack E ambiguity calibration v2
- Tune shared engine ranking for additional ambiguous city families (e.g., `san jose`, `london`, `vancouver`, `portland`).
- Preserve:
  - seeded home/destination precedence
  - alias behavior (`EST/CST/PST`)
  - selected-row single-marker contract
  - time swap/seeding/history behavior

4) Pack E regression additions
- Add dataset-backed ordering assertions in `city_picker_engine_test.dart` for added ambiguous families.
- Keep `city_picker_perf_budget_test.dart` green under existing budget thresholds.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) literal audit + Pack H residual migrations
2) localization seed/runtime test expansion
3) ambiguity v2 tuning + regression tests
4) full gates
5) docs/handoff refresh

## Definition of done
- High-traffic runtime-localization residuals are effectively cleared.
- Shared picker ranking improves on additional ambiguous city families without regressions.
- Perf contracts remain green.
- Repo green (`format`, `analyze`, `test`).
