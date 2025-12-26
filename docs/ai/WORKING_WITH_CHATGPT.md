# AI-assisted development workflow (Unitana)

This project is intentionally developed with AI in the loop. The goal is speed without turning the codebase into a brittle Jenga tower.

## The rules that prevent compile churn

1. **Only change one thing per patch.**
   - One feature change, or one refactor, or one layout fix.
   - Mixed patches are how “undefined identifier” chains happen.

2. **Prefer surgical diffs over full file rewrites.**
   - When you need a large change, do it as a sequence of small, reversible edits.
   - If a file must be rewritten, do it in two phases: (1) move code with no behavior change, (2) modify behavior.

3. **Keep function signatures stable.**
   - If you rename a field or method, do a repo-wide search and update all call sites in the same patch.
   - Never introduce a new helper and forget to declare its backing fields.

4. **Let the formatter win.**
   - Run `dart format .` before committing.
   - Avoid “manual line wrapping” as a style goal. If a widget tree is too wide, extract widgets.

5. **Enforce a “green gate” locally.**
   - Before each commit, run:

     ```bash
     flutter analyze
     flutter test
     ```

   - If a change is UI-only, still run `flutter analyze` so missing imports, renamed methods, and unused fields get caught early.

## Why our earlier patches broke

We repeatedly hit the same failure modes while stabilizing `first_run_screen.dart`:

- **Dangling identifiers** (methods or fields referenced but not declared): `_pageController`, `_maxVisited`, `_goToStep`, `_canGoToStep`.
- **Signature drift**: helper widgets changed their parameter list, but call sites were not updated.
- **Layout constraints**:
  - `Expanded` used inside a `SingleChildScrollView` (unbounded height) caused “incoming height constraints are unbounded”.
  - Rows without `Expanded/Flexible` caused horizontal overflow.
  - The review step used a fixed-height Column that overflowed on shorter screens.

These are predictable failures, which means we can prevent them with structure.

## Structural improvements that reduce risk

### 1) Split large screens into smaller widgets

`lib/features/first_run/first_run_screen.dart` is doing too much. The next refactor should extract:

- `FirstRunNavBar` (bottom controls, progress dots)
- `FirstRunStepIntro`, `FirstRunStepProfile`, `FirstRunStepHome`, `FirstRunStepDestination`, `FirstRunStepReview`
- `PlaceReviewCard`

Keeping each widget in its own file makes it harder to “forget” a dependency and easier to test.

### 2) Add golden tests for the wizard

A few golden tests (one per step, plus review) will catch overflow regressions immediately.

### 3) Add an internal “layout budget” helper

For any dense “card” UI:

- prefer `Wrap` over `Row` when content may exceed width
- prefer `Flexible(fit: FlexFit.loose)` over `Expanded` inside scrollable parents
- prefer `ListView` / `SingleChildScrollView` for review-style content

### 4) Use a simple patch checklist

Before sending a patch upstream:

- [ ] `flutter analyze` is clean
- [ ] `flutter test` passes
- [ ] no unused private fields left behind (unless intentionally staged)
- [ ] no “TODO: wire this later” references that are required at runtime

## Using Flutter docs

When touching navigation, layout constraints, or platform behavior, anchor decisions in the official docs:

- layout constraints: `Expanded`, `Flexible`, `SingleChildScrollView`, `PageView`
- navigation: `Navigator`, routes, and state restoration
- platform differences: iOS safe areas, text scaling, accessibility

Tip: treat Flutter docs as the source of truth when a change feels “subtle”. Subtle is where most UI regressions are born.
