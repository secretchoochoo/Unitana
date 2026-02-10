NEXT CHAT PROMPT — XL-M: Pack W Optional Lo-Fi Audio Spike (Off By Default)

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/REFERENCE_INDEX.md`
4) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
5) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
6) `app/unitana/lib/features/dashboard/widgets/settings_licenses_page.dart`
7) `app/unitana/lib/features/dashboard/models/dashboard_copy.dart`
8) `app/unitana/lib/app/app_state.dart`

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
Execute a safe Pack W spike for an optional lo-fi audio feature that is disabled by default and does not degrade app reliability.

## Required outcomes
1) Feature scaffold
- Add a minimal audio-control architecture (state + settings toggle + volume baseline), default OFF.
- Ensure startup behavior does not auto-play audio.

2) UX contract
- Add clear settings controls and copy for enabling/disabling background lo-fi.
- Keep behavior deterministic across app restarts.

3) Safety/guardrails
- Keep feature fully optional and non-blocking.
- Ensure no regressions to existing dashboard/tool flows.

4) Tests
- Add deterministic tests for persisted OFF default and toggle persistence.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) state/storage scaffold
2) settings wiring
3) minimal playback seam (optional/no-op-safe)
4) tests
5) full gates + docs refresh

## Definition of done
- Pack W spike exists, defaults OFF, and is persistence-safe.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-N (Pack I tutorial overlay near-finalization pass).
- Following slice: XL-O (Pack Y wearables/platform add-ons planning only).
