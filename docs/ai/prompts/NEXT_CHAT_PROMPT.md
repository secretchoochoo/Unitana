NEXT CHAT PROMPT — Pack H Localization Expansion (Phase 2.5)

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/TIME_TOOL_REPURPOSE_PLAN.md`
4) `docs/ai/reference/JET_LAG_REDESIGN_SLICE_SPEC.md`

Then execute using this contract.

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
Expand runtime localization coverage from the pilot subset while preserving current UX and reliability contracts.

## Required outcomes
1) Pack H runtime seam expansion
- Continue migrating high-traffic hardcoded strings to `DashboardCopy` + runtime lookup (`DashboardLocalizations`).
- Prioritize dashboard/tool modal labels, tooltips, stale/error/fallback states, and instructional helper text.
- Keep English behavior as fallback.

2) Localization plumbing hardening
- Keep seeded key usage deterministic (`localization_seed.dart`).
- Add/adjust tests to guard key lookup fallback and migrated-surface behavior.
- Avoid full translation rollout; keep scope to migration-safe wiring.

3) Regression lock
- Keep Pack B/C reliability messaging stable.
- Keep Pack N/M behavior green:
  - city-first picker + advanced fallback
  - overlap reveal contract
  - action-row alignment

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (if scope shifts again)

## Definition of done
- More user-facing surfaces run through runtime localization lookup.
- Localization fallback behavior remains deterministic and test-guarded.
- Reliability and Pack N/M contracts remain green.
- Repo is green (`format`, `analyze`, `test`).
