NEXT CHAT PROMPT — Pack H Localization Bootstrap (Phase 1.5)

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
Expand localization-ready copy seams with minimal churn, then prepare the first ARB-ready mapping pass for high-traffic dashboard/tool text.

## Required outcomes
1) Pack H seam expansion
- Continue extracting hardcoded user-facing strings from high-traffic dashboard/tool surfaces into centralized copy helpers.
- Keep behavior and visual layout unchanged.
- Prioritize strings that currently appear in tests and stale/error states.

2) ARB-ready key mapping prep
- Define a deterministic key naming scheme for extracted copy (without full translation rollout yet).
- Add a lightweight mapping scaffold (or TODO contract) that makes the future ARB migration mostly mechanical.

3) Reliability/Time regression lock
- Re-verify stale/retry/freshness copy contracts.
- Keep Pack N/M regressions green:
  - city-first picker + advanced fallback
  - overlap reveal contract
  - action-row alignment

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (if scope shifts again)

## Definition of done
- More user-facing copy is centralized and localization-ready.
- ARB migration path is clearer with stable keys/scaffold.
- Reliability and Pack N/M contracts remain green.
- Repo is green (`format`, `analyze`, `test`).
