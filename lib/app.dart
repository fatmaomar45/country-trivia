import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/country_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/storage_service.dart';
import 'presentation/screens/trivia_screen.dart';
import 'presentation/viewmodels/trivia_viewmodel.dart';

/// The root widget of the Country Trivia app.
///
/// Sets up the Provider tree with all required dependencies.
class CountryTriviaApp extends StatelessWidget {
  const CountryTriviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Country Trivia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _AppHome(),
    );
  }
}

/// Internal home widget that initializes the Provider tree asynchronously.
class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  late final Future<TriviaViewModel> _viewModelFuture;

  @override
  void initState() {
    super.initState();
    _viewModelFuture = _createViewModel();
  }

  Future<TriviaViewModel> _createViewModel() async {
    final storageService = await StorageService.create();
    final repository = CountryRepository(
      ApiService(),
      storageService,
    );
    final viewModel = TriviaViewModel(
      repository: repository,
      storageService: storageService,
    );
    await viewModel.initialize();
    return viewModel;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TriviaViewModel>(
      future: _viewModelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to start: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _viewModelFuture = _createViewModel();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return ChangeNotifierProvider<TriviaViewModel>.value(
          value: snapshot.data!,
          child: const TriviaScreen(),
        );
      },
    );
  }
}
