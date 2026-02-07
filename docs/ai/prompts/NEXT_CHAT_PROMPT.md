NEXT CHAT PROMPT — Pack H Localization Pilot Wiring (Phase 2)

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
Start real localization runtime wiring on a low-risk pilot subset using the existing key seed and centralized copy seams.

## Required outcomes
1) Pack H pilot runtime seam
- Introduce minimal localization provider/plumbing suitable for gradual rollout.
- Wire a small dashboard/tool subset to runtime key lookups (not full app migration yet).
- Keep current English copy as default/fallback behavior.

2) Seed-to-runtime mapping contract
- Reuse `app/unitana/lib/l10n/localization_seed.dart` keys.
- Ensure placeholder values are supported for seeded templates (for example `{age}`).
- Add deterministic tests that lock fallback behavior and key resolution.

3) Regression lock
- Keep reliability copy and stale/retry contracts stable.
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
- Localization runtime pilot exists and is test-guarded.
- Existing UX remains unchanged with English fallback.
- Pack N/M and reliability contracts remain green.
- Repo is green (`format`, `analyze`, `test`).
