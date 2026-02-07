NEXT CHAT PROMPT — Final Residual Copy Audit + Pack E Ambiguity V4

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/CITY_PICKER_PERF_BUDGET.md`
4) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
5) `app/unitana/lib/l10n/localization_seed.dart`
6) `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
7) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
8) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
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
Finish remaining hardcoded high-traffic copy audit and run ambiguity v4 tuning on additional same-country collisions while preserving timezone/alias behavior and perf contracts.

## Required outcomes
1) Final residual copy audit
- Run a strict scan for remaining visible hardcoded strings on dashboard/weather/devtools/profile/time surfaces.
- Migrate any remaining high-traffic literals through `DashboardCopy` + runtime keys.
- Keep fallback deterministic and readable.

2) Localization contracts
- Add stable `dashboard.*` keys for newly migrated literals.
- Expand:
  - `dashboard_localizations_runtime_test.dart`
  - `localization_seed_contract_test.dart`
- Add focused widget tests only when needed for critical migrated UI labels.

3) Pack E ambiguity v4
- Tune shared ranking on additional same-country collisions beyond current `portland|US` bonus.
- Preserve:
  - alias/direct-zone behavior (`EST/CST/PST`, timezone-ID search)
  - seeded home/destination precedence
  - selected-row single-marker contract
  - existing perf budget thresholds

4) Regression/perf guardrails
- Extend `city_picker_engine_test.dart` with deterministic dataset-backed assertions for new v4 families.
- Keep `city_picker_perf_budget_test.dart` green.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) residual literal audit + migrations
2) localization seed/runtime test expansion
3) ambiguity v4 tuning + regression additions
4) full gates
5) docs/handoff refresh

## Definition of done
- Residual high-traffic hardcoded copy is materially reduced again.
- Ambiguity behavior improves on additional same-country families without timezone/perf regressions.
- Repo green (`format`, `analyze`, `test`).
