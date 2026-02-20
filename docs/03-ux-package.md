# Unitana — UX Package (Current Runtime Contracts)

Updated: 2026-02-19

## Metadata
- Owner: Design + Engineering
- Source of truth: Runtime UX contracts in dashboard/tool/wizard surfaces under `app/unitana/lib/features/`
- Last validated against code: 2026-02-19

## 1) UX principles

- Dual-reality first: home and destination context should be visible and understandable at a glance.
- Useful before perfect: show best available data with explicit freshness state.
- Deterministic interactions: same action pattern across similar tool surfaces.
- Compact readability: prioritize legibility on small phones before adding density.

## 2) Shared surface rules

### Typography hierarchy
- Tile/tool title: concise and stable.
- Primary value: highest visual priority.
- Secondary value: comparison/reference line.
- Status/help copy: de-emphasized but readable.

### Freshness/state language
- Use explicit freshness language (`updated`, `stale`, `cached`) where data is network-backed.
- Avoid alarmist wording when stale fallback still has usable last-known values.

### Accessibility baseline
- Controls remain tappable at phone scale.
- Avoid color-only signaling.
- Keep semantic labels for key status/actions in testable widgets.

## 3) Dashboard UX contract

- Hero anchors the context and reality toggle.
- Grid tiles are scannable and editable.
- Pull-to-refresh is available and should not block core interaction.
- Tools/menu controls remain discoverable and stable.

## 4) Tool UX taxonomy

### A) Converter tools
Examples: temperature, distance, weight, area, volume, pressure, currency.

Contract:
- Input -> run -> result flow.
- Swap and unit selectors are explicit where supported.
- History supports quick reuse/copy patterns.

### B) Matrix/lookup tools
Examples: shoes, paper sizes, mattress sizes, clothing sizes, cups↔grams estimates.

Contract:
- Table-first interaction, not forced generic conversion UX.
- Cell tap copies value.
- Row tap/focus updates selected reference.
- Columns can paginate/swipe to avoid unreadable horizontal cram.
- Missing mapping is explicit (`—`).
- Reference-only tools include uncertainty/disclaimer copy where needed.

### C) Dedicated tools
Examples: weather summary, world time map, jet lag, tip helper, tax/vat helper, hydration.

Contract:
- Purpose-built cards and controls per domain.
- Keep framing consistent with modal shell while allowing domain-specific layout.

## 5) Settings and profile UX contract

- Single unified menu surface for operational actions and settings.
- Profile creation/editing should feel continuous from wizard to dashboard.
- Theme and audio controls support immediate preview feedback where available.

## 6) Copy and naming contract

- Use short tile names when needed for readability.
- Keep full names in picker/menu where space allows.
- Avoid internal jargon in user-facing labels.
- Prefer explicit reference language for approximate tables.

## 7) Current high-risk UX debt (to be addressed in hardening phases)

- Very large modal/dashboard files can accumulate interaction drift.
- Matrix readability and pagination consistency must remain locked across tool additions.
- Freshness messaging consistency across hero/tile/modal surfaces requires periodic audits.

## 8) Hardening direction

Hardening phases should prioritize:
- decomposition of hotspot files,
- comment hygiene (remove stale notes, keep contract comments only),
- performance checks on frequent rebuild surfaces,
- deterministic regression coverage for high-churn UI contracts.
