# Places Hero V2 spec (canonical)

This document defines the contract for `PlacesHeroV2`.

Source file:
- `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`

If you change any behavior covered here, you must update this spec and any affected tests.

## Intent

- Clocks are the highest priority content.
- Layout stability is a feature. The hero should not “jump” when we add future visual life.
- All hero text that matters stays one line visible (scale down, no ellipsis).

## Layout contract

### Container

- Hero is a single rounded card container.
- Padding, gaps, and right-rail width are responsive but deterministic:
  - **Compact** when `maxHeight < 280` or `maxWidth < 320`.
  - `pad`: 10 (compact), 14 (default)
  - `gap`: 6 (compact), 10 (default)
  - `right rail width`: 160 (compact), 196 (default)

### Internal structure

Top to bottom:

1. **Reality toggle (segmented)**
2. **Clocks header (two lines, centered)**
3. **Main row**
   - Left: temperature + wind/gust + currency
   - Right: reserved marquee slot (empty for now) + Sunrise/Sunset pill anchored at the bottom

The clocks header and main row are vertically stable; adding future elements must not push these blocks around.

## Stable keys

These keys are treated as contract because tests and/or persistence rely on them:

- `places_hero_v2`
- `places_hero_segment_destination`
- `places_hero_segment_home`
- `hero_primary_temp`
- `hero_secondary_temp`
- `hero_wind_line`
- `hero_gust_line`
- `hero_sun_pill`
- `hero_sunrise_row`
- `hero_sunset_row`
- `hero_rate_line`

Do not rename without updating tests.


## Reality toggle

- Two segments: **Destination** (left) and **Home** (right).
- The left segment label is left-aligned; the right segment label is right-aligned.
- Each label is one line, ellipsized if necessary.
- Selected segment uses a subtle filled background (no hard borders that change layout).

## Clocks header

### Alignment and typography

- Two lines, centered.
- Both lines:
  - Render as **single-line visible**.
  - Use scale-down (FittedBox + `BoxFit.scaleDown`), not truncation.

Typography intent (not pixel-perfect, but hierarchy is contract):
- **Line 1 (context line)** uses a heavier headline style (bold, high contrast).
- **Line 2 (time line)** uses a slightly smaller style and a muted color.

### Exact formatting

When both places are present:

Line 1:

`<PrimaryCity> • <SecondaryCity> <DeltaLabel>`

Example:

`Lisbon • Denver +7h`

Rules:
- Separator is a bullet: `•`.
- `<DeltaLabel>` uses the format produced by `TimezoneUtils.formatDeltaLabel`:
  - `+7h`, `-1h`, `0h`.

Line 2:

`<PrimaryClock> <PrimaryAbbr> • <SecondaryClock> <SecondaryAbbr> (<Weekday> <Day> <Mon>)`

Example:

`01:03 WET • 6:03 PM MST (Fri 2 Jan)`

Rules:
- Separator is a bullet: `•`.
- Clock formatting respects each place’s `use24h` setting.
- Date uses the primary place date in `Mon/Tue/...` + day + month abbreviation form.

Fallbacks:
- If only the primary place exists: line 1 is `<PrimaryCity>`, line 2 is `<PrimaryClock> <PrimaryAbbr>`.
- If nothing is selected: line 1 is `No place selected`, line 2 is `--`.

## Left block: wind and gust

Wind and gust are readability-first.

Contract:
- **Two separate lines** (never merged).
- The labels **Wind** and **Gust** are visually emphasized (higher contrast and stronger weight than the numeric portion).
- Each line is **single-line visible** via scale-down. No ellipsis.
- Units are never truncated. Both systems appear every time.

Label emphasis:
- The literal labels `Wind` and `Gust` are rendered in higher contrast (white) and heavier weight than the numeric portion of the line.

Exact string patterns:

If the primary place unit system is metric:
- `Wind <km/h> km/h (<mph> mph)`
- `Gust <km/h> km/h (<mph> mph)`

If imperial:
- `Wind <mph> mph (<km/h> km/h)`
- `Gust <mph> mph (<km/h> km/h)`

If weather is missing:
- `Wind - km/h (- mph)`
- `Gust - km/h (- mph)`

## Left block: currency and rate

Contract:
- Amount line is bold/high-contrast and uses the approximate symbol `≈`.
- Rate line begins with `Rate:` and stays single-line visible via scale-down (no ellipsis).
- The label `Rate:` is visually emphasized (higher contrast and stronger weight than the numeric portion).

## Sunrise/Sunset pill

### Presence

- The Sunrise/Sunset pill always exists and is anchored at the bottom of the right rail.

### Title

- Title text is exactly: `Sunrise / Sunset`.
- Title is centered.
- Single-line visible via scale-down.

### Rows

- Two rows:
  - Sunrise row begins with the literal `Sunrise`.
  - Sunset row begins with the literal `Sunset`.
- The labels **Sunrise** and **Sunset** are visually emphasized (higher contrast and stronger weight than the numeric portion).
- Each row is single-line visible via scale-down.
- Times use a bullet separator between timezones.
- The `Sunrise` and `Sunset` labels are rendered in higher contrast (white) and heavier weight than the numeric portion of the line.

Exact row format:

`Sunrise <HH:MM> <PrimaryAbbr> • <HH:MM> <SecondaryAbbr>`

`Sunset <HH:MM> <PrimaryAbbr> • <HH:MM> <SecondaryAbbr>`

Rules:
- Sunrise/sunset times are rendered in **24-hour format** (`HH:MM`) for both places.
- If sun data is missing, show placeholders:
  - `Sunrise --:--`
  - `Sunset --:--`

## Reserved marquee slot (future “alive” element)

The hero has a reserved area for a future “alive” element that adds motion or a subtle pixel scene.

Where it lives:
- The **top portion of the right rail**, above the Sunrise/Sunset pill.
- This region contains the "Alive" element implemented as a fixed-size `CustomPaint` scene inside an `Expanded` container.

Hard rules:
- Adding the alive element must **not** change the overall hero layout:
  - Do not change padding/gap values.
  - Do not change the right rail width.
  - Do not insert new vertical blocks that push the clocks header or sun pill.
- Implementation must be **paint-only** when animated (CustomPaint or equivalent).
- No literal words inside the alive element.

Test stability rules:
- Widget tests must not hang on `pumpAndSettle` because of a repeating animation controller.
- Tests should be able to freeze the alive element to a deterministic static frame.

Implementation keys:
- `hero_marquee_slot` (container)
- `hero_alive_paint` (CustomPaint)


