# Current handoff (canonical)

## Status
- Build: green (through Slice R1). Run `dart format .`, `flutter analyze`, `flutter test` before merging.
- ToolPicker: opened from the top-left tools icon; Quick Tools lens removed; Most Recent + Search remain.
- Dashboard: default tiles removable and persistent; restoring removed defaults works without duplicates.
- Dashboard tiles: inherit per-tool tint and per-lens accent mapping.
- Places Hero V2: stable (clocks first; no weather icon block; sun pill present; wind and gust split). Specs are canonical in docs/ui/PLACES_HERO_V2_SPEC.md.
- iOS app icon visibility: backlog only.

## Shipped slices (high level)

- Slice P0: canonical UI specs added for Places Hero V2 and the dashboard (docs/ui/PLACES_HERO_V2_SPEC.md, docs/ui/DASHBOARD_SPEC.md).
- Slice C: ToolPicker two-level hierarchy (Activity Lenses -> Tools) with stable keys.
- Slice H: ToolPicker UX (search, most-recent shortcut, single-expanded accordion), Favorites removed.
- Slice I: Lens accent colors (Dracula palette tinting for lens headers + tool row icons).
- Slice M: tools menu can run tools without adding widgets; widgets are added via explicit “+ Add Widget” affordance.
- Slice O4: Quick Tools lens removed from picker accordion.
- Slice O1: Add Widget confirmation is visible while bottom sheets are open (in-modal notice).
- Slice O2: per-tool icon + lens accent coloring on dashboard tiles (removes legacy global purple accent).
- Slice O6: default dashboard tiles can be removed in edit mode; removals persist and can be restored via the picker.
- Slice O7: “Reset Dashboard Defaults” menu action restores defaults from ToolDefinitions.defaultTiles and clears customizations.
- Slice O7 hotfix series: reset wiring hardened, hidden-default persistence migration tolerates legacy types, and redundant menu entries removed.
- Slice O7n: Places Hero V2 polish, Sunrise / Sunset title centered within the pill; labels Wind, Gust, Sunrise, Sunset, and Rate are emphasized (white + bold) for readability.
- Slice O7o: Places Hero V2 analyzer cleanup only (removed lint warnings; no behavior change).
- Slice R1: Tile footer CTA updated to `Convert` and uses a conversion icon (swap_horiz) tinted to the tool accent.
 - Slice O11: Hero marquee slot restored with paint-only “Alive” pixel scene (CustomPaint) that animates in runtime and renders a deterministic still frame in widget tests.

## Immediate next work (priority order)

### O12: Pixel weather scenes (condition-based) (NEXT)
Goal: scenes per condition (Sunny, Partly Cloudy, Rain, Snow, Mix, etc.), API-ready mapping.

- Define `WeatherKind` + mapping layer (stubbed initially).
- Implement a small set first (Sunny, Cloudy, Rain, Snow) plus placeholders for rare types.

### R2: Tool modal header icon tint uses tool accent
Goal: modal cohesion with picker and tiles; add a tint widget test.

### R3: Tool modal layout v2 with terminal surfaces
Goal: Input/Result/History share a single “terminal” surface component; stable structure keys; responsive.

### Tool expansion bundle (Weather/Time + Money/Shopping)
Goal: end-to-end tools, one toolId each, history logs, consistent units.

## Policy: Device clock only (no server time sync)
- All time displays should derive from the device clock (DateTime.now / system time).
- Apply timezone conversion for presentation only.
- Do not add NTP or server-time sync.

## Guardrails
- Avoid creating scripts to shuffle docs.
- Prefer small diffs with clear patch log entries in `docs/ai/context_db.json`.
- Deliver patches as “changed files only” bundles, zipped, preserving paths.


### O11j Notes
- Added hero marquee keys: hero_marquee_slot (container), hero_alive_paint (CustomPaint).
- Alive animation runs via CustomPaint repaint; it is disabled under widget tests using FLUTTER_TEST env, so pumpAndSettle will not hang.


- **O11k** (2026-01-02): Restored hero marquee slot with test-safe paint-only animation; hardened Places Hero V2 layout to eliminate small-phone overflows; shrank tile Convert pill to prevent tile overflows.

- **O11k1** (2026-01-02): Fixed HeroAliveMarquee compile failure by importing kIsWeb and hardened animation gating (tests + disableAnimations + TickerMode).

- **O11k2** (2026-01-02): Removed kIsWeb usage from the hero marquee painter (compile-safe without foundation import); stars render unconditionally to avoid platform-gating logic.

- **O11k3** (2026-01-02): Fixed remaining small-device overflows in Places Hero V2 (left rail now uses flexible vertical distribution); ensured Alive marquee paints at full width; reworked UnitanaTile layout to be height-safe (prevents micro overflows from the Convert pill).
