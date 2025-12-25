# Unitana — MVP Truth

## Why Unitana exists
Moving between countries can feel like living with two operating systems in your head. You are trying to enjoy a place, not do math in the street.

Unitana is for people who *know* one system (often imperial) and *want* to learn the other (often metric), not because they love conversions, but because they want their brain to relax into the new normal.

This is not a calculator app. It is an orientation tool you actually want to open while traveling or relocating.

---

## Product in one sentence
A travel-first “decoder ring” dashboard that shows dual reality side-by-side and teaches intuition through daily exposure, without clutter.

---

## Core concepts (corrected)

### Place
A **Place** represents a single context:
- One city
- One time zone
- One unit system (metric or imperial)
- One clock preference (12h / 24h)
- One set of enabled tiles

A Place never contains both “home” and “destination” systems.

### Profile (MVP concept)
A **Profile** is a lightweight grouping concept that pairs:
- One **Home** Place (baseline)
- One **Destination** Place (learning context)

In MVP, the profile exists as a name plus two Places. It is not yet a first-class model.

### Place types (badges)
- Living
- Visiting
- Other

In first run:
- Home behaves like **Living**
- Destination behaves like **Visiting**

---

## North Star
Users stop translating and start recognizing.

---

## MVP scope (hard constraints)

### Places
- First run creates exactly **two Places**:
  - Home (Living)
  - Destination (Visiting)
- One default Place exists at all times.
- Typical user: up to 3 Places.
- Power user: up to 10 Places.

### Tiles (MVP)
- Temperature (dual)
- Wind (dual)
- Distance and speed
- Weight and groceries
- Cooking basics (cups ↔ grams only)
- Fitness basics
- Time zones (home/local)
- Currency quick view

### Widgets
- Display-only.
- Snapshot-based.
- Honest freshness cues.
- No implied real-time behavior.

---

## Trust rules (non-negotiable)
- Accuracy over novelty.
- Every network-backed value has:
  - a source
  - a timestamp
  - a staleness state
- Cached data is shown calmly and clearly.

---

## Accessibility (day one)
- Dynamic type without broken layouts.
- Large hit targets.
- Screen-reader labels for all meaningful controls.
- One-handed reach prioritized.

---

## Non-goals
- No cloud sync in MVP.
- No interactive widgets.
- No ingredient-aware cooking intelligence.
- No ads.

---

## Open questions (not blocking)
- Default tile sets per Place type.
- Currency enabled by default for Visiting (assumed yes).
- Weather provider selection.
