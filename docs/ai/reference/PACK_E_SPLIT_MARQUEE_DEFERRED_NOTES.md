# Pack E Deferred Note: Split Marquee (Weather Sheet Only)

Date: 2026-02-07

## Scope correction
- Split marquee should **not** be applied to the dashboard hero marquee.
- Split marquee exploration is deferred for the **Weather sheet middle bridge area** only (between destination/home weather tiles).

## Why deferred
- The desired weather-sheet version should represent each city's weather context, not just city labels.
- We are planning broader animation upgrades, so this should be designed with the upcoming scene system work instead of patching current dashboard hero behavior.

## Reusable implementation ideas from reverted prototype
- lightweight top overlay chips with flag + city text
- deterministic left/right mapping with swap-safe ordering
- compact, contrast-safe chip treatment tuned for Dracula palette

## Future implementation requirements (weather sheet)
- Render split visuals in the weather sheet middle bridge, not in dashboard hero.
- Ensure each side reflects that city's weather scene/condition state.
- Keep text and icon readability stable across small-phone widths.
- Preserve existing hero contracts and avoid cross-surface regressions.
