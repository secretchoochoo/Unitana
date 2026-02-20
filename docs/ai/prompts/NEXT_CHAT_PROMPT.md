NEXT CHAT PROMPT — XL-X: Performance Tuning + Hardening Phase C

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/REFERENCE_INDEX.md`
4) `docs/ai/reference/XL_W_DOCS_REALIGNMENT_AND_HARDENING_PLAN_2026-02-19.md`
5) `docs/ai/reference/PACK_X_RETRO_BASELINE_XL_H2.md`
6) `app/unitana/lib/features/dashboard/widgets/profiles_board_screen.dart`
7) `app/unitana/lib/features/first_run/first_run_screen.dart`
8) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
9) `app/unitana/lib/features/dashboard/models/dashboard_session_controller.dart`
10) `tools/verify.sh`

## Core operating rules
- Work directly in-repo (Codex-first).
- If runtime or tests are changed, keep repo green:
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- Preserve non-negotiables:
  - collapsing pinned `SliverPersistentHeader` morph
  - canonical hero key uniqueness
  - wizard previews with `includeTestKeys=false`
  - goldens opt-in only

## Mission
Execute XL-X phase C by hardening profile and first-run wizard lifecycles, with emphasis on state continuity and predictable navigation behavior under rapid user interactions.

## Required outcomes
1) Profile/wizard lifecycle hardening
- Audit profile creation/edit flows and wizard transitions for delayed navigation, stale state, and accidental side effects.
- Extract safe helpers where high-churn logic is still deeply nested.
- Preserve user-visible behavior unless fixing confirmed defects.

2) State continuity guardrails
- Ensure key session preferences (for example active audio/theme toggles) are not inadvertently reset during profile and wizard transitions.
- Keep persistence and restoration contracts explicit.

3) Contract/comment hygiene
- Remove stale comments and replace with concise runtime-contract comments.
- Keep comments aligned to current behavior only.

4) Deterministic regression coverage
- Add/update targeted tests around lifecycle or state-continuity fixes introduced in this slice.

5) Docs refresh
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Definition of done
- XL-X phase C hardening changes land with no UX regressions.
- Repo remains green with full verify gates.

## Forward plan after this slice
- XL-X phase D: selective performance profiling + low-risk hot-path micro-optimizations.
