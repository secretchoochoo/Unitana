# Unitana — MVP Truth

## Why Unitana exists
Moving between countries can feel like living with two operating systems in your head. You are trying to enjoy a place, not do math in the street.

Unitana is for people who *know* one system (often imperial) and *want* to learn the other (often metric), not because they love conversions, but because they want their brain to relax into the new normal.

This is not a “calculator app.” It is an orientation tool you actually want to open while traveling or relocating, the way you check the weather before you step outside.

---

## Product in one sentence
A travel-first “decoder ring” dashboard that shows dual reality side-by-side (home vs local, imperial vs metric) and teaches intuition through daily exposure, without clutter.

---

## Who it’s for
- Travelers who want to feel oriented quickly (weather, money, time, distance) without digging through multiple apps.
- New expats and relocators who are tired of mentally translating everything.
- Curious learners who want metric (or imperial) to become automatic through repetition and context.

---

## The user promise
- **Calm at-a-glance clarity**  
  Key numbers live in one quiet screen, designed for fast glances and one-handed use.

- **Learning without lecturing**  
  The app helps you build intuition (what 28°C *feels like*, what 100 km/h *means*) through gentle, culturally aware hints. It never pretends to be an authority, and it never gives medical or legal guidance.

- **Works when you’re offline**  
  Unitana should not collapse on airplane mode. Conversions and time zones still work; cached data stays visible with honest freshness states.

- **Widgets you can trust**  
  Widgets are built for reality: refresh unpredictability, throttling, and background limits. Freshness cues are accurate and never imply real-time updates.

---

## North Star
Users stop *translating* and start *recognizing*. They can estimate comfortably without opening a converter.

---

## MVP core loop
1. User opens the dashboard (or glances at widgets).
2. Sees home vs local context plus dual units instantly.
3. Learning aids quietly reinforce intuition in the moment.
4. Caches refresh when possible; stale states are clear, calm, and honest.

---

## What we will be best at
- **Orientation over utility sprawl**  
  A focused dashboard that reduces decision fatigue, not a kitchen-sink toolbox.

- **Speed and simplicity**  
  Minimal taps to value. Complexity stays behind intentional actions.

- **Offline-first trust**  
  The app remains useful without network and never hides staleness.

- **Home-screen habit**  
  Widgets and a calm dashboard make Unitana something you return to naturally.

---

## MVP scope (hard constraints)

### Places
- First run requires exactly **one default Place**.
- A Place = home system + destination system + enabled tile groups + time zones.
- Typical user: up to 3 Places. Power user: up to 10.
- Place types/badges (MVP): **Living**, **Visiting**, **Other**.
- One default Place with fast switching.

### Tiles (MVP)
- Temperature (dual), optional “feels like”
- Wind speed (dual)
- Distance and speed (dual)
- Weight and cooking basics (cups/grams only, no ingredient intelligence)
- Fitness basics (kg/lb, km/mi pace)
- Time zones (home/local, DST-aware)
- Currency quick view with “mental math” helpers

### Learning aids
- Default mode: **Human**
- Optional setting: **Neutral**
- Optional “Both” only if it can be shown without clutter.

### Widgets (MVP)
- Display-only.
- Must tolerate refresh unpredictability.
- Freshness cues must be accurate.
  - iOS: avoid heavy-handed “Last updated” banners; prefer subtle timestamps or implicit freshness indicators when possible.
  - Android: assume periodic refresh delays can occur and design for it.

### Monetization
- Free download with subscription and free trial using platform mechanisms.
- Messaging must not overpromise trial eligibility.
- No trust-breaking patterns (surprise gates, aggressive blocking, bait-and-switch).

---

## Non-goals (explicit)
- No cloud sync in MVP (local-only), but architecture must allow it later.
- No interactive widgets in MVP.
- No ingredient-aware cooking intelligence.
- No ad SDK in MVP.

---

## Trust rules (non-negotiable)
- Accuracy matters more than novelty.
- Every network-backed value must have:
  - a source
  - a timestamp
  - a staleness state
- If data is stale, show it calmly and clearly. Never pretend it is fresh.

---

## Accessibility rules (day one)
- Dynamic type supported without broken layouts.
- High contrast and large hit targets.
- VoiceOver and TalkBack labels for every meaningful control.
- One-handed reach matters, especially for travel contexts.

---

## Success metrics (MVP)
- Day-7 retention (do people keep it installed?)
- Widget adds per active user
- Time-to-value: app open to “I got what I needed” in under ~3 seconds on a warm start
- Low confusion signals: few Place edits after setup, few repeated refresh attempts

---

## Open questions (not blocking)
- Default tile sets for each Place type (Living vs Visiting vs Other)
- Whether currency is enabled by default for Visiting
- Which single weather provider to start with (prioritize accuracy and reasonable terms)
