NEXT CHAT PROMPT — XL-W: Clothing Sizes Usage-Quality Evaluation and Scope Decision

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/REFERENCE_INDEX.md`
4) `docs/ai/reference/CLOTHING_SIZES_DECISION_PACK_XL_U.md`
5) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
6) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
7) `app/unitana/lib/features/dashboard/models/tool_registry.dart`
8) `app/unitana/lib/features/dashboard/models/tool_lens_map.dart`
9) `app/unitana/test/clothing_sizes_matrix_interaction_test.dart`

## Core operating rules
- Work directly in-repo (Codex-first).
- If runtime or tests are changed, keep repo green:
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- Preserve non-negotiables:
  - collapsing pinned `SliverPersistentHeader` morph
  - canonical hero key uniqueness
  - wizard previews with `includeTestKeys=false`
  - goldens opt-in only

## Mission
Run an XL-level quality pass on the newly activated `clothing_sizes` tool and decide whether to expand data scope now or defer additional expansion.

## Required outcomes
1) Usage-quality audit
- Validate matrix readability and copy behavior on compact surfaces.
- Validate disclaimer clarity and non-predictive language consistency.
- Identify any row-label or category wording that could imply fit certainty.

2) Scope decision
- Decide one path with explicit rationale:
  - expand categories/rows now, or
  - keep current v1 scope and defer expansion.
- If expand: define exact row additions and guardrails.
- If defer: define acceptance gates and trigger signals.

3) Contract hardening
- Add/adjust deterministic tests for any changed behavior.
- Keep missing mappings explicit (`—`) where data is unknown.

4) Docs refresh
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Definition of done
- XL-W decision is explicit and documented.
- Any runtime changes are regression-tested.
- Repo remains green.

## Forward plan after this slice
- XL-X: tool-category and unit-coverage audit + taxonomy cleanup across picker/search and matrix tools.
