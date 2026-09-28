import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/services/cache_service.dart';

/// Displays a flag image loaded from the network with disk caching.
///
/// Shows a loading spinner while fetching and a placeholder icon on error.
class FlagImage extends StatelessWidget {
  /// The URL of the flag image to display.
  final String url;

  /// The width of the image (defaults to 320).
  final double width;

  const FlagImage({super.key, required this.url, this.width = 320});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        cacheManager: CacheService.flagImageCache,
        width: width,
        height: width * 0.67, // ~3:2 aspect ratio for most flags
        fit: BoxFit.cover,
        placeholder: (context, url) => SizedBox(
          width: width,
          height: width * 0.67,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => SizedBox(
          width: width,
          height: width * 0.67,
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
