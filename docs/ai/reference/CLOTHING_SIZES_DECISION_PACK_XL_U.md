# XL-U: Clothing Sizes Decision Pack

## Purpose
Finalize whether `clothing_sizes` should be shipped, deferred, or removed, and lock a practical execution contract that avoids misleading fit guidance.

## Decision Summary
- **Decision:** Keep `clothing_sizes` in roadmap, but ship only as a **Reference** tool (not predictive fit, not brand-fit recommender).
- **Why:** There is still clear user value for cross-region label translation, but brand/cut variance is too high for deterministic “this will fit you” claims.
- **What not to do in v1:** No brand-level mappings, no confidence theater, no recommendation engine.

## Option Review

### Option A: Remove `clothing_sizes`
- **Pros:** Eliminates fit-liability risk and maintenance burden.
- **Cons:** Leaves a frequent travel/retail use case unserved; users will still need this elsewhere.
- **Decision:** Rejected.

### Option B: Keep as global reference matrix (recommended)
- **Pros:** High utility with bounded risk; deterministic, testable lookup behavior.
- **Cons:** Must communicate uncertainty clearly; cannot promise fit outcome.
- **Decision:** Accepted.

### Option C: Keep with brand mappings
- **Pros:** Potentially more practical outcomes for some users.
- **Cons:** High churn, legal/accuracy risk, regional inconsistency, heavy data maintenance.
- **Decision:** Deferred indefinitely (out of v1 scope).

## v1 Product Scope (If Shipped)

### Regions
- `US`
- `EU`
- `UK`
- `JP`

### Categories
- `Women Tops`
- `Women Bottoms`
- `Men Tops`
- `Men Bottoms`
- `Outerwear (Unisex)`

### Explicitly out of v1
- Brand-specific mappings
- Kids/baby segmentation
- Dress sizing complexity by fit style
- Tailored-fit recommendation

## UX Contract
- Tool is presented as **Reference** lookup, not conversion certainty.
- Row-level uncertainty copy is always visible, not hidden.
- Standard disclaimer copy is shown once per modal view:
  - “Sizes vary by brand and cut. Use this as a reference and check retailer size charts.”
- Copy/tap behavior remains deterministic and consistent with other matrix tools.

## Data Contract (v1)
- Canonical key: `region + category + reference_label`.
- Each row must include:
  - source labels for all in-scope regions
  - optional note (`regular fit`, `approx`, etc.)
  - provenance/source marker (`public standard`, `retailer aggregate`, etc.)
- Missing mappings are explicit (`—`) rather than inferred.

## Activation Gate (Must pass all)
1. Region/category matrix finalized with deterministic row coverage.
2. Uncertainty/disclaimer copy approved and wired in modal.
3. Picker + modal + copy-to-clipboard regressions added.
4. No brand-level implication in labels/copy.
5. Fallback behavior for missing mapping rows verified.

## Recommendation For Next Slice
- **XL-V:** `clothing_sizes` v1 reference-only implementation spike
  - Build minimal matrix model (regions/categories above).
  - Implement modal shell + row copy behavior.
  - Add uncertainty/disclaimer presentation contracts.
  - Add tests and keep repo green.
