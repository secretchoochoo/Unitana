NEXT CHAT PROMPT — Pack H Localization Expansion (Phase 8)

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
Continue localization runtime migration for remaining high-traffic dashboard/tool text and harden ARB transition artifacts for repeatable review.

## Required outcomes
1) Runtime seam expansion
- Migrate the next focused batch of hardcoded microcopy from:
  - weather/devtools/status and settings-adjacent surfaces
  - any remaining dashboard/profile edge-state notices
  - remaining time/jet-lag helper leftovers (if any)
- Preserve current English UX behavior.

2) ARB-transition artifact hardening
- Keep using seeded stable keys.
- Extend seed export workflow/artifacts so key inventory remains deterministic and easy to diff/review.
- Do not do full translation rollout yet.

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
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (advance phase if scope shifts again)

## Definition of done
- Additional high-impact microcopy is runtime-localization backed.
- Seed/export and fallback behavior remain deterministic, test-guarded, and reviewable.
- Reliability and Pack N/M contracts remain green.
- Repo is green (`format`, `analyze`, `test`).
