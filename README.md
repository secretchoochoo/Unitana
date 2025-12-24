# Unitana

Unitana is a travel-first “decoder ring” that helps people live in two measurement systems at once, so they learn through exposure instead of constant translation.

It’s built for travelers and relocators who want to feel oriented quickly: weather, time zones, distance/speed, weights, cooking basics, fitness metrics, and currency cues, shown side-by-side in a calm dashboard (plus display-only widgets).

---

## Project status
**Phase:** Pre-build (docs-first)  
**Current focus:** Lock MVP truth, flows, and wireframes before committing to a full UI build.

---

## Where to start (source of truth)
- **MVP truth (why we exist + hard constraints):** `docs/00-mvp-truth.md`
- **Flows / navigation map (next):** `docs/01-flows.md`
- **Wireframes (after flows):** `docs/02-wireframes.md`
- **Architecture decisions (short, durable):** `docs/adr/`

---

## Guiding principles
- Calm dashboard, not a kitchen-sink utility
- Offline-first trust (cached data shown honestly)
- Widgets designed around real refresh constraints (no fake real-time)
- Learning aids are orientation helpers, not authorities
- Accessibility is day one

---

## Repo conventions (so future-us stays sane)
- Docs live in `docs/` and evolve alongside code.
- Every non-trivial decision gets a short ADR in `docs/adr/`.
- Prefer small commits with clear messages.

**Suggested commit prefixes**
- `docs:` documentation changes
- `feat:` new feature work
- `fix:` bug fixes
- `chore:` tooling/repo maintenance
- `test:` tests only
- `refactor:` refactors without behavior change

---

## Development
Not wired up yet (stack selection pending).

When we pick the stack, this section will include:
- local prerequisites
- install steps
- build/run commands for iOS and Android
- how widgets are tested
- how release builds are produced

---

## License
TBD (defaulting to “All Rights Reserved” until we decide otherwise).
