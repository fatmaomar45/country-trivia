import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/cache_constants.dart';
import '../models/country.dart';

/// HTTP client for the REST Countries API.
///
/// Uses Dio with a cache interceptor to avoid redundant network requests.
class ApiService {
  final Dio _dio;

  ApiService({Dio? dio}) : _dio = dio ?? _createDio();

  /// Creates a pre-configured Dio instance with caching.
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(
          store: MemCacheStore(),
          policy: CachePolicy.request,
          hitCacheOnErrorExcept: [401, 403],
          maxStale: CacheConstants.countriesApiMaxAge,
          priority: CachePriority.normal,
          keyBuilder: CacheOptions.defaultCacheKeyBuilder,
          allowPostMethod: false,
        ),
      ),
    );

    return dio;
  }

  /// Fetches all countries with their name and ISO alpha-2 code.
  ///
  /// Returns a list of [Country] objects. Malformed entries are skipped.
  Future<List<Country>> fetchAllCountries() async {
    final response = await _dio.get(ApiConstants.allCountriesEndpoint);

    if (response.data is! List) {
      throw Exception('Unexpected API response format');
    }

    final countries = <Country>[];
    for (final item in response.data as List) {
      try {
        countries.add(Country.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries
        continue;
      }
    }

    return countries;
  }
}
