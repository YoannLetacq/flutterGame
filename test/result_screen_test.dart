import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/ui/result_screen.dart';

void main() {
  testWidgets('ResultScreen displays result information', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultScreen(),
      ),
    );
    expect(find.text('Résultats de la partie'), findsOneWidget);
  });
}
