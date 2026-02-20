# Release Sync - 2026-02-20 (v1.0.0 realignment)

## Scope synced from main to development
- Dashboard/profile edit mode drag now starts from long-press on tile.
- Dashboard `+` slot insertion is anchor-stable to selected slot.
- Unit Price modal copy/layout readability pass:
  - `Pack size`/`Quantity` -> `Units`
  - helper copy clarified
  - non-interactive tutorial step styling
  - comparison result lines wrap on explicit value lines
- Settings no longer exposes auto-suggest profile by location.
- About sheet copy corrected:
  - legalese uses standard copyright format
  - build channel text is environment-driven
  - data-provider text reflects runtime behavior.

## Runtime provider contract (current)
- Weather runtime source: Open-Meteo.
- WeatherAPI: development diagnostics path only.
- Currency runtime source: Frankfurter (primary) with open.er-api fallback.

## Permission impact
- Location-based profile suggestion is removed from user settings surface.
- No user-visible location-toggle flow remains in settings.
