# SceneKey catalog (Hero marquee weather scenes)

## Purpose
A **SceneKey** is a stable identifier for a tiny pixel-art “alive” scene rendered in the Places Hero V2 marquee slot. SceneKeys are provider-agnostic; weather providers map their condition codes to SceneKeys.

This catalog is designed for:
- Paint-only animation (CustomPaint) inside a fixed-size marquee box.
- Deterministic still rendering for widget tests (no endless controllers that block pumpAndSettle).
- Day/night variation driven by the Places Hero top toggle (Denver vs Lisbon) using the device clock for “is it day here?” display logic.

## Technical constraints (non-negotiable)
- **Canvas**: small, fixed-size (use the existing marquee slot constraints). Treat it as a pixel grid; place pixels on integer coordinates.
- **Paint cost**: avoid per-frame allocations. Reuse Paint objects and precomputed lists where possible.
- **Animation**: time-based progression (Ticker) is allowed, but must be test-safe:
  - If `TickerMode` is off, render a stable still frame.
  - Provide a deterministic seed/frame index in tests (so golden-style snapshots are possible later).
- **No text** and no literal words inside the art.

## Visual language (Dracula-adjacent, readability first)
- High-contrast silhouettes (simple shapes) and a limited palette.
- Strong separation between **sky**, **horizon**, and **foreground**.
- Weather overlays must be legible at a glance: rain must read as rain, snow as snow, etc.

## Distinctness contract (what "different" means in one second)
These scenes are tiny. Distinctness must come from a few strong cues, not extra detail.

Rules:
- Each SceneKey has at least two signature cues (shape + motion, or shape + overlay).
- Cloud families must not share the same silhouette. Cloudy uses bands; Overcast uses a single ceiling; Storm uses jagged, lower contrast blocks.
- Precipitation must differ by geometry, not just density:
  - Drizzle: short, sparse ticks.
  - Rain: longer, consistent streaks.
  - Sleet: diagonal slush plus a few flakes.
  - Snow: flakes with gentle drift.
  - Ice pellets: bright, short ticks with tiny bounces.
- Visibility effects (Mist vs Fog) must differ by depth:
  - Mist stays near the horizon.
  - Fog adds a near-foreground veil that eats contrast.
- Wind reads through streak direction and curl; sky color is secondary.

---

## SceneKey schema
Each SceneKey entry uses this structure:

- **SceneKey**: stable id (ALL_CAPS)
- **Primary read**: what a user should recognize within 250ms
- **Base composition**: sky + horizon + foreground
- **Day/Night rule**: how the sun or moon is shown (time-based for the selected location)
- **Overlay**: precipitation/visibility effects (if any)
- **Motion**: 1–3 subtle loops (low amplitude)
- **WeatherAPI mapping**: condition codes (from weather_conditions.csv)
- **Implementation notes**: paint + particle strategy

---

## Catalog (WeatherAPI MVP)

### Distinctness matrix (design reference)
This table is the quick check for making each family read differently; the full entries below hold the implementation detail.

| SceneKey | Must read as | Signature cues | Confusable with | Resolve by |
|---|---|---|---|---|
| CLEAR | open sky | sun or moon + stars; ocean shimmer | PARTLY_CLOUDY | keep sky clean; no cloud bands |
| PARTLY_CLOUDY | sun behind one cloud | single occluding cloud; sun/moon halo peeks | CLOUDY | only one cloud; keep sky brighter |
| CLOUDY | layered clouds | two drifting bands; ridge still visible | OVERCAST | visible gaps and edges; lighter ceiling |
| OVERCAST | heavy blanket | one thick ceiling slab; dim horizon | RAIN_* | no streaks; emphasize ceiling weight |
| MIST | bright horizon haze | low bands hugging horizon; ridge softened | FOG | no foreground blanket; keep mid-sky clearer |
| FOG | low visibility | foreground fog patch; sky and horizon blend | MIST | push opacity; hide ridge more |
| DRIZZLE | fine rain | short sparse ticks; slow fall | RAIN_LIGHT | keep ticks short and sparse |
| RAIN_LIGHT | light rain | thin longer streaks; rare splash | DRIZZLE | increase length; add occasional splash |
| RAIN_MODERATE | steady rain | denser streak field; darker sky | RAIN_HEAVY | avoid gust streaks; keep cadence steady |
| RAIN_HEAVY | intense rain | very dense streaks; occasional gust streak | RAIN_MODERATE | gust streak cue and darker ridge |
| SLEET | mixed precip | diagonal slush streaks + a few flakes | FREEZING_RAIN | diagonal cue; mixed geometry |
| SNOW_LIGHT | light snow | sparse flakes; gentle drift | DRIZZLE | flakes are dots, not lines |
| SNOW_MODERATE | steady snow | more flakes; a few 2px flakes | SNOW_HEAVY | keep ridge visible; limit density |
| SNOW_HEAVY | heavy snow | near-whiteout top; wind drift | BLIZZARD | keep gust surge less aggressive |
| BLOWING_SNOW | windy snow | horizontal or diagonal streaks | BLIZZARD | lower density; keep ridge readable |
| BLIZZARD | whiteout | dense streaks + flakes; 2-frame gust surge | BLOWING_SNOW | increase density and surge |
| ICE_PELLETS | pellet ticks | short bright ticks; small bounces | HAIL | if hail later, make pellets chunkier |
| THUNDER_RAIN | storm | lightning flash + rain | RAIN_HEAVY | lightning is the cue; keep flash rare |
| THUNDER_SNOW | rare storm snow | lightning + snow field | THUNDER_RAIN | keep snow visible during flash |


### Distinctness matrix

| SceneKey | Must read as | Signature cues | Confusable with | Resolve by |
|---|---|---|---|---|
| CLEAR | open sky | sun/moon disc + sea sparkle | PARTLY_CLOUDY | add a single cloud bite in PARTLY_CLOUDY |
| PARTLY_CLOUDY | sun behind one cloud | one cloud occluding disc + slow 1px drift | CLOUDY | CLOUDY uses two bands, no visible disc |
| CLOUDY | layered cloud cover | two separated cloud bands + parallax drift | OVERCAST | OVERCAST is a single heavy ceiling, no gaps |
| OVERCAST | heavy blanket | thick ceiling with uneven edge + darker ridge | THUNDER_RAIN | storms add rain streaks and occasional flash |
| MIST | horizon haze | 2 to 3 thin horizon bands + softened ridge | FOG | FOG adds a near-foreground veil |
| FOG | low visibility | near-foreground veil + reduced horizon contrast | OVERCAST | fog eats the ridge more than overcast does |
| DRIZZLE | fine wetness | short sparse ticks + muted sky | RAIN_LIGHT | rain streaks are longer and more consistent |
| RAIN_LIGHT | light rain | longer sparse streaks + rare splashes | DRIZZLE | use streak length and spacing, not speed |
| RAIN_MODERATE | steady rain | denser streaks + darker sea band | RAIN_HEAVY | heavy adds gust diagonals and lower contrast |
| RAIN_HEAVY | intense rain | dense streaks + occasional gust diagonal | THUNDER_RAIN | thunder adds flash, not just more rain |
| SLEET | mixed precip | diagonal slush streaks + a few flakes | SNOW_LIGHT | snow uses flakes, not diagonal slush |
| SNOW_LIGHT | light snow | sparse flakes + gentle drift | ICE_PELLETS | pellets are ticks and bounce |
| SNOW_MODERATE | steady snow | higher density + a few 2px flakes | SNOW_HEAVY | heavy approaches whiteout, ridge fades |
| SNOW_HEAVY | near-whiteout | dense flakes + upper sky haze | BLIZZARD | blizzard adds fast horizontal streaks |
| BLOWING_SNOW | windy snow | mostly streaks, few flakes | BLIZZARD | blizzard has surge cadence and higher density |
| BLIZZARD | severe snowstorm | streak surge + ridge barely visible | SNOW_HEAVY | blizzard reads as wind first |
| ICE_PELLETS | pellets | short bright ticks + tiny bounces | SLEET | sleet is diagonal, pellets are vertical ticks |
| THUNDER_RAIN | storm | rain + occasional lightning | OVERCAST | lightning is the differentiator, keep flashes brief |
| THUNDER_SNOW | lightning snow | snow + occasional lightning | SNOW_HEAVY | flash is the differentiator, keep subtle |

### CLEAR
- **Primary read**: clear sky (sunny by day, crisp moon by night)
- **Base composition**: low mountain ridge + calm ocean band; wide open sky.
- **Day/Night rule**: show a small sun disc by day; by night swap to moon + 2–3 stars.
- **Overlay**: none.
- **Motion**: ocean shimmer (alternating 2 pixel columns), slow.
- **WeatherAPI mapping**: 1000 (Sunny / Clear)
- **Implementation notes**: two-frame wave shimmer toggled by `(frameIndex % 2)`.

### PARTLY_CLOUDY
- **Primary read**: sun partially covered by a single cloud
- **Base composition**: same ridge + ocean baseline as CLEAR for consistency.
- **Day/Night rule**: sun/moon peeks behind cloud (partial occlusion).
- **Overlay**: none.
- **Motion**: cloud shifts 1px left/right every few seconds.
- **WeatherAPI mapping**: 1003 (Partly cloudy)
- **Implementation notes**: cloud is a 3–4 blob cluster; move in a tiny “breathing” loop.

### CLOUDY
- **Primary read**: layered clouds
- **Base composition**: ridge silhouette; sky filled with two cloud bands.
- **Day/Night rule**: dimmer palette at night; moon barely visible behind band 1.
- **Overlay**: none.
- **Motion**: parallax cloud drift (top band slower than bottom).
- **WeatherAPI mapping**: 1006 (Cloudy)
- **Implementation notes**: drift wraps by modulo width, no allocations.

### OVERCAST
- **Primary read**: heavy blanket cloud cover
- **Base composition**: sky is one thick band; ridge + ocean darker.
- **Day/Night rule**: no visible sun/moon; just subtle gradient shift.
- **Overlay**: none.
- **Motion**: slow gradient roll (1px vertical shift every N frames).
- **WeatherAPI mapping**: 1009 (Overcast)
- **Implementation notes**: a single “ceiling” rectangle with uneven bottom edge.

### MIST
- **Primary read**: low, bright haze hugging the horizon
- **Base composition**: ridge is faint; ocean band softened.
- **Day/Night rule**: at night, haze is cooler and slightly dimmer.
- **Overlay**: 2–3 semi-opaque horizontal mist bands.
- **Motion**: mist bands slide slowly with tiny phase offsets.
- **WeatherAPI mapping**: 1030 (Mist)
- **Implementation notes**: band alpha is simulated via sparse dithering.

### FOG
- **Primary read**: thick fog, visibility reduced
- **Base composition**: ridge partially hidden; sky and horizon merge.
- **Day/Night rule**: keep a faint moon halo at night only if it remains legible.
- **Overlay**: denser bands than MIST, plus a near-foreground fog patch.
- **Motion**: slow lateral drift of bands; foreground patch pulses (2-frame).
- **WeatherAPI mapping**: 1135 (Fog), 1147 (Freezing fog)
- **Implementation notes**: Freezing fog can add 2–3 “sparkle” pixels that blink slowly.

### DRIZZLE
- **Primary read**: fine rain, gentle
- **Base composition**: CLOUDY base with slightly lower horizon contrast.
- **Day/Night rule**: sun/moon hidden behind clouds.
- **Overlay**: thin, sparse vertical drizzle lines.
- **Motion**: drizzle falls (y increments), wraps at bottom.
- **WeatherAPI mapping**: 1150 (Patchy light drizzle), 1153 (Light drizzle)
- **Implementation notes**: use a fixed set of line x positions; per frame, shift y.

### FREEZING_DRIZZLE
- **Primary read**: icy drizzle (rain that looks sharp/cold)
- **Base composition**: DRIZZLE base, cooler sky tone.
- **Day/Night rule**: same as DRIZZLE.
- **Overlay**: drizzle lines + tiny “ice specks” near ground.
- **Motion**: specks blink; drizzle falls slower.
- **WeatherAPI mapping**: 1072 (Patchy freezing drizzle possible), 1168 (Freezing drizzle), 1171 (Heavy freezing drizzle)
- **Implementation notes**: differentiate heavy via density, not speed.

### RAIN_LIGHT
- **Primary read**: light rain
- **Base composition**: CLOUDY base.
- **Overlay**: rain lines, moderate density.
- **Motion**: steady fall; occasional 1px “splash” at ocean line.
- **WeatherAPI mapping**: 1063 (Patchy rain possible), 1180 (Patchy light rain), 1183 (Light rain), 1240 (Light rain shower)
- **Implementation notes**: keep splashes rare to avoid visual noise.

### RAIN_MODERATE
- **Primary read**: steady rain with heavier sheeting
- **Base composition**: OVERCAST-ish sky + darker ridge.
- **Overlay**: thicker rain density (more lines).
- **Motion**: slightly faster fall than RAIN_LIGHT.
- **WeatherAPI mapping**: 1186 (Moderate rain at times), 1189 (Moderate rain), 1243 (Moderate or heavy rain shower)
- **Implementation notes**: retain readability by keeping line spacing consistent.

### RAIN_HEAVY
- **Primary read**: heavy rain, intense
- **Base composition**: dark overcast sky; ridge nearly black.
- **Overlay**: dense rain + occasional diagonal gust streak.
- **Motion**: fast fall; gust streak appears every few seconds.
- **WeatherAPI mapping**: 1192 (Heavy rain at times), 1195 (Heavy rain), 1246 (Torrential rain shower)
- **Implementation notes**: gust streak should be 1–2 frames only.

### FREEZING_RAIN
- **Primary read**: rain that feels sharp and icy
- **Base composition**: overcast with cooler tone.
- **Overlay**: longer rain streaks + a few pellet ticks.
- **Motion**: streaks fall; pellets bounce 1px at ground line.
- **WeatherAPI mapping**: 1198 (Light freezing rain), 1201 (Moderate or heavy freezing rain)
- **Implementation notes**: pellets are sparse and short-lived.

### SLEET
- **Primary read**: mixed rain/snow (slushy diagonal)
- **Base composition**: cloudy base.
- **Overlay**: diagonal sleet streaks plus a few small flakes.
- **Motion**: diagonal movement (x+1, y+1), wrap.
- **WeatherAPI mapping**: 1069 (Patchy sleet possible), 1204 (Light sleet), 1207 (Moderate or heavy sleet), 1249 (Light sleet showers), 1252 (Moderate or heavy sleet showers)
- **Implementation notes**: diagonal direction should remain consistent for legibility.

### SNOW_LIGHT
- **Primary read**: light snow
- **Base composition**: CLOUDY base, brighter ground line.
- **Overlay**: small flakes (single pixels) drifting down.
- **Motion**: flakes fall with slight sideways drift.
- **WeatherAPI mapping**: 1066 (Patchy snow possible), 1210 (Patchy light snow), 1213 (Light snow), 1255 (Light snow showers)
- **Implementation notes**: drift should be subtle to avoid “confetti.”

### SNOW_MODERATE
- **Primary read**: steady snowfall
- **Base composition**: overcast sky; ridge visible but muted.
- **Overlay**: increased flake density; a few larger 2px flakes.
- **Motion**: steady fall; occasional swirl frame (minor).
- **WeatherAPI mapping**: 1216 (Patchy moderate snow), 1219 (Moderate snow), 1258 (Moderate or heavy snow showers)
- **Implementation notes**: larger flakes help differentiate from SNOW_LIGHT.

### SNOW_HEAVY
- **Primary read**: thick snowfall
- **Base composition**: dark overcast; ridge almost hidden.
- **Overlay**: dense flakes; near-whiteout upper sky.
- **Motion**: faster fall; slight wind drift.
- **WeatherAPI mapping**: 1222 (Patchy heavy snow), 1225 (Heavy snow)
- **Implementation notes**: cap density so the scene does not become a white block.

### BLOWING_SNOW
- **Primary read**: windy snow, horizontal streaks
- **Base composition**: ridge + ground line; sky dim.
- **Overlay**: horizontal/diagonal streaks (not flakes).
- **Motion**: streaks sweep across; loop wraps.
- **WeatherAPI mapping**: 1114 (Blowing snow)
- **Implementation notes**: fewer streaks than BLIZZARD; readable wind direction.

### BLIZZARD
- **Primary read**: near-whiteout storm
- **Base composition**: ridge barely visible.
- **Overlay**: heavy streaks + dense flakes.
- **Motion**: fast sweep with a 2-frame “gust surge.”
- **WeatherAPI mapping**: 1117 (Blizzard)
- **Implementation notes**: protect contrast by keeping ridge in a distinct dark tone.

### ICE_PELLETS
- **Primary read**: pellets/hail-like ticks
- **Base composition**: cloudy base.
- **Overlay**: short vertical ticks and small “bounce” pixels on ground.
- **Motion**: ticks fall; bounce 1px then vanish.
- **WeatherAPI mapping**: 1237 (Ice pellets), 1261 (Light showers of ice pellets), 1264 (Moderate or heavy showers of ice pellets)
- **Implementation notes**: pellets are brighter than rain lines, shorter than snow.

### THUNDER_RAIN
- **Primary read**: storm with lightning and rain
- **Base composition**: dark overcast.
- **Overlay**: rain (moderate) + lightning flash.
- **Motion**: lightning flashes briefly (1–2 frames) every 6–10 seconds.
- **WeatherAPI mapping**: 1087 (Thundery outbreaks possible), 1273 (Patchy light rain with thunder), 1276 (Moderate or heavy rain with thunder)
- **Implementation notes**: flash can brighten a small sky region; avoid full-screen strobe.

### THUNDER_SNOW
- **Primary read**: snow + lightning (rare but distinct)
- **Base composition**: overcast snow base.
- **Overlay**: snow (moderate) + lightning flash.
- **Motion**: same flash cadence as THUNDER_RAIN, but with flakes.
- **WeatherAPI mapping**: 1279 (Patchy light snow with thunder), 1282 (Moderate or heavy snow with thunder)
- **Implementation notes**: keep flash subtle; snow remains readable.

---

## Extended (non-WeatherAPI MVP) conditions

### WINDY
- **Primary read**: moving air (no precipitation)
- **Base composition**: CLEAR-like sky with fewer sparkles; ridge stays crisp.
- **Overlay**: 3 to 5 wind streaks (thin curves or angled dashes).
- **Motion**: streaks sweep left-to-right in a loop; one streak has a slightly different phase to avoid sameness.
- **Inclusive UX note**: avoid debris or danger motifs; keep it playful and neutral.
- **Implementation notes**: streaks should never cover the whole canvas; keep them in the upper half.

### TORNADO
- **Primary read**: funnel cloud (rare, but unmistakable)
- **Base composition**: storm sky; ridge very dark.
- **Overlay**: a narrow-to-wide funnel silhouette that touches the horizon line.
- **Motion**: subtle lateral wobble (1px) and a two-frame dither shimmer inside the funnel.
- **Inclusive UX note**: no destruction; the funnel is a symbol, not a disaster scene.
- **Implementation notes**: keep the funnel small enough to fit, centered-right works well.

### HAZE_DUST
- **Primary read**: dry low-contrast haze
- **Base composition**: sky and ridge are closer in value; horizon looks washed.
- **Overlay**: soft bands plus a few drifting specks.
- **Motion**: bands drift slowly; specks blink rarely.
- **Inclusive UX note**: avoid war-zone or apocalyptic cues; keep it atmospheric.
- **Implementation notes**: rely on contrast reduction and banding, not heavy particles.

### SMOKE_WILDFIRE
This is **not** in WeatherAPI’s standard condition list, but it is useful if we later add AQI, wildfire smoke, or other providers.

- **Primary read**: distant wildfire smoke haze over a forest ridgeline
- **Base composition**: pine ridge silhouette; sun/moon is muted behind a brown-gray haze.
- **Overlay**: drifting smoke bands, slightly uneven and rising.
- **Motion**: smoke bands rise slowly (y-1 every N frames) and shift laterally; subtle ember specks very rarely (optional).
- **Inclusive UX note**: keep it evocative but not alarming; no flames, no emergency motifs.
- **Implementation notes**: smoke is a few band shapes with dithered edges; use a cooler brown-gray and keep contrast against the sky.


### WINDY
This is **not** in WeatherAPI’s standard condition list, but it matches Unitana’s internal WeatherCondition set.

- **Primary read**: strong wind, clear direction
- **Base composition**: ridge + ocean baseline; sky can be CLEAR or CLOUDY toned depending on upstream condition family.
- **Overlay**: 3–6 wind streaks (short arcs), all aligned in one direction.
- **Motion**: streaks glide across and recycle, never jitter.
- **Inclusive UX note**: keep it energetic, not chaotic.
- **Implementation notes**: wind should read as geometry first, color second.

### TORNADO
Also not in WeatherAPI’s standard condition list, but worth reserving.

- **Primary read**: funnel touching down
- **Base composition**: stormy sky + darker ridge.
- **Overlay**: a tapered funnel with sparse debris pixels near the ground.
- **Motion**: slow clockwise drift of debris pixels; funnel subtly changes width (two-frame toggle).
- **Inclusive UX note**: avoid sirens, warnings, or disaster iconography.
- **Implementation notes**: funnel must remain legible at ~24px height; favor silhouette.

### HAZE_DUST
Future visibility condition family for haze, dust, and sand.

- **Primary read**: warm-toned veil in the lower sky
- **Base composition**: ridge softened; sun becomes a muted disc by day.
- **Overlay**: dithered haze layers with occasional single-pixel grit near the horizon.
- **Motion**: slow lateral drift; grit pixels blink rarely.
- **Implementation notes**: separate from MIST by tone (warm) and by a stronger sun disc.

### ASHFALL
Future visibility condition family for volcanic ash.

- **Primary read**: falling gray flecks (not snow)
- **Base composition**: dim sky; ridge high contrast.
- **Overlay**: downward flecks that are darker than snow, irregular spacing.
- **Motion**: flecks fall slower than rain and do not sparkle.
- **Implementation notes**: avoid looking like confetti; keep density low.

---

## WeatherAPI mapping policy
- Use WeatherAPI’s offline condition list (CSV/JSON) and map **every condition code** to a SceneKey.
- Many codes intentionally collapse into the same SceneKey family (for example, several rain intensities).
- The hero toggle selects which location’s day/night rule is applied to the scene.


## WeatherAPI condition-code mapping (complete)

| Code | Day text | Night text | SceneKey |
|---:|---|---|---|
| 1000 | Sunny | Clear | CLEAR |
| 1003 | Partly cloudy | Partly cloudy | PARTLY_CLOUDY |
| 1006 | Cloudy | Cloudy | CLOUDY |
| 1009 | Overcast | Overcast | OVERCAST |
| 1030 | Mist | Mist | MIST |
| 1063 | Patchy rain possible | Patchy rain possible | RAIN_LIGHT |
| 1066 | Patchy snow possible | Patchy snow possible | SNOW_LIGHT |
| 1069 | Patchy sleet possible | Patchy sleet possible | SLEET |
| 1072 | Patchy freezing drizzle possible | Patchy freezing drizzle possible | FREEZING_DRIZZLE |
| 1087 | Thundery outbreaks possible | Thundery outbreaks possible | THUNDER_RAIN |
| 1114 | Blowing snow | Blowing snow | BLOWING_SNOW |
| 1117 | Blizzard | Blizzard | BLIZZARD |
| 1135 | Fog | Fog | FOG |
| 1147 | Freezing fog | Freezing fog | FOG |
| 1150 | Patchy light drizzle | Patchy light drizzle | DRIZZLE |
| 1153 | Light drizzle | Light drizzle | DRIZZLE |
| 1168 | Freezing drizzle | Freezing drizzle | FREEZING_DRIZZLE |
| 1171 | Heavy freezing drizzle | Heavy freezing drizzle | FREEZING_DRIZZLE |
| 1180 | Patchy light rain | Patchy light rain | RAIN_LIGHT |
| 1183 | Light rain | Light rain | RAIN_LIGHT |
| 1186 | Moderate rain at times | Moderate rain at times | RAIN_MODERATE |
| 1189 | Moderate rain | Moderate rain | RAIN_MODERATE |
| 1192 | Heavy rain at times | Heavy rain at times | RAIN_HEAVY |
| 1195 | Heavy rain | Heavy rain | RAIN_HEAVY |
| 1198 | Light freezing rain | Light freezing rain | FREEZING_RAIN |
| 1201 | Moderate or heavy freezing rain | Moderate or heavy freezing rain | FREEZING_RAIN |
| 1204 | Light sleet | Light sleet | SLEET |
| 1207 | Moderate or heavy sleet | Moderate or heavy sleet | SLEET |
| 1210 | Patchy light snow | Patchy light snow | SNOW_LIGHT |
| 1213 | Light snow | Light snow | SNOW_LIGHT |
| 1216 | Patchy moderate snow | Patchy moderate snow | SNOW_MODERATE |
| 1219 | Moderate snow | Moderate snow | SNOW_MODERATE |
| 1222 | Patchy heavy snow | Patchy heavy snow | SNOW_HEAVY |
| 1225 | Heavy snow | Heavy snow | SNOW_HEAVY |
| 1237 | Ice pellets | Ice pellets | ICE_PELLETS |
| 1240 | Light rain shower | Light rain shower | RAIN_LIGHT |
| 1243 | Moderate or heavy rain shower | Moderate or heavy rain shower | RAIN_HEAVY |
| 1246 | Torrential rain shower | Torrential rain shower | RAIN_HEAVY |
| 1249 | Light sleet showers | Light sleet showers | SLEET |
| 1252 | Moderate or heavy sleet showers | Moderate or heavy sleet showers | SLEET |
| 1255 | Light snow showers | Light snow showers | SNOW_LIGHT |
| 1258 | Moderate or heavy snow showers | Moderate or heavy snow showers | SNOW_HEAVY |
| 1261 | Light showers of ice pellets | Light showers of ice pellets | ICE_PELLETS |
| 1264 | Moderate or heavy showers of ice pellets | Moderate or heavy showers of ice pellets | ICE_PELLETS |
| 1273 | Patchy light rain with thunder | Patchy light rain with thunder | THUNDER_RAIN |
| 1276 | Moderate or heavy rain with thunder | Moderate or heavy rain with thunder | THUNDER_RAIN |
| 1279 | Patchy light snow with thunder | Patchy light snow with thunder | THUNDER_SNOW |
| 1282 | Moderate or heavy snow with thunder | Moderate or heavy snow with thunder | THUNDER_SNOW |
