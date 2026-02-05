# Goldens workflow

Unit tests and golden tests run with `GoogleFonts.config.allowRuntimeFetching = false` to avoid network dependency.

## Prerequisite: install fonts

```bash
cd ~/unitana
./tools/fetch_google_fonts_for_tests.sh

cd ~/unitana/app/unitana
flutter pub get
```

## Update goldens

```bash
cd ~/unitana/app/unitana
flutter test --update-goldens test/goldens/places_hero_v2_goldens_test.dart
flutter test --update-goldens test/goldens/pinned_mini_hero_goldens_test.dart
```
