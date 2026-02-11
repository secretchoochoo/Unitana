# Public Release Branching Strategy (XL-O)

## Goals
- Keep fast iteration on mainline development.
- Create a stable public release track without internal-only surfaces.
- Support independent public versioning cadence.

## Branch Model
- `main`:
  - full development trunk (includes internal docs/dev utilities).
- `release/public`:
  - public-app stabilization branch.
  - only release-approved changes are cherry-picked/merged.
- `release/public/x.y`:
  - optional per-release hardening branch from `release/public`.

## Environment Gating
- Use compile-time flags (dart-define) for internal-only features.
- Current gate:
  - `UNITANA_DEVTOOLS_ENABLED=true|false`
  - default remains `true` for dev, set `false` for public build pipeline.

## AI Docs Policy
- Do not ship internal AI docs in release artifacts.
- Repo options:
  1. Keep docs in `main`, exclude from release packaging artifacts only.
  2. Maintain a clean `release/public` branch where `docs/ai` is removed.
- Preferred: option 1 first (lower git overhead), option 2 if compliance/legal requires branch-level exclusion.

## Versioning Strategy
- Continue build-time injection:
  - `UNITANA_APP_VERSION`
  - `UNITANA_BUILD_NUMBER`
- Public builds use semantic release tags:
  - `vMAJOR.MINOR.PATCH`
- Internal/dev builds keep `dev` channel identifiers.

## Promotion Flow
1. Develop on `main`.
2. Cut `release/public` from a known green commit.
3. Disable devtools via release pipeline define.
4. Apply release-only polish/fixes on `release/public`.
5. Tag + ship from `release/public`.
6. Back-merge critical fixes to `main`.

## Guardrails
- Required gates on release branch:
  - `dart format .`
  - `flutter analyze`
  - `flutter test`
- Manual checklist:
  - devtools hidden
  - about/version metadata correct
  - licensing page complete for shipped assets/dependencies

## Immediate Next Actions
- Add CI lane for `release/public` with `UNITANA_DEVTOOLS_ENABLED=false`.
- Add a release checklist doc tied to tag creation.
- Decide final docs exclusion policy (artifact-only vs branch-level).
