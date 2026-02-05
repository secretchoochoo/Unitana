# NEXT_CHAT_PROMPT (Senior Review + Hardening)

## DEPRECATED
Use the canonical prompt at: `docs/ai/prompts/NEXT_CHAT_PROMPT.md`.
This file is quarantined for historical context and should not be edited.

You are taking over the Unitana project in a stabilization phase. Goal: keep the build green, harden the Places Hero and pinned mini-hero behavior, then proceed to the next dashboard slice.

## Current state
- Places Hero V2 is the canonical hero.
- Pinned mini-hero (condensed readout) should appear when scrolling down, then disappear when scrolling back up.
- Live data must never render as long-lived placeholders on a fresh launch.

## New changes in P1.23zb
- `dashboard_screen.dart`
  - Adds a first-frame `refreshAll` to populate mock/live data.
  - Adds a manual refresh control beside the refresh status label.
  - Makes the pinned trigger earlier so it is harder to "miss".
- `places_hero_v2.dart`
  - Clocks split into 2 lines: time line (with delta highlighted) and date line.
  - Currency pill primary line font made larger while still using `FittedBox`.
- `data_refresh_status_label.dart`
  - Visual stale cue (orange) when label says `Stale`.

## What to audit
1. **Data lifecycle**
   - Confirm we refresh on first frame and do not accidentally double-refresh or spam calls.
   - Confirm toggling weather backend still works.
2. **Pinned mini-hero contract**
   - Verify pinned overlay reliably shows after the hero scrolls off, on multiple screen sizes.
   - Ensure no overflows and no layout jumping.
3. **Remove dead paths**
   - Delete any remaining "Hero Readout v2" or developer-tools variant that is no longer used.
   - Remove unused widgets and update docs that still reference old UI.
4. **Tests**
   - Add at least one widget test for pinned overlay trigger.
   - Add a widget test for the clock block rendering two lines and date separation.

## Verification gates
Run these from `unitana/app/unitana`:
```bash
dart format .
flutter analyze
flutter test
```

## Patch workflow expectation
If you generate a patch, include:
- Changed-files-only zip
- Copy-paste apply commands
- A short verification checklist

