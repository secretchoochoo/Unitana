# Unitana Incident Postmortem
## Incident
**Title:** City Picker Expansion Regression Cascade (First Run + City Picker + Review)  
**Severity:** Sev1 (developer-impacting, build-breaking)  
**Date window (America/Denver):** Dec 24–26, 2025 (iterative)  
**Owner:** Executive Operator (Cody) with the Virtual App Team (Product, UX, Eng, QA, Docs)

## Summary
While expanding the City Picker (dataset enrichment + search relevance + “popular cities” empty-state UX), the project entered a regression loop where fixes in one area repeatedly destabilized others. The failures escalated from UI/test regressions into compiler and analyzer failures (syntax corruption, missing identifiers, constructor drift), then stabilized only after restoring a consistent “contract” across model, widgets, and tests.

The end state is **stable and running**, with a known remaining functional issue: **the Welcome step is not meaningfully visible** because FirstRunScreen auto-advances to the profile-name step almost immediately.

## Impact
### User impact (development)
- `flutter analyze` and `flutter test` repeatedly failed, blocking iteration.
- Onboarding and city picker behavior became unreliable mid-iteration (tests brittle, UI overflow, missing keys).
- Significant time was spent on repair work rather than feature value.

### Product impact
- City Picker improvements shipped locally, but the process cost clarity and confidence.
- Onboarding intent (“calm, welcoming”) became partially undermined by auto-advance behavior.

## What changed
### Intended scope
- Improve city dataset quality and presentation.
- Improve search relevance (city name priority, sensible empty-state list).
- Add useful city metadata display (timezone offset hint, currency symbol clarity).

### Actual touched areas
- `lib/data/cities.dart` (City model, helpers like timezone/currency display)
- `lib/widgets/city_picker.dart` (search UX, filtering, presentation)
- `lib/features/first_run/first_run_screen.dart` (onboarding flow + city selection wiring)
- Tests (constructor requirements and UI hooks/keys)

## Timeline (condensed)
- **T0:** City picker enhancements initiated (data + search + display).
- **T1:** First Run review/UI tests begin failing due to UI/layout and key drift.
- **T2:** Cascading compile failures after “repair edits” (string escaping around `$`, missing identifiers, missing/renamed fields).
- **T3:** Recovery via repeated “format → analyze → test” loops; restore contracts and remove broken assumptions.
- **T4:** Stable build achieved; remaining UX bug observed: Welcome step flashes or is skipped.

## Root causes (primary)
1) **Contract drift between files**
   - City model fields and widget usage diverged (e.g., getters like `display`, `defaultUse24h`, `admin1Name` appearing/disappearing between iterations).
   - Constructor signatures changed without synchronized updates in tests and callers.

2) **Large-file edit collisions**
   - Big widget files (FirstRunScreen) were edited in ways that increased the chance of “splice errors” and structural corruption.
   - Dart formatter failures were an early signal that parse validity was lost.

3) **Unbounded change scope**
   - Feature work (search, dataset, UX polish) and refactor work (structural changes, helpers, keys) happened in the same patch window.
   - This increased the blast radius and complicated debugging.

4) **AI context drift**
   - In a long-running chat, the assistant sometimes reasoned against an internal “expected model” rather than the repo’s actual current code, leading to invented/incorrect fields.

## Contributing factors
- **Tests coupled to UI structure/text** at points (later improved by moving to keys).
- **Onboarding screens not scroll-safe** in small test viewports, causing overflow that hid widgets from finders.
- **Dataset/schema uncertainty** (what fields are actually present, what is “authoritative”).

## Detection
- Immediate detection via:
  - `dart format` failing (parse invalid)
  - `flutter analyze` compile errors
  - `flutter test` failing widget tests

## Resolution
- Restore parse validity first (formatter must succeed).
- Resolve compiler/analyzer errors next (stop the bleeding).
- Fix tests last, but treat them as a contract (keys and layout safety).
- Align City model fields with UI usage, not vice versa.
- Re-stabilize FirstRunScreen so it compiles and renders in constrained viewports.

## What went well
- The “format → analyze → test” loop worked as a reliable triage ladder.
- Keys became the stable interaction contract for tests (more resilient than text matching).
- City picker capability increased substantially once the model/UI contract was re-established.

## What went wrong
- Too many concerns changed at once (feature + refactor + UX polish).
- Lack of a “single source of truth” handoff artifact early in the work led to repeated re-derivation of intent and schema.
- Welcome-step behavior was implemented as a timed auto-advance, which conflicts with the desired onboarding pacing.

## Where we got lucky
- No production release; regressions were contained to local dev.
- The team caught issues early through tests, rather than later through manual QA.

---

# Sustaining Engineering Action Plan (Next Slice)

## Quality gates (QA Lead: must-haves)
1) **CI or pre-commit gate** (local now, CI later):
   - `dart format .`
   - `flutter analyze`
   - `flutter test`
2) **“No compile errors ever land” rule**:
   - Any PR/patch that breaks `flutter analyze` is incomplete by definition.

## Reduce blast radius (Mobile Eng Lead)
1) **Break up monolithic `FirstRunScreen`**
   - Extract step widgets into separate files or small private widgets:
     - intro/welcome
     - profile name
     - place selection
     - review
   - Extract shared components:
     - key-value row widget
     - review cards
2) **Create explicit contracts**
   - A short `docs/contracts.md`:
     - City model fields that UI is allowed to use
     - Stable widget keys used by tests
     - Rules for adding/removing fields

## City picker cleanup (UX + Eng)
1) **Search intent hierarchy**
   - City name (prefix) wins.
   - City name (contains) next.
   - Country/region next.
   - Timezone/currency only as fallback tokens, or behind an “advanced” approach.
2) **Empty-state behavior**
   - If query is empty: show curated “popular cities” spanning time zones.
   - Only show long alphabetical list after user begins typing (or behind “Browse all”).
3) **Metadata clarity**
   - Replace ambiguous numeric hints with explicit, human text:
     - “UTC+1” instead of “07” (or remove numbers entirely if unclear).
   - Show currency as: “$ USD” or “€ EUR” (symbol + code).

## Dataset governance (Docs + Eng)
1) **Data build script + validation**
   - Build cities.json from a known source (or a curated subset initially).
   - Add validation rules:
     - no “s-*” junk ids
     - required fields present
     - duplicates flagged
2) **Document the schema**
   - `docs/cities_schema.md` with examples and “why these fields exist”.

## AI ops playbook (Docs Lead)
1) **Handoff file per chat**
   - `docs/ai_handoff.md` updated at the end of each major slice:
     - what changed
     - why it changed
     - what is “do not break”
2) **Prompt discipline**
   - Every new chat starts with:
     - current repo snapshot (zip)
     - contracts (keys, constructors, model fields)
     - explicit “do not invent fields” rule
3) **Change management**
   - Each patch is:
     - one goal
     - one set of files
     - tests run and recorded

---

# Known remaining bug
## Welcome step flashes / is skipped
**Observed:** On fresh first run, the app often shows the profile-name step immediately; the Welcome step appears only briefly (not long enough to function as a real first screen).  
**Most likely cause:** In `FirstRunScreen.initState()`, a timer auto-advances from step 0 to step 1 after ~600ms, often before the UI is usable.  

**Fix approach (first task next chat):**
- Remove auto-advance; keep Welcome until user taps **Start**.
- If you still want “intentional pacing,” do it with animation, not a forced step change.

