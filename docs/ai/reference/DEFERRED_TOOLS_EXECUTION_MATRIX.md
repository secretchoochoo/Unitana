# Deferred Tools Execution Matrix

## Purpose
Convert current deferred-tool rationale into executable delivery slices with explicit prerequisites.

## Current deferred tools

| Tool ID | UI Label | Why Deferred (current contract) | Needed to Activate | Proposed Slice |
|---|---|---|---|---|
| `clothing_sizes` | Clothing Sizes | High brand variance remains unresolved for deterministic fit mapping | Region/category matrix + confidence bands + explicit fit uncertainty policy + acceptance tests | Pack F final decision (defer lock) |

## Newly activated in this slice

- `energy` (`Calories / Energy`) is now enabled as a configurable converter tool (`kcal ↔ kJ`) with picker activation and modal conversion coverage.
- `pace` is now enabled as a configurable converter tool (`min/km ↔ min/mi`) with deterministic pace parsing (`mm:ss`, `XmYs`, decimal) and modal conversion coverage.
- `cups_grams_estimates` is now enabled as a lookup-style estimates surface with a core ingredient matrix and explicit approximation notes.
- `hydration` is now enabled as a dedicated non-medical helper surface with explicit safety/guardrail copy and deterministic intake estimate math.

## Existing planning/artifacts

- Architecture/defer reasons in code: `app/unitana/lib/features/dashboard/models/tool_registry.dart`
- Pack-F sequencing: `docs/ai/reference/PACK_F_MEGA_SLICE_TOOLS_EXPANSION_PLAN.md`
- Lookup-table UX baseline: `docs/ai/reference/LOOKUP_TABLE_TOOLS_UX_PATTERN.md`
- Historical audit notes: `docs/ai/reference/TOOLS_CATALOG_AUDIT_2026-01-06.md`

## Final decision

1. `clothing_sizes` remains deferred for now.
2. Activation is blocked until all acceptance criteria are implemented:
   - region + category matrix with explicit row provenance,
   - confidence bands shown in-result (not hidden in footnotes),
   - explicit fit uncertainty policy copy for every mapped row,
   - deterministic interaction tests for picker + modal + uncertainty rendering.

Rationale: ship highest confidence and lowest safety/model risk first, then progress to tools that require stronger domain policy and dataset quality controls.

## Definition of readiness for each deferred tool

Before moving any deferred tool to enabled, require:

1. Canonical input/output contract documented in `docs/ai/reference`.
2. Deterministic conversion/lookup logic test coverage.
3. Picker + modal interaction tests.
4. Clear user-facing copy for approximations/uncertainty.
5. Defer reason removed/replaced in `ToolRegistry`.
