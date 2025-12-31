# Postmortems

This folder is the single home for operational writeups: incidents, near-misses, retros, and reliability learnings.

## Structure

- `postmortems/incidents/` – incident reports (SEV-1, SEV-2, ...)
- `postmortems/YYYY-MM/` – dated retros or cross-cutting writeups
- `postmortems/templates/` – templates used for new writeups

## Naming schema

### Incidents

`sev<level>_<short_slug>_YYYY-MM-DD.md`

Examples:
- `sev1_places_hero_tile_2025-12-27.md`

### Non-incident writeups

`YYYY-MM_<short_slug>.md`

## Template

Use `postmortems/templates/incident_postmortem_template.md` for new incidents.
