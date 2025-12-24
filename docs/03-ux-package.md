# Unitana — UX Package (MVP)
File: `docs/03-ux-package.md`

This document defines the MVP tile catalog explaining purpose, data inputs, display rules, rounding rules, learning aids, widget mappings, Place badge defaults, and accessibility rules. It is intended to remove ambiguity for implementation.

---

## 1) MVP tile catalog

### Tile anatomy (shared)
Each tile uses a consistent hierarchy:
- **Title** (small)
- **Primary value** (large, local system)
- **Secondary value** (medium, home system)
- Optional **learning hint** (1 line, subdued, Human mode only)
- **Freshness cue** (subtle “Updated X ago” or “Cached” indicator)

Freshness cues:
- **Fresh**: shows “Updated X min ago” (or equivalent subtle phrasing)
- **Stale**: shows “Cached X hours ago” + muted warning icon
- **Missing**: shows “Not set for this Place” + a “Configure” CTA

---

## 2) Tile definitions (MVP)

Notes
- “Local” means destination system for the active Place.
- “Home” means home system for the active Place.
- Weather and currency are cached network-backed tiles.
- Conversions and time zone logic work offline.

### 2.1 Temperature
Purpose: Make weather feel intuitive in both systems.

Inputs
- Network: daily forecast temperature (high/low); optional “feels like”
- Place context: weather city

Display rules
- Primary: local unit (°C or °F based on Place local system)
- Secondary: home unit
- Optional “feels like” appears as a small sub-label, not a second big number

Rounding
- Temperature: round to nearest whole degree
- Feels like: round to nearest whole degree

Learning aid
- Human mode: short neutral orientation hint based on the primary value range.
  - Example: “Light jacket weather” (no medical advice).
- Neutral mode: no hint; just numbers.

Stale state
- Keep last known temperature visible.
- Freshness cue must reflect cache timestamp.

Accessibility
- Label: “Temperature. Local 28 degrees Celsius. Home 82 degrees Fahrenheit. Updated 12 minutes ago.”

---

### 2.2 Wind
Purpose: Help users interpret wind speed quickly.

Inputs
- Network: wind speed from forecast
- Place context: weather city

Display rules
- Primary: local unit (km/h if metric; mph if US customary)
- Secondary: home unit

Rounding
- Wind: round to nearest whole unit

Learning aid
- Human mode: short hint such as “Breezy” or “Windy” based on ranges.
- Neutral: none.

Accessibility
- Label: “Wind. Local 18 kilometers per hour. Home 11 miles per hour. Cached 9 hours ago.”

---

### 2.3 Distance
Purpose: Support everyday navigation intuition.

Inputs
- Offline: user-provided value (quick input) or preset examples (optional)
- Place: unit systems

Display rules
- Primary: local unit (km or mi)
- Secondary: home unit
- If quick input exists, show last input; else show a small helper: “Enter a distance” (optional in MVP)

Rounding
- If value < 10: show 1 decimal (2.3 km)
- If value >= 10: show whole numbers (12 km)
- Keep rounding consistent across both units

Learning aid
- Human mode: may show a “walking time” approximation only if it is clearly labeled as an estimate.
  - Example: “About a 25 min walk” (optional; safe and non-authoritative).
- Neutral: none.

Accessibility
- Label includes both units and whether it is user-entered.

---

### 2.4 Speed
Purpose: Driving speed intuition (km/h vs mph).

Inputs
- Offline: user-provided value via quick input
- Place: unit systems

Display rules
- Primary: local unit (km/h or mph)
- Secondary: home unit
- Optionally include common reference lines in details view (not required in tile)

Rounding
- Whole numbers only

Learning aid
- Human mode: simple context like “Highway speed” (avoid legal claims).
- Neutral: none.

---

### 2.5 Weight and groceries
Purpose: Grocery and everyday weights (kg/g vs lb/oz).

Inputs
- Offline: user input
- Place: unit systems

Display rules
- Primary: local unit (kg or lb depending on local system)
- Secondary: home unit
- Offer a tiny toggle in details view between “weight” and “grocery pack” presets later, not in MVP tile

Rounding
- If value < 10: 1 decimal (1.0 kg)
- If value >= 10: whole numbers
- If grams/ounces are shown in details: grams whole numbers; ounces 1 decimal

Learning aid
- Human mode: short intuition cues like “About a bag of apples” only if phrased as a loose comparison and not too cute.
- Neutral: none.

---

### 2.6 Cooking basics (cups and grams only)
Purpose: Reduce cooking friction without ingredient intelligence.

Inputs
- Offline: user input
- Place: unit systems

Display rules
- Show common conversions such as cups to grams only where standard and generic.
- MVP focus: simple volume to mass reminders, but avoid pretending precision without an ingredient.

Rounding
- Favor whole grams for display.
- If a value is inherently uncertain, prefer showing a range or a note: “Varies by ingredient” (in details view).

Learning aid
- Human mode: one line: “Weights beat cups for repeatability” (optional).
- Neutral: none.

---

### 2.7 Fitness basics
Purpose: Keep basic fitness metrics consistent across systems.

Inputs
- Offline: user input (weight, distance, pace)
- Place: unit systems

Display rules
- Weight: kg/lb
- Distance: km/mi
- Pace: min/km vs min/mi (optional in MVP, but included in scope)

Rounding
- Pace: show mm:ss
- Distance: same as Distance tile
- Weight: same as Weight tile

Learning aid
- Human mode: minimal. Example: “5:00/km is about 8:03/mi”.
- Neutral: none.

---

### 2.8 Time zones (home vs local, DST-aware)
Purpose: Kill mental math for time differences.

Inputs
- Offline: time zone IDs from Place
- System clock

Display rules
- Show both times with clear labels: “Home” and “Local”
- Include abbreviations when possible (MST, WET, etc.)
- If DST changes affect offsets, show it as a normal result

Rounding
- None (use system time formatting)

Learning aid
- Human mode: “Local is +7 hours” (or similar) as a small line.
- Neutral: none.

Accessibility
- Label: “Time zones. Home 9:14 AM Mountain Time. Local 4:14 PM Western European Time.”

---

### 2.9 Currency quick view + mental math
Purpose: Fast mental conversions without pretending to be financial guidance.

Inputs
- Network: cached currency rate for base/local currencies in Place
- Offline: last cached rate and timestamp

Display rules
- Primary: a small set of example amounts (for example 10, 20, 50) or a single anchor amount (10)
- Secondary: rate line in small text: “1 EUR ≈ 1.10 USD”
- Always show timestamp and staleness

Rounding
- Example conversions: 2 significant digits or nearest whole currency unit depending on magnitude
  - Example: €10 ≈ $11
  - Example: €50 ≈ $55

Learning aid
- Human mode: “Rule of thumb” phrasing, never certainty.
- Neutral: none.

Accessibility
- Label includes rate and freshness.

---

## 3) Widget mapping (display-only MVP)

Widgets are “views of the last snapshot.” They do not promise live updates.

Small widget
- Temperature (primary) + freshness cue
- Optional: Place name

Medium widget
- Temperature
- Time zones (Home and Local)
- Freshness cue

Large widget
- Temperature
- Wind
- Currency quick view
- Time zones
- Freshness cue

Widget states
- Missing snapshot: “Open Unitana to set up” + deep link
- Stale snapshot: show values, but freshness clearly shows age

---

## 4) Place badge defaults (tile group presets)

Living (recommended default)
- Weather: ON
- Time zones: ON
- Distance and speed: ON
- Weight and groceries: ON
- Currency: OFF by default (can be enabled)
- Cooking basics: OFF by default
- Fitness basics: OFF by default

Visiting
- Weather: ON
- Time zones: ON
- Distance and speed: ON
- Currency: ON by default
- Weight and groceries: ON
- Cooking basics: OFF by default
- Fitness basics: OFF by default

Other
- Minimal starter: Time zones ON, Temperature ON, Distance ON
- Everything else OFF by default

---

## 5) Learning-aid pattern library (MVP)

Modes
- Human: one line, helpful, culturally aware, not preachy.
- Neutral: numbers only; no hints.

Temperature examples
- 0°C: “Cold; gloves weather for many people.”
- 10°C: “Cool; a light jacket helps.”
- 20°C: “Comfortable for many.”
- 30°C: “Hot; shade helps.”

Speed and distance
- 5 km: “A moderate walk for many people.”
- 100 km/h: “Common highway speed in many countries.”

Time zones
- “Local is +7 hours from home.”
- “DST can change offsets; Unitana follows your selected zones.”

Currency mental math
- “Rule of thumb” language only; always show the rate and timestamp.

---

## 6) Accessibility rules (day one)
- Dynamic type must not truncate the dual values; prefer wrapping.
- Minimum hit targets: 44x44 points equivalent.
- Every tile must have a single screen-reader label that reads both values and freshness.
- Avoid relying on color alone for stale states; include icon + text.

---

## 7) Open items (non-blocking)
- Exact free widget allowance (assumed: 1) and paid allowance (assumed: 3+).
- Whether “feels like” is included in MVP temperature tile (assumed: optional toggle).
- Whether distance and speed inputs share one “Quick Convert” view or stay as separate tiles (assumed: separate tiles in MVP).
