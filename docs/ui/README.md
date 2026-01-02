# UI Assets

This folder is the single home for UI artifacts: simulator screenshots, markup images, and mockups.

## Specs

- Places Hero V2: `PLACES_HERO_V2_SPEC.md`
- Dashboard: `DASHBOARD_SPEC.md`

## Folder map

- `docs/ui/screenshots/raw/` – unedited simulator screenshots
- `docs/ui/screenshots/markup/` – screenshots with annotations
- `docs/ui/mockups/` – design mockups (Figma exports, etc.)

## Naming schema

Use this pattern:

`YYYY-MM-DD_context_device_variant.ext`

Where:
- `context` is a short slug (e.g. `dashboard_v2`, `onboarding_review`, `city_picker`)
- `device` is `iphone_13mini`, `iphone_15pro`, `pixel_8`, etc.
- `variant` is one of: `raw`, `markup`, `mock`

Examples:
- `2025-12-28_dashboard_v2_iphone_13mini_raw.png`
- `2025-12-28_dashboard_v2_iphone_13mini_markup.png`
- `2025-12-29_city_picker_overflow_iphone_13mini_raw.png`

## Rules

- Never overwrite old screenshots. Add a suffix (`_v2`, `_v3`) if needed.
- Keep markup separate from raw so raw images remain usable for future comparisons.
- Prefer PNG for screenshots and SVG/PDF for vector mockups.
