import 'package:flutter/material.dart';

/// A banner shown when a question is resolved.
///
/// Displays the result message and a "Next Flag" button.
class ResultBanner extends StatelessWidget {
  /// The result message to display.
  final String message;

  /// Whether the user's last answer was correct.
  final bool isCorrect;

  /// Callback when the "Next Flag" button is pressed.
  final VoidCallback onNext;

  const ResultBanner({
    super.key,
    required this.message,
    required this.isCorrect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.orange,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.info,
            color: isCorrect ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isCorrect ? Colors.green.shade900 : Colors.orange.shade900,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next Flag'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCorrect ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
