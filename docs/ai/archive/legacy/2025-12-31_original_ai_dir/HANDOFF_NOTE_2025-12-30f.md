# Unitana Handoff Note — 2025-12-30f

## What changed
- Updated `app/unitana/test/dashboard_tool_insertion_persistence_test.dart` to make the long-press "Remove tile" regression test reliable in the scrollable dashboard grid:
  - Ensures the target tile is visible before gesture simulation.
  - Prefers long-pressing the inner label ("Added Area") when present to avoid hit-test edge cases.
  - Falls back to long-pressing the tile itself when needed.

## Why
Flutter test hit-testing can miss or warn on long-press targets inside scrollable/stacked render trees, even when the widget exists. This makes the regression test flaky. The updated approach targets a more stable gesture surface without changing runtime behavior.

## Verify
From repo root:
- `dart format .`
- `flutter analyze`
- `flutter test`
