# P1.23 Fast Retro

Date: 2026-01-30

## Why UI/UX regressed repeatedly
- **Design decisions were not anchored to a single, testable contract.** Intent lived in chat, scattered notes, and code. Small tweaks sometimes resurrected older patterns because the target state was not captured in one canonical spec.
- **The hero is multi-modal and tightly coupled.** Compact mode, micro fallback, and pinned overlay share helpers and keys. A fix in one mode can change another mode’s layout or semantics.
- **Invisibility is not absence.** We used opacity/ignore-pointer patterns where tests expected widgets to not exist at all. This created “looks right” but fails tests behavior.
- **Live data wiring is brittle without guardrails.** When a data field is null or missing, the UI can silently render blanks. That reads as “broken data,” even when the UI is functioning.

## What we should do differently
### 1) Update the design spec as we iterate
- Maintain a single markdown contract for the hero and pinned overlay that includes:
  - Layout regions and their responsibilities
  - Keys that tests rely on
  - Which content is allowed in the pinned overlay (toggle-only) versus the hero (full mini hero)
  - Micro-mode behavior and allowed fallbacks
- Treat changes to that contract as first-class work: update doc, update tests, then update code.

### 2) Add safeguards that catch regressions early
High value tests to add or strengthen:
- **Hero header contract**: time line and date line are present; date uses middle dot separators; time line allows up to 2 lines in compact mode.
- **Currency contract**: centered alignment; primary line uses a larger style; micro mode still centers.
- **Wind/gust content**: no duplicate emojis; “Wind” line contains only one wind emoji, same for gust.
- **Null-data snapshots**: when sun/env/weather is null, show a clear placeholder (em dash) and never an empty string.
- **Pinned overlay existence contract**: when not visible, widgets are not built (findNothing), not merely transparent.

### 3) Improve the AI handoff and state strategy
- Keep **one** canonical state file: `docs/ai/context_db.json`.
- Keep **one** canonical handoff: `docs/ai/handoff/CURRENT_HANDOFF.md`.
- Any patch that changes UI contracts must update:
  - the hero contract doc
  - the tests that encode it
  - the handoff entry and patch log

## Backlog accuracy and cleanup
- Run a backlog sweep and group items into: Stabilization, Hardening, UX polish, Tools.
- Mark deprecated patterns explicitly (pills/readout variants we do not want) and remove dead files only during the hardening phase.
- Docs cleanup target list:
  - Duplicate or superseded hero design notes
  - Old prompts that no longer match the current workflow
  - Stale experimental specs that are no longer pursued

## Proposed next phases
1. **Stabilize to green**: fix remaining test/analyze failures; confirm live data fields are rendering.
2. **Hardening**: reduce coupling, add contract tests, remove dead code and stale docs.
3. **Design lock**: freeze the hero contract and require contract update plus tests for any future UI change.
4. **Resume Tools**: move focus back to tool modals and the remaining tool backlog.
