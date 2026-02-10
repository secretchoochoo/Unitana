# Tools Catalog Audit (2026-01-06)

> Status: Historical audit (archival).
> For current pack state and contracts, use `/Users/codypritchard/unitana/docs/ai/context_db.json`, `/Users/codypritchard/unitana/docs/ai/handoff/CURRENT_HANDOFF.md`, and `/Users/codypritchard/unitana/docs/ai/reference/REFERENCE_INDEX.md`.

## Purpose
Unitana is a travel-first decoder ring. Tools should reduce friction in real travel moments (and secondarily in adjacent daily life), while staying consistent with the Tool Modal interaction model (input, swap, convert, history; tap to copy, long-press to edit).

This audit provides:
- An inventory of tools currently listed in `ToolRegistry`.
- A keep/ship/later/reference/remove recommendation for each tool.
- A short list of next slices once the operator chooses what to ship.

## Hard constraints
- One toolId per tool; lenses are presentation only.
- Stable keys everywhere (persistence and tests).
- Repo stays green (`dart format .`, `flutter analyze`, `flutter test`).

## Naming policy
All tool titles must be Title Case. This slice enforces Title Case labels in `ToolRegistry` so the Tools menu and picker stay consistent.

## Evaluation rubric
A tool earns a place in the menu when it meets most of these:
1) Decoder-ring value: immediate usefulness in travel situations.
2) Global fit: does not assume US-only norms.
3) Low data burden: works offline or degrades gracefully.
4) Modal fit: can live inside the standard tool modal without becoming a mini-app.
5) Maintenance cost: unlikely to rot quickly.

## Inventory and recommendations

Legend:
- **Ship now**: Phase A completion target (core decoder ring primitives).
- **Ship later**: good fit, but not needed before Weather wiring.
- **Reference card**: static guidance or small lookup table; avoid heavy UX.
- **Remove**: does not fit product goals or duplicates another tool.

### Travel Essentials
| Tool | ToolId | Current state | Recommendation | Notes |
|---|---|---|---|---|
| Distance | `distance` | Shipped and enabled | **Ship now** | Core travel conversion primitive. |
| Speed | `speed` | Shipped and enabled | Ship later | Useful, but less frequent than distance/temp/currency. |
| Time Format | `time_format` | Listed, not wired | **Ship now** | 12h/24h is a core “dual reality” concept. |
| Jet Lag Delta | `jet_lag_delta` | Listed, not wired | Ship later | Depends on time data; keep simple (delta only). |
| Data Storage | `data_storage` | Listed, not wired | Ship later | Useful for roaming plans and file sizes; conversion only (MB/GB). |
| Temperature | `temperature` | Shipped and enabled | **Ship now** | Core travel primitive; ensure modal polish. |

### Food and Cooking
| Tool | ToolId | Current state | Recommendation | Notes |
|---|---|---|---|---|
| Liquid Volume | `liquid_volume` | Shipped and enabled | Ship later | Already useful, keep. |
| Weight | `weight` | Shipped and enabled | Ship later | Keep; overlaps with food and home. |
| Oven Temperature | `oven_temperature` | Listed, not wired | Reference card | Often just °C ↔ °F with context; can be a preset view of Temperature. |
| Cups ↔ Grams Estimates | `cups_grams_estimates` | Listed, not wired | Reference card | Risk of complexity; do not attempt ingredient density in MVP. |

### Health and Fitness
| Tool | ToolId | Current state | Recommendation | Notes |
|---|---|---|---|---|
| Body Weight | `body_weight` | Shipped and enabled | Ship later | Useful, but not travel-core. |
| Height | `height` | Shipped and enabled | Ship later | Useful for forms and sizing. |
| Pace | `pace` | Listed, not wired | Remove (for now) | A derived metric that can balloon in UX; revisit only if demand. |
| Hydration | `hydration` | Listed, not wired | Remove (for now) | Not a decoder ring conversion; becomes a tracker. |
| Calories / Energy | `energy` | Listed, not wired | Ship later | Keep only as calories ↔ kJ conversion, nothing more. |

### Home and DIY
| Tool | ToolId | Current state | Recommendation | Notes |
|---|---|---|---|---|
| Length | `length` | Listed, not wired | Ship later | Core conversion primitive, but less urgent than time/currency. |
| Area | `area` | Shipped and enabled | Ship later | Already present, keep. |
| Volume | `volume` | Listed, not wired | Ship later | Can share engine with liquids, but should remain one toolId. |
| Pressure | `pressure` | Listed, not wired | Ship later | Nice for tires, scuba, espresso; keep simple. |

### Weather and Time
| Tool | ToolId | Current state | Recommendation | Notes |
|---|---|---|---|---|
| Weather Summary | `weather_summary` | Listed, not wired | Ship later | Depends on provider wiring; keep in backlog. |
| World Clock Delta | `world_clock_delta` | Listed, not wired | Ship later | Should align with Places Hero time model. |

### Money and Shopping
| Tool | ToolId | Current state | Recommendation | Notes |
|---|---|---|---|---|
| Currency | `currency_convert` | Shipped and enabled | **Ship now** | Core; backend FX is an improvement, not a gate. |
| Tip Helper | `tip_helper` | Listed, not wired | Ship later | Calculator-first; guidance later (see below). |
| Sales Tax / VAT Helper | `tax_vat_helper` | Listed, not wired | Ship later | Must handle “VAT included” vs “add tax”. Keep toggles explicit. |
| Unit Price Helper | `unit_price_helper` | Listed, not wired | Ship later | Great travel shopping tool; keep simple. |

### Quick Tools and Odd but Useful
| Tool | ToolId | Current state | Recommendation | Notes |
|---|---|---|---|---|
| Shoe Sizes | `shoe_sizes` | Listed, not wired | Reference card | Lookup table by region; no API. |
| Clothing Sizes | `clothing_sizes` | Listed, not wired | Reference card | Lookup table; keep lightweight. |
| Paper Sizes | `paper_sizes` | Listed, not wired | Reference card | A-series vs Letter/Legal; static reference. |
| Time Zones Lookup | `timezone_lookup` | Listed, not wired | Ship later | Potentially redundant with World Clock Delta; keep only one “time zone lookup” surface. |

## Audit decisions
1) Keep the lenses. They are helpful as a mental model, but they must remain presentation-only.
2) Phase A “ship now” should stay narrow: Time Format plus modal polish on the existing primitives (Currency, Distance, Temperature).
3) Avoid tools that become trackers (Hydration) or require deep domain modeling (Cups ↔ Grams ingredient densities) in MVP.
4) Prefer “Reference card” implementations for size and paper lookups. They are valuable, but they should not pull the conversion modal into complexity.

## Appendix A: Currency rates strategy (spike summary)

### Do we need an API at all?
Not always. For a decoder ring experience, a manual “1 EUR ≈ 1.10 USD” style quick entry can carry a surprising amount of value. That said, a live reference rate unlocks:
- fast mental anchoring without hunting for a rate,
- consistent conversions across sessions,
- a clear “last updated” timestamp.

### Recommended approach
- Source: ECB reference rates (EUR base), pulled server-side once per day.
- Backend: cache the latest rate set and compute cross rates on demand.
- App: call a Unitana endpoint (`GET /fx/latest`) and show “Last updated” in the tool.

Rationale:
- No secrets in the mobile app.
- Centralized caching and fallback behavior.
- Provider independence: we can swap sources later without rewriting the client.

## Appendix B: Tip Helper scope (spike summary)

### What we should ship
Tip Helper should be a calculator first:
- bill amount
- tip percent (preset chips plus custom)
- split count
- “round up” toggle

This works offline, is globally useful, and does not require us to be “right” about etiquette.

### Cultural guidance (optional)
If we add etiquette guidance, treat it as reference text that is:
- clearly marked as general guidance,
- conservative,
- easy to update via a small local dataset.

Do not block the calculator on etiquette content. Avoid a heavy country-by-country rule engine in MVP.

### Where it belongs
`Money and Shopping > Tip Helper` is a valid placement. It should not be merged into Currency.
