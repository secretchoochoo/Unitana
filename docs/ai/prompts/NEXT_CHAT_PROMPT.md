NEXT CHAT PROMPT — Pack H Taxonomy Localization + Pack E Ambiguity V5

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/CITY_PICKER_PERF_BUDGET.md`
4) `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart`
5) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
6) `app/unitana/lib/l10n/localization_seed.dart`
7) `app/unitana/lib/l10n/localization_seed_es.dart`
8) `app/unitana/lib/l10n/dashboard_localizations.dart`
9) `app/unitana/lib/data/city_picker_engine.dart`
10) `app/unitana/lib/data/city_picker_ranking.dart`
11) `app/unitana/test/city_picker_engine_test.dart`

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
Advance Pack H by localizing remaining picker/lens taxonomy copy, and advance Pack E with ambiguity v5 data-driven city prominence tuning beyond static overrides.

## Required outcomes
1) Pack H taxonomy localization
- Audit remaining hardcoded high-traffic lens/tool taxonomy strings (especially in `activity_lenses.dart` and picker section labels).
- Migrate selected surfaces through runtime localization seam.
- Keep fallback deterministic and readable.

2) Pack H ARB bridge follow-up
- Ensure `app_en.arb` / `app_es.arb` bridge files stay in sync with new keys.
- Expand runtime tests for Spanish partial-key behavior where new keys are added.

3) Pack E ambiguity v5
- Add data-driven prominence signal(s) for exact-city collisions (not only static zone maps).
- Preserve:
  - alias/direct-zone behavior (`EST/CST/PST`, timezone-ID search)
  - seeded home/destination precedence
  - selected-row single-marker contract
  - perf budget thresholds

4) Regression/perf guardrails
- Expand dataset-backed ordering contracts in `city_picker_engine_test.dart`.
- Keep `city_picker_perf_budget_test.dart` green.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) taxonomy residual audit + migrations
2) ARB bridge/key sync + runtime tests
3) ambiguity v5 tuning + regression additions
4) full gates
5) docs/handoff refresh

## Definition of done
- Remaining high-traffic taxonomy literals are reduced.
- Ambiguity behavior improves with data-driven prominence signals, no alias/perf regressions.
- Repo green (`format`, `analyze`, `test`).
