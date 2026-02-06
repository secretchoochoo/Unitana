# CURRENT_HANDOFF (Unitana) - Wizard, Collapsing Header, Multi-Profile

## Snapshot
- **Date:** 2026-02-06
- **Status:** Repo is green (`dart format`, `flutter analyze`, `flutter test`) after Pack A (city data platform foundation) implementation.
- **Operating mode:** Codex is now the primary workflow; apply edits directly in-repo (do not require patch zip workflow unless explicitly requested).

## Latest changes (2026-02-05)
- **Pack A shipped:** canonical city data schema is now enforced for all in-scope cities.
- `assets/data/cities_v1.json` regenerated from GeoNames with required `lat/lon` coverage for all rows.
- Added canonical schema validators:
  - runtime/shared validator: `app/unitana/lib/data/city_schema_validator.dart`
  - script validator: `app/unitana/tools/validate_cities_v1.py`
  - test validator: `app/unitana/test/city_data_schema_validation_test.dart`
- Generator updated to emit coordinates and fail fast on malformed rows:
  - `app/unitana/tools/generate_cities_v1.py`
- Added lifecycle/ownership contract:
  - `docs/ai/design_lock/CITY_DATA_SCHEMA_CONTRACT.md`

## Latest changes (2026-02-06)
- Pack F contracted implementation sprint (phase 2) shipped:
  - tool registry now carries explicit architecture metadata per tool:
    - `surfaceType` (`dedicated`, `configurableTemplate`, `aliasPreset`, `deferred`)
    - `aliasTargetToolId` for alias/preconfiguration entries
    - `deferReason` for deferred tools
  - deferred backlog is now encoded in-code (not only docs) for:
    - `cups_grams_estimates`, `pace`, `hydration`, `energy`, `tip_helper`, `tax_vat_helper`, `unit_price_helper`, `clothing_sizes`
  - tool picker now differentiates deferred items with `Deferred` badge + rationale text instead of generic `Soon` for all disabled entries.
  - added regression guard `tool_registry_architecture_matrix_test.dart` to lock deferred IDs/reasons and critical alias targets.
  - added picker UX regression guard `toolpicker_deferred_badge_test.dart` to ensure deferred rows render `Deferred` + defer rationale and remain non-launchable.
- Pack C reliability visibility follow-up (2026-02-06):
  - Currency tool modal now surfaces stale/error status using live-data currency health signals:
    - stale/cached message
    - backoff vs retry-now messaging when last refresh failed
    - explicit `Retry rates` action when retry is available now
  - dashboard and board tool-launch paths now pass currency stale/retry/error metadata into the modal.
  - added regression guard `currency_tool_stale_status_banner_test.dart`.
- Pack F visual guardrails follow-up (2026-02-06):
  - added targeted opt-in golden contract suite for key tool/weather surfaces:
    - `tool_time_from_zone_tile.png` and `tool_time_to_zone_tile.png` (Time base zone selectors)
    - `tool_time_zone_converter_card.png` (Time Zone Converter interaction card)
    - `tool_modal_long_title_overflow.png` (tool title two-line ellipsis overflow contract)
    - `weather_summary_stale.png` and `weather_summary_live.png` (weather freshness/stale visual states)
  - new test suite: `app/unitana/test/goldens/tool_surface_contract_goldens_test.dart`.
  - golden catalog updated in `app/unitana/test/goldens/README.md`.
  - generated baseline assets under `app/unitana/test/goldens/goldens/` for the new suite.
  - added a test-only freshness hook (`debugSetLastRefreshedAt`) in `DashboardLiveDataController` so stale/live weather states can be captured deterministically in goldens without async timer flake.
- Pack F lookup UX follow-up (2026-02-06):
  - lookup-table tools now render a styled `Size Matrix` section (replacing plain `Nearby` list rows) with:
    - explicit column headers (`Size`, `From`, `To`)
    - selected-row highlight treatment using accent + Dracula contrast
    - centered selected row when neighboring rows exist (proximity framing)
    - tap-to-copy on value cells and tap-to-reselect on size labels
  - added regression coverage in `app/unitana/test/mattress_sizes_matrix_interaction_test.dart` (matrix rendering + reselection behavior).
  - added planning artifact `docs/ai/reference/DEFERRED_TOOLS_EXECUTION_MATRIX.md` to map each deferred tool to activation prerequisites, execution slices, and recommended ship order.
- Pack F activation bundle (phase 6):
  - activated `tip_helper` as an enabled dedicated tool surface (`surfaceType: dedicated`) with full picker + modal launch wiring.
  - implemented dedicated Tip Helper modal interaction contract:
    - locale-aware preset tip chips by country context
    - split controls
    - rounding mode controls (`none`, `nearest`, `up`, `down`)
    - results panel with tip/total/per-person and rounding adjustment lines
  - mapped `tip_helper` into `money_shopping` lens for canonical discoverability guarantees.
  - added regression coverage:
    - `tip_helper_modal_interaction_test.dart`
    - activation assertion in `toolpicker_activation_bundle_test.dart`
    - deferred/audit expectation updates in `tool_registry_architecture_matrix_test.dart`, `toolpicker_deferred_badge_test.dart`, and `tool_lens_map_test.dart` adjacency.
- Pack F contracted implementation sprint (phase 1) shipped:
  - Time-family split implemented in tool surfaces:
    - `Time` now remains the live home/destination clocks + delta workflow.
    - `timezone_lookup` picker alias now opens a distinct `Time Zone Converter` surface (`time_zone_converter` tool definition) with explicit local-time conversion + per-tool history.
    - swap behavior in converter rebases entered local time across source-zone changes (preserves instant intent instead of resetting input).
  - Time tool live-update behavior hardened:
    - time surfaces now tick on a minute timer so live clocks/delta stay current while open.
  - Weather clarity/refresh contract implemented:
    - weather sheet now shows freshness state (`Live updates enabled` vs `Data may be stale`) and a short manual/auto refresh policy line.
    - AQI labeling upgraded to value + health band (example: `72 (Moderate)`).
    - pollen labeling upgraded to explicit scale semantics (`x.x/5 (Band)`).
    - headers clarified to `AQI (US)` and `Pollen (0-5)`.
  - Tool visual/title real-estate policy implementation:
    - tool modal titles now allow two lines with ellipsis instead of single-line fade truncation.
  - Regression coverage added/updated:
    - `time_tool_modal_interaction_test.dart` now covers Time Zone Converter alias open + explicit conversion history behavior.
    - `toolpicker_activation_bundle_test.dart` now asserts timezone lookup opens `time_zone_converter`.
    - `weather_summary_tile_open_smoke_test.dart` now asserts freshness indicator and updated AQI/Pollen labels.
- Header controls follow-up:
  - removed `Edit Widgets` from the menu and moved edit entry to an inline `✏ Edit` action on the status row.
  - `Updated …` + refresh cluster is now visually centered to the same title axis with a small right optical nudge.
  - kept small-phone overflow safety via responsive scaling; devtools overflow regression remains green.
- Profiles board add-slot balancing:
  - add-profile placeholder tiles now render as an even, balanced count for the 2-column grid (no orphan final cell in common 2-profile state).
  - added regression coverage in `profile_switcher_switch_profile_flow_test.dart`.
- Pack C stale/retry/cache hardening:
  - `DashboardLiveDataController` now exposes explicit currency stale + retry semantics (`isCurrencyStale`, `shouldRetryCurrencyNow`, `lastCurrencyError`, `lastCurrencyErrorAt`).
  - currency retry backoff is now constructor-configurable for deterministic tests (default remains 2 minutes).
  - added `dashboard_currency_retry_cache_semantics_test.dart` for TTL/no-refetch, outage backoff suppression, and immediate retry behavior when configured.
- Pack B global coverage hardening:
  - added `dashboard_live_data_global_city_coverage_test.dart` with representative city set (Tokyo/Cairo/Sao Paulo/Sydney/Nairobi/Reykjavik) for live weather/sun/AQI/pollen success path coverage.
- Pack F activation bundle (phase 1):
  - activated `world_clock_delta` and `jet_lag_delta` entries in tool registry.
  - wired both entries to the existing mature Time modal flow as interim E2E activation.
  - added `toolpicker_activation_bundle_test.dart` to verify both entries open Time modal from picker search.
- Pack F activation bundle (phase 2):
  - activated `data_storage` entry end-to-end (tool registry + picker + modal + conversion engine).
  - added multi-unit data-storage conversion support (`B/KB/MB/GB/TB`) in tool modal + converter wiring.
  - expanded `toolpicker_activation_bundle_test.dart` to verify Data Storage opens and performs conversion.
- Pack F activation + lookup shell expansion (phase 3):
  - activated `paper_sizes`, `mattress_sizes`, `timezone_lookup`, and `oven_temperature` in registry/picker flow.
  - mapped `timezone_lookup` to the Time modal (timezone/delta migration path) and `oven_temperature` to Temperature.
  - added shared lookup-table modal shell for size/reference tools with:
    - from/to system selectors + swap
    - primary size/category selector
    - immediate mapped result card
    - nearby row context + optional approximation notes
    - one-tap `Reset Defaults` support
  - migrated `shoe_sizes` from numeric conversion form to the lookup-table shell.
  - shipped `paper_sizes` and `mattress_sizes` on the same lookup shell.
  - expanded activation tests in `toolpicker_activation_bundle_test.dart` for paper, mattress, timezone, and weather entry behavior.
- Weather tool baseline direction implemented:
  - selected utility-first baseline (existing read-only weather cockpit sheet) rather than generic converter treatment.
  - tools-menu launch path now routes `weather_summary` directly to `WeatherSummaryBottomSheet` (same behavior as weather tile tap).
  - added regression assertion that picker-launched weather opens the weather sheet and not a converter modal.
- Save/update feedback matrix closure (high-value):
  - profile deletion now emits `Profile deleted` success toast.
  - profile edit save now emits `Profile updated` success toast.
  - add-profile save now emits `Profile created` success toast.
  - first-run create path now seeds a pending success toast so dashboard can show `Profile created` after navigation.
  - added toast regression coverage in:
    - `profile_feedback_toast_test.dart`
    - `profile_delete_confirmation_consistency_test.dart`
    - `distance_tool_modal_interaction_test.dart` (`History cleared`)
- Edit-mode stability hardening:
  - fixed edit-mode anchor freeze race (`setState during build`) by deferring `_freezeVisibleAnchorsForEdit()` to post-frame in `dashboard_board.dart`.
  - validated with `dashboard_edit_drag_handle_hit_testing_test.dart` and full suite.
- Planning/sequence hardening follow-up:
  - added Pack D preflight restore/backup runbook: `docs/ai/reference/PACK_D_RESTORE_BACKUP_STRATEGY.md`.
  - added restore-point helper script: `tools/create_restore_point.sh` (captures base commit, status, diffs, tracked files, and worktree snapshot archive).
  - added Time-tool repurpose sequence doc: `docs/ai/reference/TIME_TOOL_REPURPOSE_PLAN.md` to move from `12h↔24h` conversion toward timezone/delta-first behavior.
- Weather tile readability follow-up:
  - Wind/Gust rows now render primary measure + smaller alternate-unit measure on the same line (example pattern: `10 km/h • 6.2 mph`).
  - updated row rendering in `places_hero_v2.dart` and revalidated wind contract/widget tests.
- Confirmation UX consistency follow-up:
  - profile deletion now uses the same destructive bottom-sheet confirmation pattern as dashboard widget deletion (no floating `AlertDialog` mismatch).
  - shared helper added at `app/unitana/lib/features/dashboard/widgets/destructive_confirmation_sheet.dart` to enforce consistency.
  - policy/safeguard documented in `docs/ai/reference/CONFIRMATION_DIALOG_POLICY.md`.
  - rollout extended to `Clear history` (tool modal) and `Reset Dashboard Defaults` so destructive confirmations now share one implementation path.
  - save/update feedback audit is now tracked in `docs/ai/reference/SAVE_UPDATE_FEEDBACK_MATRIX.md` with explicit current-state gaps.
- Edit-mode parity + hero typography follow-up:
  - profiles board now mirrors dashboard edit-mode jiggle behavior while preserving long-press drag reorder.
  - dashboard edit tiles move value content lower in edit mode for better spacing under drag/edit/delete icon row.
  - hero details pill typography was tuned down slightly for `Sunrise • Sunset` and `Wind • Gust`.
  - wind/gust value rows are now centered (title + values alignment parity).
  - profile drag interaction now mirrors dashboard behavior: drag handle is directly draggable (no long-press requirement on tile body).
  - profiles board edit mode now supports dropping onto empty `+` slots; dragged profile swaps with that empty slot so a `+` appears where the profile came from.
  - fixed profile-drag overlay layout crash by constraining drag feedback tile dimensions (prevents unbounded-height flex errors seen in error.log).
  - profiles board now enforces a minimum of 10 total grid cells (profiles + add slots), adding one extra 1x2 row of `+` tiles.
- Pack F table-tools UX direction lock:
  - added `docs/ai/reference/LOOKUP_TABLE_TOOLS_UX_PATTERN.md` as canonical guidance for lookup-table interactions (`paper_sizes`, `shoe_sizes`, `mattress_sizes`).
  - sequence set to ship paper sizes first on the lookup framework, then shoe sizes, then mattress sizes.
- Fixed pinned mini-hero reality toggle interaction handoff:
  - removed the visible-but-untappable dead zone during collapse transition
  - pinned mini layer now becomes interactive at the same threshold where expanded hero input is disabled
- Fixed mini-hero reality toggle consistency:
  - compact toggle order now matches main hero order (destination left, home right)
- Fixed pinned mini-hero reactivity:
  - pinned bar now listens to session/live-data changes so temperature/readout updates immediately when toggling realities
- Added regression guard:
  - `app/unitana/test/dashboard_pinned_reality_toggle_interaction_test.dart` verifies toggle order and pinned-toggle reality switching behavior.
- Fixed city label readability in wizard/place selection:
  - numeric GeoNames `admin1Code` values (example: `17`) are no longer shown in user-facing city labels
  - labels now prefer `admin1Name`; if only numeric admin code exists, label falls back to `City, CC`.
- Pack C mapping fidelity hardening:
  - added canonical `country -> currency` resolver sourced from the city dataset
  - wired resolver into hero currency, pinned mini-hero currency, dashboard currency tile previews, and currency tool defaults
  - unsupported non-EUR/USD live-rate pairs now render deterministic placeholders (`—`) instead of reusing EUR→USD rates incorrectly
  - added regression tests for dataset mapping coverage and non-EUR currency-direction behavior.
- Profile switcher UX polish:
  - removed redundant `Profiles` header label from the switcher sheet
  - edit-profile flow now supports cancel back to profile switcher
  - add-profile flow now supports cancel back to profile switcher and removes the draft profile
  - first-profile onboarding remains non-cancellable by contract
- Pack C global currency rates upgrade:
  - `DashboardLiveDataController` now resolves pair rates for all mapped currencies using EUR-base rates (live Frankfurter fetch when available) with deterministic fallback coverage
  - hero + mini hero + currency tool now display non-EUR/USD pairs (for example JPY) with real pair math instead of placeholder dashes
  - added tests for profile cancel flows, first-run cancel guard, global currency rate coverage, and Frankfurter latest-rates parsing.
- Pack B fallback hardening:
  - live refresh now enforces per-place fallback snapshots (weather/sun/env) when provider calls fail or coordinates are unavailable
  - this guarantees no blank critical hero states under outage/partial-failure paths
  - added deterministic failure-mode tests in `dashboard_live_data_refresh_fallback_test.dart` using controller test knobs.
- Pollen + currency readability follow-up:
  - fixed pollen null path: when air-quality provider returns AQI but no pollen grains, UI now keeps previous/seeded pollen index (no `--` regression)
  - hero + mini-hero currency line now scales base amount for tiny-per-unit pairs (e.g., `¥100≈$0.69` instead of `¥1≈$0.01`)
  - added weather mapping audit test coverage for Open-Meteo WMO codes and standardized label wording to `Mostly clear`.
- Currency tool input UX follow-up:
  - currency modal now pre-fills a scaled default suggested input based on active pair magnitude (same policy as hero/mini currency display)
  - tiny-per-unit directions (JPY-class) open with meaningful defaults (example `100`) instead of `1`
  - guarded by regression test in `dashboard_currency_global_mapping_test.dart`.
- Currency tool manual unit-pair follow-up:
  - currency modal now allows explicit manual `from` and `to` currency selection from the mapped global currency set
  - conversion records now persist optional `fromUnit` / `toUnit` metadata
  - dashboard currency tile applies latest history only when that history pair matches the active city-derived pair; otherwise it falls back to live preview for context fidelity.
- Weather-type audit follow-up:
  - Open-Meteo mapper test coverage now validates the full known WMO code set used by the backend contract (not only representative samples)
  - known codes must map to explicit labels (no generic fallback label for contracted codes).
- Tools audit checkpoint:
  - tool registry now has 7 deferred entries (coming-soon surfaces), so tools completion remains open under Pack F.
  - Deferred IDs: `cups_grams_estimates`, `pace`, `hydration`, `energy`, `tax_vat_helper`, `unit_price_helper`, `clothing_sizes`.
- Profile UX rework (phase 1):
  - replaced split menu actions (`Switch profile` + `Add profile`) with a single `Profiles` entry.
  - added a dedicated tiled `Profiles Board` screen with:
    - tap-to-switch profile
    - manage mode with per-profile edit/delete controls
    - add profile tile
    - drag reorder support (long-press drag target reordering) persisted via app-state profile order.
  - board supports editing any profile (not only active) by temporarily switching context for the wizard and restoring the prior active profile after edit flow.
  - delete guard remains: last remaining profile cannot be deleted.
  - updated profile flow tests to the new board-based entry path.
- Profile/currency UX parity follow-up:
  - profile board app bar now uses `Manage` -> edit-mode `X`/`✔` actions to align with tile-edit interaction patterns.
  - profile tiles now expose explicit drag/edit/delete affordances in edit mode and include additional add-profile `+` slots for denser grid parity with dashboard behavior.
  - dashboard header now exposes inline `✏ Edit` action; menu no longer includes `Edit Widgets`.
  - currency token formatting now isolates mixed-direction text runs and applies suffix placement for Arabic-script currencies to avoid bidi reorder defects (example IQD/AED family).
  - all required gates re-verified green after these updates (`dart format`, `flutter analyze`, `flutter test`).
- Startup/profile flow hardening follow-up:
  - fixed a restart defect where users could be forced back into the wizard when an incomplete draft profile was active.
  - app-state load now auto-recovers active profile to an existing setup-complete profile (living + visiting places) when available.
  - added startup regression tests to verify:
    - incomplete active profile + complete alternate profile boots to dashboard and re-persists active profile id.
    - no complete profiles still routes to first-run as expected.
  - profile persistence test updated to assert round-trip active-profile restore using setup-complete profiles.
- Dashboard/profile edit-surface alignment follow-up:
  - profile-board edit tiles now use a compact two-row header model (title row + centered icon row) to prevent crowding with long city names.
  - dashboard edit tiles now mirror the same centered icon-row affordance pattern (drag/edit/delete) for interaction parity.
  - dashboard edit mode no longer renders the `Edit mode` pill, reclaiming vertical space for cleaner icon/action separation.
  - dashboard edit value typography was reduced and shifted lower with added vertical breathing room to avoid icon/value overlap.
  - edit action affordances remain text-based (`Cancel` / `Done`) with compact sizing/spacing consistency across dashboard and profile board.
- Late pass follow-up (tools + design pivot):
  - `baking` is explicitly represented in tool taxonomy/picker flow (not only a default dashboard seed).
  - `oven_temperature` is now treated as a distinct tool identity and duplicate Temperature presentation was reduced pending broader taxonomy cleanup.
  - tool/lens naming policy now favors `&` over `and` for tighter labels.
  - Time tool generic convert/planner/history framing was removed in favor of a timezone-first interim baseline (`From/To`, swap, now, delta).
  - Weather sheet copy and clarity were improved: user-facing provider-agnostic copy removed and pollen labeling clarified as an explicit index scale.
  - Product direction is now explicitly design-first for the next context window: unify artistic/visual language before further heavy Time-tool expansion.
- Design-only decision matrix lock (2026-02-06):
  - tool architecture contract is now explicit: every tool must be classified as `Dedicated`, `Configurable template`, `Alias/preconfiguration`, or `Deferred`.
  - duplication policy is explicit: one canonical engine per domain; aliases are allowed only when context/defaults materially differ (example: `Oven Temperature` as a Temperature alias, not a separate conversion engine).
  - Time-family recommendation is locked to Option B:
    - `Time` = home/destination live clocks + offset delta (profile-context first).
    - `Time Zone Converter` = explicit arbitrary-zone conversions/planning.
    - `Time Zone Map` = deferred optional visualization (not required for Pack F residual).
  - Time IA contract:
    - defaults = profile home/destination zones.
    - swap = swaps zones and preserves entered local datetime values relative to selected zone.
    - 12h/24h = display preference only (Settings/Profile), not conversion mode.
    - history = only explicit user conversions/plans (no passive clock snapshots).
    - refresh = clocks tick every minute; offset/delta recompute on timezone/date changes.
  - visual-system contract for tool + marquee-adjacent surfaces is now locked:
    - shared typography hierarchy and title handling (full title in picker/menu, short alias on compact tiles, modal title max two lines then ellipsis).
    - one tokenized component shape/radius system (no ad hoc pills).
    - consistent spacing rhythm and icon weight/style.
    - maintain Dracula palette direction while unifying artwork/visual language.
  - Weather clarity contract:
    - AQI and pollen must use user semantics (value + band/scale), no provider/dev copy.
    - manual refresh stays exposed; auto-refresh follows live-data cadence.
    - stale indicator appears when data age exceeds freshness threshold.
  - regression guardrails plan:
    - add targeted opt-in golden/screenshot coverage for Time base surface, Time Zone Converter core state, weather freshness/stale states, and title overflow behavior.
    - keep goldens opt-in only (`UNITANA_GOLDENS=1`).

## Planning reset (Codex-era large packs)
Backlog has been reprioritized away from small, fragmented slices into larger execution packs:
1) **Pack A (P0): City data platform foundation**
- Canonical city schema + full coverage for geo/time/currency/defaults.
2) **Pack B (P0): Live weather/time/AQI/pollen end-to-end**
- Reliable live data for every in-scope city.
3) **Pack C (P0): Live currency conversion global coverage**
- City/country mapped currency with stable live conversion behavior.
4) **Pack D (P1): Full repository docs/text audit + consolidation**
- README/doc accuracy, Mermaid validity, and doc architecture cleanup.
5) **Pack E (P1): Marquee scene V2 facelift**
- Move current scenes to a readable 16-bit style with a consistent visual language.
6) **Pack F (P1): Tools surface completion**
- Resolve remaining “coming soon” surfaces and unit-matrix parity.
7) **Pack G (P2): Polish/compliance release readiness**
- About/licenses/accessibility/haptics/release checklist.
8) **Pack H (P1): Localization and language settings**
- Add app language selection in Settings plus i18n/l10n + locale-aware formatting coverage.
9) **Pack I (P2): In-app playful tutorial overlay (near-finalization)**
- Add a skippable overlay walkthrough once UI contracts stabilize (avoid high churn while core UX is still changing).
- Scope initial tutorial to: Home/Destination picker flow (wizard slide 2), Save Profile (slide 3), hero toggle pills (Sunrise/Sunset, Wind/Gust, Pollen/AQI), tools menu, add-widget flow, and settings entry.
- Visual direction: playful callouts/circles with Dracula palette accents; Cabin Sketch-style typography is an optional exploration track.
10) **Pack J (P1): Weather tool full redesign + positioning decision**
- Current Weather modal must not remain a generic converter-style form.
- Before implementation, run an explicit options pitch and choose direction: conversion utility vs richer weather cockpit with larger marquee + deeper API detail.
- Selected direction must align with Unitana travel intent and established Dracula visual language.
11) **Icebox:** Optional radio feature.

Current execution focus:
- **Now:** implement the locked design contracts in Pack F residual execution (tool taxonomy cleanup, Time-family split behavior, weather semantics/refresh clarity, visual tokenization, and targeted visual regression guards).
- **Next:** complete remaining tools activation/defer decisions under the new architecture matrix and close high-value interaction/test gaps.
- **Later:** Pack E production facelift and Pack H localization.

## What’s true right now (high signal)
### 1) Dashboard header is a continuous collapsing header (no pop-in)
- The dashboard uses a **pinned `SliverPersistentHeader`** that morphs from **PlacesHeroV2 (expanded)** into the **pinned mini-hero readout (collapsed)** continuously with scroll.
- The old threshold-based “insert mini hero” approach is not allowed to return (it caused visible scroll jumps).

### 2) Wizard is consolidated into 3 steps (and must stay visually stable)
1) **Welcome to Unitana**
2) **Pick Your Places** (home + destination pickers, unit system + clock format controls, mini-hero preview)
3) **Name and Confirm** (profile name, PlacesHeroV2 preview, CTA: **Create Profile**)

Key visual rules that have regressed multiple times:
- Titles use the same font family as the dashboard profile name (**Roboto Slab**).
- Slide 2 must fit on a single phone screen without scrolling; unit/clock pills must remain compact.
- Slide 3 must not show duplicate toggle rows (remove the extra “mini hero” toggle row; the hero preview already contains its own toggle).

### 3) Test stability doctrine is now enforced via key hygiene
- Canonical hero keys must be **unique in the widget tree at all times**.
- `PlacesHeroV2` gates canonical test keys behind **`includeTestKeys`**:
  - Dashboard surface sets `includeTestKeys: true` (tests rely on these).
  - Wizard previews and any other preview surfaces must set `includeTestKeys: false` to avoid duplicate finders.

### 4) Multi-profile support landed (P1)
- Added a **UnitanaProfile** model, persisted **profiles list** and **active profile id**.
- Added a **Profiles** bottom sheet for switching profiles; onboarding wizard can run in:
  - **create mode** (add a new profile)
  - **edit mode** (edit active profile)
- Persisted settings are now **namespaced per profile** (layout, anchors, hidden tools, env mode) with bootstrap/migration from legacy single-profile keys.

## Current build state
- **Expected:** green across `dart format`, `flutter analyze`, `flutter test`.
- **If you see red in Codex:** treat the provided `error.log` as authoritative; do not “clean up warnings” by changing behavior. Prefer minimal diffs that restore green.

## Where regressions keep coming from (read before touching code)
### A) Duplicate widget keys/finders during collapsing header transition
Root cause: both hero and mini layers can coexist during scroll; any reused canonical key becomes a duplicate finder failure.
Guardrails:
- Only the dashboard instance should emit canonical hero keys.
- Preview surfaces must set `includeTestKeys: false`.
- Compact/pinned layer must not reuse expanded-layer canonical keys.

### B) Pinned header occluding taps in widget tests
Some tests must scroll targets into view before tapping; otherwise taps land “off-screen” due to the pinned header.
Guardrails:
- Use `ensureVisibleAligned()` (or equivalent) before tapping tiles that can sit near the top edge.

### C) Wizard layout “fits on one screen” drift
Slide 2 in particular tends to regress (pills expanding, pushing content off-screen).
Guardrails:
- Keep unit/clock controls compact and explicitly wrapped to two lines (units first row, clock second row).
- Prefer smaller text + tighter padding on pills; avoid full-width segmented controls.

## Commands (local)
From `app/unitana`:
- `dart format .`
- `flutter analyze`
- `flutter test`

## Goldens workflow (gated)
- Golden tests are **gated** behind `UNITANA_GOLDENS=1` to keep CI green by default.
- Baselines live under: `app/unitana/test/goldens/goldens/`
- When intentionally changing visuals:
  1) Update the relevant design lock (at minimum: `HERO_MINI_HERO_CONTRACT.md`).
  2) Update tests/invariants if required.
  3) Regenerate baselines with: `UNITANA_GOLDENS=1 flutter test --update-goldens`

## Next slice targets (high-confidence backlog)
1) **Pack B:** harden weather/time/AQI/pollen end-to-end for representative global cities and provider failure modes.
2) **Pack C:** complete global currency conversion reliability (city/country mapping fidelity + cache/fallback tests).
3) **Pack F:** audit disabled tools for purpose/ROI (keep, merge, or remove) and activate the highest-value bundle.
4) **Pack D:** after B/C, run a full docs/text audit and consolidation pass.
5) **Pack H:** scaffold localization epic (language selector + ARB pipeline + locale formatting tests).

## Files you should treat as contracts (update them when behavior changes)
- `docs/ai/handoff/CURRENT_HANDOFF.md` (this file)
- `docs/ai/context_db.json` (patch log + decisions)
- `docs/ai/design_lock/HERO_MINI_HERO_CONTRACT.md`
- `docs/ai/design_lock/CITY_DATA_SCHEMA_CONTRACT.md`

## Codex handoff prompt (copy/paste)
Use the full high-context prompt in:
- `docs/ai/prompts/NEXT_CHAT_PROMPT.md`

That file is now the canonical copy/paste prompt for the next window.
