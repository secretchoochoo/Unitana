# Cleanup and hardening plan (next phase)

## Scope boundaries for this phase
- **Stabilize and document**. No new features unless they remove fragility.
- **Favor reversible changes**. Small PRs, each with a clear rollback.

## P0: Fix remaining dashboard fragility
1. **Finalize the “Custom” tile as minimal**
   - Treat it as a placeholder until we decide real copy and interactions.
   - Prefer a single label over multiple lines in small tiles.

2. **Tile layout budget guideline**
   - Every 2x2 tile must render within a 147x147 box with:
     - Title row (icon + short title)
     - One primary value (single line)
     - Optional secondary or footer, but not both, unless verified on small devices.
   - Use `maxLines`, `TextOverflow.ellipsis`, and conditional sections.

3. **Add widget-level regression tests (golden or layout)**
   - Render dashboard at small size (iPhone SE / small Android) and assert:
     - No RenderFlex overflow
     - No exceptions in logs
   - Render in light and dark.

## P1: Reduce compile churn and “death by a thousand lints”
1. **Establish a strict patch discipline**
   - Always provide: reason, files touched, and a small diff.
   - Avoid reformatting unrelated files in the same commit.

2. **Strengthen analyzer hygiene**
   - Fix `info`-level issues while in the file.
   - Keep `flutter analyze` clean before moving on.

3. **Avoid API drift**
   - If Flutter warns about deprecations, replace them immediately.
   - Prefer official docs for anything that smells version-sensitive.

## P2: Documentation hardening
1. **Docs information architecture check**
   - Identify the “front door” docs (root README, docs/README).
   - Ensure every docs folder has a README that explains what belongs there.

2. **Revision history convention**
   - For architecture and process docs, add a short changelog section:
     - Date, summary, author.

3. **Add a standing “Lessons learned” doc**
   - Short bullets of real issues (overflow, null assertions, unicode pitfalls).
   - Each entry should include: symptom, root cause, fix pattern.

## P3: AI workflow and prompt hardening
1. **Build a compact “context database”**
   - A small JSON file with:
     - product thesis
     - architecture decisions
     - naming conventions
     - UI layout budgets
     - do and do-not rules

2. **Slice execution template**
   - For each new task:
     - Goal
     - Files to touch
     - Diff-only changes
     - Verify steps (analyze, run, tests)

## Definition of Done for this phase
- Dashboard renders on small devices with zero overflows.
- `flutter analyze` is clean.
- A basic dashboard rendering test exists.
- Docs have: retro, cleanup plan, updated AI workflow guidance, and a next-chat handoff prompt.
