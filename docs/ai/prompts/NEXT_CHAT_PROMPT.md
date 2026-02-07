NEXT CHAT PROMPT — Pack E Phase 6c (Redundant Home/Destination Label Audit)

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/SCENEKEY_REDESIGN_AUDIT.md`
4) `docs/ai/reference/SCENEKEY_CATALOG.md`
5) `docs/ai/reference/PACK_E_SPLIT_MARQUEE_DEFERRED_NOTES.md`

Then execute using this contract.

## Core operating rules
- Keep repo green if any code/docs are touched:
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- Work directly in-repo (Codex-first).
- Preserve non-negotiables:
  - collapsing pinned `SliverPersistentHeader` morph
  - canonical hero key uniqueness
  - wizard previews with `includeTestKeys=false`
  - goldens opt-in only

## Mission
Remove redundant `Home` / `Destination` UI labels where city+flag context already communicates intent, while preserving places/reality behavior and clarity.

## Required outcomes
1) Scope guard
- Do not change dashboard hero marquee semantics.
- Keep weather-sheet work constrained to per-city cards (middle bridge card remains removed).

2) Label audit slice
- Audit Time/Weather/Jet Lag/profile surfaces for `Home` / `Destination` labels that are redundant next to city+flag context.
- Keep labels where they are semantically required (for role disambiguation, accessibility clarity, or empty-state fallback).
- Keep implementation low-risk and avoid behavior changes to zone seeding, swap actions, and reality toggles.

3) Readability and layout safety
- Ensure resulting copy remains legible on small phones and does not crowd neighboring weather sections.
- Preserve hero grid contracts and avoid overlap/clipping on small phones.
- Keep existing interaction behavior unchanged.
- Prevent jank from dynamic weather updates and avoid extra key collisions.

4) Regression lock
- Keep pinned collapsing header behavior stable.
- Keep tool/weather data readability stable (no text overlap/regression).
- Keep goldens opt-in only.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (advance to next slice)

## Definition of done
- Redundant `Home` / `Destination` text is removed where city/flag context already implies meaning, without harming usability.
- No regressions in collapse behavior, readability, or interaction.
- Repo is green (`format`, `analyze`, `test`).
