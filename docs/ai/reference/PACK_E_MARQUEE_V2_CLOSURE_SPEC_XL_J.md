# PACK E Marquee V2 Closure Spec (XL-J)

## Scope
This document closes Pack E at the contract/spec layer by locking readability, spacing, animation, and acceptance rules for current Marquee V2 behavior.

## Readability Principles
- Prioritize city/time/value legibility over decorative scene detail.
- Keep scene contrast subordinate to text contrast in both dark and light themes.
- Avoid role-heavy labels (for example `Home`/`Destination`) where city-first labeling already disambiguates.
- On compact surfaces, degrade scene detail before reducing critical text readability.

## Layout and Token Rules
- Hero collapse contract remains unchanged: no changes that break pinned `SliverPersistentHeader` morph.
- Maintain canonical hero-key safety: preview surfaces must not create duplicate hero keys.
- Keep mini-scene previews in weather cards right-aligned and size-constrained to preserve city/temp/condition text.
- Use semantic theme tokens for border/text/surface color in both light and dark themes; avoid fixed Dracula literals on shared surfaces.

## Animation and Performance Constraints
- Scene animation must remain subtle and non-chaotic; no high-frequency blinking/strobing behavior.
- Particle density should favor readability (lower noise in rain/snow/fog/smoke families).
- Respect small-device rendering budgets already guarded by test/perf baselines.
- Goldens remain opt-in only.

## Small-Screen Acceptance Checks
- No render overflow in narrow weather/hero surfaces.
- Forecast and scene subcomponents remain tappable/readable on phone-width layouts.
- Selection and marker contracts stay deterministic (single marker where contract specifies one).
- Existing smoke/regression tests protecting compact weather and hero surfaces must remain green.

## Locked Non-Negotiables
- Collapsing pinned header morph preserved.
- Canonical hero key uniqueness preserved.
- Wizard previews keep `includeTestKeys=false`.
- Weather/hero visuals remain contract-driven by existing scene taxonomy.

## Deferred / Out of Scope
- Location-specific scene families (city/rural/beach variants).
- A full art-asset replacement pipeline.
- New marquee interaction mechanics beyond current readable V2 behavior.

