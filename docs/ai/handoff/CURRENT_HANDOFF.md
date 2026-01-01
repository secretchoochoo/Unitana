# Current handoff (canonical)

## Status
- Build: green expected after latest test hotfix is applied (Slice H hotfix: scoped scrolling).
- PlacesHeroV2: stable.
- ToolPickerSheet:
  - Slice C shipped the two-level hierarchy (Activity Lenses -> Tools) with stable keys.
  - Slice H shipped picker UX (search, most-recent shortcut, single-expanded accordion) and removed Favorites.
- Dracula-inspired text colors: implemented across major surfaces; keep auditing for contrast regressions.
- iOS app icon visibility: backlog only.

## Immediate next work
1. Tools expansion, Bundle 2: implement additional tool tiles and modals using the ToolRegistry (dedup-first). Target the next highest value set (Weather + Time, Money + Shopping) while keeping the “one tool, many contexts” rule.
2. Numeric limits + overflow strategy (new slice):
   - Add max digit limits per field (default 6 to 8, with explicit exceptions like currency).
   - Add a shared result formatting strategy so tile “last result” always stays readable (scale down, compact notation, or truncation only as a last resort).
3. Refresh-all wiring: the UI affordance exists; hook it to any remaining API fetches and make it the single entry point for refreshing dashboard data.
4. Iconography roadmap (later slices):
   - Lens-level color tinting aligned to Dracula palette.
   - Second-level (tool) icons review for clarity and consistency.
5. Modal history log upgrade (spike): terminal-like history list; tap-to-copy with toast confirmation.
6. Theme audit + regressions: keep Dracula contrast, text hierarchy, and widget tests green as UI evolves.

## Git hygiene (do this once tests are green)
Suggested flow:
- `git status -sb`
- `dart format . && flutter analyze && flutter test`
- `git add -A`
- `git commit -m "Slice H hotfix: stabilize ToolPicker tests"`
- `git push`

## Guardrails
- Avoid creating scripts to shuffle docs.
- Prefer small diffs with clear patch log entries.
