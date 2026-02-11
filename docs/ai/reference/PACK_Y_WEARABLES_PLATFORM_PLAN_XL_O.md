# Pack Y Wearables + Platform Add-ons Plan (XL-O)

## Scope
Planning-only artifact for post-core expansion into:
- Apple Watch
- Wear OS
- Android home-screen widgets

No runtime implementation is included in XL-O.

## In Scope
- Define minimum viable glance surfaces for each platform.
- Define shared sync/state contracts with mobile Unitana.
- Define rollout phases, risk matrix, and test strategy.
- Define release guardrails (battery/background/data freshness/privacy).

## Out Of Scope
- Shipping native watch apps in this slice.
- Shipping Android widgets in this slice.
- New backend services for watch/widget-specific storage.
- Deep health integrations (HealthKit/Google Fit) in initial launch.

## Platform MVP Proposals
### Apple Watch (watchOS)
- Complication-like glance: current city pair time delta (`Δ +7h`) and local times.
- Weather glance: condition + temp for active reality city.
- Quick swap action: Home/Destination reality toggle for glance data.

### Wear OS
- Tile: dual-city time + offset + quick refresh indicator.
- Tile: weather snapshot (temp/condition/alert severity chip).
- Optional action deep-link back into phone app for full tools.

### Android Home-screen Widgets
- `2x1`: Time delta + city pair labels.
- `4x2`: Time + weather + sunrise/sunset compact strip.
- Tap action launches dashboard preserving active reality context.

## Sync And State Contracts
- Mobile app remains source of truth for:
  - active profile id
  - home/destination city pair
  - reality mode (home/destination)
  - cached live data snapshots (time/weather/env)
- Wearables/widgets consume a read-only projection.
- Refresh contract:
  - use existing mobile cache freshness policy first
  - platform-triggered refresh is best-effort and rate-limited
- Degraded mode contract:
  - stale badge + last updated age
  - never blank primary glance slots

## Dependency And Risk Matrix
- Data freshness:
  - risk: stale snapshots under background limits
  - mitigation: stale-state semantics + deterministic fallback copy
- Battery:
  - risk: aggressive polling drains watch/phone
  - mitigation: bounded refresh windows and event-driven updates
- Background execution limits:
  - risk: OS throttling (watchOS/Wear OS/widget update cadence)
  - mitigation: design around bounded schedules + cached projections
- Connectivity:
  - risk: watch disconnected from phone
  - mitigation: local last-known snapshot with explicit stale status
- Surface density/readability:
  - risk: overloading tiny surfaces
  - mitigation: strict MVP copy budgets and one-action glance design

## Phased Rollout
1. Phase 0 (planning + contracts)
- lock schemas for projection payload and stale-state behavior.

2. Phase 1 (Android widgets first)
- ship `2x1` and `4x2` widgets with cache-driven data.

3. Phase 2 (Wear OS tile)
- ship time/weather tiles with deep links.

4. Phase 3 (Apple Watch)
- ship equivalent minimal glance set after Phase 2 telemetry.

5. Phase 4 (cross-platform polish)
- expand interactions only if reliability/battery SLOs hold.

## Test Strategy
- Contract tests:
  - projection payload schema (required fields + fallback behavior)
  - stale-state labeling consistency across surfaces
- Snapshot tests:
  - baseline glance rendering with compact/long city names
- Integration tests:
  - active profile/reality changes propagate to projections
- Performance budgets:
  - update latency budget from mobile state change -> projection availability
- Battery guardrails:
  - validate update cadence limits by platform policy

## Release Guardrails
- Block rollout if:
  - stale state appears without timestamp or badge
  - any glance surface renders blank primary values
  - refresh cadence exceeds defined battery budget thresholds
- Rollout gating:
  - internal -> beta -> staged public enablement per platform
