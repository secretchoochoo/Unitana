# Weather Regional Override Decision

- Date: `2026-04-05`
- Scope: decide whether Unitana should add any region-specific live weather overrides, and what evidence threshold a global app should require before doing so.

## Decision

Do **not** add any country-specific runtime override yet.

Instead:
- keep the current global-provider strategy,
- keep the new confidence/disagreement layer active,
- treat any broader regional-provider evaluation as optional future research, not an active delivery slice.

## Why

The broader benchmark evidence is not strong enough to justify a hard runtime fork by country.

From the saved `200`-city report:
- observation coverage: `97/200`
- `Open-Meteo`: `55` wins, `0.713` avg composite
- `MET Norway`: `42` wins, `0.698` avg composite
- provider priors remain effectively neutral:
  - `Open-Meteo`: `50.2%`
  - `MET Norway`: `49.8%`

That means the product problem is **not** “Open-Meteo is globally broken.” The problem is more specific:
- Open-Meteo has more **fog false positives** than MET Norway:
  - `Open-Meteo`: `8`
  - `MET Norway`: `4`
- some of those false positives are trust-damaging because they create strong, visible labels like `Fog`.

## What the current evidence does and does not justify

The current evidence is enough to justify deeper regional evaluation, but not enough to justify shipping country-by-country runtime branching.

Signals we have:
- live Porto spot check on `2026-04-05`:
  - Open-Meteo returned `Fog`
  - MET Norway did not agree
- `200`-city expanded sample included two Portugal entries:
  - `Ponte de Lima`:
    - observation: `partlyCloudy`
    - Open-Meteo: `fog`
    - MET Norway: `clear`
    - winner: `MET Norway`
  - `Campo De Ourique`:
    - observation: `clear`
    - Open-Meteo: `partlyCloudy`
    - MET Norway: `partlyCloudy`
    - winner: `MET Norway`

This is enough to say:
- Portugal is **not random noise**
- but it is **not enough sample depth** to justify introducing an IPMA override path in production yet
- and, more importantly, Unitana is a **global app**, so a Portugal-first production fork would be too narrow without a broader regional strategy

## Product recommendation

Near term:
- keep Open-Meteo as the primary runtime provider
- keep MET Norway as the bounded second-opinion path for risky labels
- keep the quieter confidence presentation without extra disclaimer copy in the weather detail surface

Optional future research:
- run a **priority-region evaluation pack** instead of jumping straight to an override
- target roughly `top 30` countries or regions by product relevance and geographic diversity
- for each region, evaluate:
  - global providers already in use:
    - Open-Meteo
    - MET Norway
  - a local or official provider **only if** a stable open API exists and the integration cost is reasonable
  - observation proxies where available
- treat this as a matrix for **research**, not an immediate runtime architecture

## Override threshold

Only add a region-specific runtime override if the narrower benchmark shows all of the following:
- a repeated, material accuracy advantage for the regional source
- a mismatch concentrated enough to be meaningfully regional rather than scattered globally
- enough API consistency and operational simplicity that the override does not become a maintenance burden
- enough evidence across multiple priority regions that the overall approach scales beyond one country anecdote

## Final take

Regional official-provider evaluation is a **possible future research path**, not part of the active product plan right now.

The current weather-trust stack is the right one for now:
- global provider,
- bounded risky-label second opinion,
- confidence softening,
- explicit explainability in the weather details UI.

## Practical stance on local providers

Local/offical APIs are worth exploring selectively, but a true “one provider per country” runtime matrix would add too much complexity too early.

The right sequence is:
- benchmark first,
- identify persistent regional outliers,
- inventory official/open APIs for those regions,
- only then decide whether any runtime override is worth shipping.
