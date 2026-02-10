# PACK L Theme Parity Closure Spec (XL-K)

## Goal
Close Pack L by locking consistent, readable token usage across dashboard/profile/tool-entry surfaces for both Dark and Light themes.

## Rules
- Use semantic `ColorScheme` and theme token pathways for shared UI controls.
- Avoid direct Dracula constants in cross-theme entry surfaces unless dark-only by design.
- Light theme prioritizes dark text contrast first; accent hues are secondary.
- Pulsing/focus states must use theme-aware accent (not fixed palette literals).

## Scope Locked In XL-K
- Dashboard tile focus pulse uses theme `primary` tone instead of fixed cyan.
- Dashboard refresh icon accent uses theme `primary` tone instead of fixed purple.
- Profile/dashboard entry surfaces preserve readability in both brightness modes.

## Acceptance Checks
- No readability regressions in profile board and top-level dashboard entry controls.
- Existing lens accent and theme-policy tests remain green.
- No change to collapse/header/hero non-negotiables.

## Follow-Up (if needed)
1. Expand semantic-token sweep to secondary settings sub-pages.
2. Add a small visual contract test for focus pulse tint in light mode.

