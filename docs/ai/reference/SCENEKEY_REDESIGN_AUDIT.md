# SceneKey redesign audit (marquee scenes)

## Purpose
A working checklist for making Weather scenes visually distinct in the Hero marquee at phone sizes.

This is a design and implementation tracker; it should stay small and action-oriented.

## Non-negotiable constraints
- Paint-only (CustomPaint), no images, no text.
- Test-safe rendering (no infinite animation loops that block `pumpAndSettle`).
- Keep the Places Hero V2 layout rules unchanged while iterating on scenes.
- SceneKeys remain stable. Improve the art, not the ids.

## Confusion clusters (what users will mix up)
1) **Cloud families**: PARTLY_CLOUDY vs CLOUDY vs OVERCAST
2) **Wet families**: DRIZZLE vs RAIN_LIGHT vs RAIN_MODERATE vs RAIN_HEAVY
3) **Cold wet**: FREEZING_RAIN vs SLEET vs ICE_PELLETS
4) **Low visibility**: MIST vs FOG (and future HAZE_DUST)
5) **Extreme**: BLIZZARD vs BLOWING_SNOW

## Priority order (small slices)
### Slice A
- PARTLY_CLOUDY: single cloud “bite” that clearly occludes sun/moon.
- OVERCAST: single heavy ceiling with uneven bottom edge; no visible sun/moon.

### Slice B
- DRIZZLE: sparse short ticks (not long streaks).
- RAIN_HEAVY: dense long streaks + rare 1–2 frame gust slash.

### Slice C
- ICE_PELLETS: short bright ticks + occasional 1px bounce at ground.
- SLEET: consistent diagonal slush lines plus a few flakes.

### Slice D
- MIST: two soft horizon bands.
- FOG: foreground fog patch that pulses (2-frame).

## Validation checklist (per slice)
- On a 320×568 emulator, does the SceneKey read in one second without focusing?
- Does the scene remain legible in both day and night modes?
- Does the motion loop stay low amplitude and non-distracting?
- Are we reusing Paints and avoiding per-frame allocations?

## Notes
- Keep palette Dracula-adjacent, but cue differences via geometry first.
- Avoid emergency motifs for smoke and storms. Evocative is fine; alarming is not.
