# XL-AA Prioritized Takeover Backlog (2026-04-05)

> Status: Current planning artifact.
> Purpose: Replace the now-mostly-completed XL-Z execution backlog with a new prioritized set of XL slices based on the verified post-modernization audit completed on 2026-04-05.

## Why this exists

The previous XL-Z backlog was largely executed successfully:

- CI exists and is green.
- full local verification is green again,
- edit-session semantics are materially better,
- searchable picker contracts improved,
- hydration and energy unit-switch regressions were fixed,
- weather trustfulness work advanced meaningfully.

The next backlog should not pretend we are still fixing those same baseline problems. The current risks are different:

- release hardening is still incomplete,
- dashboard density and layout philosophy are still underdesigned,
- large orchestration files remain the main maintainability hotspot,
- localization and taxonomy are still transitional,
- a few tools still add more surface area than product value.

## Evidence baseline

- Verified on 2026-04-05:
  - `./tools/verify.sh` passes locally,
  - `.github/workflows/ci.yml` exists,
  - release artifact exists at `app/unitana/build/app/outputs/flutter-apk/app-release.apk`.
- Critical remaining release gap:
  - Android still uses `com.example.unitana` and debug signing for release,
  - iOS still uses `com.example.unitana` bundle identifiers.
- Main structural hotspots still include:
  - `dashboard_screen.dart`,
  - `dashboard_board.dart`,
  - `tool_modal_bottom_sheet.dart`,
  - `places_hero_v2.dart`,
  - `dashboard_copy.dart`,
  - `profiles_board_screen.dart`.

## Operating posture

- Treat this as a consolidation-and-product-clarity backlog, not a feature expansion backlog.
- Keep at most one `XL` slice active at a time, or one `XL` plus one clearly bounded `M` unblocker.
- Do not expand low-value tools while dashboard/layout/localization/release discipline remain unresolved.
- Every slice should end with:
  - updated tests,
  - docs or handoff notes,
  - a verification note,
  - an explicit keep/refactor/remove decision for any touched product surface.

## Recommended execution order

1. `XL-AA1` - Release Hardening And Production Identity
2. `XL-AA2` - Dashboard Density, Layout, And Board UX
3. `XL-AA3` - Dashboard/Profile Structural Decomposition
4. `XL-AA4` - Localization, Taxonomy, And Product Language Consolidation
5. `XL-AA5` - Tool Portfolio Rationalization
6. `XL-AA6` - Regression Gates, Accessibility, And Journey Hardening
7. `XL-AA7` - Performance, Asset, And Instrumentation Budgets

## Slice guardrails

- `AA1` and `AA2` are the highest-value near-term work.
- `AA3` should begin only after the board/layout direction is decided, otherwise we will refactor around unstable UX assumptions.
- `AA4` should land before another broad copy or category pass.
- `AA5` should be evidence-driven and willing to demote or remove weak utilities.
- `AA6` should convert current test strength into real release protection.
- `AA7` should use measured bottlenecks, not speculative micro-optimizations.

## Working slices

### XL-AA1 - Release Hardening And Production Identity

- Status: `In Progress (phase A complete 2026-04-05)`
- Priority: `P0`
- Size: `L`
- Owner mix: `Shared` (`Platform`, `Frontend`, `QA`)
- Why first:
  - The app now behaves better than it ships.
  - Production identity and release discipline still lag behind the product and code quality baseline.
- Includes:
  - replace example Android namespace/application ID and iOS bundle identifiers,
  - replace debug release signing with proper release signing configuration,
  - add CI assertions that fail on example IDs or debug-signed release paths,
  - validate version/build-number flow against the release checklist,
  - produce one fully hardened release candidate build path.
- Excludes:
  - dashboard UX redesign,
  - feature-level tool changes.
- Exit criteria:
  - no production target uses example identifiers,
  - release builds are signed through a real release path,
  - CI can fail fast on release-config regressions,
  - release notes/checklist path is updated to match reality.

#### XL-AA1 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| AA1.1 | Replace Android example namespace/application ID | P0 | S | Platform | Cover manifest/package drift too |
| AA1.2 | Replace iOS example bundle IDs and verify schemes/configs | P0 | S | Platform | Keep build settings aligned |
| AA1.3 | Move Android release off debug signing | P0 | M | Platform | Real keystore path and documented setup |
| AA1.4 | Add release-config CI assertions | P0 | S | QA/Platform | Fail on example IDs or debug signing |
| AA1.5 | Reconcile release checklist with actual artifact path/version flow | P1 | S | Shared | Keep docs trustworthy |

#### XL-AA1 progress note

- Phase A completed on 2026-04-05:
  - replaced example platform identifiers with `app.unitana` across Android, iOS, macOS, and Linux runtime targets,
  - moved Android release signing off the debug-signing path and wired it to a real `key.properties`-driven release config,
  - added a committed `android/key.properties.example` template for local release-signing setup,
  - added local Apple signing override templates for iOS and macOS release builds,
  - documented the release build workflow and public-build command path,
  - added `tools/verify_release_config.sh` and wired it into both `./tools/verify.sh` and GitHub Actions,
  - updated release-readiness checklist references to include the new release-config guard,
  - verified green with full `./tools/verify.sh`.
- Remaining for completion:
  - provision the real Android release keystore and validate a signed release build path outside the repo,
  - set/verify Apple signing team and distribution settings for actual store delivery if not already managed outside the repo,
  - refresh release checklist/handoff notes once the first fully signed production artifact path is exercised end-to-end.

### XL-AA2 - Dashboard Density, Layout, And Board UX

- Status: `In Progress (phase A complete 2026-04-05)`
- Priority: `P0`
- Size: `XL`
- Owner mix: `Shared` (`Design`, `Frontend`, `QA`)
- Why second:
  - The dashboard is the app's home surface and still feels overexposed, sparse, and underconstrained despite stronger interaction contracts.
- Includes:
  - redesign the visible-empty-slot behavior outside edit mode,
  - define a modern tile-cap and overflow strategy,
  - improve board density and row behavior on phone and tablet,
  - align add-widget affordances with the new density model,
  - bring profile-board scaling into a deliberate relationship with dashboard scaling.
- Excludes:
  - deep controller refactors before the UX contract is settled,
  - adding new tile types.
- Exit criteria:
  - normal browsing mode does not look like an unfinished edit canvas,
  - add-widget discovery remains clear without permanent empty-grid noise,
  - tablet layouts use space intentionally,
  - dashboard and profiles have an explicit shared-or-intentionally-different scaling contract.

#### XL-AA2 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| AA2.1 | Define board-density rules for phone and tablet | P0 | M | Design/Frontend | Rows, caps, overflow, empty-slot policy |
| AA2.2 | Remove or constrain always-visible empty slots outside edit mode | P0 | M | Frontend | Replace with clearer add affordance |
| AA2.3 | Rework add-widget entry points around the new board model | P0 | M | Frontend/Design | Avoid hiding creation behind edit-only flows |
| AA2.4 | Redesign profile-board large-screen scaling | P1 | M | Frontend/Design | Current fixed two-column tablet rule is weak |
| AA2.5 | Add layout goldens for dashboard/profile density states | P0 | M | QA | Phone, narrow phone, tablet, edit mode |

#### XL-AA2 progress note

- Phase A completed on 2026-04-05:
  - removed the always-visible empty-slot grid from normal dashboard browsing mode,
  - replaced the non-edit placeholder canvas with a single intentional inline `Add Widget` affordance,
  - preserved the larger placeholder grid in edit mode so drag/drop and insertion still have clear open targets,
  - improved profiles-board scaling so tablet-width layouts use three columns instead of staying pinned to two,
  - added focused regression coverage:
    - `app/unitana/test/dashboard_board_density_contract_test.dart`
    - `app/unitana/test/profiles_board_responsive_smoke_test.dart`
  - verified green with full `./tools/verify.sh`.
- Phase B completed on 2026-04-05:
  - introduced a true wide-layout dashboard breakpoint so very wide surfaces can use four columns instead of stretching the same three-column board indefinitely,
  - kept existing phone (`2`) and tablet (`3`) behavior stable while extending reorder persistence coverage into the new wide-layout case,
  - updated regression coverage in:
    - `app/unitana/test/dashboard_reorder_persistence_breakpoints_test.dart`
  - reverified green with full `./tools/verify.sh`.
- Phase C completed on 2026-04-05:
  - introduced an explicit browse-mode overflow contract instead of rendering an unbounded dashboard by default,
  - phone browsing now caps at five visible board rows and tablet/wide browsing caps at four visible board rows,
  - overcrowded dashboards can expand to `Show all widgets` and collapse back to `Show fewer widgets`,
  - edit mode remains uncapped so drag/drop, removal, and insertion still operate on the full board,
  - duplicate-tool focus can now auto-expand the board when the existing tile is hidden below the collapsed rows,
  - added focused regression coverage in:
    - `app/unitana/test/dashboard_board_density_contract_test.dart`
  - reverified green with focused dashboard regression coverage before the next full verify pass.
- Remaining for later AA2 continuation:
  - promote the highest-value dashboard/profile density states into mandatory visual regression coverage,
  - revisit whether dashboard and profiles should share more of the same responsive-grid rules,
  - decide later whether the current expand/collapse overflow model is the final product contract or a stepping stone to a stricter capped or sectioned board.

### XL-AA3 - Dashboard/Profile Structural Decomposition

- Status: `Planned`
- Priority: `P1`
- Size: `XL`
- Owner mix: `Shared` (`Frontend`, `QA`)
- Why third:
  - The next meaningful maintainability gain is no longer more surface extraction; it is reducing orchestration concentration and broad rebuild risk.
- Includes:
  - split board/session orchestration out of `dashboard_screen.dart` and `dashboard_board.dart`,
  - define a board-layout engine/presenter boundary,
  - extract profile-board layout/state handling into clearer modules,
  - reduce `tool_modal_bottom_sheet.dart` responsibility to routing/orchestration where practical,
  - preserve current interaction contracts while shrinking high-risk change surfaces.
- Excludes:
  - net-new dashboard features,
  - speculative state-management rewrites without a bounded migration plan.
- Exit criteria:
  - dashboard board/layout logic is testable outside giant widget files,
  - profile board no longer depends on one oversized screen file for most behavior,
  - modal/tool routing is thinner,
  - the top change-risk files are materially smaller and simpler.

#### XL-AA3 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| AA3.1 | Define board presenter/layout-engine seam | P0 | M | Frontend | Contracts before extraction |
| AA3.2 | Extract dashboard board state/layout logic into dedicated modules | P0 | L | Frontend | Keep widget integration coverage |
| AA3.3 | Extract profile-board layout/action handling | P1 | M | Frontend | Pair with scaling contract from AA2 |
| AA3.4 | Continue tool modal state/controller decomposition | P1 | L | Frontend | Routing/orchestration shell goal |
| AA3.5 | Add parity tests for extracted board and modal contracts | P0 | M | QA | Prevent refactor regressions |

### XL-AA4 - Localization, Taxonomy, And Product Language Consolidation

- Status: `Planned`
- Priority: `P1`
- Size: `L`
- Owner mix: `Shared` (`Frontend`, `Design`, `QA`)
- Why fourth:
  - The app now has better product behavior than product language. Naming, translation ownership, and category taxonomy are still partially transitional.
- Includes:
  - complete the migration away from seed/fallback drift where practical,
  - fill or intentionally remove incomplete ARB entries,
  - settle final category naming beyond partial `Reference` cleanup,
  - remove `oddUseful`, `quickTools`, and old time-converter residue from the active taxonomy path,
  - tighten copy on tools that still overclaim usefulness or smartness.
- Excludes:
  - broad marketing rewrite,
  - locale expansion beyond supported quality.
- Exit criteria:
  - active strings have one clear source of truth,
  - category/lens naming is internally and externally consistent,
  - legacy time-conversion taxonomy residue is gone from active UX paths,
  - copy for trust-sensitive tools is plainer and more honest.

#### XL-AA4 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| AA4.1 | Audit and resolve incomplete ARB coverage | P0 | M | Frontend/QA | Add missing-string gate |
| AA4.2 | Reduce runtime localization fallback drift | P1 | M | Frontend | Finish or narrow transitional path |
| AA4.3 | Finalize category naming and remove internal taxonomy residue | P0 | S | Design/Frontend | `Reference` may not be final |
| AA4.4 | Remove active legacy time-converter naming residue | P1 | S | Frontend | IDs, labels, descriptors, docs where active |
| AA4.5 | Rewrite trust-sensitive copy for tax, energy, and weak lookup tools | P1 | S | Design/Frontend | Make limitations explicit without clutter |

### XL-AA5 - Tool Portfolio Rationalization

- Status: `Planned`
- Priority: `P1`
- Size: `XL`
- Owner mix: `Shared` (`Product`, `Design`, `Frontend`, `QA`)
- Why fifth:
  - The app has stabilized enough that the next product win is reducing weak or muddled surface area instead of adding more.
- Includes:
  - evaluate clothing sizes for expansion vs demotion vs removal,
  - decide whether daily energy should be improved, simplified, demoted, or removed,
  - tighten Tax / VAT framing into an explicitly manual calculator contract,
  - confirm the time widget/tool alignment as a deliberate pattern rather than accidental divergence,
  - standardize picker expectations across similar chooser flows.
- Excludes:
  - weather-provider strategy changes,
  - backend/data-source expansion unless needed for a keep decision.
- Exit criteria:
  - each weak or questionable tool has a documented keep/refactor/remove direction,
  - clothing and energy are no longer "maybe useful" placeholders,
  - tax calculator trust posture is explicit,
  - picker consistency is treated as a product standard.

#### XL-AA5 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| AA5.1 | Decide clothing-size keep/expand/demote direction with dataset reality in view | P0 | M | Product/Design/Frontend | Current dataset is too shallow for confidence |
| AA5.2 | Simplify or demote daily energy estimate | P1 | S | Product/Frontend | Avoid low-signal maintenance burden |
| AA5.3 | Tighten Tax / VAT into an explicitly manual calculator mental model | P0 | S | Design/Frontend | Keep visible contextual presets only |
| AA5.4 | Document the time-widget analog/text pattern as a deliberate UX rule | P1 | S | Design/Frontend | Compact vs expanded behavior |
| AA5.5 | Standardize picker contract across currency/timezone/other searchable flows | P1 | M | Frontend/Design | Search, selected, suggested, all |

### XL-AA6 - Regression Gates, Accessibility, And Journey Hardening

- Status: `Planned`
- Priority: `P1`
- Size: `XL`
- Owner mix: `Shared` (`QA`, `Frontend`, `Design`)
- Why sixth:
  - The test suite is stronger now, but too much of the app's interaction polish and accessibility quality still depends on convention rather than hard gates.
- Includes:
  - promote a focused golden suite into required CI,
  - add high-value end-to-end journeys for dashboard/profile/tool-management flows,
  - continue semantics/focus-order audits through modal and picker surfaces,
  - add dynamic-text and non-color-indicator coverage where dense UI still risks failure.
- Excludes:
  - exhaustive full-device matrix automation from day one,
  - visual testing on every low-risk screen.
- Exit criteria:
  - layout-sensitive surfaces have mandatory visual protection,
  - core user journeys have E2E regression coverage,
  - accessibility coverage goes beyond isolated semantics assertions,
  - design regressions are harder to ship accidentally.

#### XL-AA6 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| AA6.1 | Promote a golden smoke suite to required CI | P0 | M | QA | Dashboard, profiles, time, tax, currency |
| AA6.2 | Add E2E coverage for widget/profile management journeys | P0 | M | QA/Frontend | Add, reorder, remove, cancel, done |
| AA6.3 | Extend accessibility audit through tool modal and picker surfaces | P1 | M | Frontend/Design | Focus order, labels, narration |
| AA6.4 | Add dynamic-type and dense-layout resilience coverage | P1 | M | QA | Small phone plus accessibility text sizes |
| AA6.5 | Add non-color state/category indicators where still needed | P1 | S | Design/Frontend | Especially dense dashboards and chips |

### XL-AA7 - Performance, Asset, And Instrumentation Budgets

- Status: `Planned`
- Priority: `P2`
- Size: `L`
- Owner mix: `Shared` (`Frontend`, `Platform`, `QA`)
- Why seventh:
  - The app already has some good isolated perf discipline. The next step is to turn that into an app-level budget and observability habit.
- Includes:
  - define measurable budgets for dashboard open, tool open, refresh latency, and key picker search paths,
  - audit APK/app-bundle size and identify top removable weight,
  - evaluate asset slimming and packaging improvements,
  - decide whether city dataset loading/compression should change based on measured impact,
  - add lightweight runtime performance instrumentation for high-value flows.
- Excludes:
  - speculative optimization without measurements,
  - weather-provider swapping as a proxy for performance work.
- Exit criteria:
  - top user flows have measurable budgets,
  - asset and package-size tradeoffs are documented with clear actions,
  - performance regressions become easier to detect during normal work,
  - optimization work is grounded in real timings and size data.

#### XL-AA7 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| AA7.1 | Add measurable budgets for dashboard open and tool open | P0 | M | Frontend/QA | Use real devices or representative emulators |
| AA7.2 | Audit package/asset weight and define slimming targets | P1 | M | Platform | APK and app-bundle view |
| AA7.3 | Add lightweight runtime perf tracing for core journeys | P1 | M | Frontend | Keep debug-only if needed |
| AA7.4 | Revisit city dataset loading only if profiling justifies it | P2 | S | Frontend | Current picker path is already disciplined |
| AA7.5 | Add release-size and perf summary to verification notes | P2 | S | Shared | Keep optimization decisions visible |

## Explicit non-goals for the next cycle

- Do not add new utility tools simply because there is room in the dashboard.
- Do not broaden weather-provider strategy while the current direction is explicitly paused as good enough for now.
- Do not start a framework-level state-management rewrite without proving the current extraction path is blocked.
- Do not preserve weak tools indefinitely just because they already exist.

## First recommended next start

If we want the highest-value next slice, start `XL-AA1` first and close the production-identity gap. If we want the highest user-visible product improvement immediately after that, start `XL-AA2`.
