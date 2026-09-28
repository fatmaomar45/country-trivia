import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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

  group('TriviaScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      when(() => mockStorage.getScore()).thenAnswer((_) async => 0);
      when(() => mockStorage.getSolvedFlags()).thenAnswer((_) async => {});
      when(() => mockRepository.generateQuestion()).thenAnswer((_) async {
        return Question(
          correct: testCountries[0],
          options: testCountries.take(4).toList(),
        );
      });

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows flag and options in playing state', (tester) async {
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

      expect(find.text('Which country does this flag belong to?'), findsOneWidget);
      expect(find.text('Germany'), findsOneWidget);
      expect(find.text('France'), findsOneWidget);
    });

    testWidgets('tapping correct answer shows result banner', (tester) async {
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

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();

      expect(find.text('Correct! +10 points'), findsOneWidget);
      expect(find.text('Next Flag'), findsOneWidget);
    });

    testWidgets('tapping wrong answer shows try again message', (tester) async {
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

      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();

      expect(find.text('Wrong! Try again'), findsOneWidget);
    });

    testWidgets('exhausting attempts shows correct answer', (tester) async {
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

      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Japan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brazil'));
      await tester.pumpAndSettle();

      expect(find.text('The answer was Germany'), findsOneWidget);
    });
  });
}
