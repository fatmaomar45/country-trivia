import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:country_trivia/core/enums/game_state.dart';
import 'package:country_trivia/data/models/country.dart';
import 'package:country_trivia/data/repositories/country_repository.dart';
import 'package:country_trivia/data/services/storage_service.dart';
import 'package:country_trivia/presentation/screens/trivia_screen.dart';
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

  Widget createTestApp() {
    return ChangeNotifierProvider<TriviaViewModel>.value(
      value: viewModel,
      child: const MaterialApp(home: TriviaScreen()),
    );
  }

  group('Full Flow Integration', () {
    testWidgets('complete game flow: load → answer → next → answer', (tester) async {
      // Setup mocks
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

      // Start the app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(viewModel.gameState, GameState.playing);
      expect(viewModel.score, 0);
      expect(viewModel.attemptsMade, 0);

      // Answer correctly on first try
      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();

      // Verify correct answer state
      expect(viewModel.gameState, GameState.revealed);
      expect(viewModel.score, 10);
      expect(viewModel.isLastAnswerCorrect, true);
      expect(find.text('Correct! +10 points'), findsOneWidget);

      // Load next question
      await tester.tap(find.text('Next Flag'));
      await tester.pumpAndSettle();

      // Verify reset state
      expect(viewModel.gameState, GameState.playing);
      expect(viewModel.attemptsMade, 0);
      expect(viewModel.score, 10); // Score persists

      // Answer wrong on first try
      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();

      // Verify wrong answer state
      expect(viewModel.gameState, GameState.playing);
      expect(viewModel.attemptsMade, 1);
      expect(find.text('Wrong! Try again'), findsOneWidget);

      // Answer correctly on second try
      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();

      // Verify correct answer on second try
      expect(viewModel.gameState, GameState.revealed);
      expect(viewModel.score, 18); // 10 + 8
      expect(viewModel.isLastAnswerCorrect, true);
    });

    testWidgets('persistence: score and solved flags are saved', (tester) async {
      final savedScores = <int>[];
      final savedFlags = <String>[];

      when(() => mockStorage.getScore()).thenAnswer((_) async => 0);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });
      when(() => mockStorage.saveScore(any())).thenAnswer((invocation) async {
        savedScores.add(invocation.positionalArguments[0] as int);
      });
      when(() => mockStorage.addSolvedFlag(any())).thenAnswer((invocation) async {
        savedFlags.add(invocation.positionalArguments[0] as String);
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Answer correctly
      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();

      // Verify persistence calls
      expect(savedScores, [10]);
      expect(savedFlags, ['DE']);
    });

    testWidgets('all attempts exhausted reveals answer', (tester) async {
      when(() => mockStorage.getScore()).thenAnswer((_) async => 0);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Exhaust all attempts
      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Japan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brazil'));
      await tester.pumpAndSettle();

      // Verify final state
      expect(viewModel.gameState, GameState.revealed);
      expect(viewModel.score, 0);
      expect(viewModel.attemptsMade, 3);
      expect(find.text('The answer was Germany'), findsOneWidget);
    });
  });
}
