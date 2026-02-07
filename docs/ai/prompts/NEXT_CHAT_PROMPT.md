NEXT CHAT PROMPT — Pack E Phase 6e (City Picker Mainstream Ranking)

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
Improve city-picker default ranking so common travel hubs appear first for mainstream users while preserving global search reach and advanced timezone fallback.

## Required outcomes
1) Scope guard
- Do not change dashboard hero marquee semantics.
- Keep weather-sheet work constrained to per-city cards (middle bridge card remains removed).

2) Mainstream ranking slice
- Re-rank default city list toward high-signal mainstream travel hubs and profile-seeded cities.
- Keep long-tail/global cities discoverable via search without overwhelming the default list.
- Preserve advanced timezone mode and abbreviation behaviors (`EST`, `CST`, etc.).

3) Readability and layout safety
- Ensure picker row copy remains legible on small phones and does not crowd the sheet.
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
- Default city list feels mainstream and useful out of the box, while search still supports global/discrete locations.
- No regressions in collapse behavior, readability, or interaction.
- Repo is green (`format`, `analyze`, `test`).
