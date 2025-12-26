# Postmortem: First-run wizard navigation and review stabilization

Date: 2025-12-26

## Summary

We stabilized the first-run onboarding wizard after a long patch cycle that alternated between compile breaks and layout overflows. The final state compiles, runs on iOS simulator, and the review step no longer overflows.

The biggest lesson: the wizard is a single high-coupling file where small name or layout changes cascade into failures. Reducing coupling and adding UI regression tests are the highest leverage next steps.

## User goal

- A multi-step wizard with a calm, minimal top area (no app bar titles).
- A bottom navigation region with back/next and progress dots.
- A review step that shows “Home” and “Destination” cards and supports horizontal paging between them.

## What went well

- We converged on a **PageView** based flow that keeps step transitions predictable.
- The **review step** now presents dense information in a card format that matches the dashboard direction.
- The final fixes were straightforward once we treated layout issues as constraint problems, not “padding problems”.

## What went wrong

### 1) Compile churn from missing private members

Repeated breakages were caused by introducing references without declaring the backing fields/methods:

- `_pageController`
- `_maxVisited`
- `_goToStep`, `_canGoToStep`
- `_prev`, `_reviewHeader`, `_profileName`, `_home`, `_dest`

This failure mode is common when patching by “partial memory” of a large file.

### 2) Signature drift on helper widgets

`_placeReviewCard` and other helper builders changed their parameter list across patches. Call sites were not updated in lockstep, leading to multiple “missing required argument” failures.

### 3) Layout constraints fighting scrollables

We hit several classic Flutter constraints issues:

- `Expanded` inside scrollables produced “incoming height constraints are unbounded”.
- A Row without Flexible children overflowed horizontally.
- A Column with fixed height content overflowed vertically on smaller screens.

These were eventually resolved by:

- using `Flexible(fit: FlexFit.loose)` where appropriate
- wrapping dense content in scrollable containers
- avoiding fixed-height Columns in constrained viewports

## Root causes

- **Single-file coupling**: the wizard mixes state, navigation, per-step UI, and dense review layout.
- **Patch granularity**: multiple conceptual changes landed together (navigation + review + layout), creating hard-to-debug interactions.
- **Missing regression harness**: no golden tests existed to flag overflow or nav regressions early.

## Corrective actions (recommended)

### A) Refactor the wizard into smaller widgets

Create:

- `first_run_nav_bar.dart`
- `steps/step_intro.dart`, `step_profile.dart`, `step_home.dart`, `step_destination.dart`, `step_review.dart`
- `widgets/place_review_card.dart`

Goal: each file should compile independently and have stable, explicit inputs.

### B) Add golden tests for each step

At minimum:

- renders without overflow at common device sizes
- review step supports horizontal paging

### C) Add a CI “green gate”

A simple GitHub Actions workflow that runs:

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

This prevents broken patches from becoming the shared baseline.

### D) Adopt a patch checklist

Before requesting a patch:

- list the exact file(s) to change
- list the new/changed fields and methods
- specify which widgets must remain scrollable, and which must not

## Notes for future AI sessions

- Avoid full rewrites of large files.
- When you add a method reference, add the method in the same patch, even if it is a stub.
- When you add `Expanded`, confirm the parent provides finite constraints.
- If you see overflow warnings, treat them as a design feedback loop: extract, wrap, or constrain.
