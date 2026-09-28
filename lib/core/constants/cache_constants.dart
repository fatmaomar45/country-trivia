/// Cache configuration constants used throughout the app.
class CacheConstants {
  CacheConstants._();

  // ── Flag Image Cache ────────────────────────────────────────────────

  /// Cache key for flag images stored via flutter_cache_manager.
  static const String flagImageCacheKey = 'flagImages';

  /// Maximum age for cached flag images (30 days — flags never change).
  static const Duration flagImageMaxAge = Duration(days: 30);

  /// Maximum number of flag images to keep in cache (~250 countries max).
  static const int flagImageMaxNrOfCacheObjects = 250;

  /// Stale period before a cached flag image is revalidated (7 days).
  static const Duration flagImageStalePeriod = Duration(days: 7);

  // ── Countries API Cache ─────────────────────────────────────────────

  /// Cache key for the REST Countries API response.
  static const String countriesApiCacheKey = 'countriesApi';

  /// Maximum age for the cached API response (7 days).
  static const Duration countriesApiMaxAge = Duration(days: 7);

  /// Stale period before the API cache is revalidated (1 day).
  static const Duration countriesApiStalePeriod = Duration(days: 1);

  /// Maximum number of API response objects to cache (single-entry cache).
  static const int countriesApiMaxNrOfCacheObjects = 1;
}
