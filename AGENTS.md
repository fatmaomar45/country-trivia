# AGENTS.md

## Project

Flutter country trivia app. MVVM + Provider. Shows a flag, user picks the correct country from 4 options. Scoring: 10/8/5 points for 1st/2nd/3rd try.

## Commands

```bash
flutter pub get          # install deps
flutter analyze          # lint (must pass before PR)
flutter test             # run all tests
flutter test test/unit/trivia_viewmodel_test.dart  # single test file
flutter run              # run on emulator (required before UI PRs)
```

## Branching

- **Default branch:** `development` — all PRs target this
- **Feature branches:** `feature/TICKET-XXX-short-description`
- **Merge:** squash merge, delete branch after merge
- **Release:** `development` → `main` via PR at stable milestones

## PR Checklist (every feature PR)

- [ ] Branch from latest `development`
- [ ] Ticket reference in title: `[TICKET-XXX] Description`
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] `flutter run` verified on emulator (UI tickets only)
- [ ] PR targets `development`

## Architecture

```
lib/
├── core/           # constants, enums (no Flutter deps)
├── data/
│   ├── models/     # Country
│   ├── services/   # ApiService (Dio), StorageService (SharedPreferences), CacheService
│   └── repositories/  # CountryRepository (generates Question objects)
├── presentation/
│   ├── viewmodels/ # TriviaViewModel (ChangeNotifier)
│   ├── screens/    # TriviaScreen
│   └── widgets/    # FlagImage, CountryOptionCard, ScoreBoard, AttemptsIndicator, ResultBanner
└── app.dart        # MaterialApp + MultiProvider
```

**Data flow:** ApiService → CountryRepository → TriviaViewModel → Widgets

**Key patterns:**
- `Country` equality is based on `isoCode` (not name)
- `Question` = correct Country + 4 shuffled options (1 correct + 3 distractors)
- `GameState` enum: `loading`, `playing`, `revealed`
- Score/solved flags persisted immediately to SharedPreferences on every change
- Flag images cached 30 days (250-item LRU), API response cached 7 days

## APIs

- **Countries:** `GET https://restcountries.com/v3.1/all?fields=name,cca2`
- **Flags:** `https://flagcdn.com/w320/{iso_lowercase}.png`

## Docs

- `docs/master_plan.md` — full architecture, ticket breakdown, execution order
- `docs/opencode-setup.md` — OpenCode PR review setup and API key instructions

## PR Review

- PRs are automatically reviewed by OpenCode's **Big Pickle** model via GitHub Actions
- Review comments are posted automatically on each PR
- Setup: add `OPENCODE_API_KEY` to repo secrets (see `docs/opencode-setup.md`)
