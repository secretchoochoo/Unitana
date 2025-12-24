# Unitana — Wireframes (MVP, Annotated)
File: `docs/02-wireframes.md`

This is an implementation-ready wireframe package for Unitana’s MVP. It translates `01-flows.md` into concrete screens, layout regions, and interaction notes.

Design intent: a calm, trustworthy dashboard that works offline, avoids clutter, and makes “dual reality” feel effortless.

---

## 0) Conventions used in this document

### Screen IDs
- **S0** App Launch / Routing
- **S1** First Run: Create Default Place (wizard)
- **S2** Dashboard
- **S3** Place Switcher (sheet)
- **S4** Place Editor (new/edit)
- **S5** Settings
- **S6** Paywall (modal)
- **S7** Widgets: Configure + Previews
- **S8** Manage Subscription (handoff + explanation)

### Modal / sheet IDs
- **M1** Tile Details (only where helpful)
- **M2** Rate Limit Notice (toast/sheet)
- **M3** Stale Data Explanation (small sheet)
- **M4** Widget Limit Sheet (leads to paywall)

### Patterns
- **Primary navigation** is “Dashboard as home.” Everything returns to S2.
- **Place** is the central organizing concept. Nearly every screen is Place-aware.
- **Freshness** is always visible but never loud.

---

## 1) Component inventory (MVP)

### Navigation + structure
- **Top App Bar**
  - Left: Place chip (current Place name + badge)
  - Right: Settings icon
- **Bottom nav**
  - None in MVP (keeps the dashboard calm)
- **Sheets**
  - Place Switcher (S3)
  - Widget config steps (S7) can be either stacked screens or sheets

### Core components
- **Place chip**
  - Label: Place name
  - Secondary: badge (Living/Visiting/Other) as a small pill
- **Tile card**
  - Title (small)
  - Primary value (large)
  - Secondary value (dual unit) (medium)
  - Optional learning hint (1 line, subdued)
  - Freshness indicator (icon + relative time) in corner or footer
- **Tile group toggles**
  - Group header + description
  - Toggle switch
- **Inline freshness row**
  - “Updated X min ago” (subtle)
  - Tap opens M3 “About freshness”
- **Empty state**
  - Icon + one sentence + CTA (“Configure”)
- **Paywall card stack**
  - Benefits list
  - Trial eligibility disclaimer
  - Primary CTA, secondary CTA, restore link

### Inputs
- Text input: Place name
- Pickers: home system, destination system, time zones, weather city, currencies
- Toggles: tile groups, learning mode (segmented), privacy/analytics opt-in

### Typography scale (wireframe-level)
- H1: Screen title
- H2: Section title
- Body: Standard copy
- Caption: Freshness, footnotes, disclaimers
- Numeric display: large “stat” style within tiles

---

## 2) Wireframe set (screen-by-screen)

### S0 — App Launch / Routing
**Purpose:** Decide whether to show First Run or Dashboard.

**Layout regions**
- Full-screen splash (lightweight branding)
- Loading indicator (short-lived)

**Logic**
- If no default Place exists: go to S1
- Else: go to S2

#### ASCII
```
+--------------------------------------------------+
|                    UNITANA                       |
|                                                  |
|                 (subtle mark)                    |
|                                                  |
|               [ loading ... ]                    |
+--------------------------------------------------+
```

---

## S1 — First Run Wizard: Create Default Place (forced)

**Purpose:** Create exactly one default Place. The wizard is not skippable.

**Steps (5)**
1) Name + badge
2) Systems (home/destination)
3) Time zones (home/local)
4) Tile groups (defaults by badge)
5) Weather city + Currency (currency auto-on for Visiting)

**Shared layout regions**
- Progress indicator (Step X of 5)
- Title + helper copy
- Primary action button (Next / Create)
- Secondary action (Back, except Step 1)
- Validation inline

### S1.1 — Step 1: Name + Badge
```
+--------------------------------------------------+
| Step 1 of 5                                      |
| Create your first Place                          |
| A Place matches your trip or relocation.         |
|                                                  |
| Place name                                       |
| [______________________________]                 |
|                                                  |
| Type                                             |
| ( ) Living     ( ) Visiting     ( ) Other        |
|                                                  |
|            [ Next ]                              |
+--------------------------------------------------+
```

### S1.2 — Step 2: Home + Destination systems
```
+--------------------------------------------------+
| Step 2 of 5                                      |
| Measurement systems                              |
| What you know vs where you are.                  |
|                                                  |
| Home system                                      |
| [ US Customary  v ]                              |
|                                                  |
| Local system                                     |
| [ Metric        v ]                              |
|                                                  |
| [ Back ]                         [ Next ]        |
+--------------------------------------------------+
```

### S1.3 — Step 3: Time zones (Home + Local)
```
+--------------------------------------------------+
| Step 3 of 5                                      |
| Time zones                                       |
| Always see home and local together.              |
|                                                  |
| Home time zone                                   |
| [ America/Denver     v ]                         |
|                                                  |
| Local time zone                                  |
| [ Europe/Lisbon      v ]                         |
|                                                  |
| [ Back ]                         [ Next ]        |
+--------------------------------------------------+
```

### S1.4 — Step 4: Tile groups
```
+--------------------------------------------------+
| Step 4 of 5                                      |
| What should your dashboard show?                 |
| You can change this any time.                    |
|                                                  |
| Weather                     [ ON ]               |
| Time zones                  [ ON ]               |
| Distance & speed            [ ON ]               |
| Weight & groceries          [ ON ]               |
| Cooking basics              [ OFF ]              |
| Fitness basics              [ OFF ]              |
| Currency                    [ ON ]               |
|                                                  |
| [ Back ]                         [ Next ]        |
+--------------------------------------------------+
```

### S1.5 — Step 5: Weather city + Currency
Defaults applied:
- Weather: **city-based only**
- Currency: **enabled by default** if Visiting

```
+--------------------------------------------------+
| Step 5 of 5                                      |
| Local context                                     |
| Make this Place feel real.                        |
|                                                  |
| Weather city                                      |
| [ Lisbon, PT            v ]                       |
|                                                  |
| Currency (Visiting: ON by default)                |
| Base currency                                     |
| [ USD                  v ]                        |
| Local currency                                    |
| [ EUR                  v ]                        |
|                                                  |
| [ Back ]                       [ Create Place ]   |
+--------------------------------------------------+
```

---

## S2 — Dashboard (the one-screen reason to open the app)

**Purpose:** Calm overview. Minimal taps. Clear freshness.

**Layout regions**
- Top bar: Place chip + settings icon
- Summary strip (optional): “Home vs Local” quick glance
- Tile grid/list (adaptive for phone/tablet)
- Freshness row (subtle): “Updated X min ago” + network state
- Pull-to-refresh gesture (rate-limited)

**Interaction notes**
- Tap Place chip → S3 Place Switcher
- Tap Settings → S5
- Tap tile → M1 details (only where it adds value)
- Pull-to-refresh → fetch weather/rates when allowed; otherwise show M2
- Offline: conversions/time zones still work; weather/rates show stale state

### S2 ASCII (phone)
```
+--------------------------------------------------+
| [ Place: Porto  (Visiting) v ]        (⚙︎)        |
|--------------------------------------------------|
| Home  9:14 AM (MST)      Local  4:14 PM (WET)    |
| Updated 12 min ago   •   Using cached data       |
|--------------------------------------------------|
| [ Temperature ]   28°C   | 82°F      (hint...)   |
| [ Wind ]          18 km/h| 11 mph                |
| [ Distance ]      2.3 km | 1.4 mi                |
| [ Speed ]         100 km/h| 62 mph               |
| [ Weight ]        1.0 kg | 2.2 lb                |
| [ Currency ]      €10 ≈ $11  (rule of thumb)     |
|                                                  |
| (pull to refresh)                                |
+--------------------------------------------------+
```

### Dashboard tile states (wireframe patterns)

**Fresh**
```
[ Temperature ]  28°C | 82°F
Updated 12m ago
```
**Stale but usable**
```
[ Temperature ]  28°C | 82°F     (!) 
Updated 9h ago (cached)
Tap for details
```
**Missing (not configured)**
```
[ Weather ]  Not set for this Place
[ Configure ]
```

---

## S3 — Place Switcher (sheet)

**Purpose:** Switch Places fast, create/edit, reorder, manage default.

**Layout regions**
- Header: “Places” + Add button
- List of Places (name + badge + small summary)
- Default indicator
- Edit and reorder controls

**Rules**
- Default Place cannot be deleted.
- Default can be changed (action: “Make default”).

### ASCII
```
+--------------------------------------------------+
| Places                                   [ + ]   |
|--------------------------------------------------|
| ★ Living: Home Base (Living)                     |
|   Systems: US → Metric  •  TZ: Denver/Lisbon     |
|   [ Edit ]                                       |
|--------------------------------------------------|
| Visiting: Porto (Visiting)                       |
|   Systems: US → Metric  •  Currency: USD/EUR     |
|   [ Edit ]  [ Make default ]                     |
|--------------------------------------------------|
| Other: Mexico Trip (Other)                       |
|   [ Edit ]                                       |
|--------------------------------------------------|
| (Reorder handle on right)                        |
+--------------------------------------------------+
```

---

## S4 — Place Editor (new/edit)

**Purpose:** One place to modify Place configuration without breaking the dashboard.

**Layout regions**
- Header: Place name + badge
- Sections:
  - Basics (name, badge)
  - Systems (home/destination)
  - Time zones
  - Tile groups
  - Weather city
  - Currency
- Save button (sticky)

### ASCII
```
+--------------------------------------------------+
| Edit Place                             [ Save ]  |
|--------------------------------------------------|
| Name                                              |
| [ Porto________________________ ]                 |
| Type                                              |
| ( ) Living  (•) Visiting  ( ) Other               |
|--------------------------------------------------|
| Systems                                           |
| Home: [ US Customary v ]                          |
| Local: [ Metric v ]                               |
|--------------------------------------------------|
| Time zones                                        |
| Home:  [ America/Denver v ]                       |
| Local: [ Europe/Lisbon v ]                        |
|--------------------------------------------------|
| Tile groups                                       |
| Weather                  [ ON ]                   |
| Currency                 [ ON ]                   |
| Cooking basics           [ OFF ]                  |
| Fitness basics           [ OFF ]                  |
| ...                                               |
|--------------------------------------------------|
| Weather city: [ Lisbon, PT v ]                    |
| Base currency: [ USD v ]  Local: [ EUR v ]        |
+--------------------------------------------------+
```

---

## S5 — Settings

**Purpose:** Global preferences, privacy stance, learning mode, subscription, widgets.

**Layout regions**
- Sections:
  - Learning
  - Display + Accessibility
  - Data + Freshness
  - Widgets
  - Subscription
  - Privacy

### S5 ASCII
```
+--------------------------------------------------+
| Settings                                          |
|--------------------------------------------------|
| Learning mode                                     |
| [ Human ] [ Neutral ]                             |
|--------------------------------------------------|
| Accessibility                                     |
| Dynamic type: follows system                      |
| High contrast tiles: [ OFF ]                      |
| Reduce motion: follows system                     |
|--------------------------------------------------|
| Data & freshness                                  |
| Stale warning threshold: [ 6 hours v ]            |
| Refresh: pull-to-refresh (rate limited)           |
|--------------------------------------------------|
| Widgets                                           |
| Configure widgets  >                              |
|--------------------------------------------------|
| Subscription                                      |
| Unitana Plus: Not subscribed  >                   |
|--------------------------------------------------|
| Privacy                                           |
| Analytics (opt-in): [ OFF ]                       |
| About data sources  >                             |
+--------------------------------------------------+
```

---

## S6 — Paywall (modal)

**Primary trigger:** Widgets (user tries to exceed free widget allowance).

**Layout regions**
- Title + value proposition
- Benefits list
- Trial copy disclaimer (no promises)
- CTA buttons
- Restore purchases
- Dismiss

### ASCII
```
+--------------------------------------------------+
| Unitana Plus                                      |
|--------------------------------------------------|
| Put Unitana on your home screen.                  |
| More widgets, more Places, deeper customization.  |
|                                                  |
| ✓ Add more widgets                                |
| ✓ More Places (power use)                         |
| ✓ Extra tile customization                         |
|                                                  |
| Trial availability varies by store account.       |
|                                                  |
| [ Start free trial ]                              |
| [ Subscribe ]                                     |
| Restore purchases                                 |
|                          [ Not now ]              |
+--------------------------------------------------+
```

---

## S7 — Widgets: Configure + Previews (in-app)

**Purpose:** Configure widget snapshots per Place and tile set, with previews.

**Flow (simple)**
1) Choose widget size preview
2) Pick Place
3) Choose tiles shown in that widget
4) Save (if within allowance), else show M4 → paywall

### S7 ASCII (step-based)
```
+--------------------------------------------------+
| Widgets                                           |
|--------------------------------------------------|
| Pick a widget size                                |
| [ Small ]  [ Medium ]  [ Large ]                  |
|--------------------------------------------------|
| Preview                                           |
| +----------------------------+                    |
| | Porto (Visiting)           |                    |
| | 28°C | 82°F                |                    |
| | Updated 12m ago            |                    |
| +----------------------------+                    |
|--------------------------------------------------|
| Place for this widget: [ Porto v ]                |
| Tiles in widget                                   |
| [✓] Temperature                                   |
| [✓] Time zones                                    |
| [ ] Currency                                      |
|--------------------------------------------------|
| [ Save widget ]                                   |
+--------------------------------------------------+
```

### Widget preview patterns (ASCII)

**Small**
```
+-----------------------+
| Porto  28°C | 82°F    |
| Updated 12m            |
+-----------------------+
```

**Medium**
```
+------------------------------+
| Porto (Visiting)             |
| Temp  28°C | 82°F            |
| Home  9:14   Local  4:14     |
| Updated 12m ago              |
+------------------------------+
```

**Large**
```
+----------------------------------+
| Porto (Visiting)                 |
| Temp      28°C | 82°F            |
| Wind      18 km/h | 11 mph       |
| Currency  €10 ≈ $11              |
| Home  9:14 AM   Local  4:14 PM   |
| Updated 12m ago                  |
+----------------------------------+
```

---

## S8 — Manage Subscription

**Purpose:** Explain what management means, then handoff to OS store.

**ASCII**
```
+--------------------------------------------------+
| Manage Subscription                               |
|--------------------------------------------------|
| Subscriptions are managed by your app store.      |
| You can change or cancel anytime from there.      |
|                                                  |
| [ Open App Store / Play Store ]                   |
+--------------------------------------------------+
```

---

# Modals / Sheets

## M1 — Tile Details (only when it adds value)
**Use when:** user taps Currency, Time Zones, Weather, or other tiles where context helps.

**Layout**
- Tile title
- Larger values
- Learning hint (1–2 lines)
- Freshness + source
- “Change configuration” quick link (if missing)

ASCII (example: Currency)
```
+--------------------------------------------------+
| Currency (Porto)                                  |
|--------------------------------------------------|
| €10 ≈ $11                                         |
| Rate: 1 EUR ≈ 1.10 USD                             |
| Hint: For quick mental math, add ~10% to euros.   |
|                                                  |
| Updated 12m ago • Source: ProviderName            |
| [ Change currencies ]                              |
+--------------------------------------------------+
```

---

## M2 — Rate Limit Notice
**Use when:** pull-to-refresh is attempted too soon.

ASCII
```
+--------------------------------------------------+
| Updated recently                                 |
| Try again in a bit to protect battery and limits. |
| [ OK ]                                           |
+--------------------------------------------------+
```

---

## M3 — Stale Data Explanation
**Use when:** user taps freshness row or stale indicator.

ASCII
```
+--------------------------------------------------+
| About freshness                                  |
|--------------------------------------------------|
| Unitana updates when it can. Widgets refresh on   |
| a schedule controlled by your OS.                 |
|                                                  |
| This Place is showing cached values from 9h ago.  |
| [ Refresh now ]   [ Learn more ]                  |
+--------------------------------------------------+
```

---

## M4 — Widget Limit Sheet (leads to paywall)
**Use when:** user tries to exceed free widget allowance.

ASCII
```
+--------------------------------------------------+
| Widget limit reached                              |
|--------------------------------------------------|
| Free includes 1 widget. Add more with Unitana Plus.|
|                                                  |
| [ See Unitana Plus ]   [ Not now ]                |
+--------------------------------------------------+
```

---

## 3) Notes for implementation and QA

### Layout strategy
- Phone: tiles as a vertical list with clear spacing
- Tablet: tiles become a 2-column grid, keeping the same hierarchy
- All states must support dynamic type without truncating critical dual values

### Most important testable behaviors
- First run is unskippable and produces exactly one default Place
- City-based weather selection (no location permission flow in MVP)
- Currency is enabled by default for Visiting Places
- Widget gating triggers paywall reliably and reversibly
- Offline mode keeps dashboard useful; stale indicators are accurate

---

## 4) Next file to produce
`docs/03-ux-package.md` (tile catalog, rounding rules, learning aid library, widget mappings).
