NEXT CHAT PROMPT — XL-V: Clothing Sizes Reference-Only Implementation Spike

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/REFERENCE_INDEX.md`
4) `docs/ai/reference/CLOTHING_SIZES_DECISION_PACK_XL_U.md`
5) `docs/ai/reference/LOOKUP_TABLE_TOOLS_UX_PATTERN.md`
6) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
7) `app/unitana/lib/features/dashboard/models/tool_registry.dart`
8) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
9) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`

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
Implement the first shippable `clothing_sizes` surface as a reference-only matrix tool (no brand-fit recommendation).

## Required outcomes
1) Reference-only activation
- Enable `clothing_sizes` in registry and picker.
- Implement a deterministic matrix/lookup surface with scoped categories + regions from XL-U.

2) Uncertainty and liability copy
- Add explicit, always-visible uncertainty/disclaimer copy in tool modal.
- Keep language factual and non-predictive.

3) Deterministic behavior contracts
- Copy/tap row behavior mirrors other matrix tools.
- Missing mappings render explicitly (`—`) rather than inferred.

4) Regression guardrails
- Add tests for:
  - picker activation/open path
  - matrix rendering and copy behavior
  - disclaimer visibility
  - missing-mapping row behavior

5) Docs refresh
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) data model + matrix rows (minimal scoped v1)
2) modal UI + disclaimer
3) picker enablement wiring
4) tests
5) docs refresh

## Definition of done
- `clothing_sizes` is enabled as a reference-only tool with explicit uncertainty guardrails.
- Deterministic behavior is regression-tested.
- Repo remains green.

## Forward plan after this slice
- XL-W: Evaluate v1 usage quality and decide expand/defer for additional categories/regions.
