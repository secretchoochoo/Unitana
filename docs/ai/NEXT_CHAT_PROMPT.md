# Unitana Next Chat Prompt (Slice 13b, Places Hero reboot)

You are entering an ongoing product development effort for a mobile application named Unitana.

## Executive context

Unitana is a travel-first “decoder ring” that helps users live in two measurement systems at once (F/C, miles/km, 12/24h, home/local time, currency) so users learn through repeated exposure. The dashboard must continuously reinforce dual reality, not hide it behind secondary screens.

## Current baseline reality

You are working from a restored, known-good baseline where:

- The app boots on iOS
- The first-run wizard is stable
- `flutter analyze` and `flutter test` are green
- The dashboard still uses the older Destination/Home card layout

A prior attempt to implement the new Places Hero widget broke compilation and tests due to widget API drift and missing or invented types. This chat must re-implement the Places Hero experience safely and incrementally.

## Required operating mode (team roles)

Respond as a coordinated team with distinct roles, each providing concise input and staying in their lane:

- Product & Strategy Lead
- UI / UX Lead
- Mobile Engineering Lead (Flutter)
- QA & Release Lead
- Senior Technical Writer
- AI Workflow / Prompt Engineer

## Working rules

- No large refactors without an explicit plan first.
- Prefer minimal, reversible changes.
- Keep analysis green frequently. Stop when `flutter analyze` is red.
- Update or refactor existing widget/regression tests so coverage stays passing.
- Ensure head-to-toe Dracula theme consistency (colors, typography hierarchy, contrast): https://draculatheme.com/spec

## Delivery format

Provide downloadable patch zips containing full revised files plus a list of added/removed files (do not use inline EOF file dumps).

## Slice goal

Implement the redesigned Dashboard “Places Hero” experience shown in the aspirational mock, while preserving stability.

### A) One top-level reality toggle that controls the page

Replace the old “Destination/Home” conceptual split with a single, full-width Places Hero widget that contains a segmented control:

- Left segment: 🇵🇹 Lisbon (Destination, local reality)
- Right segment: 🇺🇸 Denver (Home reality)

The toggle must switch which reality is primary across the page:

- When Lisbon is selected: Lisbon values are primary (bigger, higher contrast, left-dominant). Denver remains present but secondary (smaller, muted, right side).
- When Denver is selected: Denver becomes primary (bigger, higher contrast, left-dominant). Lisbon becomes secondary.

Toggle UI requirements:

- The mock accidentally shows two dots on the Denver side. This must not appear.
- Denver label text should be right-aligned within the segmented control (readable, not clipped).
- The segmented control must be the single source of truth for the page’s “primary place.”

### B) Refresh button

Top-left of the dashboard is a circular refresh icon button.

- Tapping refresh triggers refresh for all live data on the page, including at least:
  - Weather (current conditions)
  - Currency exchange rates
  - Any other network-backed values used by the hero
- Implement as an explicit refresh action (not only pull-to-refresh).
- Provide subtle loading and error states without layout jumps.

### C) Places Hero widget content

Hero shows, at minimum:

Primary (selected place)

- Local time with meridiem and timezone acronym (DST-aware)
  - Example: 9:13 AM WEST (Lisbon)
- Large temperature for the selected place
  - Example: 20°C
- Wind and gusts in the selected system
  - Example: 7 km/h Gusts 11 km/h
- Currency conversion (EUR/USD example)
  - €10 ≈ $11
  - 1 EUR ≈ 1.10 USD

Secondary (non-selected place)

- Secondary time on the right, smaller and muted, with delta
  - Example: 2:13 AM MDT +7h
- Secondary temperature aligned on the right (muted)
  - Example: 68°F
- Do not label secondary temps with “Home:” or similar; placement and styling must carry meaning.

Weather icon placement

- Solid Dracula-friendly surface (no star field)
- Partly-cloudy sun icon inside the hero
- Slightly larger than current
- Pulled left from the extreme right edge so it feels intentional

### D) Tool tiles and shared modal

The 2x2 grid below the hero remains but must be modular and scalable.

- Tapping any tool tile opens a shared bottom-sheet modal template:
  - Top half: calculator input UI (enter value, choose units, swap direction)
  - Bottom third: conversion history (last 10)
  - Most recent item: larger and bold
  - Tap history row: reload into calculator

History should persist at least for the session; persist across restarts if storage patterns already exist.

## Engineering constraints

- Establish a single state source for selected place that drives hero and tiles.
- Refresh action must be debounced and safe (avoid overlapping calls; handle partial failures).
- Keep changes incremental and reversible.

## Tests

Update existing widget/regression tests to match the new dashboard layout.

Add focused widget tests for:

- Toggle switching primary/secondary (Lisbon ↔ Denver)
- Refresh button triggers refresh flows
- Modal opens from each tile and renders history list
- Most-recent styling and tap-to-reload behavior

## Delivery checklist

Before you edit:

- Provide a short plan.

When you deliver:

- Patch zip with full revised files
- List of added/removed files
- Exact verification commands:

```bash
flutter analyze
flutter test
```

Call out any follow-up tasks intentionally not implemented.
