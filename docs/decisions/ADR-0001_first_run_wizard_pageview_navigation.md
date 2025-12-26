# ADR-0001: PageView-based first-run wizard navigation

Status: Accepted

## Context

Unitana’s onboarding is a multi-step flow. Earlier iterations had navigation and layout regressions caused by scattered state, missing private fields, and mixed responsibilities.

## Decision

Use a controlled `PageView` with a single `PageController`, and gate navigation using `_page` and `_maxVisited`.

## Consequences

Positive:
- A single source of truth for navigation.
- Easier to reason about which transitions are allowed.
- The review step can be a normal page without special routing.

Tradeoffs:
- Requires careful handling of scrollability on content-heavy steps.
- Encourages a large screen file unless components are extracted.

## Follow-ups

- Extract step widgets into separate files.
- Add a golden test suite for the wizard.
