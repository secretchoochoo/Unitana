# Current handoff (canonical)

## Status
- Repo is green at merge gates: `dart format .`, `flutter analyze`, `flutter test`.
- Sev1 (P1.11 Hero) is closed.
- Places Hero V2 is stable with Option 3 (two-bay layout).

## Sev1 closure summary
### What was failing
- Widget tests used pathological constraints that yielded tiny inner boxes (observed: `w=124, h=26` after padding). Any multi-line `Column` inside this space overflowed.
- A separate contract test required the hero left rail to be readable, including a minimum width target (>=150 on phone surface). Flex splits were not guaranteeing it.

### What fixed it
- Micro-first gating for Env and Currency. Mode selection happens before any multi-line `Column` is constructed.
- Explicit width allocation with minimums, rather than relying on flexible children.
- Stable keys kept intact, including a specific contract: `hero_currency_primary_line` always points to a `Text` widget.

## Contracts (non-negotiable)
- Keep repo green: `dart format .`, `flutter analyze`, `flutter test`.
- Stable keys everywhere (tests and persistence depend on them).
- Patch workflow: changed-files-only zip, paths preserved.
- Exactly one refresh label. It lives under the city header (header-only contract). There is no refresh label under the hero marquee.

## Places Hero V2 contracts
### Region map (phone surface)
- Top-left: temperature.
- Top-right: marquee.
- Bottom-left: Env (AQI or Pollen) and Currency.
- Bottom-right: Sunrise and Sunset, with Wind and Gust toggled in the same pill.

### Micro behavior
- Env and Currency must degrade to a single-line micro layout under tight constraints. The micro trigger must occur before building any multi-line `Column`.

## Current UX issue
The hero is stable but the top row can feel visually compressed. The next work is no longer about preventing overflows. It is about visual proportions:
- Currency, Env (AQI/Pollen), and Sunrise/Sunset should look flatter vertically to free space for the temperature and marquee.
- Once space is available, the temperature should be vertically centered with the marquee row.

## Latest slice completed
### P1.13 Hero Lane Geometry and Visual Compaction
Status: complete.

What changed:
- Marquee condition label duplication removed (single widget-layer label).
- Marquee slot is allowed to grow within the top band (capped) instead of being hard-limited to 84dp.
- Top row stretches and centers lane contents so temperature and marquee align vertically when there is height to do so.
- Env, Currency, and Sunrise/Sunset padding tightened to reduce perceived vertical weight.

## Next slice (single objective)
### P1.14 Hero polish and proportional tuning
Goal: tune the hero proportions to match the red-box intent more closely, without re-introducing test fragility.

Focus:
- Rebalance left stack vs Sunrise/Sunset footprint (horizontal and vertical) so the bottom band reads as two intentional lanes.
- Ensure currency and Env pills can be slightly narrower and typography can scale down in non-compact mode (as long as keys and micro rules remain authoritative).
- Verify iconography consistency for currency and Env in both normal and micro modes.

Definition of Done:
- Tests stay green.
- No RenderFlex overflows in the hero under pathological constraints.
- Marquee tile is not visually “capsuled” on phone surfaces and the condition text remains legible.
