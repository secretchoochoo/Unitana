# CURRENT_HANDOFF (Unitana) - Wizard, Collapsing Header, Multi-Profile

## Snapshot
- **Date:** 2026-02-05
- **Status:** Repo is green (`dart format`, `flutter analyze`, `flutter test`) after P0 stabilization + P1 profile-switching/namespaced prefs + modal UX cleanup.
- **Operating mode:** Codex is now the primary workflow; apply edits directly in-repo (do not require patch zip workflow unless explicitly requested).

## Latest changes (2026-02-05)
- Dashboard menu sheet height reduced to the same bounded behavior used by profile/tool flows (`0.82` screen height cap) to avoid near-fullscreen takeover on phones.
- Added top-right `X` close controls to dashboard/menu-related sheets:
  - main menu sheet
  - profile switcher sheet
  - developer tools sheet
  - weather override sheet
  - clock override sheet
  - reset defaults confirmation sheet
- Multi-profile behavior status:
  - real profile switching is active
  - add-profile flow creates a new profile, switches to it, and opens wizard edit flow
  - dashboard layout/session prefs remain namespaced per active profile
- Tests:
  - full suite passes after these changes
  - profile switching + namespaced persistence tests are in place and green

## What’s true right now (high signal)
### 1) Dashboard header is a continuous collapsing header (no pop-in)
- The dashboard uses a **pinned `SliverPersistentHeader`** that morphs from **PlacesHeroV2 (expanded)** into the **pinned mini-hero readout (collapsed)** continuously with scroll.
- The old threshold-based “insert mini hero” approach is not allowed to return (it caused visible scroll jumps).

### 2) Wizard is consolidated into 3 steps (and must stay visually stable)
1) **Welcome to Unitana**
2) **Pick Your Places** (home + destination pickers, unit system + clock format controls, mini-hero preview)
3) **Name and Confirm** (profile name, PlacesHeroV2 preview, CTA: **Create Profile**)

Key visual rules that have regressed multiple times:
- Titles use the same font family as the dashboard profile name (**Roboto Slab**).
- Slide 2 must fit on a single phone screen without scrolling; unit/clock pills must remain compact.
- Slide 3 must not show duplicate toggle rows (remove the extra “mini hero” toggle row; the hero preview already contains its own toggle).

### 3) Test stability doctrine is now enforced via key hygiene
- Canonical hero keys must be **unique in the widget tree at all times**.
- `PlacesHeroV2` gates canonical test keys behind **`includeTestKeys`**:
  - Dashboard surface sets `includeTestKeys: true` (tests rely on these).
  - Wizard previews and any other preview surfaces must set `includeTestKeys: false` to avoid duplicate finders.

### 4) Multi-profile support landed (P1)
- Added a **UnitanaProfile** model, persisted **profiles list** and **active profile id**.
- Added a **Profiles** bottom sheet for switching profiles; onboarding wizard can run in:
  - **create mode** (add a new profile)
  - **edit mode** (edit active profile)
- Persisted settings are now **namespaced per profile** (layout, anchors, hidden tools, env mode) with bootstrap/migration from legacy single-profile keys.

## Current build state
- **Expected:** green across `dart format`, `flutter analyze`, `flutter test`.
- **If you see red in Codex:** treat the provided `error.log` as authoritative; do not “clean up warnings” by changing behavior. Prefer minimal diffs that restore green.

## Where regressions keep coming from (read before touching code)
### A) Duplicate widget keys/finders during collapsing header transition
Root cause: both hero and mini layers can coexist during scroll; any reused canonical key becomes a duplicate finder failure.
Guardrails:
- Only the dashboard instance should emit canonical hero keys.
- Preview surfaces must set `includeTestKeys: false`.
- Compact/pinned layer must not reuse expanded-layer canonical keys.

### B) Pinned header occluding taps in widget tests
Some tests must scroll targets into view before tapping; otherwise taps land “off-screen” due to the pinned header.
Guardrails:
- Use `ensureVisibleAligned()` (or equivalent) before tapping tiles that can sit near the top edge.

### C) Wizard layout “fits on one screen” drift
Slide 2 in particular tends to regress (pills expanding, pushing content off-screen).
Guardrails:
- Keep unit/clock controls compact and explicitly wrapped to two lines (units first row, clock second row).
- Prefer smaller text + tighter padding on pills; avoid full-width segmented controls.

## Commands (local)
From `app/unitana`:
- `dart format .`
- `flutter analyze`
- `flutter test`

## Goldens workflow (gated)
- Golden tests are **gated** behind `UNITANA_GOLDENS=1` to keep CI green by default.
- Baselines live under: `app/unitana/test/goldens/goldens/`
- When intentionally changing visuals:
  1) Update the relevant design lock (at minimum: `HERO_MINI_HERO_CONTRACT.md`).
  2) Update tests/invariants if required.
  3) Regenerate baselines with: `UNITANA_GOLDENS=1 flutter test --update-goldens`

## Next slice targets (high-confidence backlog)
1) **Finish golden coverage for the wizard** (Step 2 phone surface; Step 3 phone surface) and verify the “no scroll” constraint.
2) **Profile switcher polish + edit mode UX hardening** (ensure no accidental state bleed between profiles; add 1-2 targeted widget tests).
3) **Small-device sweep** (320×568 and common phone sizes) focusing on:
   - hero env pill readability
   - collapsed mini-hero readout legibility
   - wizard Step 2 one-screen fit

## Files you should treat as contracts (update them when behavior changes)
- `docs/ai/handoff/CURRENT_HANDOFF.md` (this file)
- `docs/ai/context_db.json` (patch log + decisions)
- `docs/ai/design_lock/HERO_MINI_HERO_CONTRACT.md`

## Codex handoff prompt (copy/paste)
You are taking over Unitana, a Flutter app. Keep the repo green and avoid regressions.

Non-negotiables:
- Do not remove the collapsing header. No threshold-based mini-hero insertion.
- Canonical hero keys must be unique; preview surfaces must not emit them.
- Slide 2 of the wizard must fit on one screen, no scrolling.
- Do not update goldens unless explicitly requested and documented.

Inputs you will receive:
- Latest codebase zip.
- Latest `error.log`.

Task:
1) Read `error.log`. Identify the smallest set of changes to restore green.
2) Make fixes with minimal behavioral change; prefer key hygiene, scroll alignment in tests, and layout constraint fixes over refactors.
3) If any behavior changes, update:
   - `docs/ai/context_db.json` patch_log + decisions
   - relevant design locks (especially `HERO_MINI_HERO_CONTRACT.md`)
4) Return a changed-files-only patch zip, plus a short changelog and rerun commands.
