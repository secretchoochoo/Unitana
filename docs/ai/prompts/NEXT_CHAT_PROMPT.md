NEXT CHAT PROMPT — Pack E Phase 5 (Weather-Sheet Bridge Visual Upgrade)

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
Upgrade the weather-sheet middle bridge from a text split scaffold toward a richer dual-city visual treatment while preserving dashboard marquee behavior.

## Required outcomes
1) Scope guard
- Do not change dashboard hero marquee semantics.
- Keep split concept work constrained to the weather-sheet middle bridge area.

2) Bridge visual upgrade slice
- Build on the existing bridge scaffold and introduce a stronger visual representation of both cities' weather context.
- Keep the implementation low-risk and bounded to weather-sheet contracts (no dashboard hero marquee changes).

3) Readability and layout safety
- Ensure bridge content remains legible on small phones and does not crowd neighboring weather sections.
- Preserve hero grid contracts and avoid overlap/clipping on small phones.
- Keep existing interaction behavior unchanged.

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
- Weather-sheet bridge has a clearer dual-city visual treatment with stable readability on phone surfaces.
- No regressions in collapse behavior, readability, or interaction.
- Repo is green (`format`, `analyze`, `test`).
