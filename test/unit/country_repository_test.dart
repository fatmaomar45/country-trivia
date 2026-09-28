import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/data/models/country.dart';
import 'package:country_trivia/data/repositories/country_repository.dart';
import 'package:country_trivia/data/services/api_service.dart';
import 'package:country_trivia/data/services/storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  late CountryRepository repository;
  late MockApiService mockApiService;
  late MockStorageService mockStorageService;

  final testCountries = [
    const Country(name: 'Germany', isoCode: 'DE'),
    const Country(name: 'France', isoCode: 'FR'),
    const Country(name: 'Japan', isoCode: 'JP'),
    const Country(name: 'Brazil', isoCode: 'BR'),
    const Country(name: 'Canada', isoCode: 'CA'),
    const Country(name: 'Australia', isoCode: 'AU'),
    const Country(name: 'India', isoCode: 'IN'),
    const Country(name: 'Mexico', isoCode: 'MX'),
  ];

  setUp(() {
    mockApiService = MockApiService();
    mockStorageService = MockStorageService();
    repository = CountryRepository(
      mockApiService,
      mockStorageService,
      random: Random(42), // seeded for deterministic tests
    );
  });

  group('CountryRepository', () {
    test('fetchAllCountries delegates to api service', () async {
      when(() => mockApiService.fetchAllCountries())
          .thenAnswer((_) async => testCountries);

      final result = await repository.fetchAllCountries();

      expect(result, testCountries);
      verify(() => mockApiService.fetchAllCountries()).called(1);
    });

    test('getUnsolvedCountries filters out solved flags', () async {
      when(() => mockApiService.fetchAllCountries())
          .thenAnswer((_) async => testCountries);
      when(() => mockStorageService.getSolvedFlags())
          .thenAnswer((_) async => {'DE', 'FR'});

      final result = await repository.getUnsolvedCountries();

      expect(result.length, 6);
      expect(result.any((c) => c.isoCode == 'DE'), false);
      expect(result.any((c) => c.isoCode == 'FR'), false);
      expect(result.any((c) => c.isoCode == 'JP'), true);
    });

    test('generateQuestion returns correct + 3 distractors', () async {
      when(() => mockApiService.fetchAllCountries())
          .thenAnswer((_) async => testCountries);
      when(() => mockStorageService.getSolvedFlags())
          .thenAnswer((_) async => {});

      final question = await repository.generateQuestion();

      expect(question.options.length, 4);
      expect(question.correct, isA<Country>());
      // All options should be unique
      final isoCodes = question.options.map((c) => c.isoCode).toSet();
      expect(isoCodes.length, 4);
      // Correct answer should be in options
      expect(question.options.any((c) => c.isoCode == question.correct.isoCode), true);
    });

    test('generateQuestion throws NotEnoughCountriesException when < 4 countries', () async {
      when(() => mockApiService.fetchAllCountries())
          .thenAnswer((_) async => testCountries.take(3).toList());
      when(() => mockStorageService.getSolvedFlags())
          .thenAnswer((_) async => {});

      expect(
        () => repository.generateQuestion(),
        throwsA(isA<NotEnoughCountriesException>()),
      );
    });

    test('generateQuestion throws when all countries are solved', () async {
      when(() => mockApiService.fetchAllCountries())
          .thenAnswer((_) async => testCountries);
      when(() => mockStorageService.getSolvedFlags())
          .thenAnswer((_) async => testCountries.map((c) => c.isoCode).toSet());

      expect(
        () => repository.generateQuestion(),
        throwsA(isA<NotEnoughCountriesException>()),
      );
    });
  });
}
