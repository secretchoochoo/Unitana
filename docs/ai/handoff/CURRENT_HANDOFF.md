# Current handoff (canonical)

## Status
- Build: should be green once `patch_2026-01-13_S6k_tool_modal_scroll_tests_hotfix` is applied (fixes failing widget tests from S6j).
- Merge gates (non-negotiable): `dart format .`, `flutter analyze`, `flutter test`.
- Dashboard architecture: sliver-based dashboard; Places Hero V2 supports a compact pinned overlay that keeps Reality toggle and key pills actionable during scroll.
- Time contract: device clock is the source of truth; timezones are display-only formatting.
- Tool modal UX contract (current):
  - Units row: units label + swap control are visually tied; swap uses a subtle pulse affordance.
  - History: terminal-style pane; tap copies **result** to clipboard; long-press copies **input** to clipboard (no “restore/edit” behavior).
  - Notices/toasts: non-interactive so they never block long-press actions.

## What we completed in this chat (high level)
- Sev1 lock: pinned mini-hero pill strip contract hardened (single-row only, no wrapping/stacking; scale-down only).
- Pinned “Details” chip: Sunrise/Sunset ↔ Wind toggle geometry hardened to avoid jitter/size-shift during transitions.
- Tool surface expansion: added Volume, Pressure, and Shoe Sizes tools (plus associated UX/test hardening).
- Tool modals: swap control placement tightened (vertically aligned with units), history pane made more terminal-like, and clipboard contract clarified (Copied result vs Copied input).
- QA hardening: targeted widget tests for the pinned pill row and tool modal clipboard behavior; tests now locate the actual Scrollable descendant reliably.

## Current priorities (next slices)
1) Multi-unit conversion UX (design-first): define the “unit matrix” approach for tools that may expand beyond a simple two-unit swap (volume, weight, length, etc.) without becoming clunky.
2) Platform icon audit execution: complete Android + iOS + one desktop/web target per `docs/ai/reference/PLATFORM_ICON_AUDIT.md`.
3) Weather binding (deferred until tool surface is close): bind provider condition codes to SceneKey behind a flag; keep network off by default until endgame.

## Backlog (captured, not scheduled)
- Multi-unit conversion UX:
  - Avoid a clunky From/To picker; explore a compact “units pill” that opens a minimal selector, or a “More units” sub-sheet that keeps the main modal clean.
  - Ensure unit selection is reflected consistently across widgets and tool modals.
  - Keep Dracula theme palette and terminal-adjacent aesthetic.
- Edit mode: drag-and-drop widget rearrangement (homescreen-style) with a subtle “shake” animation.
- Modals: optional top-right close “X” (tasteful Dracula theme) in addition to outside-tap dismissal.
- History header polish: consider a more deliberate Dracula-themed treatment while preserving readability.

## Contracts to preserve
- Stable keys everywhere (persistence + tests).
- No public widget API churn unless strictly necessary.
- Pinned mini-hero pill strip: single row only, never stacks/wraps; scale-down only (no ellipsis).
- Deliver patches as changed-files-only zips, paths preserved.
