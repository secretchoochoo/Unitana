NEXT CHAT PROMPT — XL-H: Pack X Retro Baseline + Profiles Surface Redesign

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
4) `app/unitana/lib/features/dashboard/widgets/profiles_board_screen.dart`
5) `app/unitana/lib/features/dashboard/dashboard_screen.dart`
6) `app/unitana/lib/features/dashboard/models/lens_accents.dart`
7) `app/unitana/lib/theme/app_theme.dart`
8) `app/unitana/lib/features/dashboard/widgets/dashboard_board.dart`
9) `app/unitana/test/profile_switcher_switch_profile_flow_test.dart`
10) `app/unitana/test/profile_feedback_toast_test.dart`
11) `app/unitana/test/dashboard_light_theme_readability_smoke_test.dart`

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
Execute XL-H by combining:
1) Pack X retro baseline capture (UX/UI/interactivity/perf findings with concrete actions).
2) Profiles page redesign for readability and tighter dashboard-family visual parity in both Light and Dark modes.

## Required outcomes
1) Profiles redesign (implementation)
- Improve information density/legibility with smaller, cleaner tiles and balanced spacing.
- Preserve existing behavior contracts (activate, edit, reorder, add, toast feedback).
- Ensure Light theme contrast/readability is materially improved.

2) Retro baseline artifact
- Produce a concise, actionable Pack X baseline document with:
  - top UX/UI strengths
  - top debt/issues (prioritized)
  - consistency/interactivity gaps
  - performance risk shortlist
  - recommended next-pack sequencing

3) Preserve existing contracts
- No regressions to:
  - matrix tools and matrix widget sync
  - world time map widget readout contracts
  - localization switching behavior
  - emergency weather taxonomy/marquee state behavior

4) Tests and guardrails
- Add/adjust tests only where they lock correctness/readability-critical behavior.
- Keep full-gate green status.

5) Docs update
- Update:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

## Suggested execution order
1) profile surface audit + redesign implementation
2) targeted tests for profile/light-theme readability contracts
3) full gates
4) Pack X retro baseline artifact
5) docs/handoff refresh

## Definition of done
- Profiles screen is materially more readable and visually aligned across Light/Dark.
- Pack X retro baseline exists with prioritized, executable follow-ups.
- Repo green (`format`, `analyze`, `test`).

## Forward plan after this slice
- Next slice: XL-I (Pack E marquee V2 continuation + Weather/Time visual harmonization).
- Following slice: XL-J (Pack W opt-in lofi audio foundation, off by default).
