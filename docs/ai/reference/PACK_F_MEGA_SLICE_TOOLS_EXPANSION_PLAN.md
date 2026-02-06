# Pack F Mega Slice: Tools Expansion, Stress, and UX Modeling

## Intent
Run an extra-large implementation slice to aggressively reduce remaining tool gaps and harden behavior by building, testing, and stress-breaking the surface.

## Scope
1) Activate and ship as many remaining tools as feasible in one sustained pass.
2) Define and implement size-matrix tool UX (shoe/paper/mattress/clothing stance).
3) Define and prototype Weather tool redesign direction with concrete UI model.
4) Expand unit matrices for high-value converters with sane defaults.
5) Guarantee easy reset to city/profile-derived defaults for all modal tool states.

## Direction locks
- Table/matrix standards tools use lookup-style UX, not generic numeric convert forms.
- Weather cannot remain generic converter UX; pick and build against a deliberate model.
- Save/update feedback should follow `SAVE_UPDATE_FEEDBACK_MATRIX.md`.

## Workstreams
### A) Remaining tool activation bundle
- Audit all disabled tool IDs in registry.
- Categorize each:
  - activate now
  - merge into existing tool
  - defer with rationale
- Implement highest-value set end-to-end:
  - registry + picker + modal + conversion logic + tests

### B) Size/matrix tools
- Build shared lookup-table shell:
  - system selector(s)
  - category/row selector
  - immediate mapped result row
  - optional notes/caveats
- Implement in this order:
  1) `paper_sizes`
  2) `shoe_sizes`
  3) `mattress_sizes`
- Evaluate `clothing_sizes` quality risk and ship only if variance handling is acceptable.

### C) Weather redesign
- Prepare a 2-option product/UX pitch and choose one:
  - Option 1: utility-first compact weather conversion helper
  - Option 2: rich weather cockpit (larger marquee + expanded API detail)
- Implement chosen option with:
  - coherent modal anatomy
  - data contract alignment with existing providers
  - tests for core rendering and fallback paths

### D) Unit matrix expansion + defaults
- For each active converter, audit missing commonly-used units.
- Add missing units where value/clarity is high.
- Add per-tool reset-to-default behavior:
  - one tap to restore city/profile-derived default from/to units and direction
  - avoid sticky overrides that outlive context unintentionally

### E) Build-break-hardening loop
- Run repeated stress cycles:
  - edit-mode reorder + drag/drop
  - small-screen layouts
  - mixed unit systems and 12/24h states
  - profile switching and restart persistence
- Add tests for every bug found during stress passes.

## Required outputs
- Updated disabled-tool audit table with status and rationale.
- Shipped activation set with tests.
- Weather redesign decision record + implemented baseline.
- Size/matrix lookup shell + initial tools shipped.
- Default-reset behavior implemented and tested.
- Docs updated:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/prompts/NEXT_CHAT_PROMPT.md`
  - `docs/ai/reference/SAVE_UPDATE_FEEDBACK_MATRIX.md` (as gaps close)

## Quality gates (required)
- `dart format .`
- `flutter analyze`
- `flutter test`

## Definition of done
- Material reduction in remaining disabled tool count.
- Weather no longer treated as generic converter placeholder.
- Size/matrix tools represented with user-appropriate lookup UX.
- Clear, consistent save/update feedback behavior across changed flows.
