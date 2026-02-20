# Unitana — Product Truth (Current Runtime)

Updated: 2026-02-19

## Metadata
- Owner: Product + Engineering
- Source of truth: Current runtime behavior in `app/unitana/lib/`
- Last validated against code: 2026-02-19

## Product in one sentence
Unitana is a dual-reality travel dashboard that keeps home and destination context visible at the same time for weather, time, currency, and conversion decisions.

## Why it exists
People relocating or traveling operate in two systems at once (units, time, weather context, currency). Unitana reduces constant mental translation by presenting both realities in one stable surface.

## Core model

### Place
A Place is one city context with:
- city + country
- timezone
- derived unit/currency defaults

### Profile
A Profile is the working unit for the app:
- one Home place
- one Destination place
- profile name
- profile-scoped dashboard layout/settings

Multiple profiles are supported. New profiles default to `Profile #N` and are editable in wizard step 3.

## Current first-run contract
The first-run/profile wizard is a 3-step flow:
1. Welcome / intro
2. Place selection (Home + Destination) with live hero preview
3. Confirm/save (profile name + theme + lo-fi audio controls)

## Current dashboard contract
- Hero supports Home/Destination reality toggle.
- Pull-to-refresh is available via `RefreshIndicator`.
- Tools launch from the tools button and support add-to-dashboard flows.
- Settings surface is unified (profiles, edit widgets, reset defaults, developer tools, app settings).
- Developer Tools are compile-time gateable via `UNITANA_DEVTOOLS_ENABLED`.

## Default dashboard tiles (fresh install)
Top-6 defaults:
- Temperature
- Currency
- Baking
- Distance
- Time
- Price Compare

## Tool surface model
Unitana tools currently ship as three surface types:
- Converter tools (input -> result)
- Lookup/matrix tools (table-first reference and copy workflows)
- Dedicated tools (domain-specific workflows: weather/time/jet lag/tip/tax/etc.)

## Data trust and transparency
- Network-backed data is freshness-aware.
- Cached/stale states are explicit.
- UI avoids claiming precision where data is approximate.
- Lookup tools show explicit missing mappings (`—`) instead of inferred values.

## Quality gates
Changes are expected to keep the repo green:
- `dart format .`
- `flutter analyze`
- `flutter test`

## Current non-goals
- Cloud account sync
- Background “always-live” guarantees beyond current refresh/caching semantics
- Brand-fit prediction for clothing sizes (reference-only matrix scope)
