# XL-Z Reconciled Audit And Execution Backlog (2026-04-04)

> Status: Current planning artifact.
> Purpose: Reconcile the 2026-04-04 takeover audits into one execution-ready backlog that favors larger working slices over fragmented issue churn.

## Why this exists

Two independent audits reached similar architectural conclusions but differed on severity, release-readiness framing, and a few factual claims. This document resolves those differences and turns the result into a practical backlog we can execute in deliberate slices.

## Evidence snapshot

- Local verification on 2026-04-04:
  - `flutter analyze` passes in `app/unitana`.
  - `flutter test` is **not green** in the checked workspace used for this audit.
  - Current locally observed failures include:
    - developer-tools menu visibility tests,
    - currency tiny-unit scaling/global mapping tests,
    - currency rate coverage (`AED->USD` missing),
    - a time tile reality-switch regression.
- Release discipline:
  - repo-level validation exists via `tools/verify.sh`.
  - local optional hook exists via `tools/githooks/pre-commit`.
  - no GitHub Actions / `.github` workflow is present in the repository.
- Structural concentration remains the dominant architectural issue:
  - `tool_modal_bottom_sheet.dart`
  - `dashboard_live_data.dart`
  - `places_hero_v2.dart`
  - `dashboard_screen.dart`

## Reconciled audit position

### We accept from Cohort A

- The app's main risk is **concentrated complexity**, not isolated bugs.
- Cross-surface interaction consistency is too weak:
  - pickers,
  - dashboard/profile edit models,
  - long-press behavior,
  - category/lens styling.
- The hydration tool has a real trust bug: unit switching does not convert the displayed input value.
- The currency picker is materially behind the timezone picker.
- The timezone converter/category accent mismatch is a real metadata defect.
- A real edit-session contract is missing.
- Tool and dashboard architecture should be modularized before more feature growth.

### We accept from Cohort B

- The app is **not a throwaway prototype**. It has meaningful engineering discipline:
  - feature-based structure,
  - versioned persistence,
  - a documented local verify flow,
  - strong test helpers,
  - some explicit perf-budget thinking.
- Missing CI should be framed as **manual gates without merge enforcement**, not "no quality process."
- Product recommendations should be less trigger-happy about removing tools without usage evidence.
- The timezone picker is the strongest reusable pattern in the app and should be promoted, not replaced.
- The Tax/VAT tool already has dual modes; the main problem is labeling and mental-model clarity.

### We reject or narrow

- "All tests pass" is not accepted as current truth for this workspace.
- "The build-side-effect critique is unsubstantiated" is rejected.
  - the dashboard build path currently triggers auto-refresh scheduling and data seeding.
- "The app is in crisis" is too strong.
  - the app has debt and drift, but the right posture is deliberate consolidation, not emergency rewrite.
- "Immediately remove low-value tools" is too strong.
  - first consolidate, clarify, instrument, and then prune with evidence.

## Product direction guardrails

- Preserve the core product idea:
  - home/destination dual-reality context,
  - strong time/weather/currency utility,
  - profile-driven defaults.
- Standardize repeated interaction patterns before expanding surface area.
- Prefer demotion, merging, or reframing over outright feature deletion unless a tool is both low-value and high-cost.
- Favor explicit user-visible defaults over hidden "smart" personalization.
- Every multi-step or mode-based surface must have a tested state contract.

## Backlog operating model

- Work in **larger slices** with a deliberate design note and exit criteria before implementation.
- Keep at most:
  - one `XL` slice active at a time, or
  - one `L/XL` slice plus one small unblocker slice in parallel.
- Child tasks exist to define scope, not to create endless ticket churn.
- Each slice should produce:
  - a short implementation plan,
  - contract tests or updated coverage,
  - docs/handoff updates,
  - a verification note.

## Working slices

### XL-Z1 — Release Gates And Trust Bugs

- Status: `Done (2026-04-04)`
- Priority: `P0`
- Size: `L`
- Owner mix: `Shared` (`Frontend`, `QA`, `Platform`)
- Why first:
  - This slice fixes user-trust defects and restores reliable baseline signals for all later work.
- Includes:
  - make the local test/analyze baseline green again,
  - add GitHub Actions for `dart format --set-exit-if-changed .`, `flutter analyze`, and `flutter test`,
  - align devtools compile-time flags into a single source of truth,
  - fix hydration unit-switch value conversion,
  - fix energy tool unit-switch value conversion if still affected,
  - add a metadata contract test for tool lens/category consistency,
  - resolve the currently failing currency scaling/rate coverage regressions.
- Excludes:
  - large tool-surface redesign,
  - live-data controller decomposition.
- Exit criteria:
  - `tools/verify.sh` passes locally,
  - CI exists and blocks merges,
  - trust bugs are covered by tests,
  - devtools behavior is deterministic across build/test modes.

#### XL-Z1 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| Z1.1 | Reproduce and fix current red tests in dashboard devtools, currency scaling, and rate coverage | P0 | M | Frontend/QA | Treat as baseline stabilization, not feature work |
| Z1.2 | Add GitHub Actions merge gate for format, analyze, test | P0 | S | Platform | Pair with branch protection recommendation |
| Z1.3 | Unify developer-tools compile flags and add contract coverage | P0 | S | Frontend | Remove `UNITANA_DEVTOOLS_ENABLED` vs `UNITANA_ENABLE_DEVTOOLS` drift |
| Z1.4 | Fix hydration displayed-value conversion on unit switch | P0 | S | Frontend | Trust bug |
| Z1.5 | Fix energy displayed-value conversion on unit switch | P1 | S | Frontend | Same contract family as hydration |
| Z1.6 | Add tool lens/category contract test | P1 | S | QA | Prevent registry/definition drift |

### XL-Z2 — Interaction Consistency Foundation

- Status: `Done (2026-04-04)`
- Priority: `P0`
- Size: `XL`
- Owner mix: `Shared` (`Frontend`, `Design`, `QA`)
- Why second:
  - This slice removes the most visible product incoherence and creates reusable contracts for the rest of the app.
- Includes:
  - extract a shared searchable picker pattern from the timezone picker,
  - apply it to currency first,
  - define a true `EditSession` model for dashboard and profiles,
  - separate long-press quick actions from edit-mode entry,
  - make `Cancel` and `Done` semantically distinct and tested,
  - align profile picker quick actions and dashboard quick actions where appropriate.
- Excludes:
  - full tool-modal decomposition,
  - deep layout redesign of the whole dashboard.
- Exit criteria:
  - one shared picker contract exists,
  - dashboard and profiles share explicit edit-session semantics,
  - long-press no longer leaves users in surprising mode states,
  - `Cancel` discard behavior is real and protected.

#### XL-Z2 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| Z2.1 | Extract `SearchablePicker` from timezone picker behavior | P0 | M | Frontend | Preserve ranking/search quality already in timezone flow |
| Z2.2 | Replace currency picker with shared picker | P0 | M | Frontend | Add common/pinned/selected behavior |
| Z2.3 | Define `EditSession` state model with clean/dirty/commit/discard semantics | P0 | M | Frontend | Shared model for dashboard + profiles |
| Z2.4 | Decouple long-press quick actions from edit-mode entry | P0 | M | Frontend/Design | Quick-action sheet should not implicitly latch edit mode |
| Z2.5 | Add discard confirmation only when edit session is dirty | P1 | S | Frontend | Avoid noisy confirmations |
| Z2.6 | Add integration coverage for dashboard/profile edit flows | P0 | M | QA | High-regression surface |

#### XL-Z2 progress note

- Phase A completed on 2026-04-04:
  - extracted a reusable searchable option picker shell,
  - upgraded the currency picker to searchable + selected/common surfacing,
  - decoupled dashboard long-press quick actions from implicit edit-mode entry,
  - added an explicit quick-action path into edit mode,
  - updated regression coverage and verified green.
- Remaining Z2 scope:
  - none for the core slice; deeper profile-surface parity can roll into future UX follow-through if needed.
- Phase B completed on 2026-04-04:
  - added a shared discard-confirmation sheet contract for edit surfaces,
  - made dashboard cancel semantics truly clean-vs-dirty aware,
  - fixed false-dirty edit entry caused by internal anchor freezing,
  - made profile reorder dirty-tracking explicit and order-aware,
  - added discard-flow regression coverage for dashboard and profiles,
  - verified green with targeted tests and full `tools/verify.sh`.

### XL-Z3 — Tool Clarity And Product Rationalization

- Status: `Complete (2026-04-04)`
- Priority: `P1`
- Size: `L`
- Owner mix: `Shared` (`Product`, `Design`, `Frontend`, `QA`)
- Why third:
  - The app has enough tools; now it needs better hierarchy, naming, and mental models.
- Includes:
  - rename `Odd & Useful` to a clearer category (`Reference` or `Utilities`),
  - redesign Tax/VAT copy and defaults around plain-language modes,
  - decide the timezone converter's long-term role:
    - standalone,
    - merged into time,
    - or demoted,
  - clarify the daily energy snapshot as an estimate or demote it,
  - restructure clothing sizes around progressive disclosure,
  - normalize system-utility naming such as cups/grams.
- Excludes:
  - deep backend or live-data changes.
- Exit criteria:
  - each questioned tool has a documented keep/merge/demote direction,
  - labels and modes use plain language,
  - category taxonomy is clearer and more professional.

#### XL-Z3 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| Z3.1 | Rename `Odd & Useful` and update category copy | P1 | S | Design/Frontend | Prefer clarity over charm |
| Z3.2 | Rewrite Tax/VAT modes as plain language with short explanations | P1 | S | Frontend/Design | Keep dual-mode behavior |
| Z3.3 | Add profile-aware suggestions for country/currency defaults where visible and overridable | P1 | M | Frontend | No hidden personalization |
| Z3.4 | Retire the standalone timezone converter and fold legacy references into the main Time tool | P1 | M | Product/Frontend | Remove weak standalone surface without breaking saved layouts |
| Z3.5 | Rework clothing sizes to clothing-type-first progressive disclosure | P1 | M | Frontend/Design | Use existing data before broadening scope |
| Z3.6 | Reframe daily energy as estimate, with clearer labels and kcal-first output | P2 | S | Frontend/Design | Keep only if value remains defensible |

#### XL-Z3 progress note

- Phase A completed on 2026-04-04:
  - renamed the `Odd & Useful` lens to `Reference`,
  - rewrote Tax/VAT surface language into clearer plain-language modes,
  - surfaced visible tax preset context tied to the active pricing location,
  - renamed the cups/grams utility to `Cups to Grams`,
  - added clearer explanatory copy to hydration and energy helper surfaces,
  - improved clothing matrix guidance and reference-only disclaimer copy,
  - updated regression coverage and verified green with full `tools/verify.sh`.
- Phase B completed on 2026-04-04:
  - initially demoted and reframed the timezone converter around converting a specific local date/time,
  - reworked clothing sizes into garment-group-first progressive disclosure,
  - filtered the matrix by garment group and narrowed the header to `Garment / Size`,
  - updated regression coverage around clothing groups, converter framing, registry placement, and activation-bundle stability.
- Product direction superseded later on 2026-04-04:
  - retire the standalone time conversion surface,
  - remove the `timezone_lookup` discovery entry,
  - normalize legacy `timezone_lookup` / `time_zone_converter` references to the main `time` tool so saved layouts do not break.
- Final Z3 direction:
  - timezone converter: `remove standalone surface and fold legacy references into time`,
  - clothing sizes: `keep and simplify around garment-first progressive disclosure`,
  - energy tool: `retain as an estimate-oriented helper until usage data justifies stronger action`.

### XL-Z4 — Tool Surface Architecture Decomposition

- Status: `Complete (phase E complete 2026-04-04)`
- Priority: `P1`
- Size: `XL`
- Owner mix: `Frontend`
- Why fourth:
  - This is the biggest maintainability win, but it should happen after the baseline trust and interaction contracts are stabilized.
- Includes:
  - split `tool_modal_bottom_sheet.dart` into per-tool components/modules,
  - introduce a per-tool state/controller contract,
  - move tool-specific calculators and UI branching out of the monolith,
  - preserve current behavior with contract tests during extraction.
- Excludes:
  - major new tool feature expansion.
- Exit criteria:
  - tool modal shell is thin,
  - high-churn tools live in dedicated files,
  - tool-specific logic can be tested independently.

#### XL-Z4 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| Z4.1 | Define tool-surface module contract and migration plan | P1 | M | Frontend | Decide routing/state pattern first |
| Z4.2 | Extract calculator-style tools into dedicated modules | P1 | L | Frontend | Start with simple converters |
| Z4.3 | Extract matrix/reference tools into dedicated modules | P1 | L | Frontend | Clothing, cups/grams, paper, mattress, shoe sizes |
| Z4.4 | Extract context-aware tools (tax, hydration, energy, time variants) into dedicated modules | P1 | XL | Frontend | Highest complexity branch |
| Z4.5 | Add per-tool smoke coverage after extraction | P1 | M | QA | Preserve current activation paths |

#### XL-Z4 progress note

- Phase A completed on 2026-04-04:
  - introduced `tool_helper_surfaces.dart` as the first dedicated module contract for extracted helper-tool UIs,
  - extracted hydration, tip helper, Tax / VAT, and daily energy estimate layouts out of `tool_modal_bottom_sheet.dart`,
  - kept state/controller logic in the modal for this pass while moving UI branching and callback wiring into dedicated widgets,
  - added direct widget coverage for the extracted helper-surface module,
  - revalidated existing modal-path regression tests and activation-bundle coverage after extraction.
- Phase B completed on 2026-04-04:
  - expanded the helper-surface module to include unit-price and pace insights/planner surfaces,
  - moved another large chunk of dedicated UI branching out of `tool_modal_bottom_sheet.dart`,
  - preserved current modal-path state ownership and interaction contracts while shrinking the modal further,
  - added direct surface coverage and revalidated modal-path regression tests for unit price and pace.
- Phase C completed on 2026-04-04:
  - introduced `tool_time_workspace.dart` as a dedicated time-family composition module,
  - moved facts-card, jet-lag planner, world-time map, and timezone-converter workspace assembly out of `tool_modal_bottom_sheet.dart`,
  - preserved modal-owned state, picker flows, and history actions while shifting the time branch to a dedicated workspace boundary,
  - added direct widget coverage for the extracted time workspace and revalidated time, jet-lag, and activation-bundle modal-path regressions,
  - reduced `tool_modal_bottom_sheet.dart` further from ~4250 LOC to ~3793 LOC.
- Phase D completed on 2026-04-04:
  - introduced `tool_lookup_workspace.dart` as a dedicated lookup/reference composition module,
  - moved lookup result-card assembly and workspace composition around `ToolLookupSurface` out of `tool_modal_bottom_sheet.dart`,
  - preserved modal-owned picker flows, copy/session persistence, and selection-state mutations while reducing modal ownership of lookup-specific assembly,
  - added direct widget coverage for the extracted lookup workspace and revalidated clothing, cups/grams, and shoe-size modal-path regressions,
  - reduced `tool_modal_bottom_sheet.dart` further from ~3793 LOC to ~3778 LOC.
- Phase E completed on 2026-04-04:
  - introduced `tool_default_workspace.dart` as a dedicated generic-converter composition module,
  - moved the shared default converter shell and result/history workspace assembly out of `tool_modal_bottom_sheet.dart`,
  - preserved modal-owned conversion logic, clipboard/session side effects, and tool-specific extras while reducing modal ownership of the standard converter path,
  - added direct widget coverage for the extracted default workspace and revalidated standard-converter modal regressions,
  - reduced `tool_modal_bottom_sheet.dart` further from ~3778 LOC to ~3775 LOC.
- XL-Z4 closeout:
  - the remaining modal complexity is now primarily orchestration, picker flows, and tool state rather than large surface composition branches,
  - the next meaningful architectural move is state/controller decomposition rather than more view extraction,
  - recommended continuation is `XL-Z5`.

### XL-Z5 — Live Data Domain Split And Performance Instrumentation

- Status: `Complete (phase E complete 2026-04-04)`
- Priority: `P2`
- Size: `XL`
- Owner mix: `Shared` (`Frontend`, `Platform`, `QA`)
- Why fifth:
  - Current live-data orchestration is too coarse and under-instrumented, but this is safer after interaction and tool-surface contracts are cleaned up.
- Includes:
  - split `DashboardLiveDataController` by domain,
  - move refresh/seeding orchestration away from broad build-path triggers where practical,
  - add startup, tool-open, refresh-latency instrumentation,
  - evaluate lazy-loading or segmentation for the city dataset.
- Excludes:
  - backend/provider replacement unless required by instrumentation.
- Exit criteria:
  - weather/currency/air-quality domains are separable,
  - critical performance timings are measurable,
  - city data loading strategy is intentionally documented.
- Progress update (2026-04-04):
  - phase A is complete:
    - introduced `app/unitana/lib/features/dashboard/models/dashboard_currency_domain.dart` as the first extracted live-data domain seam,
    - moved currency backend state, rate cache hydration, TTL/backoff checks, refresh normalization, and fallback logic behind the new domain boundary,
    - preserved `DashboardLiveDataController`'s public currency-facing API through delegation,
    - added `app/unitana/test/dashboard_currency_persistence_hydration_test.dart`,
    - revalidated currency and live-data fallback regressions.
  - phase B is complete:
    - introduced `app/unitana/lib/features/dashboard/models/dashboard_env_domain.dart` as the second extracted live-data domain seam,
    - moved env snapshot storage, deterministic seeding, pollen bucketing, AQ refresh, and env-specific error tracking behind the new domain boundary,
    - preserved `DashboardLiveDataController`'s public env-facing API through delegation,
    - added focused AQ-failure regression coverage in `app/unitana/test/dashboard_live_data_refresh_fallback_test.dart`,
    - revalidated global-city coverage and weather-emergency taxonomy behavior.
  - phase C is complete:
    - removed dashboard-driven live-data side effects from `build()` in `app/unitana/lib/features/dashboard/dashboard_screen.dart`,
    - introduced an explicit post-frame maintenance scheduler for visible-place seeding and stale auto-refresh checks,
    - added test-only live-data injection to verify the orchestration contract directly,
    - added `app/unitana/test/dashboard_live_data_maintenance_contract_test.dart`,
    - revalidated dashboard smoke and developer-tools clock behavior.
  - phase D is complete:
    - added debug-only runtime timing instrumentation in `app/unitana/lib/common/debug/runtime_perf_trace.dart`,
    - instrumented city dataset load timing in `app/unitana/lib/data/city_repository.dart`,
    - instrumented dashboard startup, dashboard refresh, and tool-picker open timing in `app/unitana/lib/features/dashboard/dashboard_screen.dart`,
    - instrumented tool modal open timing in `app/unitana/lib/features/dashboard/widgets/tool_modal_bottom_sheet.dart`,
    - documented the city dataset loading decision in `docs/ai/reference/CITY_DATASET_LOADING_DECISION_2026-04-04.md`,
    - kept the current hybrid city-data loading strategy in place pending evidence from the new traces.
  - recommended next continuation:
    - phase E should decide whether the remaining weather-heavy path still merits a dedicated extraction or whether XL-Z5 can close with a lighter controller cleanup pass.
  - phase E is complete:
    - introduced `app/unitana/lib/features/dashboard/models/dashboard_weather_domain.dart` as the third dedicated live-data domain seam,
    - moved weather backend persistence, weather/sun/forecast storage, weather debug overrides, emergency assessment entrypoint, fallback seeding, and the weather refresh pipeline behind the new domain boundary,
    - preserved `DashboardLiveDataController`'s public weather-facing API through delegation,
    - added `app/unitana/test/dashboard_weather_persistence_hydration_test.dart`,
    - reduced `app/unitana/lib/features/dashboard/models/dashboard_live_data.dart` from ~2059 LOC to ~1494 LOC.
  - XL-Z5 closeout:
    - currency, env, and weather are now separable domains,
    - build-triggered dashboard live-data side effects were removed in phase C,
    - critical runtime timings are now measurable,
    - the city data loading strategy is explicitly documented,
    - recommended continuation is `XL-Z6`.

#### XL-Z5 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| Z5.1 | Split live data controller into weather/currency/air-quality domains | P2 | XL | Frontend | Completed in phase E with dedicated currency, env, and weather seams |
| Z5.2 | Remove or narrow build-triggered refresh/seeding side effects | P2 | M | Frontend | Completed in phase C via post-frame maintenance scheduling |
| Z5.3 | Add timing instrumentation for startup, tool open, refresh | P2 | M | Frontend/Platform | Completed in phase D; use new traces to decide next budgets |
| Z5.4 | Evaluate lazy-load strategy for city dataset and document decision | P2 | M | Frontend | Completed in phase D; keep hybrid load path until traces prove stronger action is worthwhile |

### XL-Z6 — Accessibility And Responsive Hardening

- Status: `In progress (phases A-B complete 2026-04-04)`
- Priority: `P2`
- Size: `L`
- Owner mix: `Shared` (`Design`, `Frontend`, `QA`)
- Why sixth:
  - Accessibility and responsive hardening should become a first-class quality track, not a cleanup afterthought.
- Includes:
  - alternate access path for long-press-only actions,
  - semantics review of dashboard and tool controls,
  - touch-target and chip-density review,
  - category differentiation beyond color alone,
  - small-phone/tablet visual regression expansion.
- Excludes:
  - a full design-system rewrite.
- Exit criteria:
  - key actions are not hidden behind gesture-only discovery,
  - semantics and focus order are materially improved,
  - responsive regressions have better visual coverage.

#### XL-Z6 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| Z6.1 | Add visible alternatives for long-press-only tile actions | P2 | M | Frontend/Design | Overflow/menu affordance or explicit handles |
| Z6.2 | Audit and improve semantics for high-value surfaces | P2 | M | Frontend | Dashboard, profiles, tool modal, pickers |
| Z6.3 | Add non-color category indicators and increase dense target resilience | P2 | M | Design/Frontend | Accessibility and trust |
| Z6.4 | Expand layout goldens/smoke coverage for small phone and tablet states | P2 | M | QA | Especially dashboard/profile/edit states |

#### XL-Z6 progress note

- Phase A completed on 2026-04-04:
  - added visible corner-action affordances for dashboard tiles outside edit mode,
  - added visible corner-action affordances for profile tiles outside edit mode,
  - kept the existing long-press quick-action contract while removing gesture-only discoverability as the sole path,
  - improved `UnitanaTile` semantics so screen readers receive richer label content,
  - added explicit profile tile semantics for label, hint, and selected state,
  - updated localized copy/seed coverage for the new affordances,
  - added focused regression tests for dashboard and profile visible action paths.
- Phase B completed on 2026-04-04:
  - added direct semantics-tree regression coverage in `app/unitana/test/dashboard_accessibility_semantics_test.dart`,
  - replaced brittle widget-level semantics inspection with resolved semantics-data assertions,
  - fixed a real small-phone overflow in `app/unitana/lib/features/dashboard/widgets/profiles_board_screen.dart` by compacting the active badge and visible corner-action button when the tile height is tight,
  - added responsive smoke coverage in `app/unitana/test/profiles_board_responsive_smoke_test.dart`,
  - captured the Tax/VAT trust follow-up as a dedicated backlog slice in `M-Z7`,
  - added a lightweight profile-rename quick action so users can rename from the profiles board without reopening the full wizard,
  - added focused regression coverage in `app/unitana/test/profile_feedback_toast_test.dart`.
- Recommended next continuation:
  - phase C: extend the semantics/focus-order audit into tool-modal and picker surfaces, add non-color category indicators, and keep widening small-device/tablet coverage where dense UI still concentrates risk.

- Overnight queued follow-up (2026-04-04, not completed yet):
  - finish dashboard/profile slot-preservation work so removing a tile or profile leaves an open slot at the original location instead of repacking immediately,
  - restore profile-tile long-press quick actions outside edit mode,
  - verify the new slot-preservation behavior with focused regression coverage before continuing broader XL-Z6 work.

### M-Z7 — Tax/VAT Rate Accuracy And Manual Rate Control

- Status: `In Progress (phase A done 2026-04-05)`
- Priority: `P1`
- Size: `M`
- Owner mix: `Shared` (`Product`, `Frontend`, `QA`)
- Why:
  - The current Tax/VAT helper still loses trust when country presets are incomplete, arbitrary, or wrong for obvious real-world cases.
- Additional user evidence captured 2026-04-04:
  - Portugal standard VAT (`23%`) was called out as an explicit example of the current trust gap.
- Direction refinement:
  - manual rate entry should become the primary interaction,
  - presets should become clearly-labeled suggestions only, or be replaced with curated/dated country defaults once backed by trustworthy source data.
- Delivered in phase A:
  - manual tax/VAT rate entry is now the primary visible control,
  - mode defaults now follow coarse regional context instead of always assuming add-on tax:
    - `US` / `CA` default add-on,
    - VAT-style contexts such as `PT` default inclusive,
  - suggestion chips now quick-fill the manual rate field instead of acting as the only rate-selection mechanism,
  - PT now seeds `23%` as the default rate and includes `23%` in the quick-fill row,
  - dashboard Tax / VAT tile preview now follows active reality/place currency and default tax-mode context instead of a static fallback,
  - focused regression coverage added/updated:
    - `app/unitana/test/tax_vat_helper_modal_interaction_test.dart`
    - `app/unitana/test/tool_helper_surfaces_test.dart`
    - `app/unitana/test/tool_helper_calculators_test.dart`
    - `app/unitana/test/dashboard_tax_vat_tile_reality_switch_test.dart`
  - verified via `./tools/verify.sh` on 2026-04-05 (`+289 ~6: All tests passed!`).
- Remaining for later phase B:
  - broaden and document any curated country-rate table beyond the currently seeded defaults,
  - add explicit provenance/version copy if we decide to support a wider maintained preset set.

### M-Z8 — Tip Helper Context And Preset Contract

- Status: `Done (2026-04-05)`
- Priority: `P1`
- Size: `S`
- Owner mix: `Frontend`, `QA`
- Why:
  - The Tip Helper currently has two trust/clarity issues:
    - preset policy should keep `18%` and `20%` alongside lower values for US usage,
    - the widget preview appears to stay pinned to USD / `$` regardless of the selected city/currency context.
- Includes:
  - preserve `18%` and `20%` in US-oriented preset sets while retaining lower-tip options,
  - audit widget preview state so the displayed currency symbol and labels follow the active pricing context,
  - confirm whether widget preview depends incorrectly on history/session state instead of live place context.
- Exit criteria:
  - US preset row includes `5%`, `10%`, `15%`, `18%`, and `20%`,
  - widget preview currency follows the active place/country context,
  - regression tests lock the preview contract down.
- Delivered:
  - introduced shared country-aware default tip selection so preset defaults and preview fallbacks stay aligned,
  - preserved the US/CA preset contract with `18%` and `20%` while keeping lower presets for PT/Europe contexts,
  - made the dashboard Tip Helper tile preview follow active reality/place currency instead of staying pinned to a static USD-flavored fallback,
  - added focused regressions:
    - `app/unitana/test/tip_helper_modal_interaction_test.dart`
    - `app/unitana/test/dashboard_tip_helper_tile_reality_switch_test.dart`
  - verified via `./tools/verify.sh` on 2026-04-05 (`+288 ~6: All tests passed!`).

### M-Z9 — Weather Precipitation And Alert Detail Visibility

- Status: `Done (2026-04-05)`
- Priority: `P1`
- Size: `M`
- Owner mix: `Frontend`, `Design`, `QA`
- Why:
  - Weather surfaces currently under-communicate two high-value signals:
    - precipitation probability,
    - alert meaning/actionability.
- Includes:
  - surface precipitation chance where relevant in the weather widget, hero, and detailed weather sheet,
  - make weather alerts inspectable with more detail instead of passive inline badges only,
  - add regression coverage for the new weather-detail affordances.
- Exit criteria:
  - precipitation probability appears when meaningful,
  - alert UI is visibly actionable and opens richer detail,
  - compact surfaces remain responsive and overflow-safe.
- Delivered:
  - added precipitation probability to WeatherAPI and Open-Meteo forecast adapters plus the dashboard forecast snapshot models,
  - weather widget tile preview now surfaces precipitation chance for the active reality when it is meaningful,
  - Places Hero condition chip now includes precipitation chance when relevant,
  - weather summary place cards now show precipitation chance inline when relevant,
  - weather summary alert banners now open a dedicated alert-details sheet instead of acting as passive warning strips,
  - hero alert states now deep-link into the same alert-details sheet for the active place,
  - focused regression coverage added:
    - `app/unitana/test/dashboard_weather_summary_tile_reality_switch_test.dart`
    - `app/unitana/test/weather_alert_details_sheet_test.dart`

### M-Z11 — Weather Provider Evaluation Harness

- Status: `Done (2026-04-05)`
- Priority: `P1`
- Size: `M`
- Owner mix: `Shared` (`Product`, `Frontend`, `QA`)
- Why:
  - We need evidence before deciding whether Open-Meteo is trustworthy enough for Unitana's current-conditions UX or whether MET Norway is materially better.
- Includes:
  - create a standalone research harness outside normal CI,
  - use a fixed curated city fixture instead of random cities so results are repeatable,
  - compare Open-Meteo and MET Norway against an observation proxy rather than only against each other,
  - output a readable report for provider-selection decisions.
- Exit criteria:
  - benchmark script exists and runs outside `verify.sh`,
  - curated city fixture is checked in,
  - scoring and caveats are documented,
  - a smoke run is completed successfully against a live city.
- Delivered:
  - added the benchmark city fixture:
    - `app/unitana/tool/fixtures/weather_benchmark_cities.json`
  - added the standalone benchmark script:
    - `app/unitana/tool/weather_provider_benchmark.dart`
  - added normalization/scoring coverage:
    - `app/unitana/test/weather_provider_benchmark_test.dart`
  - documented the harness and run instructions:
    - `docs/ai/reference/WEATHER_PROVIDER_BENCHMARK_HARNESS_2026-04-05.md`
  - completed a live Porto smoke run:
    - output written to `tmp/weather_provider_benchmark_porto.md` and `tmp/weather_provider_benchmark_porto.json`
    - in that smoke sample, `MET Norway` beat `Open-Meteo` against the airport observation proxy because Open-Meteo classified Porto as fog while the observation proxy was clear.
  - completed the first full 25-city benchmark report:
    - `docs/ai/reference/WEATHER_PROVIDER_BENCHMARK_2026-04-05.md`
    - `tmp/weather_provider_benchmark_2026-04-05.json`
    - observation coverage landed at `23` cities because Santiago and Dubai had no live METAR observation payload at run time,
    - across those `23` observed cities:
      - `Open-Meteo`: `13` wins, `0.763` average composite, `61%` exact bucket match,
      - `MET Norway`: `10` wins, `0.727` average composite, `52%` exact bucket match,
    - takeaway:
      - Open-Meteo is not obviously inferior overall in this first pass,
      - but the Porto fog mismatch remains a valid product-trust concern and shows why single-city spot checks can diverge from aggregate outcomes.
  - intended next use:
    - run the full curated 25-city benchmark before making a provider-selection decision.

### M-Z12 — Expanded Weather Benchmarking And Confidence Prior

- Status: `Done (phases A-E complete 2026-04-05)`
- Priority: `P1`
- Size: `M`
- Owner mix: `Shared` (`Product`, `Frontend`, `QA`)
- Why:
  - A fixed 25-city report is useful, but not enough to justify a provider decision or drive runtime confidence behavior.
- Delivered in phase A:
  - expanded the benchmark harness so it can sample from the full `cities_v1.json` dataset instead of only the fixed 25-city fixture,
  - added deterministic sample-size and sample-seed controls,
  - added automatic nearest-METAR-station lookup through AviationWeather `stationinfo`,
  - added station-cache support so broader runs are repeatable and faster,
  - added benchmark-derived provider priors to the markdown and JSON outputs,
  - completed a live `30`-city expanded-sample smoke run:
    - `tmp/weather_provider_benchmark_sample30.md`
    - `tmp/weather_provider_benchmark_sample30.json`
    - observation coverage: `17/30`
    - provider prior outcome:
      - `MET Norway`: `55.1%`
      - `Open-Meteo`: `44.9%`
  - added test coverage for:
    - dataset sampling,
    - nearest-station selection,
    - provider-prior normalization.
- Delivered in phase B:
  - completed and saved a broader `100`-city report:
    - `docs/ai/reference/WEATHER_PROVIDER_BENCHMARK_SAMPLE100_2026-04-05.md`
    - observation coverage: `39/100`
    - provider prior outcome:
      - `MET Norway`: `52.1%`
      - `Open-Meteo`: `47.9%`
  - added a pure runtime weather-confidence policy in app code:
    - `app/unitana/lib/features/dashboard/models/dashboard_weather_confidence.dart`
  - expanded live weather payloads to include confidence-supporting metadata:
    - cloud cover
    - visibility
  - dashboard weather tile, hero, and weather summary now use confidence-aware presentation:
    - strong labels like `Fog` are softened when confidence is weak,
    - visibility-led scenes are visually downshifted when confidence is not high.
  - added focused regression coverage:
    - `app/unitana/test/dashboard_weather_confidence_policy_test.dart`
    - `app/unitana/test/dashboard_weather_summary_tile_reality_switch_test.dart`
    - `app/unitana/test/dashboard_places_hero_v2_test.dart`
    - `app/unitana/test/weather_summary_tile_open_smoke_test.dart`
    - `app/unitana/test/weather_summary_narrow_layout_smoke_test.dart`
  - targeted verification passed on 2026-04-05:
    - `flutter analyze`
    - focused weather regression suite green
- Delivered in phase C:
  - completed and saved a broader `200`-city report:
    - `docs/ai/reference/WEATHER_PROVIDER_BENCHMARK_SAMPLE200_2026-04-05.md`
    - observation coverage: `97/200`
    - provider summary:
      - `Open-Meteo`: `55` wins, `0.713` avg composite, `37%` exact bucket match
      - `MET Norway`: `42` wins, `0.698` avg composite, `47%` exact bucket match
    - provider prior outcome:
      - `Open-Meteo`: `50.2%`
      - `MET Norway`: `49.8%`
  - decision from broader sample:
    - the aggregate result is still too close to justify a hard provider switch,
    - priors should remain near-neutral and the product should rely more on runtime confidence than aggressive provider favoritism.
- Delivered in phase D:
  - added a minimal live second-opinion path for risky current-condition labels using MET Norway:
    - `app/unitana/lib/data/met_norway_client.dart`
  - runtime weather confidence now incorporates second-provider disagreement for risky labels instead of relying only on priors + freshness + supporting fields,
  - second-opinion fetches stay bounded:
    - only risky labels/scenes trigger them,
    - non-risky weather does not turn into a full dual-provider architecture.
  - added focused disagreement regression coverage:
    - `app/unitana/test/dashboard_weather_confidence_policy_test.dart`
- Delivered in phase E:
  - weather detail UI now explains softened labels directly in the weather summary sheet instead of making low-confidence states feel opaque,
  - added copy-level explainability hints for:
    - provider disagreement,
    - generic low-confidence current conditions,
    - stale/model-driven very-low-confidence states,
  - rendered the hint inside:
    - `app/unitana/lib/features/dashboard/widgets/weather_summary_bottom_sheet.dart`
  - added focused regression coverage:
    - `app/unitana/test/dashboard_weather_confidence_policy_test.dart`
    - `app/unitana/test/weather_alert_details_sheet_test.dart`
  - decision after phase E:
    - keep the provider strategy stable for now,
    - treat regional override investigation as a separate follow-up only if benchmark outliers justify the added complexity.

### M-Z13 — Regional Weather Override Evaluation

- Status: `Deferred`
- Priority: `P2`
- Size: `S`
- Owner mix: `Shared` (`Product`, `Frontend`, `QA`)
- Why:
  - the broad benchmark does not justify a provider switch, but it does show enough concentrated fog-label trust risk to evaluate whether a global app should support any targeted regional candidates before ever adding runtime overrides.
- Entry criteria:
  - only start after `M-Z12` is complete and confidence/disagreement scoring is live.
- Current decision:
  - do **not** add any country-specific runtime override yet.
  - use `docs/ai/reference/WEATHER_REGIONAL_OVERRIDE_DECISION_2026-04-05.md` as the decision baseline.
- Planned deliverables:
  - a priority-region benchmark pack across roughly `top 30` countries or regions,
  - an inventory of stable official/open weather APIs for those regions where practical,
  - comparison of:
    - `Open-Meteo`,
    - `MET Norway`,
    - local/official providers when integration cost is reasonable,
    - observation proxies where available,
  - a go/no-go recommendation for whether any regional runtime override strategy is justified at all.
- Deferral note:
  - this slice is intentionally paused for now because the current global provider + disagreement/confidence path is considered good enough for the active product plan.

### M-Z10 — Weather Freshness Truthfulness

- Status: `Done (2026-04-05)`
- Priority: `P1`
- Size: `S`
- Owner mix: `Frontend`, `QA`
- Why:
  - shared live-data freshness was allowing successful currency refreshes to make failed/stale weather look freshly updated.
- Delivered:
  - weather now records its own successful refresh timestamp inside the weather domain,
  - dashboard refresh-status UI now uses weather-specific freshness when a weather backend is selected,
  - weather summary and devtools weather freshness lines now use weather-specific freshness instead of the shared live-data timestamp,
  - weather auto-refresh cadence now keys off the last successful weather refresh instead of shared freshness,
  - focused regressions added:
    - `app/unitana/test/dashboard_live_data_refresh_fallback_test.dart`
    - `app/unitana/test/data_refresh_status_label_weather_contract_test.dart`
  - targeted verification passed on 2026-04-05:
    - `flutter analyze`
    - focused weather freshness regression suite green

#### M-Z7 child backlog

| ID | Item | Priority | Size | Owner | Notes |
|---|---|---|---|---|---|
| Z7.1 | Add explicit manual tax/VAT rate input as a primary control | P1 | S | Frontend | Must work even when no preset is selected |
| Z7.2 | Build a curated dated country-rate table for supported presets | P1 | M | Product/Frontend | Example: Portugal VAT 23% in the documented 2026 reference set |
| Z7.3 | Show preset provenance/version copy in the Tax/VAT helper | P2 | S | Frontend/Design | Avoid false authority |
| Z7.4 | Add regression tests for preset application, manual override, and mode math | P1 | S | QA | Protect rate accuracy and override behavior |

## Recommended execution order

1. `XL-Z1` — restore trustworthy baseline and merge enforcement.
2. `XL-Z2` — standardize the interaction layer.
3. `XL-Z3` — improve product clarity and tool positioning.
4. `XL-Z4` — decompose the tool surface architecture.
5. `XL-Z5` — split live-data domains and instrument performance.
6. `XL-Z6` — harden accessibility and responsiveness.

## Suggested first three implementation plans

### First slice to start now: XL-Z1

- Write a short implementation note listing:
  - the currently failing tests,
  - the devtools-flag single-source-of-truth decision,
  - the multi-unit conversion contract for hydration/energy.
- Fix baseline red tests before layering new work.
- Land CI in the same slice so baseline stability becomes enforceable.

### Second slice: XL-Z2

- Start with contracts before widgets:
  - picker contract,
  - edit-session contract,
  - quick-action contract.
- Migrate one surface first:
  - currency picker for shared picker,
  - dashboard for edit-session semantics,
  - then profiles.

### Third slice: XL-Z3

- Keep this product-facing and deliberate:
  - name/category decision,
  - Tax/VAT mental model rewrite,
  - timezone converter role decision,
  - clothing UX restructure.
- Do not combine it with the tool-modal decomposition work.

## Not now

- New tool expansion.
- Wearables/platform expansion.
- Large aesthetic re-theme work.
- Feature-flag systems broader than what is needed for risky redesign slices.

## Definition of done for backlog slices

- Code shipped with tests appropriate to the change:
  - unit tests for conversions/state logic,
  - integration tests for flow semantics,
  - visual regression where layout/state presentation is core.
- Docs updated:
  - this backlog if sequencing changes materially,
  - `CURRENT_HANDOFF.md` with the latest executed slice.
- Verification note captured with exact commands run.
