# XL Backlog Bundle Map (2026-02-11)

## Current
- XL-U shipped: Clothing Sizes Decision Pack (reference-only recommendation locked).
- XL-V (next): Clothing Sizes reference-only implementation spike.

## Remaining Core Tracks
- Release channel split and gating hardening:
  - verify `UNITANA_DEVTOOLS_ENABLED=false` as public default contract.
  - finalize public About/version surface.
  - stage branch/tag rehearsal for `release/public`.
- Weather runtime reliability and trust UX:
  - live-network defaults in runtime with test hermetic guard.
  - explicit freshness/advisory copy (weather + currency).
  - emergency simulation controls scoped to developer builds.
- Tool readability/performance pass:
  - matrix focused/all-systems model stabilization.
  - evaluate virtualization/pagination only where density still fails.
  - tighten tokenized search synonyms for unit-heavy tools.

## Proposed Follow-On XL Bundles
- XL-Q: Public Channel Lockdown
  - enforce devtools-off public profile, release flavor config, smoke tests.
- XL-R: Tool Surface Final Polish
  - matrix UX A/B closure, default-widget set decision, copy + hierarchy polish.
- XL-S: Weather & Alerts Confidence Pack
  - alert semantics QA, marquee scene legibility closure, stale/advisory standards.
- XL-T: Versioning + Release Ops
  - semantic/app versioning hooks, build metadata strategy, distribution checklist.
- XL-U: Clothing Sizes Decision Pack
  - keep/toss decision with user-value scoring.
  - if kept: region matrix scope (US/EU/UK/JP), category scope, and brand-policy strategy.
  - if tossed: migration path for existing references and replacement recommendations.
- XL-V: Clothing Sizes v1 implementation (reference-only)
  - enable `clothing_sizes` with scoped matrix categories/regions.
  - enforce uncertainty/disclaimer contract + deterministic missing mapping behavior.
  - add picker/modal/disclaimer regression coverage.

## Decision Gates
- Gate A: approve public default tile set.
- Gate B: approve advisory/disclaimer taxonomy per tool family.
- Gate C: approve commercial-safe lo-fi asset replacement before public launch.
