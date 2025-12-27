# Unitana task slice template

Use this template when requesting the next slice of work. It keeps changes small, reversible, and easy to verify.

## 1) Slice header
- Slice name: <short, imperative>
- Goal: <one sentence>
- Non-goals: <what we will not touch in this slice>
- Risk level: low | medium | high

## 2) Current state (facts only)
- Branch: <branch name>
- Build status: <passes / fails>
- Known warnings: <list>
- Screens affected: <list>

## 3) Requirements
### Product
- <requirement>

### UI / UX
- <requirement>

### Engineering
- <requirement>

### QA
- <requirement>

## 4) Constraints and rules
- Prefer minimal patches over refactors.
- Do not change core models or navigation without an explicit plan.
- Avoid null assertions (`!`) for theme extensions; provide safe fallbacks.
- Prefer unicode escapes for fragile characters in strings (for example \u00B0 and \u20AC).

## 5) Delivery format
Return a downloadable patch zip that contains full-file replacements for all changed files.

Include:
- Changed paths
- Added paths
- Removed paths
- Operator apply commands
- Verification commands
- Smallest-iPhone device check steps

## 6) Verification checklist
Run these and report any failures:

```bash
cd app/unitana

dart format .
flutter analyze
flutter test
flutter run
```

Device check:
- Smallest iPhone target
- Light and dark mode
- Landscape sanity check for onboarding

## 7) Rollback plan
- Git: `git restore <paths>` or `git checkout -- <paths>`
- If a slice touches dependencies: `flutter pub get` after rollback

## 8) Patch notes entry
Provide a short patch note with:
- What changed (user-facing)
- What changed (engineering)
- Risk and test coverage

