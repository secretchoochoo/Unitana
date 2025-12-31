# Unitana Handoff Note — 2025-12-30e

## What changed
- Replaced `app/unitana/test/dashboard_tool_insertion_persistence_test.dart` with a version that matches the current Unitana app APIs:
  - Uses `UnitanaAppState(UnitanaStorage())` and `DashboardScreen(state: ...)`.
  - Uses the current `Place` constructor fields (`cityName`, `timeZoneId`, `unitSystem`, `use24h`, etc.).
  - Keeps regression coverage for:
    - Tool insertion via a `+` slot and persistence across rebuild.
    - Long-press **Remove tile** for a user-added tile and persistence across rebuild.

## Why
The prior test file variant referenced non-existent modules (`AppState`, `AppStorage`, `package:unitana/storage/app_storage.dart`) and mismatched widget constructors, causing compilation failures.

## Verify
From repo root:
- `dart format .`
- `flutter analyze`
- `flutter test`
