import 'package:flutter/foundation.dart';

import '../../core/enums/game_state.dart';
import '../../data/models/country.dart';
import '../../data/repositories/country_repository.dart';
import '../../data/services/storage_service.dart';

/// ViewModel that manages all game logic for the trivia app.
///
/// Provided via Provider at the top of the widget tree.
class TriviaViewModel extends ChangeNotifier {
  final CountryRepository _repository;
  final StorageService _storageService;

  TriviaViewModel({
    required CountryRepository repository,
    required StorageService storageService,
  })  : _repository = repository,
        _storageService = storageService;

  // ── State Fields ─────────────────────────────────────────────────────

  GameState _gameState = GameState.loading;
  GameState get gameState => _gameState;

  Question? _currentQuestion;
  Question? get currentQuestion => _currentQuestion;

  int _attemptsMade = 0;
  int get attemptsMade => _attemptsMade;

  int _score = 0;
  int get score => _score;

  Set<String> _solvedFlags = {};
  Set<String> get solvedFlags => _solvedFlags;

  String? _feedbackMessage;
  String? get feedbackMessage => _feedbackMessage;

  bool _isLastAnswerCorrect = false;
  bool get isLastAnswerCorrect => _isLastAnswerCorrect;

  // ── Points Table ─────────────────────────────────────────────────────

  static const List<int> pointsTable = [10, 8, 5];

  /// Returns the points for a given 1-indexed attempt number.
  /// Returns 0 if the attempt number is out of range.
  int pointsForAttempt(int attemptNumber) {
    if (attemptNumber < 1 || attemptNumber > pointsTable.length) return 0;
    return pointsTable[attemptNumber - 1];
  }

  // ── Initialization ───────────────────────────────────────────────────

  /// Loads persisted data and generates the first question.
  Future<void> initialize() async {
    _gameState = GameState.loading;
    notifyListeners();

    try {
      _score = await _storageService.getScore();
      _solvedFlags = await _storageService.getSolvedFlags();
      await _generateQuestion();
    } catch (e) {
      _feedbackMessage = 'Failed to load game data. Please try again.';
      _gameState = GameState.loading;
      notifyListeners();
    }
  }

  // ── Answer Submission ────────────────────────────────────────────────

  /// Submits an answer and updates game state accordingly.
  Future<void> submitAnswer(Country selected) async {
    if (_gameState != GameState.playing || _currentQuestion == null) return;

    final isCorrect = selected.isoCode == _currentQuestion!.correct.isoCode;

    if (isCorrect) {
      final points = pointsForAttempt(_attemptsMade + 1);
      _score += points;
      _isLastAnswerCorrect = true;
      _feedbackMessage = 'Correct! +$points points';

      // Persist score and solved flag immediately
      await _storageService.saveScore(_score);
      await _storageService.addSolvedFlag(_currentQuestion!.correct.isoCode);
      _solvedFlags = {..._solvedFlags, _currentQuestion!.correct.isoCode};

      _gameState = GameState.revealed;
    } else {
      _attemptsMade++;
      _isLastAnswerCorrect = false;

      if (_attemptsMade >= 3) {
        _feedbackMessage =
            'The answer was ${_currentQuestion!.correct.name}';
        _gameState = GameState.revealed;
      } else {
        _feedbackMessage = 'Wrong! Try again';
        // Stay in playing state
      }
    }

    notifyListeners();
  }

  // ── Next Question ────────────────────────────────────────────────────

  /// Loads the next question and resets attempt counter.
  Future<void> loadNextQuestion() async {
    _attemptsMade = 0;
    _isLastAnswerCorrect = false;
    _feedbackMessage = null;
    await _generateQuestion();
  }

  // ── Private Helpers ──────────────────────────────────────────────────

  Future<void> _generateQuestion() async {
    try {
      _currentQuestion = await _repository.generateQuestion();
      _gameState = GameState.playing;
    } catch (e) {
      _feedbackMessage = 'No more countries available!';
      _gameState = GameState.revealed;
    }
    notifyListeners();
  }
}
