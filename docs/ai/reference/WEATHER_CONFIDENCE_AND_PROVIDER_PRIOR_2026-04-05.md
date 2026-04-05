# Weather Confidence And Provider Prior (2026-04-05)

## Purpose

This document defines the product direction for turning weather-provider benchmark results into a runtime confidence model.

The key principle is:

- benchmark results create a **provider prior**
- live conditions create a **runtime confidence score**
- the runtime score decides whether the UI should present a condition label strongly, softly, or cautiously

The prior should inform the confidence model, not replace it.

## Why a provider prior exists

A single city can be misleading.

Example:

- Porto showed a strong Open-Meteo fog mismatch versus observation
- the first 25-city benchmark did **not** show Open-Meteo as clearly worse overall
- the first 30-city expanded sample favored `MET Norway`

This means provider trust should be:

- evidence-based
- re-runnable
- able to drift over time as benchmark coverage changes

## Runtime confidence model

The intended runtime score should combine:

1. **Provider prior**
   - benchmark-derived weight from broader evaluation runs
2. **Freshness**
   - age of current weather payload
3. **Condition severity**
   - stronger labels like fog/storm should require more confidence than cloudy/fair
4. **Supporting signals**
   - visibility, cloud cover, precipitation, wind, alert presence
5. **Disagreement signals**
   - if multiple providers or benchmark-informed heuristics disagree, confidence drops

## Suggested interpretation bands

- `0.80 - 1.00`: high confidence
- `0.60 - 0.79`: medium confidence
- `0.40 - 0.59`: low confidence
- `< 0.40`: very low confidence

## Suggested UI policy

- High confidence:
  - show the direct label, e.g. `Fog`
- Medium confidence:
  - show the label with restrained presentation, e.g. `Fog likely`
- Low confidence:
  - soften to a broader statement, e.g. `Low visibility risk`
- Very low confidence:
  - avoid strong condition claims and prefer `Current conditions uncertain`

## Current benchmark-driven priors

These should come from the latest benchmark report, not from hard-coded product assumptions.

As of the first expanded-sample smoke run on 2026-04-05:

- `MET Norway`: `55.1%`
- `Open-Meteo`: `44.9%`

These are not final product constants. They are a research output and should be regenerated as the benchmark sample grows.

## Product rule

If a broader benchmark continues to favor one provider, that provider should receive a higher prior weight.

But if live signals are weak, stale, or internally contradictory, even a favored provider should still produce a low-confidence UI state.

## Next step

The next implementation step should be:

- add a pure runtime confidence policy in app code,
- feed benchmark priors into that policy through a stable config input,
- and soften strong labels like `Fog` when runtime confidence falls below threshold.
