import 'dart:math';

import '../models/country.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// A trivia question consisting of a correct answer and 4 shuffled options.
class Question {
  /// The correct country for the displayed flag.
  final Country correct;

  /// The 4 answer options (1 correct + 3 distractors), shuffled.
  final List<Country> options;

  const Question({required this.correct, required this.options});
}

/// Thrown when there are not enough unsolved countries to generate a question.
class NotEnoughCountriesException implements Exception {
  final String message;
  const NotEnoughCountriesException([this.message = 'Not enough countries to generate a question']);
  @override
  String toString() => 'NotEnoughCountriesException: $message';
}

/// Combines API data and local storage to generate trivia questions.
class CountryRepository {
  final ApiService _apiService;
  final StorageService _storageService;
  final Random _random;

  CountryRepository(
    this._apiService,
    this._storageService, {
    Random? random,
  }) : _random = random ?? Random();

  /// Fetches all countries from the API.
  Future<List<Country>> fetchAllCountries() => _apiService.fetchAllCountries();

  /// Returns countries whose ISO code is NOT in the solved set.
  Future<List<Country>> getUnsolvedCountries() async {
    final all = await fetchAllCountries();
    final solved = await _storageService.getSolvedFlags();
    return all.where((c) => !solved.contains(c.isoCode)).toList();
  }

  /// Picks a random correct country + 3 random distractors.
  /// Returns a [Question] with shuffled options.
  Future<Question> generateQuestion() async {
    final pool = await getUnsolvedCountries();
    if (pool.length < 4) {
      throw NotEnoughCountriesException();
    }

    final correct = pool[_random.nextInt(pool.length)];
    final distractors = _sampleDistractors(pool, correct, 3);

    return Question(
      correct: correct,
      options: [correct, ...distractors]..shuffle(_random),
    );
  }

  /// Samples [count] unique distractors from [pool], excluding [correct].
  List<Country> _sampleDistractors(List<Country> pool, Country correct, int count) {
    final candidates = List<Country>.from(pool)..remove(correct);
    candidates.shuffle(_random);
    return candidates.take(count).toList();
  }
}
