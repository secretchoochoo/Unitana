NEXT CHAT PROMPT — Pack E 6h/6i + Pack H Follow-up (Post-Overnight)

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `app/unitana/lib/features/dashboard/models/time_zone_catalog.dart`
4) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
5) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
6) `app/unitana/lib/l10n/localization_seed.dart`
7) `app/unitana/lib/l10n/dashboard_localizations.dart`
8) `app/unitana/test/time_zone_catalog_test.dart`
9) `app/unitana/test/time_tool_modal_interaction_test.dart`
10) `app/unitana/test/dashboard_localizations_runtime_test.dart`

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
Continue the city-picker quality push after 6e/6f/6g and extend Pack H localization migration with deterministic fallback coverage.

## Required outcomes
1) Pack E 6h ranking calibration
- Tune mainstream ranking weights using broader city-name ambiguity cases (same-name cities across countries/regions).
- Keep profile-seeded home/destination precedence stable.
- Preserve long-tail discoverability via search.

2) Pack E 6i picker clarity edge-case pass
- Further reduce duplicate-feeling rows for same-name cities while keeping valid alternatives reachable.
- Add subtle disambiguation improvements (country/region context) without increasing row clutter.
- Preserve alias/advanced timezone behavior (`EST`, `CST`, `PST`, timezone-id search).

3) Pack E regression expansion
- Add tests for:
  - same-name city disambiguation ordering
  - selected-row marker contract under mixed city+zone results
  - no regression in Time/Jet Lag swap + seeding + conversion history behavior

4) Pack H follow-up migration
- Migrate additional residual high-traffic hardcoded copy in dashboard/weather/devtools/profile surfaces still bypassing `DashboardCopy`.
- Add stable `dashboard.*` seed keys for new strings.
- Keep runtime fallback deterministic and readable for missing keys.

5) Pack H tests/fallback hardening
- Expand localization runtime tests for newly migrated keys/placeholders.
- Add contract assertions for any new weather/devtools/profile strings moved to runtime localization.

6) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (advance again)

## Suggested execution order
1) Ranking calibration (6h)
2) Picker clarity edge cases (6i)
3) Regression tests
4) Pack H migration + localization tests
5) Full gates
6) Docs/handoff

## Definition of done
- City picker remains mainstream-first but cleaner on edge cases.
- Power-user timezone path and alias behavior stay intact.
- Additional high-traffic UI strings are runtime-localized with stable fallback behavior.
- Repo is green (`format`, `analyze`, `test`).
