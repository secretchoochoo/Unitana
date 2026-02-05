# Goldens

Golden tests are deterministic. They do not allow runtime font downloading.

## One-time font prerequisite

Before generating or updating goldens, fetch the required TTFs into the app asset bundle:

```bash
cd ~/unitana
./tools/fetch_google_fonts_for_tests.sh

cd ~/unitana/app/unitana
flutter pub get
```

## Update goldens

```bash
cd ~/unitana/app/unitana
UNITANA_GOLDENS=1 flutter test test/goldens
flutter test --update-goldens test/goldens/places_hero_v2_goldens_test.dart
flutter test --update-goldens test/goldens/pinned_mini_hero_goldens_test.dart
```

Notes
- Goldens are **opt-in**. Normal `flutter test` runs skip golden expectations.
- To run all goldens without updating, set `UNITANA_GOLDENS=1`.
- `--update-goldens` also enables golden writes even if `UNITANA_GOLDENS` is not set.

PNGs are written to the paths referenced by each test, typically under `test/goldens/goldens/`.

Capture notes
- Goldens are captured at a fixed surface size in the tests (390x844).
- If your local capture looks slightly off, double-check you are not running with any custom device pixel ratio overrides.


## New goldens

### Dashboard screen (full screen)

- `dashboard_phone_expanded.png`: dashboard at scroll position 0 (header expanded)
- `dashboard_phone_collapsed.png`: dashboard scrolled enough to collapse the header

### First run wizard

- `wizard_step2_phone.png`: Slide 2 (Pick Your Places) on a phone-sized surface
- `wizard_step3_phone.png`: Slide 3 (Name and Confirm) on a phone-sized surface
