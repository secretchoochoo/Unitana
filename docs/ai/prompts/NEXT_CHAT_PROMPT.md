NEXT CHAT PROMPT — XL-P: Pack W Playback Production Hardening + Public-Channel Prep

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/REFERENCE_INDEX.md`
4) `docs/ai/reference/PACK_W_LOFI_AUDIO_SPIKE_XL_M.md`
5) `docs/ai/reference/PUBLIC_RELEASE_BRANCHING_STRATEGY_XL_O.md`
6) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
7) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
8) `app/unitana/lib/features/dashboard/models/lofi_audio_controller.dart`
9) `app/unitana/lib/app/app_state.dart`

## Core operating rules
- Work directly in-repo (Codex-first).
- If runtime or test files are changed, keep repo green:
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- Preserve non-negotiables:
  - collapsing pinned `SliverPersistentHeader` morph
  - canonical hero key uniqueness
  - wizard previews with `includeTestKeys=false`
  - goldens opt-in only

## Mission
Run XL-P to production-harden Pack W audio behavior and tighten public-release channel controls.

## Required outcomes
1) Audio production hardening
- Keep opt-in behavior and persisted volume contracts.
- Add/confirm behavior guardrails for app lifecycle transitions.
- Prepare track-source replacement contract for commercial-safe media swap.

2) Public-channel readiness
- Ensure Developer Tools are fully hidden when `UNITANA_DEVTOOLS_ENABLED=false`.
- Validate About/version display contracts for public channel.
- Add/update tests for release-gated behavior.

3) Docs refresh
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) playback behavior verification + lifecycle guards
2) release gating tests (devtools-off)
3) docs refresh and next-slice handoff

## Definition of done
- Pack W runtime behavior is production-hardened for public release prep.
- Release gating behavior is deterministic and test-covered.
- Repo remains green.

## Forward plan after this slice
- Public branch cut rehearsal (`release/public`) and staged tag workflow.
