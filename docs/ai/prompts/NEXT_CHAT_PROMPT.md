NEXT CHAT PROMPT — XL-N: Pack I Tutorial Overlay Near-Finalization Pass

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/REFERENCE_INDEX.md`
4) `docs/ai/reference/PACK_W_LOFI_AUDIO_SPIKE_XL_M.md`
5) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
6) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
7) `app/unitana/lib/features/dashboard/widgets/places_hero_v2.dart`
8) `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`
9) `app/unitana/lib/features/first_run/first_run_screen.dart`

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
Start Pack I by implementing a minimal, skippable tutorial overlay foundation that is safe against current UI churn.

## Required outcomes
1) Overlay foundation
- Add opt-in/first-run gating state for tutorial visibility.
- Implement lightweight overlay primitives for key dashboard targets.
- Support skip/dismiss and replay-from-settings behavior contract scaffolding.

2) Near-finalization scope only
- Cover highest-value targets first:
  - wizard place selection/save action hints
  - dashboard hero pills/tools entry/settings entry hints
- Keep implementation modular to avoid broad UI coupling.

3) Regression guardrails
- Add deterministic tests for gating and dismissal persistence.

4) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) persistence + settings replay scaffold
2) minimal overlay renderer
3) targeted hook points (wizard/dashboard)
4) tests
5) full gates + docs refresh

## Definition of done
- Pack I foundation exists with skip/replay persistence contracts.
- No regressions to dashboard/wizard behavior.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-O (Pack Y wearables/platform add-ons planning only).
- Following slice: XL-P (Pack W playback backend integration, if prioritized).
