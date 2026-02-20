# Unitana — Runtime Flows

Updated: 2026-02-19

## Metadata
- Owner: Product + Engineering
- Source of truth: Navigation and flow behavior in `app/unitana/lib/features/`
- Last validated against code: 2026-02-19

## 1) App bootstrap

1. App loads persisted state.
2. If onboarding/profile baseline is incomplete, user enters first-run wizard.
3. Otherwise user lands on dashboard.

## 2) First-run and profile creation flow

Wizard steps:
1. Welcome
2. Places
3. Confirm

Step 2 behavior:
- User picks Home and Destination cities.
- Hero preview updates using selected places.

Step 3 behavior:
- User sets/edits profile name.
- User can preview/select theme mode.
- User can toggle lo-fi audio and adjust volume.
- Save persists profile and returns to dashboard context.

## 3) Dashboard primary flow

Entry actions:
- Toggle Home/Destination reality from hero controls.
- Pull down to refresh data.
- Open tools picker from tools button.
- Open unified settings menu from menu button.

Tool launch:
- User selects tool from picker/search.
- Tool opens modal surface (converter, matrix/lookup, or dedicated).
- User can run conversion/lookup and optionally add widget to dashboard.

## 4) Unified settings flow

Current settings entry includes:
- Profiles
- Edit Widgets
- Reset Dashboard Defaults
- Developer Tools (when enabled)
- Theme
- Language
- Auto-suggest profile by location
- Lo-fi audio controls

## 5) Profiles flow

- User opens Profiles from settings.
- User can switch active profile.
- User can create new profile, then complete wizard flow.
- Profile changes reflect in dashboard context and tile content.

## 6) Tool matrix/lookup flow

For matrix tools (shoes, paper, mattress, clothing, cups/grams):
- Table is primary interaction surface.
- Tap value cell copies value.
- Tap reference cell reselects row.
- Pagination/swipe is used for multi-system column readability.
- Missing mappings display as `—`.

## 7) Data freshness and reliability flow

- Weather/currency data tracks freshness and stale conditions.
- UI signals stale/cached states rather than hiding uncertainty.
- Retry semantics are explicit where applicable.

## 8) Release/public-build flow (in progress)

Current code supports compile-time hiding of Developer Tools.
Broader public-build separation/versioning strategy is tracked in AI reference docs and upcoming XL slices.
