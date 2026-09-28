import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../core/constants/cache_constants.dart';

/// Provides pre-configured [CacheManager] instances for flag images
/// and the REST Countries API response.
class CacheService {
  CacheService._();

  /// Cache manager for flag images.
  ///
  /// - 30-day max age (flags never change)
  /// - 250-item LRU cap (~250 countries max)
  /// - 7-day stale period before revalidation
  static CacheManager get flagImageCache => CacheManager(
        Config(
          CacheConstants.flagImageCacheKey,
          stalePeriod: CacheConstants.flagImageStalePeriod,
          maxNrOfCacheObjects: CacheConstants.flagImageMaxNrOfCacheObjects,
          repo: JsonCacheInfoRepository(
            databaseName: CacheConstants.flagImageCacheKey,
          ),
          fileService: HttpFileService(),
        ),
      );

  /// Cache manager for the REST Countries API response.
  ///
  /// - 7-day max age
  /// - Single-entry cache (one API response)
  /// - 1-day stale period before revalidation
  static CacheManager get countriesApiCache => CacheManager(
        Config(
          CacheConstants.countriesApiCacheKey,
          stalePeriod: CacheConstants.countriesApiStalePeriod,
          maxNrOfCacheObjects: CacheConstants.countriesApiMaxNrOfCacheObjects,
          repo: JsonCacheInfoRepository(
            databaseName: CacheConstants.countriesApiCacheKey,
          ),
          fileService: HttpFileService(),
        ),
      );
}
