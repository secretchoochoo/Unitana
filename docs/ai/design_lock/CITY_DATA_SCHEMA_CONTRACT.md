# CITY DATA SCHEMA CONTRACT (PACK A LOCK)

## Scope
Canonical schema and lifecycle for `app/unitana/assets/data/cities_v1.json`.

This dataset is the source of truth for:
- city picker coverage
- timezone display defaults
- weather/AQI/pollen geolocation inputs
- city->currency defaults
- onboarding unit + 12/24h defaults

## Required fields (every record)
- `id` (string, non-empty, stable)
- `cityName` (string, non-empty)
- `countryCode` (ISO-3166 alpha-2, string length 2)
- `timeZoneId` (IANA timezone string, non-empty)
- `currencyCode` (ISO-4217 alpha-3, string length 3)
- `defaultUnitSystem` (`metric` or `imperial`)
- `defaultUse24h` (boolean)
- `lat` (number in `[-90, 90]`)
- `lon` (number in `[-180, 180]`)

Optional enrichment fields:
- `admin1Code`, `admin1Name`, `countryName`, `iso3`, `continent`

## Ownership
- Canonical source file: `app/unitana/assets/data/cities_v1.json`
- Generator: `app/unitana/tools/generate_cities_v1.py`
- Validator script: `app/unitana/tools/validate_cities_v1.py`
- Validator test: `app/unitana/test/city_data_schema_validation_test.dart`
- Runtime validator helpers: `app/unitana/lib/data/city_schema_validator.dart`

## Lifecycle
1. Update input dumps from GeoNames (`cities15000.zip`, `cities1000.zip`, `admin1CodesASCII.txt`, `countryInfo.txt`).
2. Regenerate:
   - `python3 tools/generate_cities_v1.py --geonames-dir <dir> --output assets/data/cities_v1.json`
3. Validate:
   - `python3 tools/validate_cities_v1.py`
   - `flutter test test/city_data_schema_validation_test.dart`
4. Run global gates:
   - `dart format .`
   - `flutter analyze`
   - `flutter test`

## Change control
Any schema or generation logic changes must update:
- `docs/ai/context_db.json` (`decisions` + `patch_log`)
- `docs/ai/handoff/CURRENT_HANDOFF.md`
- this contract file
