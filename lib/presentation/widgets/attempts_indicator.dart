import 'package:flutter/material.dart';

/// A row of dots showing remaining attempts.
///
/// Filled dots represent remaining attempts, empty dots represent used attempts.
class AttemptsIndicator extends StatelessWidget {
  /// The number of attempts made so far (0-3).
  final int attemptsMade;

  /// The maximum number of attempts allowed.
  final int maxAttempts;

  const AttemptsIndicator({
    super.key,
    required this.attemptsMade,
    this.maxAttempts = 3,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = maxAttempts - attemptsMade;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxAttempts, (index) {
        final isRemaining = index < remaining;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            isRemaining ? Icons.circle : Icons.circle_outlined,
            size: 16,
            color: isRemaining
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        );
      }),
    );
  }
}
