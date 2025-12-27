# Testing (Unitana)

Unitana aims to keep a small set of fast widget tests that catch the kinds of regressions we have repeatedly hit:

- RenderFlex overflows on small devices
- wizard navigation gating changes
- modal and bottom-sheet behavior
- analyzer churn caused by missing imports, renamed keys, or signature drift

## Run the full verification sequence

From `app/unitana/`:

```bash
dart format .
flutter analyze
flutter test
flutter run
```

Or from the repo root:

```bash
./tools/verify.sh
```

## Test conventions

### Smallest phone surface size

When a UI is sensitive to tile constraints, tests should set a small surface size so overflows are caught early:

- common target: `Size(320, 568)`

Always reset the surface size in a `finally` block so later tests are not affected.

### Prefer stable selectors

- Use `ValueKey('...')` and `find.byKey(...)` rather than matching on visible copy.
- Text copy changes often during UI tuning; keys stay stable.

### Treat FlutterError as a test failure

Many layout problems surface as Flutter framework errors rather than thrown exceptions. Regression tests should capture `FlutterError.onError` and fail if any errors are reported during pump and interaction.

## Current regression tests

Located in `app/unitana/test/`:

- `dashboard_regression_test.dart`: dashboard renders on a small surface size, and the overflow menu bottom sheet opens without framework errors.
- `first_run_review_regression_test.dart`: selects curated cities (Home and Destination) and reaches the Review step without layout errors.
