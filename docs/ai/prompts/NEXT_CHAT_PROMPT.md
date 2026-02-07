NEXT CHAT PROMPT — Pack E Phase 6b (Weather-Sheet In-Card Marquee Polish)

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
Polish the weather-sheet in-card mini-marquee treatment so each city card mirrors dashboard weather context cleanly on phone surfaces.

## Required outcomes
1) Scope guard
- Do not change dashboard hero marquee semantics.
- Keep weather-sheet work constrained to per-city cards (middle bridge card remains removed).

2) In-card marquee polish slice
- Build on the current per-card top-right mini-marquee treatment and tune visual hierarchy between city name, condition, marquee, and temperatures.
- Keep the implementation low-risk and bounded to weather-sheet contracts (no dashboard hero marquee changes).
- If motion or ornamentation harms scanability on phone surfaces, keep static visuals and document that decision.

3) Readability and layout safety
- Ensure bridge content remains legible on small phones and does not crowd neighboring weather sections.
- Ensure in-card marquee + text layout remains legible on small phones and does not crowd neighboring weather sections.
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
- Weather-sheet per-city cards retain strong readability and either:
  - gains subtle motion polish that remains stable on phone surfaces, or
  - intentionally remains static with documented rationale.
- No regressions in collapse behavior, readability, or interaction.
- Repo is green (`format`, `analyze`, `test`).
