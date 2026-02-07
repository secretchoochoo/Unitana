NEXT CHAT PROMPT — Pack H Final Residual Sweep + Pack E Ambiguity V3

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/CITY_PICKER_PERF_BUDGET.md`
4) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
5) `app/unitana/lib/l10n/localization_seed.dart`
6) `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
7) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
8) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
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
Close remaining high-traffic runtime-localization residuals (especially hero env/details microcopy) and run an ambiguity v3 pass for same-country/same-name city disambiguation without perf regressions.

## Required outcomes
1) Pack H final residual sweep
- Audit `places_hero_v2.dart`, time/jet-lag helper surfaces, and related dashboard/profile/devtools views for remaining visible hardcoded literals.
- Migrate residual user-facing literals through `DashboardCopy` runtime localization.
- Keep fallback behavior deterministic and readable.

2) Pack H contracts/tests
- Add stable `dashboard.*` seed keys for every newly migrated literal.
- Expand:
  - `dashboard_localizations_runtime_test.dart`
  - `localization_seed_contract_test.dart`
- Add focused widget tests for any migrated critical hero/devtools strings if needed.

3) Pack E ambiguity v3 (same-country/same-name)
- Improve ranking behavior for same-country duplicates where one row is clearly mainstream (e.g., `Portland` family behavior).
- Preserve:
  - alias behavior (`EST/CST/PST`)
  - direct timezone search behavior
  - seeded home/destination precedence
  - selected-row single-marker contract

4) Pack E regression/perf guardrails
- Extend `city_picker_engine_test.dart` with deterministic contracts for new v3 behavior.
- Keep `city_picker_perf_budget_test.dart` green under existing thresholds.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) residual literal audit + migrations
2) localization seed/runtime test expansion
3) ambiguity v3 tuning + regression additions
4) full gates
5) docs/handoff refresh

## Definition of done
- Remaining high-traffic residual literals are materially reduced.
- Same-country ambiguity behavior improves without regression to timezone/alias flows.
- Perf budgets remain green.
- Repo green (`format`, `analyze`, `test`).
