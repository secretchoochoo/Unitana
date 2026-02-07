NEXT CHAT PROMPT — Pack H Localization Expansion (Phase 3)

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
Expand runtime localization wiring to remaining high-traffic dashboard/tool microcopy while preparing for ARB/delegate rollout.

## Required outcomes
1) Pack H runtime seam expansion
- Migrate additional hardcoded dashboard/tool strings to localization-backed copy helpers.
- Prioritize helper/instruction lines, stale/error states, and confirmation/status microcopy.
- Preserve current English wording and UX behavior.

2) ARB/delegate readiness prep
- Keep using seeded stable keys.
- Add minimal scaffolding notes/code seams needed for future Flutter localization delegate/ARB generation integration.
- Do not attempt full translation rollout yet.

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
- More high-impact dashboard/tool microcopy is runtime-localization backed.
- Fallback and placeholder behavior remains deterministic and test-guarded.
- Reliability and Pack N/M contracts remain green.
- Repo is green (`format`, `analyze`, `test`).
