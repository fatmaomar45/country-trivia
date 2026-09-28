import 'package:flutter/material.dart';

/// AppBar widget displaying the current score and solved count.
class ScoreBoard extends StatelessWidget implements PreferredSizeWidget {
  /// The user's current score.
  final int score;

  /// The number of solved flags.
  final int solvedCount;

  /// The total number of countries available.
  final int totalCount;

  const ScoreBoard({
    super.key,
    required this.score,
    required this.solvedCount,
    required this.totalCount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Country Trivia'),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag, size: 20),
              const SizedBox(width: 4),
              Text(
                '$solvedCount/$totalCount',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.stars, size: 20),
              const SizedBox(width: 4),
              Text(
                '$score',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
