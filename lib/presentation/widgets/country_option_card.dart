import 'package:flutter/material.dart';

import '../../core/enums/game_state.dart';
import '../../data/models/country.dart';

/// A tappable card displaying a country name as an answer option.
///
/// Changes appearance based on selection state and correctness.
class CountryOptionCard extends StatelessWidget {
  /// The country to display.
  final Country country;

  /// Whether this card is currently selected.
  final bool isSelected;

  /// Whether this card is the correct answer.
  final bool isCorrect;

  /// The current game state.
  final GameState gameState;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  const CountryOptionCard({
    super.key,
    required this.country,
    required this.isSelected,
    required this.isCorrect,
    required this.gameState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRevealed = gameState == GameState.revealed;

    Color backgroundColor = theme.colorScheme.surface;
    Color borderColor = theme.colorScheme.outline;
    Color textColor = theme.colorScheme.onSurface;

    if (isRevealed) {
      if (isCorrect) {
        backgroundColor = Colors.green.shade100;
        borderColor = Colors.green;
        textColor = Colors.green.shade900;
      } else if (isSelected) {
        backgroundColor = Colors.red.shade100;
        borderColor = Colors.red;
        textColor = Colors.red.shade900;
      }
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primaryContainer;
      borderColor = theme.colorScheme.primary;
    }

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: isRevealed ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  country.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isRevealed && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (isRevealed && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
