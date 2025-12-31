# SEV-1 Postmortem: Places Hero Tile Refactor Broke Build

**Date:** 2025-12-27

**Severity:** SEV-1 (build and all tests broken)

**Status:** Resolved via rollback to last known-good baseline

**Primary area:** Dashboard (Places Hero tile refactor)

## Summary

We attempted a large dashboard UI refactor to replace the existing Destination/Home tiles with a single full-width Places Hero widget (segmented toggle, dual-reality layout, and integrated weather and currency). The implementation introduced widget API drift and missing symbols, which caused `flutter analyze` to fail and prevented widget tests from compiling.

We restored the repository to a stable baseline (app boots on iOS, `flutter analyze` and `flutter test` pass). We are preserving the aspirational design and the lessons learned so we can re-implement the feature using smaller, reversible steps.

## Impact

- Local build broken for the implementation branch/worktree.
- All widget and smoke tests failed to compile due to dashboard widget errors.
- Work could not be safely merged without a rollback.

## Detection

Detected immediately by `flutter analyze` and `flutter test` output showing errors in `lib/features/dashboard/widgets/places_hero_tile.dart`, including null-safety type mismatches, undefined identifiers, missing required named parameters, and duplicate named arguments.

## Timeline

Times are approximate and based on terminal output and patch filenames.

- T0: Begin refactor of Places Hero tile to match the new mock.
- T0 + 1: `flutter analyze` reports multiple errors in `places_hero_tile.dart`.
- T0 + 2: A compile-fix patch is attempted, but tests still fail to load due to API drift and missing symbols.
- T0 + 3: Decision made to stop iteration and rollback to the last known-good baseline.
- T0 + 4: Baseline restored; `flutter analyze` and `flutter test` return clean.

## Root cause

The refactor changed and referenced multiple public-facing APIs at once (widget constructors, named parameters, helper methods, and domain types). These changes were not made in a single coordinated pass, resulting in a mismatch between:

- What call sites passed vs what constructors required
- What types were referenced vs what the codebase defined
- What helper methods were called vs what was implemented

## Contributing factors

- Null-safety boundary ambiguity: optional selection values were passed into non-null required parameters.
- Invented or missing domain types: `UnitSystem` was referenced without verifying the existing model layer.
- Constructor parameter drift: new named parameters (`prefersMetric`, `localLabel`, `homeLabel`, `isCompact`) were used without matching constructors.
- Partial implementations: helper methods such as `_formatTime` were referenced but not wired into the widget class where used.
- High change surface area: the refactor touched layout, state, formatting, and demo data generation in one pass.

## What went well

- The build gates (`flutter analyze`, `flutter test`) correctly prevented a broken dashboard from advancing.
- The rollback path was available and fast (stable baseline preserved locally).
- We captured the aspirational UI mock and acceptance criteria so the intent is not lost.

## What went poorly

- Too many concurrent changes created a wide failure blast radius.
- API drift accumulated over multiple edits, then failed hard.
- The refactor lacked a parallel implementation strategy (new widget alongside old).

## Resolution

Rollback to the last known-good baseline where the app boots and tests pass. Preserve the refactor intent through:

- This postmortem
- Updates to `docs/ai/context_db.json`
- Updates to workflow rules in `docs/ai/WORKING_WITH_CHATGPT.md`

## Action items

### Immediate

- Re-implement the Places Hero widget as a new widget file (parallel to the existing dashboard UI).
- Add focused widget tests for the new widget before wiring it into the dashboard.
- Add a small feature flag or temporary toggle to switch between old and new dashboard layouts.

### Workflow and quality

- Enforce a refactor cadence: `flutter analyze` must stay green after each file-level change.
- Freeze widget public APIs during refactor; modify signatures only once at the integration pass.
- Require a symbol audit step before introducing new domain enums or models (verify the symbol exists in the repo).
- Add a lightweight CI step (or a pre-push script) to run analyze and tests.

## Follow-up slice definition

The next implementation slice should be strictly incremental:

1. Create a new `PlacesHeroCardV2` widget (or similar) that takes existing `Place` models and renders static content from the mock.
2. Add tests for toggle behavior and layout stability.
3. Wire the widget into the dashboard behind a flag.
4. Only after the above is stable, replace the old widgets and delete dead code.
