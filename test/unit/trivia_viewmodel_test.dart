import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/core/enums/game_state.dart';
import 'package:country_trivia/data/models/country.dart';
import 'package:country_trivia/data/repositories/country_repository.dart';
import 'package:country_trivia/data/services/storage_service.dart';
import 'package:country_trivia/presentation/viewmodels/trivia_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

class MockCountryRepository extends Mock implements CountryRepository {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  late TriviaViewModel viewModel;
  late MockCountryRepository mockRepository;
  late MockStorageService mockStorage;

  final testCountries = [
    const Country(name: 'Germany', isoCode: 'DE'),
    const Country(name: 'France', isoCode: 'FR'),
    const Country(name: 'Japan', isoCode: 'JP'),
    const Country(name: 'Brazil', isoCode: 'BR'),
    const Country(name: 'Canada', isoCode: 'CA'),
  ];

  setUp(() {
    mockRepository = MockCountryRepository();
    mockStorage = MockStorageService();
    viewModel = TriviaViewModel(
      repository: mockRepository,
      storageService: mockStorage,
    );
  });

  group('TriviaViewModel', () {
    test('initial state is loading', () {
      expect(viewModel.gameState, GameState.loading);
      expect(viewModel.score, 0);
      expect(viewModel.attemptsMade, 0);
      expect(viewModel.currentQuestion, isNull);
    });

    test('pointsForAttempt returns correct values', () {
      expect(viewModel.pointsForAttempt(1), 10);
      expect(viewModel.pointsForAttempt(2), 8);
      expect(viewModel.pointsForAttempt(3), 5);
      expect(viewModel.pointsForAttempt(0), 0);
      expect(viewModel.pointsForAttempt(4), 0);
    });

    test('initialize loads score and solved flags from storage', () async {
      when(() => mockStorage.getScore()).thenAnswer((_) async => 50);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {'DE'});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });

      await viewModel.initialize();

      expect(viewModel.score, 50);
      expect(viewModel.solvedFlags, {'DE'});
      expect(viewModel.gameState, GameState.playing);
      expect(viewModel.currentQuestion, isNotNull);
    });

    test('correct answer on first try awards 10 points', () async {
      when(() => mockStorage.getScore()).thenAnswer((_) async => 0);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });
      when(() => mockStorage.saveScore(any())).thenAnswer((_) async {});
      when(() => mockStorage.addSolvedFlag(any())).thenAnswer((_) async {});

      await viewModel.initialize();
      await viewModel.submitAnswer(testCountries[0]);

      expect(viewModel.score, 10);
      expect(viewModel.gameState, GameState.revealed);
      expect(viewModel.isLastAnswerCorrect, true);
      expect(viewModel.feedbackMessage, 'Correct! +10 points');
    });

    test('correct answer on second try awards 8 points', () async {
      when(() => mockStorage.getScore()).thenAnswer((_) async => 0);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });
      when(() => mockStorage.saveScore(any())).thenAnswer((_) async {});
      when(() => mockStorage.addSolvedFlag(any())).thenAnswer((_) async {});

      await viewModel.initialize();
      await viewModel.submitAnswer(testCountries[1]); // wrong
      await viewModel.submitAnswer(testCountries[0]); // correct

      expect(viewModel.score, 8);
      expect(viewModel.gameState, GameState.revealed);
      expect(viewModel.isLastAnswerCorrect, true);
    });

    test('correct answer on third try awards 5 points', () async {
      when(() => mockStorage.getScore()).thenAnswer((_) async => 0);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });
      when(() => mockStorage.saveScore(any())).thenAnswer((_) async {});
      when(() => mockStorage.addSolvedFlag(any())).thenAnswer((_) async {});

      await viewModel.initialize();
      await viewModel.submitAnswer(testCountries[1]); // wrong
      await viewModel.submitAnswer(testCountries[2]); // wrong
      await viewModel.submitAnswer(testCountries[0]); // correct

      expect(viewModel.score, 5);
      expect(viewModel.gameState, GameState.revealed);
    });

    test('exhausting all attempts reveals correct answer with 0 points', () async {
      when(() => mockStorage.getScore()).thenAnswer((_) async => 0);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });

      await viewModel.initialize();
      await viewModel.submitAnswer(testCountries[1]); // wrong
      await viewModel.submitAnswer(testCountries[2]); // wrong
      await viewModel.submitAnswer(testCountries[3]); // wrong

      expect(viewModel.score, 0);
      expect(viewModel.gameState, GameState.revealed);
      expect(viewModel.isLastAnswerCorrect, false);
      expect(viewModel.feedbackMessage, 'The answer was Germany');
    });

    test('loadNextQuestion resets attempts and generates new question', () async {
      when(() => mockStorage.getScore()).thenAnswer((_) async => 0);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });

      await viewModel.initialize();
      await viewModel.submitAnswer(testCountries[1]); // wrong, attempts = 1
      await viewModel.loadNextQuestion();

      expect(viewModel.attemptsMade, 0);
      expect(viewModel.gameState, GameState.playing);
    });
  });
}
