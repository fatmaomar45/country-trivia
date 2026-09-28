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
    return Scaffold(
      appBar: const ScoreBoard(score: 0, solvedCount: 0, totalCount: 0),
      body: SafeArea(
        child: Consumer<TriviaViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(context, viewModel),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TriviaViewModel viewModel) {
    switch (viewModel.gameState) {
      case GameState.loading:
        return const Center(child: CircularProgressIndicator());

      case GameState.playing:
        return _buildPlayingState(context, viewModel);

      case GameState.revealed:
        return _buildRevealedState(context, viewModel);
    }
  }

  Widget _buildPlayingState(BuildContext context, TriviaViewModel viewModel) {
    final question = viewModel.currentQuestion;
    if (question == null) {
      return const Center(child: CircularProgressIndicator());
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
      return const Center(child: CircularProgressIndicator());
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
