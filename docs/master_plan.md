# Country Trivia — Master Plan

## 1. Overview

A Flutter trivia game where the user is shown a country flag and must pick the correct country name from four options. Points are awarded based on how quickly the user guesses correctly. Solved flags and total points persist across sessions.

---

## 2. Core Requirements

| # | Requirement | Details |
|---|-------------|---------|
| R1 | Display a flag image | Loaded from `https://flagcdn.com/w320/{iso}.png` |
| R2 | Show 4 country options | 1 correct answer + 3 random distractors |
| R3 | Scoring system | 1st try = 10 pts, 2nd try = 8 pts, 3rd try = 5 pts, exhausted = 0 pts |
| R4 | Reveal correct answer | After all 3 attempts are exhausted |
| R5 | No repeat flags | Solved flags never reappear across sessions/restarts |
| R6 | Persist points | Stored in SharedPreferences |
| R7 | Architecture | MVVM pattern with Provider for state management |
| R8 | Image caching | Flag images cached on disk to avoid redundant network requests |

---

## 3. API Design

### 3.1 Country Data API

> **NOTE:** The originally specified URL (`https://gitkraken.com/learn/git/git-flow`) is a Git tutorial page, not a country API. We will use **REST Countries** (`https://restcountries.com`) — the standard free country data API that provides ISO codes compatible with flagcdn.com.

| Endpoint | Purpose |
|----------|---------|
| `GET https://restcountries.com/v3.1/all?fields=name,cca2` | Fetch all countries (name + ISO alpha-2 code) |

**Response shape (per item):**
```json
{
  "name": { "common": "Germany" },
  "cca2": "DE"
}
```

### 3.2 Flag Image CDN

| URL Pattern | Purpose |
|-------------|---------|
| `https://flagcdn.com/w320/{iso_lowercase}.png` | 320px-wide PNG flag image |

The `cca2` value from REST Countries is lowercased to build the flag URL (e.g., `"DE"` → `https://flagcdn.com/w320/de.png`).

---

## 4. Architecture — MVVM + Provider

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                   │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │ TriviaScreen │  │ FlagImage    │  │ CountryCard│ │
│  └──────┬──────┘  └──────────────┘  └────────────┘ │
│         │ consumes                                 │
│         ▼                                           │
│  ┌──────────────────────────────────────────────┐   │
│  │         TriviaViewModel (ChangeNotifier)      │   │
│  │  - currentCountry                              │   │
│  │  - options (List<Country>)                     │   │
│  │  - attemptsLeft / attemptsMade                 │   │
│  │  - score                                       │   │
│  │  - gameState (loading, playing, revealed)      │   │
│  │  - submitAnswer(Country)                       │   │
│  │  - loadNextQuestion()                          │   │
│  └───────────────┬──────────────────────────────┘   │
├──────────────────┼──────────────────────────────────┤
│                  │  Data Layer                       │
│  ┌───────────────▼──────────────────────────────┐   │
│  │            CountryRepository                   │   │
│  │  - fetchAllCountries()                         │   │
│  │  - getUnsolvedCountries(Set<String>)           │   │
│  │  - generateQuestion(List<Country>)             │   │
│  │      returns (correct, [distractors])          │   │
│  └───────────────┬──────────────────────────────┘   │
│         ┌────────┴────────┐                          │
│         ▼                 ▼                          │
│  ┌─────────────┐  ┌──────────────┐                  │
│  │ ApiService  │  │StorageService│                  │
│  │ (Dio/HTTP)  │  │(SharedPrefs) │                  │
│  └─────────────┘  └──────────────┘                  │
└─────────────────────────────────────────────────────┘
```

---

## 5. Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp + Provider setup
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart         # URLs, SharedPreferences keys
│   │   └── cache_constants.dart       # Cache keys, max age, max objects
│   └── enums/
│       └── game_state.dart            # enum GameState { loading, playing, revealed }
│
├── data/
│   ├── models/
│   │   └── country.dart               # Country model (name, isoCode)
│   ├── services/
│   │   ├── api_service.dart           # HTTP client (Dio) — fetches countries
│   │   ├── storage_service.dart       # SharedPreferences wrapper
│   │   └── cache_service.dart         # CacheManager instances for flags + API
│   └── repositories/
│       └── country_repository.dart    # Combines API + storage, generates questions
│
├── presentation/
│   ├── viewmodels/
│   │   └── trivia_viewmodel.dart      # ChangeNotifier — all game logic
│   ├── screens/
│   │   └── trivia_screen.dart         # Main game screen
│   └── widgets/
│       ├── flag_image.dart            # CachedNetworkImage for flags
│       ├── country_option_card.dart   # Single answer button
│       ├── score_board.dart           # Top bar showing score + progress
│       ├── attempts_indicator.dart    # Visual dots/hearts for remaining tries
│       └── result_banner.dart         # "Correct!" / "The answer was X" overlay
│
└── di/
    └── injection.dart                 # MultiProvider setup / service registration

test/
├── unit/
│   ├── trivia_viewmodel_test.dart     # Game logic tests
│   └── country_repository_test.dart   # Question generation tests
└── widget/
    └── trivia_screen_test.dart        # Widget/integration tests
```

---

## 6. Data Models

### 6.1 `Country`

```dart
class Country {
  final String name;       // e.g. "Germany"
  final String isoCode;    // e.g. "DE" (alpha-2, as returned by API)

  const Country({required this.name, required this.isoCode});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']['common'] as String,
      isoCode: json['cca2'] as String,
    );
  }

  String get flagUrl => 'https://flagcdn.com/w320/${isoCode.toLowerCase()}.png';
}
```

---

## 7. Services

### 7.1 `ApiService`

- Uses **Dio** for HTTP (better error handling, interceptors).
- Method: `Future<List<Country>> fetchAllCountries()`
- Calls `GET https://restcountries.com/v3.1/all?fields=name,cca2`
- Returns parsed `List<Country>`
- Should handle: no internet (throw), partial failures, malformed items (skip).

### 7.2 `StorageService`

- Wraps **SharedPreferences**.
- Keys: `solved_flags` (JSON-encoded list of ISO codes), `total_points` (int).

| Method | Signature | Purpose |
|--------|-----------|---------|
| `getSolvedFlags` | `Future<Set<String>>` | Load solved ISO codes |
| `saveSolvedFlag` | `Future<void> addSolvedFlag(String iso)` | Append a solved flag |
| `getScore` | `Future<int>` | Load persisted score |
| `saveScore` | `Future<void> saveScore(int score)` | Persist score |

---

## 8. Image Caching Strategy

### 8.1 Overview

Flag images are served by `flagcdn.com` as static PNGs that never change for a given country. Caching them on disk eliminates redundant network requests, reduces data usage, and makes the app feel instant on repeat visits.

### 8.2 Caching Layers

| Layer | Mechanism | Scope | Purpose |
|-------|-----------|-------|---------|
| **Memory cache** | `CachedNetworkImage` internal LRU | App session | Instant display of recently-viewed flags |
| **Disk cache** | `flutter_cache_manager` (backing store for `CachedNetworkImage`) | Persistent across restarts | Avoid re-downloading flags the user has already seen |
| **HTTP cache** | `Dio` interceptor with `DioCacheInterceptor` | API responses | Cache REST Countries JSON response |

### 8.3 Disk Cache Configuration

```dart
// lib/core/constants/cache_constants.dart
class CacheConstants {
  static const String flagImageCacheKey = 'flagImages';
  static const Duration flagImageMaxAge = Duration(days: 30);
  static const int flagImageMaxNrOfCacheObjects = 250; // ~250 countries max

  static const String countriesApiCacheKey = 'countriesApi';
  static const Duration countriesApiMaxAge = Duration(days: 7);
}
```

```dart
// lib/data/services/cache_service.dart
class CacheService {
  static CacheManager get flagImageCache => CacheManager(
    Config(
      CacheConstants.flagImageCacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: CacheConstants.flagImageMaxNrOfCacheObjects,
      repo: JsonCacheInfoRepository(databaseName: CacheConstants.flagImageCacheKey),
      fileService: HttpFileService(),
    ),
  );

  static CacheManager get countriesApiCache => CacheManager(
    Config(
      CacheConstants.countriesApiCacheKey,
      stalePeriod: const Duration(days: 1),
      maxNrOfCacheObjects: 1,
      repo: JsonCacheInfoRepository(databaseName: CacheConstants.countriesApiCacheKey),
      fileService: HttpFileService(),
    ),
  );
}
```

### 8.4 FlagImage Widget with Caching

```dart
// lib/presentation/widgets/flag_image.dart
class FlagImage extends StatelessWidget {
  final String url;
  final double width;

  const FlagImage({super.key, required this.url, this.width = 320});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: CacheService.flagImageCache,
      width: width,
      fit: BoxFit.cover,
      placeholder: (context, url) => const SizedBox(
        width: 320,
        height: 213,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => const SizedBox(
        width: 320,
        height: 213,
        child: Center(child: Icon(Icons.broken_image, size: 48)),
      ),
    );
  }
}
```

### 8.5 API Response Caching

The REST Countries API response is cached for **7 days** using `DioCacheInterceptor`:

```dart
// lib/data/services/api_service.dart
final dio = Dio(BaseOptions(
  baseUrl: ApiConstants.baseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

// Add cache interceptor
dio.interceptors.add(DioCacheInterceptor(
  options: CacheOptions(
    store: MemCacheStore(), // or DbCacheStore / FileCacheStore for disk
    policy: CachePolicy.request,
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 7),
    priority: CachePriority.normal,
    cipher: null,
    keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    allowPostMethod: false,
  ),
));
```

### 8.6 Cache Invalidation

| Cache | Invalidation Trigger | Strategy |
|-------|---------------------|----------|
| Flag images | Never (flags don't change) | 30-day max age, LRU eviction at 250 items |
| Countries API | App update or 7-day expiry | 7-day max age, single-entry cache |
| Solved flags / Score | Never (user data) | Persisted in SharedPreferences, not cache |

### 8.7 Cache Management UI (Optional Future Enhancement)

A settings option to clear the flag image cache:

```dart
// In settings or debug menu
await CacheService.flagImageCache.emptyCache();
await CacheService.flagImageCache.removeAllFiles();
```

---

## 9. Repository

### 9.1 `CountryRepository`

```dart
class CountryRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  CountryRepository(this._apiService, this._storageService);

  /// Fetch all countries from API.
  Future<List<Country>> fetchAllCountries() => _apiService.fetchAllCountries();

  /// Return countries whose ISO code is NOT in the solved set.
  Future<List<Country>> getUnsolvedCountries() async {
    final all = await fetchAllCountries();
    final solved = await _storageService.getSolvedFlags();
    return all.where((c) => !solved.contains(c.isoCode)).toList();
  }

  /// Pick a random correct country + 3 random distractors.
  /// Returns a `Question` object with shuffled options.
  Future<Question> generateQuestion() async {
    final pool = await getUnsolvedCountries();
    if (pool.length < 4) throw NotEnoughCountriesException();

    final correct = pool.random();
    final distractors = (pool..remove(correct)).sample(3);
    return Question(
      correct: correct,
      options: [correct, ...distractors]..shuffle(),
    );
  }
}
```

### 9.2 `Question` (value object)

```dartclass Question {
  final Country correct;
  final List<Country> options; // always length 4, shuffled

  const Question({required this.correct, required this.options});
}
```

---

## 10. ViewModel — `TriviaViewModel`

This is the heart of the MVVM layer. It is a `ChangeNotifier` provided at the top of the widget tree.

### 10.1 State Fields

| Field | Type | Description |
|-------|------|-------------|
| `_gameState` | `GameState` | `loading`, `playing`, `revealed` |
| `_currentQuestion` | `Question?` | Current flag + options |
| `_attemptsMade` | `int` | 0–3, incremented on wrong answers |
| `_score` | `int` | Running total, persisted on change |
| `_solvedFlags` | `Set<String>` | Cache of solved ISO codes |
| `_feedbackMessage` | `String?` | "Correct! +10" / "Wrong, try again" / "The answer was X" |

### 10.2 Key Methods

| Method | Logic |
|--------|-------|
| `initialize()` | Load storage (score + solved flags), fetch countries, generate first question |
| `submitAnswer(Country selected)` | Compare `selected.isoCode == currentQuestion.correct.isoCode`. If correct → award points, persist score, mark solved, state → `revealed`. If wrong → increment attempts; if attempts == 3 → state → `revealed` with correct answer shown; else stay in `playing` |
| `loadNextQuestion()` | Reset attempts, generate next question, state → `playing` |
| `pointsForAttempt(int attempts)` | Returns `[10, 8, 5][attempts - 1]` or 0 if > 3 |

### 10.3 Scoring Logic

```dart
// Points table (1-indexed attempt number)
static const List<int> pointsTable = [10, 8, 5];

int pointsForAttempt(int attemptNumber) {
  if (attemptNumber < 1 || attemptNumber > pointsTable.length) return 0;
  return pointsTable[attemptNumber - 1];
}
```

### 10.4 Answer Submission Flow

```
submitAnswer(selected)
  │
  ├─ selected == correct?
  │    ├─ YES → award pointsForAttempt(attemptsMade + 1)
  │    │        save score to prefs
  │    │        add correct.isoCode to solvedFlags → save to prefs
  │    │        feedback = "Correct! +N points"
  │    │        gameState = revealed
  │    │
  │    └─ NO → attemptsMade++
  │             attemptsMade == 3?
  │               ├─ YES → feedback = "The answer was {correct.name}"
  │               │        gameState = revealed
  │               └─ NO  → feedback = "Wrong! Try again"
  │                        gameState = playing
```

### 10.5 Persistence on Every Change

- Score and solved flags are written to SharedPreferences **immediately** when they change (not batched), so the app can be killed at any point without data loss.

---

## 11. UI / Presentation Layer

### 11.1 Screen Layout (`TriviaScreen`)

```
┌──────────────────────────────────┐
│  ScoreBoard (AppBar)             │  ← Score: 120 | Solved: 15/195
├──────────────────────────────────┤
│                                  │
│        ┌──────────────┐          │
│        │              │          │
│        │  Flag Image  │          │  ← 320px wide, rounded corners
│        │              │          │
│        └──────────────┘          │
│                                  │
│   "Which country does this       │
│        flag belong to?"          │
│                                  │
│   Attempts: ● ● ○                │  ← 3 dots, filled = used
│                                  │
│   ┌──────────┐  ┌──────────┐    │
│   │ Option A │  │ Option B │    │  ← 2×2 grid of country cards
│   └──────────┘  └──────────┘    │
│   ┌──────────┐  ┌──────────┐    │
│   │ Option C │  │ Option D │    │
│   └──────────┘  └──────────┘    │
│                                  │
│   ┌──────────────────────────┐   │
│   │   Result Banner          │   │  ← Shown when gameState == revealed
│   │   "Correct! +10"         │   │     or "The answer was Germany"
│   │   [Next Flag →]           │   │
│   └──────────────────────────┘   │
└──────────────────────────────────┘
```

### 11.2 Widget Responsibilities

| Widget | Responsibility |
|--------|---------------|
| `ScoreBoard` | Displays current score and solved count in the AppBar |
| `FlagImage` | Loads flag from URL with `CachedNetworkImage` (disk + memory cache), shows loading spinner + error placeholder |
| `CountryOptionCard` | A tappable card showing a country name; changes color on correct/wrong selection |
| `AttemptsIndicator` | Row of 3 dots showing remaining attempts |
| `ResultBanner` | Overlay/banner shown when the question is resolved; includes "Next" button |

### 11.3 State-Driven UI Behavior

| `GameState` | UI Behavior |
|-------------|-------------|
| `loading` | Show `CircularProgressIndicator` centered |
| `playing` | Flag + 4 options visible, all tappable |
| `revealed` | Correct option highlighted green, wrong selection highlighted red (if any), result banner shown, "Next Flag" button enabled |

---

## 12. Dependencies (`pubspec.yaml`)

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.2 | State management (ChangeNotifier) |
| `dio` | ^5.7.0 | HTTP client for REST Countries API |
| `shared_preferences` | ^2.3.3 | Persist score + solved flags |
| `cached_network_image` | ^3.4.1 | Efficient flag image loading + disk/memory caching |
| `flutter_cache_manager` | ^3.4.1 | Disk cache manager backing `CachedNetworkImage` |

---

## 13. Persistence Schema (SharedPreferences)

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `total_points` | `int` | `120` | Cumulative score across all sessions |
| `solved_flags` | `String` (JSON array) | `["DE","FR","JP","BR"]` | ISO codes of all solved flags |

---

## 14. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| No internet on first launch | Show error state with "Retry" button; do not crash |
| All countries solved | Show "Congratulations! You've solved all flags." with final score + "Play Again" (resets solved set) |
| Fewer than 4 unsolved countries | Use whatever is available; if 0, trigger "all solved" screen |
| Flag image fails to load | Show placeholder icon; still allow answering |
| API returns malformed country | Skip that entry, log warning |
| App killed mid-question | Score and solved flags already persisted; on restart, current question is discarded and a new one generated |

---

## 15. Testing Strategy

### 15.1 Unit Tests (`test/unit/`)

| Test File | What's Tested |
|-----------|--------------|
| `trivia_viewmodel_test.dart` | Scoring logic (10/8/5/0), attempt tracking, answer submission flow, solved-flag tracking |
| `country_repository_test.dart` | Question generation (correct + 3 distractors, all unique, shuffled), unsolved filtering |

### 15.2 Widget Tests (`test/widget/`)

| Test File | What's Tested |
|-----------|--------------|
| `trivia_screen_test.dart` | Loading state, option tap → correct/wrong flow, result banner appearance, next question loading |

### 15.3 Test Approach

- Use `mocktail` or `mockito` to mock `ApiService` and `StorageService`.
- Test the ViewModel in isolation with mocked repositories.
- Widget tests use `Provider<TriviaViewModel>.value` with a pre-configured ViewModel.

---

## 16. Implementation Phases

### Phase 1 — Foundation
1. Add dependencies to `pubspec.yaml`
2. Create `core/constants/api_constants.dart`
3. Create `core/enums/game_state.dart`
4. Create `data/models/country.dart`

### Phase 2 — Data Layer
5. Implement `ApiService` (Dio-based, with `DioCacheInterceptor` for API response caching)
6. Implement `StorageService` (SharedPreferences wrapper)
7. Implement `CacheService` (CacheManager instances for flags + API)
8. Implement `CountryRepository` (fetch, filter, generate questions)

### Phase 3 — ViewModel
9. Implement `TriviaViewModel` with full game logic
10. Wire up persistence calls

### Phase 4 — UI
11. Create `FlagImage` (with `CachedNetworkImage` + `CacheService`), `CountryOptionCard`, `ScoreBoard`, `AttemptsIndicator`, `ResultBanner` widgets
12. Build `TriviaScreen` composing all widgets
13. Set up `MultiProvider` in `app.dart` / `main.dart`

### Phase 5 — Polish & Testing
14. Write unit tests for ViewModel and Repository
15. Write widget tests for TriviaScreen
16. Add error states, loading states, empty states
17. Final integration test on device/emulator

---

## 17. File-by-File Implementation Checklist

- [ ] `pubspec.yaml` — add `provider`, `dio`, `shared_preferences`, `cached_network_image`, `flutter_cache_manager`
- [ ] `lib/core/constants/api_constants.dart` — API URLs, pref keys
- [ ] `lib/core/constants/cache_constants.dart` — Cache keys, max age, max objects
- [ ] `lib/core/enums/game_state.dart` — `enum GameState { loading, playing, revealed }`
- [ ] `lib/data/models/country.dart` — `Country` model with `fromJson`, `flagUrl`
- [ ] `lib/data/services/api_service.dart` — Dio HTTP client
- [ ] `lib/data/services/storage_service.dart` — SharedPreferences wrapper
- [ ] `lib/data/services/cache_service.dart` — CacheManager instances for flags + API
- [ ] `lib/data/repositories/country_repository.dart` — fetch, filter, generate `Question`
- [ ] `lib/presentation/viewmodels/trivia_viewmodel.dart` — game logic + `ChangeNotifier`
- [ ] `lib/presentation/widgets/flag_image.dart` — cached network image
- [ ] `lib/presentation/widgets/country_option_card.dart` — answer button
- [ ] `lib/presentation/widgets/score_board.dart` — score display
- [ ] `lib/presentation/widgets/attempts_indicator.dart` — dots for remaining tries
- [ ] `lib/presentation/widgets/result_banner.dart` — result + next button
- [ ] `lib/presentation/screens/trivia_screen.dart` — main screen
- [ ] `lib/app.dart` — `MaterialApp` + `MultiProvider`
- [ ] `lib/main.dart` — `runApp(const CountryTriviaApp())`
- [ ] `test/unit/trivia_viewmodel_test.dart`
- [ ] `test/unit/country_repository_test.dart`
- [ ] `test/widget/trivia_screen_test.dart`

---

## 18. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Dio over `http`** | Better error handling, interceptors, request cancellation |
| **CachedNetworkImage for flags** | Flags are reused across sessions; caching avoids redundant network calls |
| **flutter_cache_manager backing store** | Provides persistent disk cache with LRU eviction and configurable max age |
| **DioCacheInterceptor for API** | Caches REST Countries JSON for 7 days, reducing API calls on app restart |
| **30-day flag cache max age** | Flags never change; long cache age with 250-item LRU cap balances storage vs. performance |
| **Immediate persistence** | Write to SharedPreferences on every score/solved change — no data loss on kill |
| **Repository pattern** | Separates data concerns from ViewModel; makes testing easy with mocks |
| **ChangeNotifier (not Bloc/Riverpod)** | Simplest Provider-compatible approach; sufficient for this app's complexity |
| **Shuffle options at generation time** | Prevents the correct answer always being in the same position |
| **ISO code as unique identifier** | Stable across API changes; directly maps to flagcdn URL |

---

## 19. Ticket Breakdown

### Phase 1 — Foundation

| Ticket | Title | Description | Dependencies |
|--------|-------|-------------|--------------|
| TICKET-001 | Add project dependencies | Add `provider`, `dio`, `shared_preferences`, `cached_network_image`, `flutter_cache_manager` to `pubspec.yaml` and run `flutter pub get` | None |
| TICKET-002 | Create `GameState` enum | Create `lib/core/enums/game_state.dart` with `enum GameState { loading, playing, revealed }` | None |
| TICKET-003 | Create `api_constants.dart` | Create `lib/core/constants/api_constants.dart` with REST Countries URL, flagcdn URL template, and SharedPreferences key names | None |
| TICKET-004 | Create `cache_constants.dart` | Create `lib/core/constants/cache_constants.dart` with cache keys, max age durations, and max object counts | None |
| TICKET-005 | Create `Country` model | Create `lib/data/models/country.dart` with `fromJson` factory and `flagUrl` getter | None |

### Phase 2 — Data Layer

| Ticket | Title | Description | Dependencies |
|--------|-------|-------------|--------------|
| TICKET-006 | Implement `StorageService` | Create `lib/data/services/storage_service.dart` — SharedPreferences wrapper with `getSolvedFlags`, `addSolvedFlag`, `getScore`, `saveScore` | TICKET-003 |
| TICKET-007 | Implement `CacheService` | Create `lib/data/services/cache_service.dart` — `CacheManager` instances for flag images (30-day, 250 items) and API response (7-day, 1 item) | TICKET-001, TICKET-004 |
| TICKET-008 | Implement `ApiService` | Create `lib/data/services/api_service.dart` — Dio HTTP client with `DioCacheInterceptor`, `fetchAllCountries()` method, error handling, response parsing | TICKET-001, TICKET-003, TICKET-004 |
| TICKET-009 | Implement `CountryRepository` | Create `lib/data/repositories/country_repository.dart` — `fetchAllCountries`, `getUnsolvedCountries`, `generateQuestion` | TICKET-005, TICKET-006, TICKET-008 |

### Phase 3 — ViewModel

| Ticket | Title | Description | Dependencies |
|--------|-------|-------------|--------------|
| TICKET-010 | Implement `TriviaViewModel` | Create `lib/presentation/viewmodels/trivia_viewmodel.dart` — `ChangeNotifier` with all game logic: `initialize`, `submitAnswer`, `loadNextQuestion`, `pointsForAttempt`, persistence calls | TICKET-002, TICKET-009 |

### Phase 4 — UI

| Ticket | Title | Description | Dependencies |
|--------|-------|-------------|--------------|
| TICKET-011 | Create `FlagImage` widget | Create `lib/presentation/widgets/flag_image.dart` — `CachedNetworkImage` with `CacheService.flagImageCache`, placeholder, error widget. **Verify:** `flutter run` on emulator completes without errors before PR | TICKET-007 |
| TICKET-012 | Create `CountryOptionCard` widget | Create `lib/presentation/widgets/country_option_card.dart` — tappable card with correct/wrong state styling. **Verify:** `flutter run` on emulator completes without errors before PR | TICKET-002 |
| TICKET-013 | Create `ScoreBoard` widget | Create `lib/presentation/widgets/score_board.dart` — AppBar widget showing score and solved count. **Verify:** `flutter run` on emulator completes without errors before PR | None |
| TICKET-014 | Create `AttemptsIndicator` widget | Create `lib/presentation/widgets/attempts_indicator.dart` — row of 3 dots showing remaining attempts. **Verify:** `flutter run` on emulator completes without errors before PR | None |
| TICKET-015 | Create `ResultBanner` widget | Create `lib/presentation/widgets/result_banner.dart` — result message + "Next Flag" button. **Verify:** `flutter run` on emulator completes without errors before PR | TICKET-002 |
| TICKET-016 | Build `TriviaScreen` | Create `lib/presentation/screens/trivia_screen.dart` — compose all widgets, wire to `TriviaViewModel` via Provider. **Verify:** `flutter run` on emulator completes without errors before PR | TICKET-010, TICKET-011, TICKET-012, TICKET-013, TICKET-014, TICKET-015 |
| TICKET-017 | Set up `app.dart` and `main.dart` | Create `lib/app.dart` with `MaterialApp` + `MultiProvider`, update `lib/main.dart` entry point. **Verify:** `flutter run` on emulator completes without errors before PR | TICKET-016 |

### Phase 5 — Testing & Polish

| Ticket | Title | Description | Dependencies |
|--------|-------|-------------|--------------|
| TICKET-018 | Write ViewModel unit tests | Create `test/unit/trivia_viewmodel_test.dart` — scoring logic, attempt tracking, answer flow, solved-flag tracking | TICKET-010 |
| TICKET-019 | Write Repository unit tests | Create `test/unit/country_repository_test.dart` — question generation, unsolved filtering | TICKET-009 |
| TICKET-020 | Write Widget tests | Create `test/widget/trivia_screen_test.dart` — loading state, tap flows, result banner, next question | TICKET-016 |
| TICKET-021 | Add error/empty/loading states | Handle edge cases: no internet, all solved, < 4 countries, flag load failure | TICKET-016 |
| TICKET-022 | Final integration test | Run full test suite on device/emulator, verify end-to-end flow | TICKET-017, TICKET-018, TICKET-019, TICKET-020, TICKET-021 |

---

## 20. Parallel Execution Groups

The following groups contain tickets that have **no dependencies on each other** and can be executed in parallel:

### Group A — Foundation (all independent)
```
TICKET-001  TICKET-002  TICKET-003  TICKET-004  TICKET-005
```
All five foundation tickets can be created simultaneously — they only depend on the existing project scaffold.

### Group B — Data Layer Services (parallel after Group A)
```
TICKET-006  TICKET-007  TICKET-008
```
`StorageService`, `CacheService`, and `ApiService` are independent of each other. All depend only on Group A outputs.

### Group C — UI Widgets (parallel after Group A)
```
TICKET-011  TICKET-012  TICKET-013  TICKET-014  TICKET-015
```
All five widget files are independent of each other. `FlagImage` depends on TICKET-007 (Group B), the rest depend only on Group A.

### Group D — Tests (parallel after implementation)
```
TICKET-018  TICKET-019  TICKET-020  TICKET-021
```
All four testing/polish tickets are independent of each other (each depends on its corresponding implementation ticket, not on each other).

---

## 21. Execution Order (Dependency-Respecting)

```
Wave 1 (Parallel):  TICKET-001  TICKET-002  TICKET-003  TICKET-004  TICKET-005
                            │
                            ▼
Wave 2 (Parallel):  TICKET-006  TICKET-007  TICKET-008
                            │
                            ▼
Wave 3 (Serial):    TICKET-009  (depends on 005 + 006 + 008)
                            │
                            ▼
Wave 4 (Serial):    TICKET-010  (depends on 002 + 009)
                            │
                            ▼
Wave 5 (Parallel):  TICKET-011  TICKET-012  TICKET-013  TICKET-014  TICKET-015
                            │
                            ▼
Wave 6 (Serial):    TICKET-016  (depends on 010 + 011-015)
                            │
                            ▼
Wave 7 (Serial):    TICKET-017  (depends on 016)
                            │
                            ▼
Wave 8 (Parallel):  TICKET-018  TICKET-019  TICKET-020  TICKET-021
                            │
                            ▼
Wave 9 (Serial):    TICKET-022  (depends on 017 + 018-021)
```

### Summary

| Wave | Tickets | Execution | Count |
|------|---------|-----------|-------|
| 1 | 001, 002, 003, 004, 005 | Parallel | 5 |
| 2 | 006, 007, 008 | Parallel | 3 |
| 3 | 009 | Serial | 1 |
| 4 | 010 | Serial | 1 |
| 5 | 011, 012, 013, 014, 015 | Parallel | 5 |
| 6 | 016 | Serial | 1 |
| 7 | 017 | Serial | 1 |
| 8 | 018, 019, 020, 021 | Parallel | 4 |
| 9 | 022 | Serial | 1 |

**Critical path:** TICKET-001 → TICKET-007 → TICKET-009 → TICKET-010 → TICKET-016 → TICKET-017 → TICKET-022 (7 tickets)

**Maximum parallelism:** 5 tickets simultaneously (Wave 1 and Wave 5)
