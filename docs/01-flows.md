# Unitana — Flows and Navigation Map (MVP)
File: `docs/01-flows.md`

This document defines the MVP user flows and screen-to-screen navigation for Unitana. It is intentionally specific enough to implement, but still flexible enough for design iteration.

---

## 1) Scope and principles

### MVP scope covered here
- First-run setup (forced creation of exactly one default Place)
- Dashboard (the one-screen reason to open the app)
- Place switcher and Place editor
- Settings (learning mode, privacy, accessibility, subscription, widgets)
- Widgets (display-only) selection and configuration
- Subscription and gating triggers
- Refresh and offline behavior (weather and currency as cached data)
- Essential error and edge flows (stale cache, no network, invalid input)

### Core principles
- Calm dashboard, fast to value
- Offline-first and honest about freshness
- Learning aids guide, they do not lecture
- Accessibility day one

---

## 2) Defaults locked for MVP (answers applied)
These defaults are now considered part of the MVP navigation contract.

- **Weather location selection**: **City-based only** (no “use current location” in MVP).
- **Currency default for Visiting Places**: **Enabled by default**.
- **Primary paywall moment**: **Widgets** (first meaningful gating moment is when the user tries to add more than the free widget allowance).

Recommended starting gate (can change later without rewriting flows):
- Free tier includes **1 widget**.
- Paywall appears when user attempts to add a **2nd widget** (or exceeds the free allowance).
- Places gating remains available later (for example 4th Place), but is not the primary moment.

---

## 3) Glossary
- **Place**: A saved configuration that defines home system, destination system, enabled tile groups, time zones, and weather and currency context.
- **Tile**: A dashboard card for a single category (temperature, currency, time zones, etc.).
- **Learning mode**: Human or Neutral.
- **Fresh / Stale**: Cache freshness states shown in UI and widgets.
- **Widget config**: Which Place and which tile(s) a widget displays.

---

## 4) Screen inventory and route map

Naming convention: `S#` for screens, `M#` for modals/sheets.

### Screens (primary)
- **S0** App Launch / Routing (decides First Run vs Dashboard)
- **S1** First Run: Create Default Place (wizard)
- **S2** Dashboard (Place-aware)
- **S3** Place Switcher (sheet/modal)
- **S4** Place Editor (create/edit)
- **S5** Settings
- **S6** Subscription Paywall (modal)
- **S7** Widgets: Configure (in-app config + previews)
- **S8** Manage Subscription (handoff to store, plus explanation)

### Supporting views (lightweight)
- **M1** Tile Details (optional, only for tiles that need it)
- **M2** Refresh Status / Rate Limit Notice (toast/sheet)
- **M3** Stale Data Explanation (small sheet)
- **M4** Widget Limit Sheet (optional helper that leads into paywall)

### Suggested route IDs (for engineering)
- `/first-run`
- `/dashboard`
- `/places/switcher`
- `/places/edit?placeId=...` and `/places/new`
- `/settings`
- `/paywall?trigger=...`
- `/widgets`
- `/subscription/manage`

---

## 5) Global navigation model (MVP)

### Top-level navigation
- Default landing screen after setup: **Dashboard (S2)**
- Global controls on Dashboard:
  - **Place chip** (opens Place Switcher S3)
  - **Settings icon** (opens Settings S5)
- The Dashboard stays the home base; everything returns here.

### Back behavior (platform-friendly)
- iOS: back gestures and nav back where appropriate; modals dismiss downward.
- Android: system back closes sheets/modals first, then returns to Dashboard, then exits app.

---

## 6) Core flows (Mermaid)

### 6.1 App launch and first-run routing
```mermaid
flowchart TD
  A["App Launch"] --> B{"Has default Place?"}
  B -- "No" --> C["S1 First Run: Create Default Place"]
  B -- "Yes" --> D["S2 Dashboard"]

  C --> E{"Valid Place created?"}
  E -- "No" --> C
  E -- "Yes" --> F["Persist Place locally"]
  F --> D
```

Notes
- First run is not skippable. User must create exactly one default Place.
- “Living” is recommended, but user can pick Visiting or Other without friction.

---

### 6.2 First-run: Create Default Place (wizard)
```mermaid
flowchart TD
  A["S1 First Run Start"] --> B["Step 1: Name Place + Badge"]
  B --> C["Step 2: Home system + Destination system"]
  C --> D["Step 3: Time zones (Home + Local)"]
  D --> E["Step 4: Enable tile group defaults"]
  E --> F["Step 5: Weather city + Currency"]
  F --> G["Review + Create"]
  G --> H["Create Default Place + Enter Dashboard"]
```

Wizard step details
- Step 1: Name + badge/type (Living, Visiting, Other)
  - Helper copy: “You can create more Places later.”
- Step 2: Home system and destination system
  - Example: US customary vs Metric
- Step 3: Time zones
  - Default: Home + Local
- Step 4: Tile group defaults
  - Living: Weather, Time, Distance/Speed, Weight, Currency
  - Visiting: Weather, Time, Currency, Distance/Speed
  - Other: Minimal starter set
- Step 5: Context (locked defaults)
  - Weather location: **pick a city/region** (no current-location toggle in MVP)
  - Currency: choose base and local currencies
    - If badge is **Visiting**, currency is enabled by default

---

### 6.3 Dashboard flow (the home base)
```mermaid
flowchart TD
  A["S2 Dashboard"] --> B{"User action"}
  B --> C["Tap Place chip"]
  B --> D["Tap Settings"]
  B --> E["Tap a Tile"]
  B --> F["Pull to refresh"]
  B --> G["Reorder tiles (optional)"]
  B --> H["Tap widget hint (optional)"]

  C --> I["S3 Place Switcher"]
  D --> J["S5 Settings"]
  E --> K["M1 Tile Details (only if needed)"]
  F --> L["Refresh attempt"]
  L --> M{"Rate limit OK?"}
  M -- "No" --> N["M2 Rate limit notice"]
  M -- "Yes" --> O["Fetch weather and rates"]
  O --> P{"Network OK?"}
  P -- "No" --> Q["Show cached values with stale state"]
  P -- "Yes" --> R["Update cache + timestamps"]
  N --> A
  Q --> A
  R --> A
```

Dashboard content states
- Fresh: normal display
- Stale but usable: subtle warning state, “tap for details”
- No data yet: empty state prompts user to configure weather/currency for the active Place

---

## 7) Place flows

### 7.1 Place switcher
```mermaid
flowchart TD
  A["S2 Dashboard"] --> B["S3 Place Switcher"]
  B --> C{"Select action"}

  C --> D["Select Place"]
  C --> E["Create new Place"]
  C --> F["Edit Place"]
  C --> G["Reorder Places"]
  C --> H["Delete Place"]

  D --> I["Set active Place"]
  I --> A

  E --> J["S4 Place Editor (New)"]
  F --> K["S4 Place Editor (Edit)"]
  J --> A
  K --> A

  H --> L{"Is default Place?"}
  L -- "Yes" --> M["Disallow delete; offer Change default flow"]
  L -- "No" --> N["Confirm delete"]
  N --> B
```

Rules
- There is always exactly one default Place.
- Default Place cannot be deleted. It can be changed.

### 7.2 Place editor (create/edit)
```mermaid
flowchart TD
  A["S4 Place Editor"] --> B["Basics: Name + Badge"]
  B --> C["Systems: Home + Destination"]
  C --> D["Time zones: Home + Local"]
  D --> E["Tile group toggles"]
  E --> F["Weather city + Currency"]
  F --> G["Save"]
  G --> H{"Validation OK?"}
  H -- "No" --> A
  H -- "Yes" --> I["Persist locally + return"]
```

---

## 8) Widgets flows (display-only MVP)

### 8.1 Configure widgets (in-app)
Widgets are configured inside the app (S7). Widgets then read from shared cached snapshots written by the app.

```mermaid
flowchart TD
  A["S5 Settings"] --> B["S7 Widgets Configure"]
  B --> C["Choose widget type and size preview"]
  C --> D["Pick Place for widget"]
  D --> E["Pick tile(s) for widget"]
  E --> F{"Within free widget allowance?"}

  F -- "Yes" --> G["Save widget config"]
  G --> H["Write widget snapshot to shared storage"]
  H --> I["Prompt user to add widget on OS home screen"]

  F -- "No" --> J["M4 Widget limit sheet"]
  J --> K["S6 Paywall (trigger: widgets)"]
```

Widget config rules (MVP)
- Each widget points at one Place.
- Widget shows a curated subset of tiles suitable for its size.
- Widget never implies live data. It shows freshness cues based on cache timestamps.

### 8.2 Widget data refresh model (high-level)
```mermaid
flowchart TD
  A["Widget renders"] --> B["Read cached snapshot"]
  B --> C{"Snapshot present?"}
  C -- "No" --> D["Show Open Unitana to set up state"]
  C -- "Yes" --> E["Render values + freshness cues"]

  F["App refresh succeeds"] --> G["Write updated snapshot"]
  G --> H["Widget updates on next allowed refresh"]
```

---

## 9) Subscription flows (trial + gating)

### 9.1 Paywall triggers (MVP)
Primary trigger (locked default)
- Exceeding the free widget allowance (recommended: 2nd widget attempt)

Secondary triggers (optional later, not required for MVP flow correctness)
- Create more than 3 Places
- Advanced customization depth (if introduced later)

### 9.2 Paywall flow
```mermaid
flowchart TD
  A["User hits gated action"] --> B["S6 Paywall modal"]
  B --> C{"User choice"}
  C --> D["Start trial / Subscribe"]
  C --> E["Not now"]
  C --> F["Restore purchases"]

  D --> G["Store flow"]
  G --> H{"Success?"}
  H -- "Yes" --> I["Unlock entitlement"]
  H -- "No" --> J["Show friendly error + stay in app"]

  E --> K["Return to previous screen"]

  F --> L["Restore via store"]
  L --> M{"Restored?"}
  M -- "Yes" --> I
  M -- "No" --> J
```

Copy rule
- Never promise a free trial. Eligibility can vary.

---

## 10) Data refresh, offline, and staleness states

### 10.1 Pull-to-refresh behavior (in-app)
- Pull-to-refresh attempts a network fetch for weather and rates.
- If rate-limited:
  - Show a calm notice: “Updated recently. Try again in a bit.”
- If offline:
  - Keep cached data visible
  - Mark stale where applicable
  - Offer “Try again” when network returns

### 10.2 Staleness UI rules (applies to tiles and widgets)
- Fresh: normal state
- Stale: subtle warning icon or muted label, plus “tap for details”
- Very stale or missing: provide a clear next step, like “Open Unitana to refresh”

---

## 11) Error and edge flows (MVP essentials)

### 11.1 No network on first run
- User can still create a Place and reach the Dashboard.
- Weather and currency tiles show setup or “no data yet” states until a refresh succeeds.

### 11.2 DST and time zone surprises
- Time zone tile always displays both zones with clear abbreviations.
- If DST changes cause offsets to shift, show it as a normal fact, not an error.

### 11.3 Invalid inputs
If the app includes in-app converter inputs (not widgets), then:
- Sanitize and validate input
- Disallow nonsensical values with gentle guidance
- Preserve last valid input where possible

---

## 12) Accessibility flow requirements (cross-cutting)
- All tappable rows and tiles must have clear labels and hints.
- Place switching must be screen-reader-friendly and easy to reorder.
- Dynamic type must not truncate critical dual values; prefer wrapping and hierarchy over tiny fonts.

---

## 13) Implementation notes for engineering
- Treat navigation as a stable contract: screen IDs and route names should not churn.
- Treat Place and widget snapshot as stable data contracts: it reduces rewrite risk later.
- Widgets must read from a single cached snapshot per Place (or per widget config) to avoid expensive computation and unpredictable refresh.
