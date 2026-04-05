# Weather Provider Benchmark Harness (2026-04-05)

## Purpose

This harness exists to answer a product-quality question, not a unit-test question:

- Is Open-Meteo accurate enough for Unitana's real-world "current conditions" UX?
- Is MET Norway materially better for the same use case?
- Are provider disagreements rare edge cases, or common enough that we should change providers or soften the UI?

This is intentionally **not** part of normal `verify.sh` / CI. It is a research tool.

## What it measures

The harness compares:

- `Open-Meteo` current conditions
- `MET Norway` `Locationforecast` nearest timeseries point
- `METAR` airport observations used as an observation proxy

### Why METAR

METAR is not perfect city-center truth, but it is much closer to an observed reality signal than comparing one forecast API against another forecast API.

This means the benchmark is strongest for:

- temperature
- wind
- broad sky state
- obvious low-visibility / fog mismatches

It is weaker for:

- neighborhood-scale microclimate differences
- cities where the airport is meaningfully far from the city center
- non-airport-specific urban weather effects

## Selection Modes

### Curated fixture mode

The benchmark uses a fixed curated fixture when you want a stable, repeatable baseline:

- `app/unitana/tool/fixtures/weather_benchmark_cities.json`

The current fixture contains `25` globally distributed, airport-served cities.

### Expanded sample mode

The harness can also sample directly from the full city dataset:

- `app/unitana/assets/data/cities_v1.json`

In this mode it:

- samples cities deterministically from the full dataset
- resolves nearest METAR stations automatically through AviationWeather `stationinfo`
- caches station lookups for faster repeated runs

## Script

- `app/unitana/tool/weather_provider_benchmark.dart`

## How to run

From `app/unitana`:

```bash
dart run tool/weather_provider_benchmark.dart \
  --output ../docs/ai/reference/WEATHER_PROVIDER_BENCHMARK_2026-04-05.md \
  --json-output ../tmp/weather_provider_benchmark_2026-04-05.json
```

Useful focused runs:

```bash
dart run tool/weather_provider_benchmark.dart --city Porto
dart run tool/weather_provider_benchmark.dart --limit 5
dart run tool/weather_provider_benchmark.dart --at 2026-04-05T06:30:00Z
```

Expanded sample runs:

```bash
dart run tool/weather_provider_benchmark.dart \
  --sample-size 100 \
  --sample-seed 42 \
  --output ../docs/ai/reference/WEATHER_PROVIDER_BENCHMARK_SAMPLE100_2026-04-05.md \
  --json-output ../tmp/weather_provider_benchmark_sample100_2026-04-05.json
```

```bash
dart run tool/weather_provider_benchmark.dart \
  --sample-size 200 \
  --sample-seed 42 \
  --output ../docs/ai/reference/WEATHER_PROVIDER_BENCHMARK_SAMPLE200_2026-04-05.md \
  --json-output ../tmp/weather_provider_benchmark_sample200_2026-04-05.json
```

## Scoring model

Each provider is scored against the observation proxy using a weighted composite:

- temperature error
- wind-speed error
- cloud-cover error when available
- normalized condition-bucket similarity

Condition buckets are intentionally coarse:

- clear
- partly cloudy
- cloudy
- fog / low visibility
- rain
- snow
- storm

This is deliberate. It avoids giving fake precision to provider-specific label vocabularies.

## Provider priors

The harness now also emits **provider priors**.

These are benchmark-derived weights intended to influence a future runtime confidence model. They are useful when:

- two providers are both plausible,
- but one has been performing better across broader benchmark runs.

The prior is not meant to override obvious live disagreement or stale data.

## Decision guidance

Use this harness to answer questions like:

- Does Open-Meteo overcall fog or low-visibility conditions?
- Does MET Norway materially outperform Open-Meteo on the specific cities that matter most to Unitana users?
- Are provider disagreements small label differences, or do they translate into visibly wrong UI states?

## Current recommendation

Run this harness before making a provider swap. If Open-Meteo repeatedly loses on:

- exact bucket match,
- fog false positives,
- or overall composite score,

then the product should either:

- switch providers,
- use a hybrid provider strategy,
- or soften strong condition labels on live surfaces.

As of 2026-04-05:

- the curated 25-city run did **not** show Open-Meteo as clearly worse overall,
- but the first expanded-sample smoke run (`30` sampled cities, `17` observed) favored `MET Norway`,
- so the next responsible step is scaling to `100-200` cities before locking provider strategy.
