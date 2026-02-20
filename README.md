# Unitana

Unitana is a travel-first dual-reality dashboard for home/destination context:
time, weather, currency, and conversion tools in one surface.

## Quick Start

From `app/unitana`:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

From repo root:

```bash
./tools/verify.sh
```

## Repo Layout

- `app/unitana/`: Flutter app source and tests.
- `docs/`: product, architecture, AI handoff/reference, and operations docs.
- `tools/`: repo-level scripts/hooks.

## Key App Surfaces

- Dashboard shell: `app/unitana/lib/features/dashboard/dashboard_screen.dart`
- Hero and weather cockpit: `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
- Tool modal surface: `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
- First-run wizard: `app/unitana/lib/features/first_run/first_run_screen.dart`

## Documentation Start Points

- `docs/README.md`
- `docs/00-mvp-truth.md`
- `docs/ai/handoff/CURRENT_HANDOFF.md`
- `docs/ai/context_db.json`
- `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
- `docs/ai/reference/REFERENCE_INDEX.md`

## Testing Notes

- Tests live in `app/unitana/test/`.
- Prefer `ValueKey('...')` selectors over visible-copy matching.
- Goldens are opt-in only; normal `flutter test` should pass without golden updates.

## Git Hook (Optional)

```bash
git config core.hooksPath tools/githooks
```
