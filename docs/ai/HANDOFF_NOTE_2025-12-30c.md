# HANDOFF NOTE — 2025-12-30c (Analyzer clean-up)

## What changed
- Dashboard menu → **Tools** action no longer captures a `BuildContext` across an async gap.
  - Replaced the `rootContext` capture + `Future.microtask(() => ...)` closure with a state method (`_openToolPickerFromMenu`) that uses the State’s `context` only when mounted.
- Replaced deprecated `Color.withOpacity(...)` usages in the dashboard “+” tile with `withValues(alpha: ...)`.

## Why
- Clears `flutter analyze` info-level findings:
  - `use_build_context_synchronously` in `dashboard_screen.dart`
  - `deprecated_member_use` for `withOpacity` in `dashboard_board.dart`

## Verification
Run from repo root:
- `dart format .`
- `flutter analyze` (expected: **0 issues**)
- `flutter test` (expected: **all green**)

## Notes
- No user-facing behavior changes intended; this is a polish + hardening patch only.
