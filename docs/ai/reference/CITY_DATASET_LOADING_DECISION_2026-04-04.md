# City Dataset Loading Decision (2026-04-04)

## Decision

Keep the current hybrid loading strategy for the city dataset.

- Do not move to unconditional global startup eager-loading.
- Do not segment or shard the city dataset yet.
- Continue warming the singleton opportunistically in setup flows that benefit from it.
- Continue allowing on-demand `CityRepository.load()` from runtime surfaces that need the data.

## Why

The city dataset remains the clearest payload hotspot in the app, but we still do not have evidence that a more complex loading scheme would produce a better user outcome than the current approach.

What is true today:

- The dataset is substantial enough to deserve explicit measurement.
- The app already avoids unconditional app-wide eager-loading.
- First-run and profile-oriented flows can warm the repository in the background before the user reaches picker-heavy surfaces.
- The repository is singleton-backed and caches the parsed data after the first load, so repeated access is already cheap in-process.
- Existing city-picker performance coverage remains strong enough that we should instrument first, then optimize with evidence.

## What changed in XL-Z5 phase D

We added lightweight debug-only runtime traces so we can observe:

- `city_repository.load`
- `dashboard.startup`
- `dashboard.refresh`
- `dashboard.tool_picker.open`
- `tool_modal.open`

These traces are behind the debug-only environment flag:

- `UNITANA_RUNTIME_PERF_TRACE=1`

This is intentionally separate from `UNITANA_PICKER_PERF_TRACE` so we can measure broader runtime behavior without conflating it with picker-specific ranking/search traces.

## Why not lazy-load harder right now

Stronger lazy-loading or segmentation would add complexity across:

- picker readiness paths,
- background warming behavior,
- tests that currently assume a unified repository contract,
- possible user-visible first-open delays if warming misses.

That complexity is only justified if traces show one of the following:

- startup cost is meaningfully degraded by current warm-up behavior,
- picker open time is dominated by first-load parsing,
- memory pressure or repeated reload patterns emerge,
- the current single-asset approach becomes a release-size or device-class problem.

## Revisit triggers

Re-open this decision if any of the following becomes true:

- debug traces show city loading materially delaying startup or first picker open,
- additional large reference datasets are added,
- mobile install size becomes a release constraint,
- low-memory device testing shows avoidable churn,
- city-picker performance budgets begin to regress.

## Current recommendation

Measure first. Keep the repository contract stable for now. Only introduce segmentation or more aggressive lazy-loading if the new runtime traces show a concrete payoff.
