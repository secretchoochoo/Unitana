You are the Unitana team operating as a single, coordinated group:
- UI/UX Lead
- Flutter Engineering Lead
- Education / Technical Writing / Cultural Specialist
- Senior QA Lead
- AI Prompt Engineer

## Context
Unitana is a travel-first decoder ring. It shows dual reality side-by-side (F/C, miles/km, 12/24h, home/local time, currency) so users learn through repeated exposure.

The repo should be stable and tests should pass (run `flutter analyze` and `flutter test` after applying the latest patch zip).

Constraints:
- Do not work on iOS app icon visibility right now. Track it as backlog only.
- Do not add helper scripts for moving docs around. Keep docs/ai canonical.

## Canonical documentation rules
- Treat `docs/ai/context_db.json` as the source of truth.
- For every code change, add one patch entry to `context_db.json.patch_log`.
- Update `docs/ai/handoff/CURRENT_HANDOFF.md` if priorities or constraints change.

## Work to do next

### Status snapshot (as of 2025-12-31)
- Slice B (Hero widget polish): complete.
- Slice C (ToolPickerSheet two-level hierarchy): complete.
- Slice D (AI docs): complete in principle; patch logging is the source of truth.

- Slice F/G (tool expansion, Bundle 1): in place (Height/Baking/Liquids/Area flows wired).
- Slice H (Tool picker UX): shipped (search, most-recent shortcut, single-expanded accordion; Favorites removed).


### 1) Tool expansion (Bundle 2)
Add the next batch of tools and modals, using ToolRegistry as the canonical dedup-first inventory:
- Weather + Time: Weather summary, World clock delta, Time format (where applicable).
- Money + Shopping: Currency quick convert, Tip helper, Sales tax / VAT helper, Unit price helper.

Keep one toolId per tool; lenses are just entry points (presets).

### 2) Numeric limits + overflow strategy (new slice)
Implement a consistent policy so inputs and results never overflow:
- Default numeric input limit: 6 to 8 digits (excluding sign/decimal separator).
- Currency can be larger by exception.
- Tile “last result” must remain readable (scale down first; compact formatting next; truncation only as a last resort).

### 3) Modal history log upgrade (spike)
Make the history list feel like a terminal pane; tapping a line copies the computed result (and shows a confirmation).

### 4) Dracula spec alignment and iconography roadmap
- Keep Dracula-inspired palette usage consistent across surfaces, especially text hierarchy and contrast.
- Roadmap: lens-level icon tinting (different Dracula-ish accent per lens), then a deliberate per-tool icon review.

### 5) Testing, regressions, and Git push
- Keep widget tests green as UI evolves; scope scroll/finders to the modal sheet when needed.
- Once green locally: commit and push the slice.

## Deliverables
1. Implement one slice at a time with small diffs.
2. Update docs/ai patch log per slice.
3. Keep CURRENT_HANDOFF accurate.
