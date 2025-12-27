# Unitana

```
U   U  N   N  I  TTTTT  AAAAA  N   N  AAAAA
U   U  NN  N  I    T    A   A  NN  N  A   A
U   U  N N N  I    T    AAAAA  N N N  AAAAA
U   U  N  NN  I    T    A   A  N  NN  A   A
 UUU   N   N  I    T    A   A  N   N  A   A
```

Unitana is a travel-first “decoder ring” app that helps people live in two measurement systems at once, so they learn through exposure.

## Quick start

From the Flutter project root:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Project layout

- `lib/main.dart` – app entry
- `lib/features/first_run/` – first-run setup wizard
  - `first_run_screen.dart` – the wizard UI and state
- `test/` – basic widget test scaffold

## First-run wizard

The wizard is implemented as a controlled `PageView` (no free swipe by default) with:

- A single state owner (`_FirstRunScreenState`) that holds draft values for:
  - profile name
  - home + destination place configuration
- A bottom navigation/control area that:
  - gates forward navigation to keep the user in a simple, linear flow
  - allows “back” and “next” where appropriate
  - exposes “Finish” on the review step

The review step renders “card” style summaries for each place. These cards are intended to become the visual basis for the dashboard widgets.

## Documentation

Project documentation lives in `docs/`:

- `docs/postmortems/` – what we learned while building and stabilizing flows
- `docs/architecture/` – current state diagrams and component structure
- `docs/ai/` – prompts, workflows, and guidance for AI-assisted development
- `docs/context/` – compact machine-ingestible context (JSON) used to seed new chats

Start here:

- `docs/ai/WORKING_WITH_CHATGPT.md`
- `docs/ai/NEXT_CHAT_PROMPT.md`


## Local quality checks

Run the standard verification sequence:

```bash
./tools/verify.sh
```

## Testing notes

- Smoke and regression widget tests live in `app/unitana/test/`.
- Prefer `ValueKey('...')` selectors in tests, rather than matching on visible copy.

Optional: enable a local pre-commit hook so you can’t accidentally commit code that fails analyze/test:

```bash
git config core.hooksPath tools/githooks
```
