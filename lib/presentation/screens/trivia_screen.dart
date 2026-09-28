import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/game_state.dart';
import '../viewmodels/trivia_viewmodel.dart';
import '../widgets/attempts_indicator.dart';
import '../widgets/country_option_card.dart';
import '../widgets/flag_image.dart';
import '../widgets/result_banner.dart';
import '../widgets/score_board.dart';

/// The main game screen that composes all trivia widgets.
class TriviaScreen extends StatelessWidget {
  const TriviaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TriviaViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: ScoreBoard(
            score: viewModel.score,
            solvedCount: viewModel.solvedFlags.length,
            totalCount: 195, // ~195 countries in the world
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(context, viewModel),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TriviaViewModel viewModel) {
    switch (viewModel.gameState) {
      case GameState.loading:
        return _buildLoadingState();
      case GameState.playing:
        return _buildPlayingState(context, viewModel);
      case GameState.revealed:
        return _buildRevealedState(context, viewModel);
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }

  Widget _buildAllSolvedState(BuildContext context, TriviaViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Congratulations!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve solved all flags!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Final Score: ${viewModel.score}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Reset logic would clear solved flags and restart
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingState(BuildContext context, TriviaViewModel viewModel) {
    final question = viewModel.currentQuestion;
    if (question == null) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        FlagImage(url: question.correct.flagUrl),
        const SizedBox(height: 24),
        Text(
          'Which country does this flag belong to?',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        AttemptsIndicator(attemptsMade: viewModel.attemptsMade),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: question.options.map((country) {
              return CountryOptionCard(
                country: country,
                isSelected: false,
                isCorrect: false,
                gameState: viewModel.gameState,
                onTap: () => viewModel.submitAnswer(country),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedState(BuildContext context, TriviaViewModel viewModel) {
    final question = viewModel.currentQuestion;
    if (question == null) {
      return _buildLoadingState();
    }

    // Check if all countries are solved
    if (viewModel.feedbackMessage == 'No more countries available!') {
      return _buildAllSolvedState(context, viewModel);
    }

    return Column(
      children: [
        FlagImage(url: question.correct.flagUrl),
        const SizedBox(height: 24),
        Text(
          'Which country does this flag belong to?',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        AttemptsIndicator(attemptsMade: viewModel.attemptsMade),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: question.options.map((country) {
              final isCorrect = country.isoCode == question.correct.isoCode;
              return CountryOptionCard(
                country: country,
                isSelected: false,
                isCorrect: isCorrect,
                gameState: viewModel.gameState,
                onTap: () {},
              );
            }).toList(),
          ),
        ),
        if (viewModel.feedbackMessage != null) ...[
          const SizedBox(height: 16),
          ResultBanner(
            message: viewModel.feedbackMessage!,
            isCorrect: viewModel.isLastAnswerCorrect,
            onNext: () => viewModel.loadNextQuestion(),
          ),
        ],
      ],
    );
  }
}
