NEXT CHAT PROMPT — Pack E Phase 2 (Dual-City Split Marquee Prototype + Decision)

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/SCENEKEY_REDESIGN_AUDIT.md`
4) `docs/ai/reference/SCENEKEY_CATALOG.md`

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
Prototype a dual-city split marquee concept for the Places Hero and decide whether it is ready to become default, while preserving current layout/interaction contracts.

## Required outcomes
1) Dual-city split marquee prototype
- Implement a prototype variant that visually represents both cities in the marquee region (or immediately adjacent bridge region) without reducing readability of temperature, env/currency, or details pill.
- Preserve hero grid contracts and avoid overlap/clipping on small phones.
- Keep existing interaction behavior unchanged.

2) Readability decision pass
- Evaluate the prototype against current marquee for scanability and visual hierarchy on phone surfaces.
- If it does not materially improve readability, keep it behind a local feature flag or revert to the current default and document why.

3) Regression lock
- Keep pinned collapsing header behavior stable.
- Keep tool/weather data readability stable (no text overlap/regression).
- Keep goldens opt-in only.

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (advance to next Pack E or Pack H slice based on outcome)

## Definition of done
- A dual-city split marquee prototype is implemented and evaluated with a clear keep/revert decision.
- No regressions in collapse behavior, readability, or interaction.
- Repo is green (`format`, `analyze`, `test`).
