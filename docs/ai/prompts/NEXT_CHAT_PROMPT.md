NEXT CHAT PROMPT — Pack E Phase 6d (City Picker Quality + Clarity)

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
Improve Time/Jet Lag city-picker quality so results feel mainstream, clean, and predictable while preserving seeded defaults and advanced timezone fallback behavior.

## Required outcomes
1) Scope guard
- Do not change dashboard hero marquee semantics.
- Keep weather-sheet work constrained to per-city cards (middle bridge card remains removed).

2) Picker quality slice
- Reduce odd/low-signal city rows in default list ordering and improve first-screen relevance for mainstream city selection.
- Ensure selected-state indicators are clear and non-confusing (no misleading multiple-check appearance).
- Keep advanced timezone mode available for power users and preserve EST/abbreviation search behavior.

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
- City-first picker feels cleaner and less confusing for mainstream users while retaining power-user timezone fallback.
- No regressions in collapse behavior, readability, or interaction.
- Repo is green (`format`, `analyze`, `test`).
