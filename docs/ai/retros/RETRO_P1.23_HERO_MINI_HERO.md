# Retro — P1.23 Hero + Mini-Hero Regressions

Date: 2026-01-30
Scope: Places Hero V2, mini-hero readout, related tests/docs.

## What happened
We iterated quickly on a dense UI area (hero + mini-hero) with multiple competing concerns (readability, overflow safety, Dracula palette cohesion, data freshness UX). Changes were frequently made across intertwined widgets and data formatting, and we repeatedly re-broke already-fixed behaviors.

## Root causes (most likely)
1) **Missing contract**: we didn’t have a single, canonical “hero contract” capturing invariants (line counts, min heights, separators, required keys, placeholder rules). Without it, changes became opinion-driven and inconsistent.
2) **Wide blast radius**: small visual tweaks (timeline text, cockpit labels) often lived in shared helpers or high-churn files; modifications spilled into adjacent states (swapped reality, missing data, modal/scroll collapsed state).
3) **Insufficient visual regression tests**: unit/widget tests caught some crashes, but did not protect against subtle layout drift and state regressions (missing mini-hero, placeholders returning).
4) **Unbounded layout paths**: the hero must work both in bounded and unbounded height contexts (scroll views, modals, widget tests). Flex widgets (`Expanded/Flexible`) + `stretch` alignment in unbounded contexts repeatedly caused crashes.
5) **Process drift in patch workflow**: many micro patches, sometimes made under imperfect context, increased the chance of rewriting “recently-correct” code.

## Start / Stop / Continue
### Start
- Maintain a single design contract doc: `docs/ai/design_lock/HERO_MINI_HERO_CONTRACT.md`.
- Add 2–3 goldens for the hero and 2 widget tests (mini-hero presence; timeline/date stability).
- Add a “layout constraint” test that mounts hero inside an unbounded-height parent to prevent flex regressions.

### Stop
- Stop changing hero styling without simultaneously updating the contract doc and goldens.
- Stop mixing behavioral changes (data refresh logic) with styling changes in the same patch.
- Stop reformatting or “cleaning up” large sections of hero code while fixing a single bug.

### Continue
- Dracula palette, white-first typography, color as accent.
- Terminal-like mini-hero direction (dense but legible readout) as long as it is locked and tested.

## Hardening plan (next)
1) **Green first**: fix the unbounded-height flex crash in `places_hero_v2.dart`.
2) **Add goldens**: primary, swapped, missing-data.
3) **Add widget tests**: mini-hero appears; timeline/date persists across toggles.
4) **Docs cleanup**: prune stale prompts and keep a canonical handoff + prompt.
5) **Design lock**: freeze hero and mini-hero until Tools work is complete.

## Notes on refresh UX
User feedback indicated “Updated X ago” was not discoverable as a refresh mechanism. Recommended:
- Keep “Updated …” status.
- Add explicit manual refresh affordance (icon button) next to it.
- Consider showing “Stale” after threshold, but avoid alarmist language; use a subtle color shift.
