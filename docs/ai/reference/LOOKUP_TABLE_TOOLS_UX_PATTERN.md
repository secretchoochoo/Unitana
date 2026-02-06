# Lookup Table Tools UX Pattern (Pack F)

## Core point
You are correct: `Shoe Sizes`, `Clothing Sizes`, `Paper Sizes` (and optionally `Mattress Sizes`) are not the same UX as numeric converters.

Numeric converters = value-in, unit-out math.  
Lookup tools = region/system mapping + equivalence table + fit/variance notes.

## Tool classes
1) `Converter tools` (existing model)
- Input field
- From/To units
- Convert action
- History

2) `Lookup table tools` (new model)
- No freeform numeric input by default
- Two selectors (Source system, Target system)
- One size/category selector
- Immediate mapped result row
- Optional “Show chart” section for neighboring equivalents

## Recommended modal anatomy (lookup type)
1. Header
- Tool icon + title

2. Selector row
- `From system` pill (e.g., US Men, EU, UK, JP cm)
- `To system` pill
- Swap action

3. Primary selector
- Size/category picker (e.g., US 9, A4, Men M)

4. Result card
- `US 9 → EU 42`
- Secondary confidence text (e.g., “Brand fit varies; verify brand chart”)

5. Optional mini table
- Nearby rows (one size down/up)
- Scroll-safe compact matrix

## Data model guidance
- Keep static datasets local and versioned in repo.
- Include explicit `confidence` and `notes` fields for fuzzy mappings.
- Prefer exact dimensions where possible (paper, mattress), and “approximate” tags where mapping is non-linear (clothing).

## Tool-specific guidance
### Shoe sizes
- Systems: US Men, US Women, UK, EU, JP(cm)
- Keep deterministic mapping table.

### Clothing sizes
- Split by category at minimum: tops, bottoms.
- Regions: US, EU, UK, JP.
- Mark mappings as approximate.

### Paper sizes
- Systems: ISO A/B, US Letter/Legal/Tabloid.
- Best rendered as dimensions + nearest equivalent.

### Mattress sizes (optional, later)
- It can make sense as a lookup/reference tool, not converter-first.
- Region-based nomenclature is inconsistent; require “approximate equivalent” labels.
- Recommend ship later than shoe/paper unless strong user demand.

## Sequencing recommendation
1. Phase 1
- Implement `paper_sizes` on lookup pattern first (tight deterministic dataset, lower ambiguity).
2. Phase 2
- Implement `shoe_sizes` on same shell (system presets + common row mapping).
3. Phase 3
- Implement `mattress_sizes` with regional caveat notes.
4. Phase 4 (optional)
- Evaluate `clothing_sizes` separately due high fit/brand variance; keep deferred unless quality bar is met.

## Pack F acceptance criteria addendum
- At least one lookup-table tool ships on the dedicated lookup UX shell.
- Do not force lookup tools into numeric converter layout unless strictly temporary.
