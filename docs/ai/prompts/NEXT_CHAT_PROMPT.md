NEXT CHAT PROMPT — Pack B/C Reliability Closure + Localization Bootstrap Prep

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
Close remaining reliability visibility gaps (especially stale/cache/retry clarity) across live-data tools, then prep the codebase for Pack H localization with minimal churn.

## Required outcomes
1) Reliability closure follow-up (Pack B/C)
- Audit current stale/cache/retry UI states for weather, currency, and any remaining live surfaces.
- Normalize user-facing freshness/status phrasing where inconsistent.
- Add any missing deterministic test coverage for stale/retry edge paths.

2) Time/Jet Lag regression lock
- Ensure recent Pack N/M behavior remains guarded:
  - city-first picker + advanced timezone fallback
  - call-window overlap reveal behavior
  - action-row alignment contract

3) Localization bootstrap prep (Pack H readiness)
- Identify and isolate hardcoded user strings on key dashboard/tool surfaces into a localization-ready structure.
- Do not attempt full translation rollout yet; focus on clean extraction seams and low-risk migration prep.

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (if scope shifts again)

## Definition of done
- Reliability/status messaging is consistent and test-guarded on in-scope live surfaces.
- Pack N/M regressions remain green.
- Localization bootstrap prep is in place without UI regressions.
- Repo is green (`format`, `analyze`, `test`).
