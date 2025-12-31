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

## SEV-1 guardrails: prevent widget API drift

We hit a SEV-1 failure mode while trying to refactor the Dashboard Places Hero widget: the code compiled locally in pieces but the public widget API and model layer drifted out of sync, and then flutter analyze and every widget test failed at once.

Hard rules for any dashboard or cross-screen widget work:

1. **Freeze the public API first.**
   - Before editing, copy the current constructor signature and any public typedefs/enums into your notes.
   - Do not change required parameters, rename fields, or add new named parameters during a layout pass.

2. **No invented domain types.**
   - If a type like `UnitSystem` is referenced, it must already exist in the repo.
   - If it does not exist, stop and create a small, explicit plan (where it lives, imports, migrations, tests).

3. **Null safety is a contract, not a suggestion.**
   - If a parameter is non-nullable, do not pass a nullable value and hope it works.
   - Fix the source of truth (state initialization) or adjust the API in a deliberate, repo-wide change.

4. **Constructor drift checks are mandatory.**
   - After changing a widget constructor, run a repo-wide search for that widget and update every call site in the same patch.

5. **Green gate at micro-steps.**
   - For high-churn files (dashboard widgets), run `flutter analyze` after each logical edit.
   - If analyze fails, do not continue stacking changes. Fix the failure immediately or revert.

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

- [ ] docs/ai/context_db.json updated (include a patch_tracking.log entry for this patch)
- [ ] patch zip includes all changed files *and* the updated context_db.json
- [ ] widget Keys used by tests remain stable and unique (never duplicate a Key)
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

## Lessons learned: dashboard tile stability

### RenderFlex overflow policy
Small tiles must be treated as “layout budgeted” components. Any text beyond the minimum should be designed to degrade gracefully, not fail layout.

Practical standards:

- **No required footers** in small tiles. Footers are optional and must be omitted when empty.
- **Secondary text is optional**; if present, it must be 1 line max in compact layouts and always ellipsized.
- **Never rely on fixed spacers** to separate sections in a fixed-height tile. Prefer conditional gaps.
- **Keep tiles resilient**: passing an empty string for secondary/footer should render nothing, not blank space that still consumes layout.

### Null safety policy for theme extensions
Avoid `!` on theme extensions inside widgets. Extensions can be absent during theme transitions, tests, or partial refactors.

Preferred pattern:

- use `Theme.of(context).extension<T>() ?? T.fallback()` if you have a safe fallback
- or keep layout tokens in a non-nullable theme wrapper used by all routes

### Deprecation hygiene
When Flutter flags a deprecation (for example `withOpacity`), treat it like a small but real tech-debt ticket. Fix it immediately when you touch the file so it does not keep resurfacing.

### Unicode and symbol hygiene
When copying code through multiple tools, prefer explicit escapes for characters that are frequently mangled:

- degrees: `\u00B0`
- euro: `\u20AC`

If the UI needs those symbols dynamically, keep them in one place (a formatter helper) so they do not appear scattered across widgets.

### Test selector hygiene

When writing widget tests, prefer `ValueKey('...')` lookups over brittle text matching.

Notes:

- `Key('some_id')` and `ValueKey('some_id')` compare equal, but `ValueKey` is clearer and avoids confusion about constructors.
- Keep keys stable even when copy changes. Tests should survive UI copy tuning.


## Lessons learned: constraint truth and compact behavior

### Don’t assume parent constraints match child constraints
If a widget receives a `compact` boolean from its parent, it may still end up laid out in a tighter space due to internal paddings, header rows, or sibling layouts. When a layout must be safe for small surfaces, compute **effective compactness** from *actual* constraints using `LayoutBuilder` inside the widget, then degrade gracefully.

Practical rule:
- if `constraints.maxHeight` or `constraints.maxWidth` is under your known safe threshold, force compact mode regardless of what the parent asked for.

### AppBar leading: avoid `Row` unless you need horizontal layout
`Row` gives children unbounded width, which makes text measure at its full intrinsic width and can cause overflow inside the leading slot. If you only need a vertical stack, use a `SizedBox(width: double.infinity, child: Column(...))` so children receive a real max width and ellipsize correctly.

### Fixed-height areas need “optional” secondary text
The AppBar and small tiles are fixed-height by design. Any secondary label (for example “Updated 8:35 AM”) must be optional, single-line, and able to disappear when the layout is tight.
