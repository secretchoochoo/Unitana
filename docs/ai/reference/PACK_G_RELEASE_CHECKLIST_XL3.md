# Pack G Release Checklist (XL 3)

Date: 2026-02-08
Scope: Pack G final checklist/signoff artifacts with B/C closure-proof links.

## Compliance and legal surfaces
- [x] Settings exposes deterministic `About` entry point.
- [x] Settings exposes deterministic `Licenses` entry point.
- [x] About content uses localized fallback-safe copy keys.
- [x] Licenses route is reachable from dashboard settings path.
- [x] Contracts locked by widget tests:
  - `app/unitana/test/dashboard_settings_about_licenses_test.dart`
  - `app/unitana/test/dashboard_language_settings_test.dart`

## Accessibility and interaction consistency
- [x] Weather forecast mode controls retain deterministic semantics/toggle keys.
- [x] Weather forecast swap affordance remains deterministic/tappable.
- [x] Narrow layout overflow-safe weather contract remains locked.
- [x] Regression suite:
  - `app/unitana/test/weather_summary_narrow_layout_smoke_test.dart`
  - `app/unitana/test/weather_summary_tile_open_smoke_test.dart`
  - `app/unitana/test/weather_summary_close_button_smoke_test.dart`

## Pack B closure-proof contracts (weather/time/AQI/pollen)
- [x] Representative global city weather/env coverage locked:
  - `app/unitana/test/dashboard_live_data_global_city_coverage_test.dart`
- [x] Failure fallback truthfulness locked:
  - `app/unitana/test/dashboard_live_data_refresh_fallback_test.dart`
- [x] Mixed success/fallback batch behavior locked:
  - `app/unitana/test/dashboard_live_data_refresh_fallback_test.dart`

## Pack C closure-proof contracts (currency reliability/global mapping)
- [x] Country->currency mapping coverage vs canonical city dataset:
  - `app/unitana/test/country_currency_map_coverage_test.dart`
- [x] Global currency conversion and UI mapping contracts:
  - `app/unitana/test/dashboard_currency_global_mapping_test.dart`
  - `app/unitana/test/dashboard_currency_rate_coverage_test.dart`
- [x] Outage/retry/cache semantics including stable multi-currency preservation:
  - `app/unitana/test/dashboard_currency_retry_cache_semantics_test.dart`

## Guardrails
- [x] City picker performance budget remains passing:
  - `app/unitana/test/city_picker_perf_budget_test.dart`
- [x] Goldens remain opt-in only.
- [x] Core non-negotiables preserved (collapsing header morph, hero key uniqueness, wizard preview test key policy).

## Signoff
- [x] `dart format .`
- [x] `flutter analyze`
- [x] `flutter test`
- [x] Handoff/context/prompt refreshed for next slice
