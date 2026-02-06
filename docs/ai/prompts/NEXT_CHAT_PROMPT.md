NEXT CHAT PROMPT — Pack F Contracted Implementation Sprint (Post Design-Lock)

You are taking over Unitana (Flutter) in a fresh, high-context window.

Read these files first:
1) `docs/ai/handoff/CURRENT_HANDOFF.md`
2) `docs/ai/context_db.json`
3) `docs/ai/reference/PACK_F_MEGA_SLICE_TOOLS_EXPANSION_PLAN.md`
4) `docs/ai/reference/LOOKUP_TABLE_TOOLS_UX_PATTERN.md`
5) `docs/ai/reference/TIME_TOOL_REPURPOSE_PLAN.md`
6) `docs/ai/reference/SAVE_UPDATE_FEEDBACK_MATRIX.md`
7) `docs/ai/reference/CONFIRMATION_DIALOG_POLICY.md`

Then execute using this contract.

## Core operating rules
- Design decisions are now locked. This pass is implementation-first.
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

## Locked design contracts to implement
1) Tool architecture matrix
- Classify and enforce behavior as:
  - dedicated tool
  - configurable template
  - alias/preconfiguration
  - remove/defer
- One canonical engine per domain; aliases only when context/defaults materially differ.
- Keep duplicate strategy explicit (example: `Oven Temperature` is a Temperature alias behavior, not a new engine).

2) Time-family split (selected: Option B)
- Ship/normalize two tools:
  - `Time`: home/destination live clocks + delta
  - `Time Zone Converter`: explicit arbitrary-zone conversion/planning flow
- Defer `Time Zone Map` (optional future surface).
- IA contract:
  - defaults from active profile home/destination zones
  - swap behavior preserves zone-bound local datetime intent
  - 12h/24h is display preference only (not conversion mode)
  - history stores only explicit user conversions/plans
  - live clocks refresh every minute; offset recompute on timezone/date transitions

3) Visual-system contract
- Apply shared tool + marquee-adjacent visual primitives:
  - consistent typography hierarchy and title treatment
  - no ad hoc pills; tokenized component shape/radius system
  - consistent spacing rhythm and icon style
- Naming/real-estate policy:
  - prefer `&` for compact labels where clarity is preserved
  - full names in menu/picker
  - compact alias labels on tiles
  - modal headers allow two lines max before ellipsis
- Keep Dracula palette direction while unifying style.

4) Weather clarity + refresh contract
- Clarify AQI/pollen semantics in user-facing copy.
- Remove provider/dev phrasing.
- Refresh policy:
  - manual refresh action remains available
  - auto-refresh follows live-data cadence
  - stale indicator appears when freshness threshold is exceeded

5) Regression guardrails (opt-in visual)
- Add targeted high-value snapshots only:
  - Time base surface
  - Time Zone Converter default + swapped states
  - Weather fresh vs stale state
  - long-name title behavior on compact surfaces
- Keep goldens opt-in only.

## Required outcomes
1) Tool architecture enforcement changes landed in code.
2) Time-family split behavior landed with tests.
3) Visual-system consistency updates landed for tool surfaces in scope.
4) Weather semantics/refresh UX landed with tests.
5) Targeted opt-in visual regression coverage added.
6) Docs updated to reflect shipped state:
   - `docs/ai/context_db.json`
   - `docs/ai/handoff/CURRENT_HANDOFF.md`
   - `docs/ai/prompts/NEXT_CHAT_PROMPT.md` (if scope shifts again)

## Execution order (required)
1) Implement tool architecture enforcement + naming/alias policy.
2) Implement Time-family split and IA behavior.
3) Implement weather clarity/refresh contract.
4) Apply visual-system token/spacing/title consistency updates for changed tool surfaces.
5) Add/adjust tests (unit/widget + targeted opt-in visual checks).
6) Run full gates and update docs.

## Definition of done
- Tool taxonomy/duplication behavior is explicit in-code, not only in docs.
- Time workflow is no longer a fuzzy mixed surface.
- Weather details are semantically clear with visible freshness state.
- Updated tool surfaces look like one family, not one-offs.
- Repo is green (`format`, `analyze`, `test`).
