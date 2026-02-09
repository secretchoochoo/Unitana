# Pack X Retro Baseline (XL-H2)

Date: 2026-02-09

## Scope reviewed
- Dashboard hero + mini-hero readability and information density.
- Tool modal consistency across Light/Dark themes.
- Matrix-style tools (Shoes/Paper/Mattress/Cups↔Grams).
- Weather + Time surface coherence (card hierarchy, graph legibility).
- Profile board usability and visual parity with dashboard cards.

## What is working well (keep)
1. Reality-first model (home/destination) is now visible in core surfaces (hero, weather cards, world time map, currency flows).
2. Matrix interaction model is predictable: tap row to focus, tap cell to copy, persisted selection into widgets.
3. Theme architecture is now token-driven enough to support systematic light/dark sweeps.
4. Timezone/city-picker correctness contracts are strong and well-tested.
5. Tool history/copy contracts are stable and performant on narrow devices.

## Highest-priority debt (P1)
1. Pack J closure debt: Weather tool still needs final product-positioning closure artifact and a concise in-tool explanation of panel intent.
2. Pack E closure debt: marquee style language is improved but not yet formally locked as a V2 spec (scene readability + spacing/token policy).
3. Pack L closure debt: some long-tail surfaces still rely on old contrast assumptions; parity is not fully closed.
4. Pack D debt: docs architecture still has overlap/noise between handoff/context/reference notes.

## Consistency + interaction gaps
1. Visual semantics drift:
- Some tools still mix old terminal-like wording with polished card language.
- Action affordances are consistent functionally, but explanatory copy quality varies by tool family.

2. Cross-tool guardrails:
- Unit-family mismatch states are handled, but not always proactively explained before error paths.

3. Micro-interaction policy:
- Flash/highlight/shake states exist but are not yet codified as a global interaction system policy.

## Performance risk shortlist
1. Large weather cards with embedded scene rendering and graphs should keep strict narrow-width smoke tests.
2. Matrix tables should avoid unbounded row expansion without lazy/virtualized constraints.
3. Profile grid edit mode animations should remain low-cost on older devices.

## Product direction: Price Compare
Goal: make it explicitly a dual-reality shopping comparator, not only a unit-normalizer.

Recommended model:
1. Context row: Active market currency + opposite market currency.
2. Product normalization row: per 100 unit + per 1 base unit (kg/L).
3. Opposite-market equivalents (using live FX when available).
4. Comparison verdict with normalized basket summary.

Guardrails:
- Keep Product A/B in same unit family while compare mode is enabled.
- Auto-align secondary unit family to avoid dead-end error states.

## Product direction: Baking + Cups↔Grams
Goal: split conversion vs density lookup responsibilities clearly.

Recommended split:
1. Baking tool:
- Unit conversion workflow (tsp/tbsp/cup/ml/L).
- Supports fractions and mixed fractions.

2. Cups↔Grams tool:
- Ingredient density lookup matrix (Cup/Tbsp/Tsp/Weight).
- Explicit approximate-language copy.

## Execution order after XL-H2
1. XL-I: Pack J closure + Pack E visual harmonization continuation.
2. XL-J: Pack E V2 spec lock artifact + remaining readability fixes.
3. XL-K: Pack L/K closure pass (theme parity + profile auto-select UX completion).
4. XL-L: Pack D docs architecture consolidation.
5. XL-M: Pack W opt-in lofi audio foundation.
