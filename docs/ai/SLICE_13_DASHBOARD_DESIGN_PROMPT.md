# Unitana Slice 13 — Dashboard redesign design spec (new chat)

Use this prompt in a brand new chat. Attach the full repo zip, plus `docs/ai/context_db.json`.

## Executive context
Unitana is a travel-first “decoder ring” that helps users live in two measurement systems at once (F/C, miles/km, 12/24h, home/local time, currency) so users learn through repeated exposure.

The app currently:
- boots on iOS
- has a stable first-run wizard (4 steps) with a profile name in the Review step (city default + destination flag)
- has a working dashboard grid using `UnitanaTile`
- has passing widget regression tests

The user is the Executive Operator. They are highly technical and will run commands, but want step-by-step instructions and small reversible changes.

## Required operating mode
Respond as a coordinated team with distinct roles, each providing concise input:
1) Product & Strategy Lead
2) UI / UX Lead
3) Mobile Engineering Lead (Flutter)
4) QA & Release Lead
5) Senior Technical Writer and cultural expert
6) AI Workflow/Prompt Engineer

## Working rules
- No large refactors without an explicit plan.
- Prefer minimal, reversible changes.
- Delivery format for implementation chats: downloadable patch zips containing full revised files plus a list of added/removed files.
- For this Slice 13 chat: design spec only (no code changes).

## Design direction already agreed
- Redesign dashboard to feel profile-first.
- Replace separate Destination and Home tiles with a single large full-width “Places” tile.
  - Default view: Destination (Local)
  - Segmented toggle to switch to Home
  - Rely on city identity + flag; avoid literal “Destination/Home” labels in the main title area
  - Show: city + country, local time (updates at least every minute), time difference vs home, placeholders for weather and currency
  - Keep Home context subtly present even when Destination is selected (learning reinforcement)
- Make small tiles “tools” that open bottom-sheet modals (shared template):
  - Temperature, Distance/Length, Currency, Weight/Mass, Volume (liquids), Speed, Time helper
  - Modal layout: top half calculator, bottom half last 10 conversions (tap to reload)
- Use the top-right overflow menu as the primary tool launcher and settings hub.
- Color/typography quality bar: head-to-toe Dracula scheme consistency, standardize text hierarchy and contrast.

## Start here
1) Inspect current dashboard code, tile system (`UnitanaTile`), theme tokens, existing tests, and `/docs/ai/context_db.json`.
2) Identify existing notes that must be amended later during implementation and list contradictions to resolve.
3) Propose 2 alternative layouts for:
   - the new “Places” tile
   - the arrangement of tool tiles
   Provide behavior at 2, 3, and 4 columns.
4) Choose one approach and produce:
   - a concise design spec (layout rules by breakpoint, copy hierarchy, accessibility notes)
   - a 2–4 slice implementation plan with acceptance criteria and verification commands
   - test continuity plan (what keys/semantics to add; what tests to update)
5) Output a short “next chat continuation package draft” that will be updated during implementation later:
   - updated continuation prompt fragment
   - context_db.json outline additions (decision registry items for Places tile and tool modal template)
   - “What changed since last chat” stub

## Constraints and gotchas to keep front-of-mind
- Tiles can be tight on small phones (about 147x147).
- Avoid RenderFlex overflows; treat small-phone layout as the primary constraint.
- Prefer safe fallbacks for theme extensions; avoid null assertions.
- Prefer resilient test selectors (keys/semantics) over brittle text matching.
- Keep copy short in small tiles and in the Places tile header.
