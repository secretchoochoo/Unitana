NEXT CHAT PROMPT — Pack H Localization Expansion (Phase 5)

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
Continue runtime localization migration on remaining high-traffic dashboard/tool microcopy and prepare the next ARB-compatible transition seams.

## Required outcomes
1) Runtime seam expansion
- Migrate another focused batch of hardcoded dashboard/tool microcopy to localization-backed copy helpers.
- Prioritize helper text in active calculator/tool bodies (tip/tax/unit-price/lookup/time guidance), notices, and confirmations.
- Preserve current English UX wording and behavior.

2) ARB transition prep
- Keep seeded key usage deterministic.
- Add low-risk scaffolding artifacts for future ARB/key export workflow (without enabling full translation rollout).

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
- Additional high-traffic microcopy is runtime-localization backed.
- Delegate/fallback behavior remains deterministic and test-guarded.
- Reliability and Pack N/M contracts remain green.
- Repo is green (`format`, `analyze`, `test`).
