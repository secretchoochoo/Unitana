# Places Hero V2

## Goal
Keep “dual reality” legible at a glance, without making clocks feel like an afterthought.

## Hero copy formats
### Header (centered)
Line 1:
- `<Primary> • <Secondary> +Nh`
- Example: `Lisbon • Denver +7h`

Line 2:
- `<PrimaryTime> <PrimaryTZ> • <SecondaryTime> <SecondaryTZ> (<Weekday> <Day> <Mon>)`
- Example: `01:03 WET • 6:03 PM MST (Fri 2 Jan)`

Notes:
- Date uses the **primary** place timezone.
- Both lines use scale-down, never ellipsis.

## Content blocks
### Left stack
- Temperature (primary) + converted secondary unit.
- Wind and Gust are shown as two lines with full units (up to 2 digits).
- Currency quick convert + small rate line.

### Right pill: Sunrise / Sunset
- Title centered: `Sunrise / Sunset`.
- Two lines:
  - `Sunrise <PrimaryTime> <TZ> • <SecondaryTime> <TZ>`
  - `Sunset <PrimaryTime> <TZ> • <SecondaryTime> <TZ>`
- Use scale-down to avoid wrapping.

## Style constraints
- Dracula theme palette; avoid adding new “hero art” that competes with the information.
- Keep layout stable across devices; prefer scale-down and fixed padding over overflow.
