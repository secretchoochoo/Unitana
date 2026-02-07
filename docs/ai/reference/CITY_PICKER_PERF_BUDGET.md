# City Picker Perf Budget

## Scope
This budget tracks search/index performance for both city-picker surfaces that now use `CityPickerEngine`:
- profile wizard city picker (`CityPicker`)
- Time/Jet Lag city + timezone picker (`ToolModalBottomSheet`)

## Dataset baseline
- Source: `app/unitana/assets/data/cities_v1.json`
- Canonical row count baseline: `33,257`
- Last baseline run date: `2026-02-07`

## Budget thresholds
Enforced in `app/unitana/test/city_picker_perf_budget_test.dart`:
- wizard index build: `<= 1500 ms`
- time picker city-entry build: `<= 1500 ms`
- representative search queries (`tokyo`, `EST`, `asia/tokyo`): `<= 250 ms`

Measurement mode:
- each operation uses `bestOf3` in a single test process
- thresholds are intentionally conservative to avoid CI flake while still catching major regressions

## Current baseline snapshot (2026-02-07)
From local test output:
- `cities=33257`
- `wizardBuildMs=278`
- `timeBuildMs=0`
- `tokyoMs=1`
- `estAliasMs=0`
- `tzPrefixMs=0`

## Notes
- `timeBuildMs` can round to `0` because `Stopwatch.elapsedMilliseconds` has millisecond resolution and hot-cache runs are very fast.
- Keep `UNITANA_PICKER_PERF_TRACE=1` available for interactive tracing when profiling slow devices.
- If budgets need adjustment, update this file and `city_picker_perf_budget_test.dart` in the same commit.
