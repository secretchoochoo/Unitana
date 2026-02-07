NEXT CHAT PROMPT — Pack E Phase 3 (Scene Readability + Vertical-Fill Continuation)

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
Continue Pack E readability polish and safe vertical-fill follow-through while preserving dashboard marquee semantics and hero layout/interaction contracts.

## Required outcomes
1) Scene readability pass
- Audit representative scene families (clear/cloud/rain/fog/wind) for label legibility and visual noise.
- Apply low-risk readability tweaks (contrast and subtle overlay balance), not a full art rewrite.

2) Vertical-fill stability pass
- Validate that current marquee vertical-fill budget remains stable across phone breakpoints and does not starve surrounding pills.
- Preserve hero grid contracts and avoid overlap/clipping on small phones.
- Keep existing interaction behavior unchanged.

3) Regression lock
- Keep pinned collapsing header behavior stable.
- Keep tool/weather data readability stable (no text overlap/regression).
- Keep goldens opt-in only.

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (advance to next slice)

## Definition of done
- Scene readability and vertical-fill stability are improved without changing dashboard marquee semantics.
- No regressions in collapse behavior, readability, or interaction.
- Repo is green (`format`, `analyze`, `test`).
