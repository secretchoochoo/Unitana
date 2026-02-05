# Hero dual-world display contract

## Intent
The hero is a "two places, one glance" dashboard. It should help a user reason about:

- **Which place is currently selected** (context).
- **What the value means in that place** (primary meaning).
- **How to translate that meaning across systems** when translation is useful.

The hero toggle selects **place context**. Only show a second value when that second value is clearly a translation of the same underlying fact.

## Data categories

### Category 1: Convertible quantities
A single physical quantity expressed in two unit systems.

Examples: temperature, distance, pressure, volume.

Rules:
- Toggle selects the **place** whose data is shown.
- Display **the selected place** in its primary unit (based on the selected place's system).
- Optionally display a **secondary** value only if it is a conversion of the same value, not a different place.
- Ordering is always: **primary (selected place's system)** then **secondary (converted)**.

### Category 2: Time and time-zone teaching
A single moment expressed across two time zones.

Examples: current clock line, sunrise/sunset.

Rules:
- Toggle selects the **local zone** (selected place).
- Show the local time first, then show the other zone in parentheses.
- Always include **timezone abbreviations** on both values.
- Use a single clock style per row to avoid mixed-format confusion:
  - Use the selected place's 12/24 preference for **both** values on that row.

Recommended format:
- `🌅 07:52 WET (00:52 MST)`
- `🌇 17:29 WET (10:29 MST)`

### Category 3: Location scalar indices
A value that is not meaningfully convertible.

Examples: AQI, pollen index.

Rules:
- Toggle selects the **place** whose value is shown.
- Show **one value only** for the selected place.
- Do not display a second place value inline unless the UI explicitly labels it as a comparison.

Label rules:
- Use clear labels even when short.
- If an abbreviation could be mistaken for a country code or a word fragment, add a clarifier.
  - Prefer: `Pollen idx 1.1` over `Pol 1.1`.

### Category 4: Currency conversion
A price teaching aid, not a realtime trading UI.

Rules:
- Toggle selects **spending context** (selected place). The base amount is shown in the selected city's currency.
- Always show the converted amount in the other city's currency.
- Prefer one stable teaching expression (MVP):
  - `€10.00 ≈ $11.00` (when Lisbon is selected)
  - `$10.00 ≈ €9.10` (when Denver is selected)
- Use grouping separators for large numbers.
- MVP uses 2 decimals for simplicity; long-term rule is currency-specific fraction digits (ISO 4217).

## Abbreviations and units

- Use abbreviations only when they are widely recognized in context.
- Prefer adding a short unit hint over inventing a shortened word.
- If a hint is needed (example: `idx`), make it visually distinct from the value (smaller/lower emphasis).

## Adding new hero pills

Before implementing a new hero pill:

1. Pick the category above.
2. Apply its rules exactly.
3. If a new pill doesn't fit any category, update this contract first.

This keeps the hero coherent and prevents "two different facts in one pill" confusion.
