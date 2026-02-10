NEXT CHAT PROMPT — XL-L: Pack D Docs Architecture Consolidation

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/PACK_L_THEME_PARITY_CLOSURE_SPEC_XL_K.md`
4) `docs/ai/reference/PACK_K_PROFILE_AUTOSUGGEST_CLOSURE_SPEC_XL_K.md`
5) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

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
Complete Pack D by consolidating docs architecture and reducing overlap/staleness across handoff/context/reference prompt artifacts.

## Required outcomes
1) Docs IA consolidation
- Identify overlapping/stale docs under `docs/ai/reference` and related handoff/prompt surfaces.
- Produce a canonical map of what is source-of-truth vs archival/supporting docs.
- Prune or mark superseded docs where safe.

2) Consistency pass
- Ensure status language across handoff/context/prompt is aligned.
- Ensure backlog pack states match shipped artifacts.

3) Minimal code changes only if required by documentation accuracy
- Avoid feature churn.

4) Preserve existing contracts
- No regressions to runtime behavior.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) inventory and classification
2) consolidation/pruning updates
3) context/handoff/prompt sync
4) full gates

## Definition of done
- Pack D docs architecture debt materially reduced.
- Canonical doc ownership is explicit.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-M (Pack W optional lofi audio spike, off by default).
- Following slice: XL-N (Pack I tutorial overlay near-finalization pass).
