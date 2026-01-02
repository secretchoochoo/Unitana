# Dashboard spec (canonical)

This document defines the stable behavior and UI contract for the dashboard.

Files of record:
- `app/unitana/lib/features/dashboard/dashboard_screen.dart`
- `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart`
- `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`

If you change any behavior covered here, you must update this spec and any affected tests.

## Product intent

The dashboard is a travel-first decoder ring. It should surface “dual reality” side-by-side so repeated exposure teaches users:
- home vs destination time
- metric vs imperial
- local vs reference currency

## Non-negotiables

- Repo stays green: `dart format .` then `flutter analyze` then `flutter test`.
- No public widget API churn unless strictly necessary.
- One `toolId` per tool. Lenses are presentation/presets only.
- Stable keys for anything tests or persistence touch.
- Device clock is the source of truth; timezone conversion is display-only.

## Layout contract

Top to bottom:

1. **Places Hero V2**
   - No weather icon block.
   - Clocks are top priority.
   - Sunrise/Sunset pill exists.
   - Wind and Gust are separate lines.
   - Full hero contract is defined in `docs/ui/PLACES_HERO_V2_SPEC.md`.

2. **Dashboard tiles**
   - Tiles are the user’s “home screen” of conversions.
   - Tiles live in a persistent layout model.

## Tools access

- The ToolPicker is opened from the **top-left tools icon**.
- The redundant “Quick Tools” lens does not exist; discovery is handled by:
  - Most Recent
  - Search

## Tile behavior

### Defaults and persistence

- Default tiles are defined in `ToolDefinitions.defaultTiles`.
- Default tiles can be removed.
- Removing a default tile creates a **hidden-default** state that persists.
- Restoring a removed default via the ToolPicker restores it **without duplicates**.
- User-added tiles persist across launches.

### Reset Dashboard Defaults

A menu action exists:

- **Reset Dashboard Defaults** restores defaults from `ToolDefinitions.defaultTiles`.
- It clears:
  - hidden-default state
  - user-added tiles
  - layout edits

### Color and icon rules

- Dashboard tiles inherit:
  - per-tool tint (icon + accent)
  - per-lens accent mapping
- Avoid global fallback accents unless a tool is truly unmapped.

### Keys and test stability

- Any widget that affects persistence or tests must have stable keys.
- Do not change Key names without updating tests.

## Modal behavior

- Tools run in a modal surface (bottom sheet).
- “+ Add Widget” is an explicit affordance that adds a tile.
- Confirmations must remain visible while modals are open (toast or in-modal notice).

