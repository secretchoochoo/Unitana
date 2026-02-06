# Deferred Tools Execution Matrix

## Purpose
Convert current deferred-tool rationale into executable delivery slices with explicit prerequisites.

## Current deferred tools

| Tool ID | UI Label | Why Deferred (current contract) | Needed to Activate | Proposed Slice |
|---|---|---|---|---|
| `cups_grams_estimates` | Cups ↔ Grams Estimates | Ingredient density quality is unresolved | Curated ingredient density dataset + food taxonomy keys + confidence/approximation labeling | Slice A (data contract + MVP table for core baking ingredients) |
| `pace` | Pace | Missing training/race context model | Pace domain model (distance/time targets, split defaults, run/walk modes) + context presets | Slice B (pace converter + split calculator MVP) |
| `hydration` | Hydration | Health-safe policy and personalization not defined | Safety policy guardrails, locale/unit defaults, optional personalization inputs | Slice C (non-medical intake helper with explicit disclaimers) |
| `energy` | Calories / Energy | Nutrition contract and unit standards incomplete | Canonical energy unit policy (kcal/kJ), food-label semantics, rounding/display rules | Slice D (strict energy unit converter first) |
| `tax_vat_helper` | Sales Tax / VAT Helper | Country/region tax disclosure contract missing | Tax mode model (`inclusive` vs `add-on`), jurisdiction defaults, disclosure copy | Slice F (mode-toggle + transparent math breakdown) |
| `unit_price_helper` | Unit Price Helper | Packaging normalization not standardized | Quantity normalization model (`per 100g`, `per kg`, `per oz`, etc.) + packaging parser | Slice G (manual quantity input + normalized compare card) |
| `clothing_sizes` | Clothing Sizes | Brand variance too high for reliable mapping | Region/category matrix + uncertainty policy + confidence badges | Slice H (reference-only launch or remain deferred) |

## Existing planning/artifacts

- Architecture/defer reasons in code: `app/unitana/lib/features/dashboard/models/tool_registry.dart`
- Pack-F sequencing: `docs/ai/reference/PACK_F_MEGA_SLICE_TOOLS_EXPANSION_PLAN.md`
- Lookup-table UX baseline: `docs/ai/reference/LOOKUP_TABLE_TOOLS_UX_PATTERN.md`
- Historical audit notes: `docs/ai/reference/TOOLS_CATALOG_AUDIT_2026-01-06.md`

## Recommended activation order

1. `unit_price_helper`
2. `tax_vat_helper`
3. `energy`
4. `pace`
5. `cups_grams_estimates`
6. `hydration`
7. `clothing_sizes` (only if quality bar is met)

Rationale: ship highest confidence and lowest safety/model risk first, then progress to tools that require stronger domain policy and dataset quality controls.

## Definition of readiness for each deferred tool

Before moving any deferred tool to enabled, require:

1. Canonical input/output contract documented in `docs/ai/reference`.
2. Deterministic conversion/lookup logic test coverage.
3. Picker + modal interaction tests.
4. Clear user-facing copy for approximations/uncertainty.
5. Defer reason removed/replaced in `ToolRegistry`.
