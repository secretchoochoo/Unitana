NEXT CHAT PROMPT — Pack E Phase 3 (Split Marquee Polish + Scene Readability Pass)

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
Polish the new split marquee treatment and improve scene readability consistency across key weather states without breaking hero layout/interaction contracts.

## Required outcomes
1) Split marquee polish
- Refine split city chip spacing/contrast/weight for cleaner scanning on phone and tablet widths.
- Preserve hero grid contracts and avoid overlap/clipping on small phones.
- Keep existing interaction behavior unchanged.

2) Scene readability pass
- Audit representative scene families (clear/cloud/rain/fog/wind) for label legibility and visual noise.
- Apply only low-risk readability tweaks (contrast, subtle overlay balance, chip legibility), not a full art rewrite.

3) Regression lock
- Keep pinned collapsing header behavior stable.
- Keep tool/weather data readability stable (no text overlap/regression).
- Keep goldens opt-in only.

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (advance to next Pack E slice)

## Definition of done
- Split marquee presentation feels cleaner and remains stable across key scene families.
- No regressions in collapse behavior, readability, or interaction.
- Repo is green (`format`, `analyze`, `test`).
