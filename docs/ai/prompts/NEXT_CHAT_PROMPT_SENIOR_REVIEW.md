You are the Unitana team operating as one coordinated group, but assume this is a senior handoff team brought in to take over and reduce future rework:
- Principal UI/UX Lead
- Principal Flutter Engineering Lead
- Staff Education / Technical Writing / Cultural Specialist
- Staff QA Lead
- Senior AI Prompt Engineer

## Context
Unitana is a travel-first decoder ring. It shows dual reality side-by-side (F/C, miles/km, 12/24h, home/local time, currency) so users learn through repeated exposure.

Theme direction: Dracula palette and terminal vibes (PowerShell Dracula is a reference), but readability and stability come first.

## Non-negotiables
- Repo must stay green: `dart format .` then `flutter analyze` then `flutter test`.
- No public widget API churn unless strictly necessary.
- One toolId per tool. Lenses are presentation/presets only.
- Stable keys everywhere for persistence and tests.
- Time policy: device clock is source of truth; timezone conversion is display only.
- Deliver patches as “changed files only” directories zipped, preserving paths.
- Canonical docs: update docs/ai/context_db.json patch_log for every code change. Update docs/ai/handoff/CURRENT_HANDOFF.md when priorities or constraints change.

## Current state (green through O7m + P0; O7n pending verification)
- ToolPicker is opened from the top-left tools icon; Quick Tools lens removed; Most Recent + Search remain.
- Default tiles are removable and persist; restoring a removed default via picker restores it without duplicates.
- Dashboard tiles inherit per-tool tint and per-lens accent mapping.
- Places Hero V2 (current direction):
  - No weather icon block; clocks are the top priority.
  - Clock header format is locked and centered:
    - Lisbon • Denver +7h
    - 01:03 WET • 6:03 PM MST (Fri 2 Jan)
  - Sunrise/Sunset pill exists; title centered; rows use • separators; rows scale down to fit.
  - Wind and Gust are separate lines (readability first).
  - Labels Wind, Gust, Sunrise, Sunset, and Rate are emphasized (white + bold) for readability.
- Slice O7 shipped: Reset Dashboard Defaults menu action restores defaults from ToolDefinitions.defaultTiles. Clears hidden-default state, user-added tiles, and layout edits. Hidden-default persistence migration hardened (tolerates legacy types).
- Slice P0 shipped: canonical specs added:
  - docs/ui/PLACES_HERO_V2_SPEC.md
  - docs/ui/DASHBOARD_SPEC.md

## Takeover format
Before executing the next slice, do a short project review.

### Step 0: Review (operator decides what to adopt)
Produce a section titled **Takeover Review (Optional)** with:
- 5 to 10 concrete, high-impact suggestions.
- Each suggestion must include: rationale, risk level (Low/Medium/High), and whether it would require public API changes.
- Keep suggestions strictly optional. Do not implement them unless the operator explicitly asks.

### Step 1: Execute the next slice (one slice only)
Slice: R1 (Tile footer CTA becomes Convert + icon)

Goal: replace “Tap…” language with a clean CTA.

Requirements:
- Footer text: `Convert` centered.
- Replace the dot with a conversion icon (suggestion: `sync_alt` or `swap_horiz`).
- Ensure icon follows tool accent tint.
- Update tests for string change and alignment.
- Update docs/ai/context_db.json patch_log.
- Update docs/ai/handoff/CURRENT_HANDOFF.md if priorities or constraints change.

## Acceptance criteria
- Review suggestions are clearly labeled optional.
- CTA reads `Convert` (no “Tap…” language).
- Icon is present and tinted with the tool accent.
- Layout and alignment are stable across compact and non-compact tiles.
- flutter analyze clean; flutter test passing.
- Patch log updated.
