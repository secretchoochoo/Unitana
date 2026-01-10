# Current handoff (canonical)

## Status
- Platform icon audit: `docs/ai/reference/PLATFORM_ICON_AUDIT.md`.
- DevTools clock override: fixed duplicate symbols for `debugClockOffset` / `setDebugClockOffset` (O12k13e) and added a Clock Override UI in the DevTools sheet (O12k13g).
- Widget test stability: Time tool modal interaction test now uses ToolPicker search-first path (O12k13f).
- Build: green (through Slice O12k13j3). Always run: `dart format .`, `flutter analyze`, `flutter test` before merging.
- Sev 1 recovery (O12k13h): fixed a DashboardScreen parse break from an incomplete AppBar menu bottom sheet edit; added a size-mirror widget test for the header Tools/Menu buttons.
- Hotfix (O12k13h1): resolved a mirror-size test failure caused by AppBar leading-slot constraints (Tools was resolving to 56x56 while Menu was 44x44) by centralizing header button size/radius to 56/28.
- Test hotfix (O12k13j1): dashboard currency modal context regression test now dismisses the tool modal via ModalBarrier tap (bottom sheet) instead of expecting a Cupertino back button.
- Test hotfix (O12k13j3): removed unsupported `warnIfMissed` parameter from `WidgetTester.tapAt()` for Flutter SDK compatibility; dismissal now taps ModalBarrier top-left.
- Theme direction: Dracula palette + terminal vibes, but readability and stability come first.
- Time policy: device clock is source of truth; timezone conversion is display only.
- Scene system: SceneKey catalog is provider-agnostic; providers map condition codes -> SceneKey.
- Hero toggle contract: the selected city drives hero weather, marquee scene, and currency. Day/night visuals follow the selected city time, except when a DevTools override explicitly forces day or night.

## Current checkpoint
- Dashboard + Places Hero V2 are stable.
- Tool modals are functional and visually close to final.
- Terminal-inspired history/results exist (monospace, prompt glyph, muted metadata).
- `$` prompt glyph is removed everywhere (currency ambiguity avoided).
- Roboto Slab is used for headings/titles (wizard, dashboard, tool modals) with bold on key labels.
- Weather backend clients exist (WeatherAPI + Open-Meteo), but network fetching is disabled by default (deferred until tool surface completion).

## What shipped recently (since last handoff refresh)
- O12k13j3: Test-only hotfix, removed unsupported `warnIfMissed` parameter from `WidgetTester.tapAt()` for Flutter SDK compatibility; kept modal dismissal stable by tapping ModalBarrier top-left.
- O12k13j1: Test-only hotfix, dismiss tool modals via ModalBarrier (showModalBottomSheet) rather than tester.pageBack().
- O12k13j: Currency modal now receives home/destination place context when launched from dashboard tiles; added a regression test that validates correct EUR/USD directionality when home is non-US.
- O12k13h1: Hotfix, aligned header button RenderBox sizing under AppBar constraints (56x56) so Tools/Menu are true mirrors by measurement and aesthetics.
- O12k13h: Sev 1 recovery, fixed DashboardScreen parse break + added test guard for mirrored header button sizing.
- O12j11: Introduced DevTools weather override typing regression (compile/analyze failures).
- O12j11a: Hotfix for DevTools weather override rendering and selection (handles `WeatherDebugOverride` variants cleanly).
- O12j11b: Typography consistency pass (Roboto Slab for key headers/titles; tool modal header sizing and alignment).
- O12k01a: Currency tool MVP enabled (ToolPicker + dashboard), place-aware direction inference (home vs destination), EUR ↔ USD via live/demo rate.

## Weather (deferred)
- Live weather is intentionally deprioritized until tool surface completion is done.
- Open-Meteo (JSON, no secret in non-commercial mode) is the preferred target for a keyless dev path; commercial usage requires a paid host + apikey.
- WeatherAPI remains supported as an alternative provider.
- Network fetching is opt-in only (default off) via dart-defines: `WEATHER_NETWORK_ENABLED=true` and `WEATHER_PROVIDER=openmeteo|weatherapi`.
- SceneKey remains the stable abstraction; provider mapping belongs in the model layer, never in UI.

## Developer Tools: Weather override (verification workflow)
- DevTools supports a coarse weather override for forcing hero scenes during development.
- The underlying override model is now polymorphic (`WeatherDebugOverride`), so UI must handle:
  - null (default)
  - coarse condition override
  - provider-style override (future)

## Developer Tools: Clock override (verification workflow)
- DevTools now includes a Clock Override sheet for simulator testing (no NTP, no backend sync).
- Entry point: Developer Tools sheet → Clock Override (key: `devtools_clock_menu`).
- Controls:
  - Enable toggle (key: `devtools_clock_enabled`) toggles whether an offset is applied.
  - Slider (key: `devtools_clock_offset_slider`) adjusts UTC offset in the range ±12 hours.
- Places Hero uses `DashboardLiveDataController.nowUtc`, so the marquee time labels and day/night behavior follow the offset immediately.

## Non-negotiables (contract)
- Repo must stay green: `dart format .` then `flutter analyze` then `flutter test`.
- No public widget API churn unless strictly necessary.
- One toolId per tool; lenses are presentation/presets only.
- Stable keys everywhere (persistence + widget tests).
- Places Hero V2 layout rules are locked during weather work (paint-only changes are allowed).
- Deliver patches as “changed files only” bundles zipped, paths preserved.
- Canonical docs:
  - Update `docs/ai/context_db.json.patch_log` for every change.
  - Update this file when priorities/constraints change.

## Current priorities (ordered)
### P0: Fix + keep repo green
1) Treat `dart format .`, `flutter analyze`, `flutter test` as merge gates.
2) Keep stable keys and avoid public widget API churn.

### P1: Phase A, tool surface completion (frontend-first)
3) Build remaining core decoder-ring tools (Time, plus any planned primitives).
   - Currency MVP is now enabled (EUR ↔ USD).
4) Keep modal structure, history behavior, and typography consistent across tools.

### P2: Phase B, UX polish + consistency
5) Swap icon placement review (right-aligned vs inline).
6) Convert button alignment across tools.
7) Arrow (→) styling consistency using Dracula palette accents.

### P3: Phase C, Weather wiring (later)
8) Weather backend wiring (Open-Meteo preferred, WeatherAPI optional), mapping, and scene binding after tool surface is largely complete.
