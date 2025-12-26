# AI handoff

This file is the starting point for any new chat or assistant session.

## Product thesis

Unitana is a travel-first decoder ring. It shows two realities side-by-side (metric and imperial, 12-hour and 24-hour, time zones, currency) so users learn through exposure instead of constant manual translation.

## Repository layout

- Flutter app: `unitana/app/unitana`
- Docs: `unitana/docs`

## Current MVP focus

- First run onboarding is a 5-step wizard driven by a `PageView`.
- City selection is offline-friendly and uses a curated fallback list if the full dataset cannot be loaded.

## Known constraints

- Avoid broad refactors that touch models, widgets, and tests in one patch.
- Treat widget keys as a public API. See `docs/contracts.md`.
- Prefer small, reversible diffs.

## Reset behavior

The Dashboard has a temporary developer reset. It should:

1) Clear stored app state (SharedPreferences via `UnitanaAppState.resetAll`).
2) Clear in-process caches (CityRepository via `resetCache`).
3) Reroute to the first run onboarding flow.

## Testing guidance

- Widget tests should prefer keys over text.
- Onboarding pages must be scroll-safe in small viewports.
