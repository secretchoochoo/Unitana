# NEXT CHAT PROMPT — Senior takeover + single-slice execution (Unitana)

You are the Unitana team operating as one coordinated group with slightly more senior backgrounds:

- Principal UI/UX Lead (mobile-first systems, interaction design)
- Principal Flutter Engineering Lead (architecture, layout stability, performance)
- Senior QA Lead (widget tests, persistence, regression prevention)
- Education / Technical Writing Specialist (UX clarity, terminology, onboarding, cultural considerations)
- AI Prompt Engineer (handoff precision, scope control)

## Inputs to review first (required)
- Repo snapshot (latest full codebase): attach the latest full repo zip.
- Build log (current failing state, if any): attach error.log.
- Reference docs in repo:
  - `docs/ai/context_db.json`
  - `docs/ai/handoff/CURRENT_HANDOFF.md`
  - `docs/ai/reference/PLATFORM_ICON_AUDIT.md`

## Context
Unitana is a travel-first decoder ring. It shows dual realities side by side (F/C, miles/km, 12/24h, home/local time, currency) so users learn through repeated exposure rather than configuration.

Theme direction:
- Dracula palette
- Terminal-adjacent aesthetics, but never at the expense of clarity
- Terminal influence is pattern recognition, not literal emulation

## Non-negotiables (contract)
- Repo must stay green (merge gates):
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- No public widget API churn unless strictly necessary.
- One toolId per tool. Lenses are presentation only.
- Stable keys everywhere (persistence + tests).
- Device clock is source of truth; timezones are display only.
- Deliver patches as changed-files-only zips, paths preserved.
- Canonical docs updates per slice:
  - Append to `docs/ai/context_db.json` (`patch_log`)
  - Update `docs/ai/handoff/CURRENT_HANDOFF.md` when status, priorities, or constraints change

## Current checkpoint
- Build is green through Slice **O12k13r20**.
- Dashboard migrated to slivers (C3a) and includes a compact pinned overlay that keeps the Places Hero reality toggle actionable during scroll (C3b).
- The Places Hero reality toggle is the global “unit reality” switch for the dashboard, including time, weather visuals, and currency context.
- Tool modal UX conventions are intact: terminal-inspired history/results, long-press to edit, consistent typography.
- Widget tests are hardened to avoid lens ordering, visible text, and ModalBarrier hit-testing; ToolPicker search-first is the stable path.
- Weather fetching remains deferred (network off by default); SceneKey remains the provider-agnostic abstraction.

## Decisions already made (do not revisit)
- One toolId per tool; lenses are presentation/presets only.
- Places Hero reality toggle drives dashboard context (time, currency, and hero visuals).
- Scene system: SceneKey catalog is provider-agnostic; providers map condition codes to SceneKey.
- Time policy: device clock is truth; timezone conversion is display only.

References:
- `docs/ai/handoff/CURRENT_HANDOFF.md`
- `docs/ai/reference/SCENEKEY_CATALOG.md`

## Phase 0: Senior takeover review (max 10 bullets)
Before implementing anything, produce a maximum of 10 bullets:
- Three keep validations (what is correct and must not change)
- Three high-risk regression zones
- Three small, high-leverage opportunities (no scope creep)
- One operator decision question (only if truly needed)

Then immediately propose:
- Accepted suggestions and dismissed suggestions, defaulting to accepting only items that do not expand scope beyond the next slice.

## Execute exactly one slice

### Slice ID: C3c “Hero Details pill toggle (☀︎/🌬) with intrinsic affordance”

Goal:
The bottom-left Details pill in the Hero Cockpit becomes multi-state without consuming extra vertical space:
- Default view: sunrise/sunset
- Alternate view: wind

Constraints:
- No Places Hero V2 relayout. Keep geometry stable; only rearrange within existing bounds.
- The toggle must feel actionable without adding heavy chrome or a second full toggle control.
- Must behave correctly in both the main Hero and the pinned overlay.
- Preserve stable keys and persistence contracts.

Requirements:
- Add a subtle, intrinsic affordance in the pill (iconography and micro-motion are allowed; keep it lightweight).
- Tap behavior:
  - Tapping the pill toggles view (sunrise/sunset ↔ wind).
  - Maintain accessibility semantics (button-like role, label updates).
- Add a small widget test that:
  - Scrolls until the pinned overlay appears.
  - Taps the Details pill.
  - Asserts the pill content swaps (by key, not visible text).

Acceptance criteria:
- No RenderFlex overflows on smallest supported device sizes.
- `dart format .`, `flutter analyze`, `flutter test` all green.
- Patch log entry appended to `docs/ai/context_db.json`.
- Update `docs/ai/handoff/CURRENT_HANDOFF.md` only if priorities or constraints changed.

Deliverables:
- One changed-files-only zip, paths preserved.
- Call out any new keys introduced.

## After the slice (do not implement now, backlog only)
- Currency promotion in the cockpit (make it first-class and glanceable) as a separate slice after C3c.
- Platform icon audit execution per `docs/ai/reference/PLATFORM_ICON_AUDIT.md` (Android + iOS + one desktop/web target).
- Weather scene binding and provider mapping once tool surface completion is closer to done.
