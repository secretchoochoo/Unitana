# Next Chat Handoff (2025-12-27)

## Current repo state (known-good baseline)

- Branch: `main` (intended to track `origin/main`)
- Build status: `flutter analyze` and `flutter test` pass on the stable baseline that was restored after a failed dashboard refactor.
- UI status: Dashboard renders with the older tile composition (Destination/Home cards plus a tile grid). First-run wizard remains stable.

This handoff intentionally treats the baseline as the source of truth. The “dream” Places Hero widget is a target, not the current implementation.

## What we attempted (and rolled back)

Goal: Replace the old Destination/Home split with a single full-width “Places Hero” widget featuring:

- Segmented toggle: Destination (local reality) vs Home (home reality)
- One top-level reality toggle drives hero + tool tiles
- Circular refresh button for all live data

Outcome: The attempt broke compilation and cascaded into all widget tests failing. Root cause was widget API drift and missing or invented domain types (null-safety mismatch, constructor parameter mismatches, undefined `UnitSystem`, missing `_formatTime`, duplicate named args).

Rollback decision: Restore last known-good code, then preserve learnings in docs and the context database.

See:
- `docs/ai/POSTMORTEM_SEV1_PLACES_HERO_TILE_2025-12-27.md`
- `docs/ai/RETRO_2025-12-27.md` (addendum)
- `docs/ai/context_db.json` (Slice 13 entry)

## Inputs for the next implementation chat

Artifacts to provide to the next chat:

- Baseline repo zip (this exact restored baseline)
- `docs/ai/context_db.json` (updated)
- Reference images:
  - Older baseline screenshot (the working widget layout)
  - Aspirational Places Hero mock (the target)

## Re-implementation strategy (the safe way)

1. **Parallel widget approach**
   - Add a new Places Hero widget next to the existing dashboard widgets.
   - Do not change public constructors of existing widgets during the first pass.
   - Wire the new widget behind a temporary feature flag or a local toggle in the dashboard screen.

2. **Single source of truth for selected place**
   - Introduce a small, testable state holder (ValueNotifier, provider, or existing state pattern) that drives:
     - Places Hero primary/secondary
     - Tool tiles primary/secondary unit displays

3. **Refresh action**
   - Add a circular refresh icon button.
   - Implement refresh as a debounced action that can safely handle partial failures.

4. **Tests first for the new behavior**
   - Add widget tests for:
     - Toggle switches primary/secondary
     - Refresh triggers the refresh mechanism
     - Tap on a tile opens the shared bottom sheet scaffold

## Verification commands

Run these locally after applying any patch:

```bash
flutter analyze
flutter test
```

## Known failure modes to avoid (hard rules)

- Do not invent domain enums or models. If a type does not exist, stop and add it deliberately with a plan.
- Do not pass nullable values into non-null parameters. Fix at the source, not with `!`.
- Do not rename constructor parameters mid-stream. Add adapters or land signature changes in an isolated commit.
- Keep analyze green frequently, and do not proceed if it is red.

