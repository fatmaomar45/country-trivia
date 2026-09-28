// Basic smoke test for the Country Trivia app.
//
// For detailed widget tests, see test/widget/trivia_screen_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:country_trivia/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryTriviaApp());
    await tester.pump();

    // The app should show a loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
