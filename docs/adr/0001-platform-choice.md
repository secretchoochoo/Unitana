# ADR 0001: Choose Flutter for MVP
File: `docs/adr/0001-platform-choice.md`  
Status: **Accepted**  
Date: 2025-12-23

## Context
Unitana is a travel-first “decoder ring” dashboard with display-only widgets in MVP. The MVP must ship on iOS and Android in a 6–10 week window, remain calm and fast, and behave honestly offline with clear freshness cues.

We need:
- One shared UI implementation for speed and consistency
- A future-ready architecture for widgets, subscriptions, and later cloud sync
- Strong accessibility support (dynamic type, screen readers, large hit targets)
- A reliable local storage layer for Places, settings, and cached snapshots

## Decision
Use **Flutter** for the main application codebase.

Widgets will be implemented as **native sidecars**:
- iOS: WidgetKit extension
- Android: AppWidget (prefer Glance unless constraints force RemoteViews)

Both widget implementations read from a shared “widget snapshot” written by the Flutter app to platform-appropriate shared storage.

## Why this decision
- One codebase for most UI and business logic; faster iteration for a solo operator.
- Flutter’s UI control supports the “calm dashboard” layout and consistent typography across platforms.
- Clear separation: Flutter app handles data model and snapshot writing; native widgets handle OS rendering and refresh mechanics.
- Leaves room for later additions like cloud sync without forcing a rewrite of the core UI layer.

## Consequences
### Positive
- Faster MVP development for iOS + Android with consistent UX.
- Shared domain layer (Places, tiles, caching rules) in Dart.
- A single accessibility strategy across most screens.

### Costs and risks
- Widgets require native work on both platforms.
- Platform-specific subscription integration still needs careful setup (StoreKit 2, Play Billing), even if UI is Flutter.
- Debugging widget refresh behavior is less predictable than in-app rendering.

## Mitigations
- Treat widgets as “display of last known snapshot,” not live views.
- Build a tiny native widget POC early (Week 2) to validate snapshot reading + rendering.
- Define a stable snapshot schema (versioned) and keep it backward compatible.
- Keep the app usable offline even if widgets are stale.

## Scope notes
- MVP will be local-only profiles (no accounts or sync yet).
- Widgets are display-only in MVP (no interaction beyond deep-link open-app).
- Weather selection is city-based only in MVP (no location permission flow).

## Follow-ups
- ADR 0002: Flutter version pinning strategy (simple vs FVM)
- ADR 0003: Widget snapshot schema and storage locations per platform
