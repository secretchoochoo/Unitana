# Next chat handoff (2025-12-30)

## Current state
- Repo is compiling; recent friction was primarily widget-test layout overflows on small surfaces.
- Dashboard direction is set: hero at top (static, snapped to grid), scrollable tile grid below, empty slots show as + buttons, tools accessible via top-right menu (alongside settings).

## Patch shipped in this handoff
- Fixes two overflow regressions (AppBar leading and Places Hero left block).
- Cleans small analyzer issues (unused import, redundant `!`) and updates a deprecation usage (`withOpacity`).

### Changed files in this patch
- `app/unitana/lib/features/dashboard/dashboard_screen.dart`
- `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
- `docs/ai/context_db.json`
- `docs/ai/WORKING_WITH_CHATGPT.md`
- `docs/ai/RETRO_2025-12-30.md`
- `docs/ai/CHAT_LESSONS_2025-12-30.json`
- `docs/ai/NEXT_CHAT_PROMPT.md` (updated)
- `docs/ai/NEXT_CHAT_PROMPT_2025-12-30.md` (snapshot)
- `docs/ai/NEXT_CHAT_HANDOFF_2025-12-30.md` (this file)

## Known issues (parked)
- Dependency constraint drift in `pubspec.lock` (packages with newer versions unavailable under current constraints).
- Remaining dashboard work: grid rework, tool modals with history logs, theme audit.

## How to validate locally
```bash
dart format .
flutter analyze
flutter test
```

## Design requirements to carry forward
- Hero: refresh-all button top-left; Denver toggle right-aligned, toggles “reality” (home vs destination) and drives units + time/weather presentation.
- Weather icon can be slightly larger and moved left; Denver button must not show the two accidental dots.
- Tool tiles (Height, Baking, Liquids, Area) open a modal with top input area and a bottom history log (last 10 executions).
- Maintain Dracula theme usage consistently across all screens and text roles.

## Patch protocol (non-negotiable)
- Every patch zip includes `docs/ai/context_db.json` updated with a new `patch_tracking.log` entry.
- Prefer single-purpose patches; keep tests green.
