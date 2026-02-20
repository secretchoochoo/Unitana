# Unitana Flutter App

## Commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

## Main Paths

- Entry: `lib/main.dart`
- App shell/state: `lib/app/`
- Dashboard feature: `lib/features/dashboard/`
- First-run wizard: `lib/features/first_run/`
- Shared city/data layer: `lib/data/`
- Localization: `lib/l10n/`
- Tests: `test/`

## Quality Gates

Run these before committing:

```bash
dart format .
flutter analyze
flutter test
```

## Notes

- Goldens are opt-in and are not required for standard test runs.
- Prefer stable `ValueKey` contracts in UI tests.
