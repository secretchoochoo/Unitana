# Open-Meteo weather backend (spike)

## Why Open-Meteo
- JSON API, simple query by lat/lon.
- No secret required for free/non-commercial usage.
- Supports sunrise/sunset and an is_day flag.
- Uses WMO weather codes (consistent across models).

## Key constraints
- The free endpoint is *non-commercial* only.
- Commercial usage requires a customer-prefixed host and an apikey.

## Implementation approach in Unitana
- Keep weather network calls **off by default** for hermetic demo builds and tests.
- Enable explicitly with Dart defines:
  - `--dart-define=WEATHER_NETWORK_ENABLED=true`
  - `--dart-define=WEATHER_PROVIDER=openmeteo`

## Endpoint shape
- `GET https://api.open-meteo.com/v1/forecast`
- Required: latitude, longitude
- Requested fields (MVP):
  - `current=temperature_2m,wind_speed_10m,wind_gusts_10m,weather_code,is_day`
  - `daily=sunrise,sunset`
  - `forecast_days=1`
  - `timezone=UTC`
  - `timeformat=unixtime`
  - `wind_speed_unit=kmh`

## Mapping
- WMO `weather_code` is mapped in-model into Unitana's stable SceneKey catalog.
- Coarse DevTools overrides remain provider-agnostic.

## Follow-ups (future slice)
- Add an explicit DevTools toggle for WEATHER_NETWORK_ENABLED and provider selection.
- Add geocoding fallback when lat/lon is unavailable.
- Expand mapping to separate rain intensity and snow intensity with more nuance.
